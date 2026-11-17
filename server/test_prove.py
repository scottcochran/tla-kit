#!/usr/bin/env python3
"""The prove tool, and the tests of ADR-0016 item 7: each tries to break a property of spec/ProveRequests.tla.

    python3 server/test_prove.py        in the tla-kit image, which has tlapm, and /proc to read processes

It starts the server as `tla-kit mcp` (or server/tla_kit_mcp.py beside it) on a project made in a temporary
directory: the skill's fixture under spec/, with a copy of its proof whose NextBounded step is broken, under two
module names. Each failing run uses --stretch 3, so that SMT's 5 s limit becomes 15 s and the run can be overlapped,
cancelled and timed out. Responses are read as they come, in any order.

  ProveRequests property   test
  AtMostOneAnswer          a cancel during a run, while waiting for the cache, and after the response: no response
                           for a cancelled request, and nothing after a response
  SuccessOnlyComplete      a broken step is a failure, though tlapm exits 0; a timed-out run is a timeout
  NoProcessOutlives        after every answer and every cancel, no tlapm and no backend is alive
  OneWriterPerCache        two runs of one module at once take turns; two modules run side by side
  NothingInProject         nothing is written into the project
  AllReaped                after every answer, no zombie is left that the server should have reaped
"""
import json
import os
import queue
import shutil
import signal
import subprocess
import sys
import tempfile
import threading
import time

HERE = os.path.dirname(os.path.abspath(__file__))
SKILL = os.environ.get("TLA_KIT_SKILL") or os.path.join(os.path.dirname(HERE), "vendor", "writing-tla-specs-and-proofs")
FIXTURE = os.path.join(SKILL, "assets", "selftest")
BACKENDS = ("tlapm", "z3", "zenon", "poly", "isabelle", "ls4")
failures = []


def check(name, cond, detail=""):
    print(("ok    " if cond else "FAIL  ") + name + ("" if cond else f": {detail}"), flush=True)
    if not cond:
        failures.append(name)


def dump(why):
    """Every process, with its state, parent, group, what it waits on, and its command: printed when an answer is
    late, so that a stall in tlapm can be told from a fault of the server's."""
    print(f"----- {why}: every process", flush=True)
    for d in sorted((x for x in os.listdir("/proc") if x.isdigit()), key=int):
        try:
            raw = open(f"/proc/{d}/stat").read()
            cmd = open(f"/proc/{d}/cmdline").read().replace("\0", " ").strip()[:160]
        except OSError:
            continue
        try:
            wchan = open(f"/proc/{d}/wchan").read() or "-"
        except OSError:
            wchan = "?"
        f = raw[raw.rindex(")") + 2:].split()
        print(f"  pid {d} state {f[0]} ppid {f[1]} pgid {f[2]} wchan {wchan}: {cmd}", flush=True)
    print("-----", flush=True)


def procs():
    out = []
    for d in os.listdir("/proc"):
        if d.isdigit():
            try:
                raw = open(f"/proc/{d}/stat").read()
            except OSError:
                continue
            comm = raw[raw.index("(") + 1:raw.rindex(")")]
            f = raw[raw.rindex(")") + 2:].split()
            out.append({"pid": int(d), "comm": comm, "state": f[0], "ppid": int(f[1])})
    return out


def backends_alive():
    return [p for p in procs() if p["state"] != "Z" and any(b in p["comm"].lower() for b in BACKENDS)]


def zombies_of(pid):
    return [p for p in procs() if p["state"] == "Z" and p["ppid"] == pid]


