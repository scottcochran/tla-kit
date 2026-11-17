#!/usr/bin/env python3
"""ADR-0016 item 6: test three assumptions about tlapm in the tla-kit image.

    python3 assumptions.py WORKDIR > report.json

WORKDIR holds Counter.tla, Counter_proof.tla (as the fixture has it) and Broken_proof.tla and Broken2_proof.tla
(the fixture's proof with NextBounded's BY cut, under two module names). Everything else is written under /tmp.

  groups   Where tlapm's backends run: every descendant of tlapm, sampled every 0.05 s while it runs, with its
           process group and session, against tlapm's own (tlapm started in a session of its own).
  kill     What a kill leaves. (a) SIGKILL to tlapm's whole group mid-run: which descendants survive, what is in the
           cache, and whether the next run on that cache completes with the same statuses as a clean run.
           (b) SIGKILL to tlapm alone, the naive design: which descendants survive it.
  shared   Two tlapm processes started together on one cache directory: on the same module, and on two modules.
           Their outputs, any error they print, and whether a third run on that cache completes as a clean one.
"""
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import time

WORK = os.path.abspath(sys.argv[1])
STEP = ["--toolbox", "12", "15", "--stretch", "3"]  # the broken step; SMT's 5 s limit becomes 15 s


def stat(pid):
    try:
        raw = open(f"/proc/{pid}/stat").read()
    except OSError:
        return None
    comm = raw[raw.index("(") + 1:raw.rindex(")")]
    f = raw[raw.rindex(")") + 2:].split()
    return {"pid": pid, "comm": comm, "state": f[0], "ppid": int(f[1]), "pgid": int(f[2]), "sid": int(f[3])}


def live(pid):
    """A process that exists and is not a zombie: a zombie is dead, only not yet reaped."""
    s = stat(pid)
    return s if s and s["state"] != "Z" else None


def all_procs():
    return {int(d): s for d in os.listdir("/proc") if d.isdigit() for s in [stat(int(d))] if s}


def descendants(root, procs):
    out, frontier = {}, {root}
    while frontier:
        nxt = {p for p, s in procs.items() if s["ppid"] in frontier and p not in out and p != root}
        for p in nxt:
            out[p] = procs[p]
        frontier = nxt
    return out


def start(module, cache, extra=()):
    return subprocess.Popen(["tlapm"] + list(extra) + ["--cache-dir", cache, module], cwd=WORK,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, start_new_session=True)


def summary(out):
    statuses = {}
    for block in re.findall(r"@!!BEGIN\n(.*?)@!!END", out, re.S):
        if "@!!type:obligation\n" in block:
            loc = re.search(r"@!!loc:(\S+)", block).group(1)
            st = re.search(r"@!!status:(.*)", block).group(1)
            prover = re.search(r"@!!prover:(\S+)", block)
            statuses.setdefault(loc, []).append(st + (f" ({prover.group(1)})" if prover else ""))
    final = {loc: v[-1] for loc, v in statuses.items()}
    lines = [l for l in out.splitlines() if re.match(r"\[(ERROR|INFO|WARNING)\]", l) or "rror" in l or "xception" in l]
    return {"final_status_by_location": final, "notable_lines": lines[:12]}


def cache_listing(cache):
    out = []
    for d, _, files in os.walk(cache):
        for f in files:
            p = os.path.join(d, f)
            out.append(f"{os.path.relpath(p, cache)} {os.path.getsize(p)}")
    return sorted(out)


def wait_for_backend(p, names=("z3", "zenon", "isabelle", "poly", "ls4", "smt", "cvc5"), limit=20):
    end = time.time() + limit
    while time.time() < end and p.poll() is None:
        d = descendants(p.pid, all_procs())
        if any(any(n in s["comm"].lower() for n in names) for s in d.values()):
            return d
        time.sleep(0.05)
    return descendants(p.pid, all_procs())