class Client:
    def __init__(self, cmd, env):
        self.p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, env=env, bufsize=1)
        self.q, self.n = queue.Queue(), 0
        self.answers, self.arrived = {}, {}  # every response by id, and when it came: none is ever dropped
        threading.Thread(target=self.read, daemon=True).start()

    def read(self):
        for line in self.p.stdout:
            m = json.loads(line)
            if "id" in m:
                self.arrived[m["id"]] = time.time()
            self.q.put(m)

    def send(self, msg):
        self.p.stdin.write(json.dumps(msg) + "\n")
        self.p.stdin.flush()

    def request(self, method, params=None):
        self.n += 1
        self.send({"jsonrpc": "2.0", "id": self.n, "method": method, "params": params or {}})
        return self.n

    def prove(self, args):
        return self.request("tools/call", {"name": "prove", "arguments": args})

    def cancel(self, rid):
        self.send({"jsonrpc": "2.0", "method": "notifications/cancelled", "params": {"requestId": rid,
                                                                                    "reason": "test"}})

    def collect(self, seconds):
        """Every message that arrives within seconds."""
        got, end = [], time.time() + seconds
        while time.time() < end:
            try:
                got.append(self.q.get(timeout=max(0.01, end - time.time())))
            except queue.Empty:
                break
        return got

    def wait(self, rid, seconds=280, dump_after=150):
        """The response to rid, and any other message that came first. Responses to other requests are kept for
        their own wait: two requests may be answered in either order. If none has come after dump_after seconds,
        every process is printed once, while the stall lasts."""
        if rid in self.answers:
            return self.answers.pop(rid), []
        others, start, dumped = [], time.time(), False
        while time.time() < start + seconds:
            try:
                m = self.q.get(timeout=1.0)
            except queue.Empty:
                if not dumped and time.time() > start + dump_after:
                    dump(f"no answer to request {rid} after {dump_after} s")
                    print("----- the server's threads (SIGUSR1):", flush=True)
                    os.kill(self.p.pid, signal.SIGUSR1)
                    time.sleep(1)
                    dumped = True
                continue
            if m.get("id") == rid:
                return m, others
            if "id" in m:
                self.answers[m["id"]] = m
            others.append(m)
        return None, others


def result(m):
    """(structured result, is error?, text) of a response; a missing response is an error, not a crash."""
    if m is None:
        return None, True, "no response"
    r = m["result"]
    return r.get("structuredContent"), r.get("isError"), r["content"][0]["text"]


def snapshot(root):
    out = {}
    for d, _, files in os.walk(root):
        for f in files:
            out[os.path.relpath(os.path.join(d, f), root)] = open(os.path.join(d, f), "rb").read()
    return out


def settled(c, name):
    """No backend alive, and no zombie the server should have reaped, once a run's answer is in."""
    time.sleep(0.5)
    alive, zombies = backends_alive(), zombies_of(c.p.pid)
    check(f"{name}: no tlapm or backend alive, nothing unreaped", not alive and not zombies,
          {"alive": alive, "zombies": zombies})