def test_groups():
    cache = "/tmp/c-groups"
    p = start("Broken_proof.tla", cache, STEP)
    me = stat(p.pid)
    seen = {}
    while p.poll() is None:
        for pid, s in descendants(p.pid, all_procs()).items():
            seen.setdefault((s["comm"], s["pgid"], s["sid"]), set()).add(pid)
        time.sleep(0.05)
    out = p.stdout.read()
    after = descendants(p.pid, all_procs())  # orphans are re-parented, so this is checked by pid below
    alive = [pid for pids in seen.values() for pid in pids if live(pid)]
    zombies = [pid for pids in seen.values() for pid in pids if stat(pid) and not live(pid)]
    return {"tlapm": {"pid": p.pid, "pgid": me["pgid"], "sid": me["sid"]}, "exit": p.returncode,
            "descendants_seen": [{"comm": c, "pgid": g, "sid": s, "in_tlapm_group": g == me["pgid"],
                                  "count": len(pids)} for (c, g, s), pids in sorted(seen.items())],
            "descendants_alive_after_exit": [stat(x) for x in alive],
            "descendants_zombie_after_exit": [stat(x) for x in zombies], "result": summary(out)}


def run_to_end(module, cache, extra=STEP):
    p = start(module, cache, extra)
    out, _ = p.communicate(timeout=600)
    return p.returncode, out


def test_kill():
    clean_code, clean_out = run_to_end("Broken_proof.tla", "/tmp/c-clean")
    res = {"clean_run": {"exit": clean_code, **summary(clean_out)}}
    # (a) the whole group
    cache = "/tmp/c-killgroup"
    p = start("Broken_proof.tla", cache, STEP)
    d = wait_for_backend(p)
    time.sleep(1.0)
    d.update(descendants(p.pid, all_procs()))
    os.killpg(p.pid, signal.SIGKILL)
    p.wait()
    time.sleep(1.0)
    res["kill_group"] = {"descendants_at_kill": sorted({s["comm"] for s in d.values()}),
                         "survivors": [stat(x) for x in d if live(x)], "cache_after_kill": cache_listing(cache)}
    code, out = run_to_end("Broken_proof.tla", cache)
    res["kill_group"]["rerun_on_that_cache"] = {"exit": code, **summary(out),
                                                "same_final_statuses_as_clean": summary(out)["final_status_by_location"]
                                                == res["clean_run"]["final_status_by_location"]}
    # (b) tlapm alone
    cache = "/tmp/c-killone"
    p = start("Broken_proof.tla", cache, STEP)
    d = wait_for_backend(p)
    time.sleep(1.0)
    d.update(descendants(p.pid, all_procs()))
    os.kill(p.pid, signal.SIGKILL)
    p.wait()
    time.sleep(1.0)
    survivors = [stat(x) for x in d if live(x)]
    res["kill_tlapm_alone"] = {"descendants_at_kill": sorted({s["comm"] for s in d.values()}),
                               "survivors": survivors}
    for s in survivors:  # leave nothing running
        try:
            os.killpg(s["pgid"], signal.SIGKILL)
        except OSError:
            pass
    return res


def test_shared():
    res = {}
    for name, mods in (("same_module", ["Broken_proof.tla", "Broken_proof.tla"]),
                       ("two_modules", ["Broken_proof.tla", "Broken2_proof.tla"])):
        cache = f"/tmp/c-shared-{name}"
        ps = [start(m, cache, STEP) for m in mods]
        outs = [p.communicate(timeout=600)[0] for p in ps]
        runs = [{"module": m, "exit": p.returncode, **summary(o)} for m, p, o in zip(mods, ps, outs)]
        listing = cache_listing(cache)
        third = {}
        for m in sorted(set(mods)):
            code, out = run_to_end(m, cache)
            s = summary(out)
            third[m] = {"exit": code, **s, "already_true": len(re.findall(r"@!!already:true", out))}
        res[name] = {"concurrent_runs": runs, "cache_after": listing, "third_run_on_that_cache": third}
    return res


report = {"tlapm": subprocess.run(["sh", "-c", "head -3 $(command -v tlapm) >/dev/null 2>&1; tlapm --version"],
                                  capture_output=True, text=True).stdout.strip()}
for name, fn in (("groups", test_groups), ("kill", test_kill), ("shared", test_shared)):
    t0 = time.time()
    try:
        report[name] = fn()
    except Exception as e:  # a failed test is reported, and the others still run
        report[name] = {"error": repr(e)}
    report[name + "_seconds"] = round(time.time() - t0, 1)
json.dump(report, sys.stdout, indent=1)