def main():
    project = tempfile.mkdtemp(prefix="tla-kit-prove-test-")
    spec = os.path.join(project, "spec")
    os.makedirs(spec)
    for f in ("Counter.tla", "Counter_proof.tla"):
        shutil.copy(os.path.join(FIXTURE, f), spec)
    good = open(os.path.join(FIXTURE, "Counter_proof.tla")).read()
    broken = good.replace("  BY LimitNat DEF TypeOK, Bounded, Next, Step, vars", "  BY DEF Bounded")
    assert broken != good
    for name in ("Broken_proof", "Broken2_proof"):
        with open(os.path.join(spec, name + ".tla"), "w") as f:
            f.write(broken.replace("MODULE Counter_proof", "MODULE " + name))
    exe = shutil.which("tla-kit")
    cmd = [exe, "mcp"] if exe else [sys.executable, "-B", os.path.join(HERE, "tla_kit_mcp.py")]
    cache = tempfile.mkdtemp(prefix="tla-kit-prove-cache-")
    c = Client(cmd, dict(os.environ, TLA_KIT_PROJECT=project, TLA_KIT_CACHE=cache))
    c.wait(c.request("initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                                    "clientInfo": {"name": "test_prove", "version": "0"}}))
    c.send({"jsonrpc": "2.0", "method": "notifications/initialized"})
    before = snapshot(project)
    # A server-side limit well inside the test's wait: a tlapm that hangs comes back as a timeout, and a lost
    # answer stays missing, so the two can be told apart.
    slow = {"module": "spec/Broken_proof.tla", "theorem": "NextBounded", "stretch": 3, "nofp": True, "timeout": 200}
    try:
        # The fixture proves.
        m, _ = c.wait(c.prove({"module": "spec/Counter_proof.tla"}))
        s, err, text = result(m)
        check("prove: the fixture's whole module proves", not err and s["success"] and s["verdict"] == "proved"
              and s["counts"]["total"] > 0 and not s["unresolved"], text[:600])
        settled(c, "after a proof")

        # A broken step is a failure, with its text, backends and reasons, though tlapm exits 0.
        m, _ = c.wait(c.prove({"module": "spec/Broken_proof.tla", "theorem": "NextBounded"}))
        s, err, text = result(m)
        u = (s or {}).get("unresolved", [])
        provers = {x["prover"] for x in (u[0]["attempts"] if u else [])}
        check("prove: a broken step by name fails, with its text, backends and reasons", not err
              and not s["success"] and s["verdict"] == "failed" and s["exit"] == 0 and len(u) == 1
              and "PROVE" in (u[0]["text"] or "") and {"smt", "zenon", "isabelle"} <= provers
              and all(x["reason"] for x in u[0]["attempts"]) and s["scope"]["from_line"] == 12
              and s["scope"]["to_line"] == 15, text[:900])
        m, _ = c.wait(c.prove({"module": "spec/Broken_proof.tla", "line": 15}))
        s, err, text = result(m)
        check("prove: the same step by its line", not err and s["verdict"] == "failed" and len(s["unresolved"]) == 1,
              text[:400])
        m, _ = c.wait(c.prove({"module": "spec/Counter_proof.tla", "theorem": "<1>1"}))
        s, err, text = result(m)
        check("prove: an ambiguous step name is refused", err and "give the lines" in text, text)

        # SuccessOnlyComplete, NoProcessOutlives: a timeout kills the whole group.
        m, _ = c.wait(c.prove(dict(slow, timeout=4)))
        s, err, text = result(m)
        check("timeout: the run is a timeout, never a success", not err and s["verdict"] == "timeout"
              and not s["success"], text[:400])
        settled(c, "after a timeout")

        # OneWriterPerCache: one module twice at once takes turns; two modules run side by side.
        # Either request may take the module's cache first, so the order of the answers is not fixed: the later
        # answer must come at least most of a run after the earlier one.
        a, b = c.prove(slow), c.prove(slow)
        ma, _ = c.wait(a)
        mb, _ = c.wait(b)
        sa, sb = result(ma)[0] or {}, result(mb)[0] or {}
        gap = abs(c.arrived.get(a, 0) - c.arrived.get(b, 0))
        run = min(sa.get("seconds", 0), sb.get("seconds", 0))
        check("one module twice: both answered, one after the other", sa.get("verdict") == "failed"
              and sb.get("verdict") == "failed" and gap >= 0.8 * run,
              {"gap": round(gap, 1), "run": run, "verdicts": [sa.get("verdict"), sb.get("verdict")]})
        t0 = time.time()
        a, b = c.prove(slow), c.prove(dict(slow, module="spec/Broken2_proof.tla"))
        ma, _ = c.wait(a)
        mb, _ = c.wait(b)
        both = time.time() - t0
        sa, sb = result(ma)[0] or {}, result(mb)[0] or {}
        check("two modules: both answered, side by side", sa.get("verdict") == "failed"
              and sb.get("verdict") == "failed" and both < sa.get("seconds", 0) + sb.get("seconds", 0) - 2,
              {"together": round(both, 1), "first": [sa.get("verdict"), sa.get("seconds")],
               "second": [sb.get("verdict"), sb.get("seconds")]})
        settled(c, "after concurrent runs")

        # AtMostOneAnswer, NoProcessOutlives: a cancel during a run.
        rid = c.prove(slow)
        time.sleep(3)
        c.cancel(rid)
        got = c.collect(8)
        check("cancel during a run: no response", all(x.get("id") != rid for x in got), got)
        settled(c, "after a cancel during a run")

        # A cancel while the request waits for its module's cache: no response, and the first is answered.
        a = c.prove(slow)
        time.sleep(1)
        b = c.prove(slow)
        time.sleep(1)
        c.cancel(b)
        ma, others = c.wait(a)
        got = others + c.collect(4)
        check("cancel while waiting for the cache: no response, and the run ahead is answered",
              ma is not None and all(x.get("id") != b for x in got), got)

        # A cancel after the response changes nothing.
        rid = c.prove({"module": "spec/Counter_proof.tla", "theorem": "TypeInit"})
        m, _ = c.wait(rid)
        c.cancel(rid)
        p = c.request("ping")
        pm, others = c.wait(p, 10)
        got = others + c.collect(2)
        check("cancel after the response: nothing more is sent", pm is not None and m is not None
              and all(x.get("id") != rid for x in got), got)
        settled(c, "at the end")
    finally:
        c.p.stdin.close()
        c.p.wait(timeout=60)
    check("nothing was written into the project (NothingInProject)", snapshot(project) == before,
          sorted(set(snapshot(project)) ^ set(before)))
    shutil.rmtree(project, ignore_errors=True)
    shutil.rmtree(cache, ignore_errors=True)
    print(f"\n{'FAILED: ' + ', '.join(failures) if failures else 'prove: every check passed'}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
