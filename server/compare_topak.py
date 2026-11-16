#!/usr/bin/env python3
"""Phase 3's "Done when": each tool of the MCP server returns what the command it stands for returns, on TOPAK's
`Alone` and `Coupling` (ADR-0008 item 5).

    python3 server/compare_topak.py TOPAK [--sample N] [--jobs N]

TOPAK is a checkout of TOPAK, read and never written. The script makes two scratch projects from its `Alone` and
`Coupling` with their module chains. The server is driven over stdio on one, as a client drives it, and each
command is run on the other. Then each pair is compared:

  info         tla-kit-info --json (in the image only)       the same JSON
  parse        SANY                                           the same outcome, and the same modules parsed
  symbols      SANY's XML exporter, read here                 the same constants, variables and definitions
  evaluate     TLC on a scratch module                        the same value, for the module's constants and its
                                                              constant-level definitions of no argument
  tlc_run      the skill's tlc_run.py                         the same row line, and a trace of the same length
  simulate     tlc_run.py --kind SIMULATE, the same seed      the same row line
  coverage     TLC -coverage                                  the same counts for every action
  state_graph  TLC -dump dot                                  the same states, initial states and edges
  tlc_rows     the skill's tlc_rows.py                        the same results file, byte for byte

Neither module has a row list in the skill's format, so one is written in each scratch project, from TOPAK's own
files: `Alone`'s rows are `spec/Alone-rows.txt`'s, under its documented constants (the file's `# Run: DEFAULTS=`
line); `Coupling`'s are the rows of `spec/Coupling-results-2026.09.29.txt`, at the constants its header names.

In the image, the server is `tla-kit mcp`; from a checkout it is server/tla_kit_mcp.py, with TLA_JAR set. --sample
runs tlc_run on the first N rows of each module rather than all. Exits non-zero on any difference.
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
SKILL = os.environ.get("TLA_KIT_SKILL") or os.path.join(os.path.dirname(HERE), "vendor", "writing-tla-specs-and-proofs")
SCRIPTS = os.path.join(SKILL, "scripts")
sys.path.insert(0, SCRIPTS)
import tla_common as t  # noqa: E402

DATE = "2000.01.01"
results = []


def same(tool, module, a, b, what=""):
    ok = a == b
    results.append((tool, module, ok))
    print(f"{'same   ' if ok else 'DIFFERS'} {tool:11} {module:9} {what}", flush=True)
    if not ok:
        print(f"        server:  {json.dumps(a)[:600]}\n        command: {json.dumps(b)[:600]}", flush=True)
    return ok


# ---------------------------------------------------------------------------------------------------------------
# The scratch projects, and a row list in the skill's format for each module

def alone_rows(topak):
    src = open(os.path.join(topak, "spec", "Alone-rows.txt"), encoding="utf-8").read()
    m = re.search(r"DEFAULTS='([^']*)'", src)
    consts = [kv.split("=", 1) for kv in m.group(1).split()]
    body = [line for line in src.splitlines() if line.strip() and not line.lstrip().startswith("#")]
    head = ["# module: Alone", "# title: Alone.tla, rows from TOPAK's spec/Alone-rows.txt"]
    head += [f"# const: {k} = {v}" for k, v in consts]
    return "\n".join(head + body) + "\n"


def coupling_rows(topak):
    src = open(os.path.join(topak, "spec", "Coupling-results-2026.09.29.txt"), encoding="utf-8").read()
    consts = re.search(r"constants: ([^;·]+?)(?:;|·|$)", src, re.M).group(1)
    head = ["# module: Coupling", "# title: Coupling.tla, rows from TOPAK's spec/Coupling-results-2026.09.29.txt"]
    head += [f"# const: {k.strip()} = {v.strip()}" for k, v in (c.split("=") for c in consts.split(","))]
    rows = []
    for line in src.splitlines():
        f = [x.strip() for x in line.split(" | ")]
        if len(f) >= 4 and f[1].startswith("Mut="):
            rows.append(f"{f[0]} {f[1][4:]} Spec INVARIANT {f[2]} {f[3]}")
    return "\n".join(head + rows) + "\n"


def make_project(topak, dest):
    spec = os.path.join(dest, "spec")
    os.makedirs(spec)
    for module in ("Alone", "Coupling"):
        for m in t.module_chain(module, os.path.join(topak, "spec")):
            shutil.copy(os.path.join(topak, "spec", m + ".tla"), spec)
    with open(os.path.join(spec, "Alone-rows.txt"), "w", encoding="utf-8") as f:
        f.write(alone_rows(topak))
    with open(os.path.join(spec, "Coupling-rows.txt"), "w", encoding="utf-8") as f:
        f.write(coupling_rows(topak))
    os.system(f"chmod -R a+rwX {dest}")
    return spec


# ---------------------------------------------------------------------------------------------------------------
# The server, over stdio

class Server:
    def __init__(self, project):
        exe = shutil.which("tla-kit")
        cmd = [exe, "mcp"] if exe else [sys.executable, "-B", os.path.join(HERE, "tla_kit_mcp.py")]
        env = dict(os.environ, TLA_KIT_PROJECT=project, TLA_PROJECT="TOPAK")
        self.p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, env=env, bufsize=1)
        self.n = 0
        self.request("initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                                    "clientInfo": {"name": "compare_topak", "version": "0"}})
        self.p.stdin.write(json.dumps({"jsonrpc": "2.0", "method": "notifications/initialized"}) + "\n")

    def request(self, method, params):
        self.n += 1
        self.p.stdin.write(json.dumps({"jsonrpc": "2.0", "id": self.n, "method": method, "params": params}) + "\n")
        self.p.stdin.flush()
        return json.loads(self.p.stdout.readline())

    def call(self, name, args):
        r = self.request("tools/call", {"name": name, "arguments": args})["result"]
        if r.get("isError"):
            return {"error": r["content"][0]["text"]}
        return r["structuredContent"]

    def close(self):
        self.p.stdin.close()
        self.p.wait(timeout=60)


# ---------------------------------------------------------------------------------------------------------------
# The commands, run directly

def run(cmd, cwd, env=None):
    p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, env=env)
    return p.returncode, t.quiet(p.stdout + p.stderr)


def jar():
    return t.require_checker(t.Layout(os.getcwd())).path


def java(tmp, main, args):
    return ["java", "-XX:+UseParallelGC", "-Xmx2g", f"-Djava.io.tmpdir={tmp}", "-cp", jar(), main] + args


def in_copy(spec, module, fn):
    """fn(tmp) run on a copy of the module chain, as the server's tools run, in a directory removed after."""
    tmp = tempfile.mkdtemp(prefix="compare-")
    try:
        for m in t.module_chain(module, spec):
            shutil.copy(os.path.join(spec, m + ".tla"), tmp)
        return fn(tmp)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


SANY_ERROR = re.compile(r"\*\*\* ?(Errors?|Parse Error|Abort)|^Fatal errors|^Semantic errors:", re.M)


def cmd_parse(spec, module):
    def go(tmp):
        _, out = run(java(tmp, "tla2sany.SANY", [module + ".tla"]), tmp)
        return {"ok": not SANY_ERROR.search(out), "modules": re.findall(r"Semantic processing of module (\w+)", out)}
    return in_copy(spec, module, go)


def cmd_symbols(spec, module):
    def go(tmp):
        p = subprocess.run(java(tmp, "tla2sany.xml.XMLExporter", ["-o", module + ".tla"]), cwd=tmp,
                           capture_output=True, text=True)
        return p.stdout[p.stdout.find("<?xml"):]
    root = ET.fromstring(in_copy(spec, module, go))
    out = {"constants": set(), "variables": set(), "definitions": set()}
    for e in root.iter("entry"):
        node = e[1]
        if node.findtext("location/filename") != module:
            continue
        if node.tag == "OpDeclNode":
            key = {"2": "constants", "3": "variables"}.get(node.findtext("kind"))
            if key:
                out[key].add(node.findtext("uniquename"))
        elif node.tag == "UserDefinedOpKind":
            out["definitions"].add(node.findtext("uniquename"))
    return {k: sorted(v) for k, v in out.items()}


def cmd_evaluate(spec, module, meta, mut, expr):
    def go(tmp):
        var = None
        for m in t.module_chain(module, spec):
            v = re.search(r"\bVARIABLES?\s+(\w+)", t.strip_comments(t.read(os.path.join(spec, m + ".tla"))))
            var = var or (v.group(1) if v else None)
        consts = dict(t.default_consts(meta), Mut=f'"{mut}"')
        with open(os.path.join(tmp, "Ev.tla"), "w") as f:
            f.write(f"---- MODULE Ev ----\nEXTENDS {module}, TLC\nASSUME PrintT(<<\"ev\", {expr}, \"ve\">>)\n"
                    f"I == FALSE /\\ {var} = {var}\nN == FALSE /\\ {var}' = {var}\n====\n")
        with open(os.path.join(tmp, "Ev.cfg"), "w") as f:
            f.write("INIT I\nNEXT N\nCONSTANTS\n" + "".join(f"  {k} = {v}\n" for k, v in consts.items()))
        _, out = run(java(tmp, "tlc2.TLC", ["-config", "Ev.cfg", "-workers", "1", "-metadir",
                                             os.path.join(tmp, "m"), "Ev.tla"]), tmp)
        m = re.search(r'<<"ev", (.*), "ve">>', out, re.S)
        return m.group(1) if m else None
    return in_copy(spec, module, go)


def cmd_tlc_run(spec, module, args):
    code, out = run([sys.executable, "-B", os.path.join(SCRIPTS, "tlc_run.py"), module] + args + ["--trace"], spec)
    row = next((line for line in out.splitlines() if " | " in line), None)
    return row, len(re.findall(r"^State \d+: ", out, re.M)) + len(re.findall(r"^Back to state \d+", out, re.M))


def tlc_cfg(meta, mut):
    consts = dict(t.default_consts(meta), Mut=f'"{mut}"')
    return "SPECIFICATION Spec\nCONSTANTS\n" + "".join(f"  {k} = {v}\n" for k, v in consts.items()) + \
        "".join(c + "\n" for c in meta["cfg"])


def cmd_tlc(spec, module, meta, flags):
    def go(tmp):
        with open(os.path.join(tmp, "MC.cfg"), "w") as f:
            f.write(tlc_cfg(meta, "none"))
        _, out = run(java(tmp, "tlc2.TLC", ["-config", "MC.cfg", "-workers", "1", "-deadlock", "-metadir",
                                             os.path.join(tmp, "m")] + flags(tmp) + [module + ".tla"]), tmp)
        dot = os.path.join(tmp, "g.dot")
        return out, (open(dot).read() if os.path.exists(dot) else "")
    return in_copy(spec, module, go)


def coverage_counts(out):
    i = out.rfind("The coverage statistics")
    action = r"^<(\S+) line (\d+), col \d+ to line \d+, col \d+ of module \w+>: (\d+):(\d+)$"
    return [list(m) for m in re.findall(action, out[i:], re.M)]


# ---------------------------------------------------------------------------------------------------------------

def compare_module(srv, a_spec, b_spec, module, sample, jobs):
    meta, rows = t.parse_rows(os.path.join(b_spec, f"{module}-rows.txt"))
    mod = f"spec/{module}.tla"

    s = srv.call("parse", {"module": mod})
    same("parse", module, {"ok": s.get("ok"), "modules": s.get("modules_parsed")}, cmd_parse(b_spec, module))

    s = srv.call("symbols", {"module": mod})
    mine = {k: sorted(x["name"] for x in s.get(k, [])) for k in ("constants", "variables", "definitions")}
    same("symbols", module, mine, cmd_symbols(b_spec, module),
         f"{len(mine['constants'])} constants, {len(mine['variables'])} variables, "
         f"{len(mine['definitions'])} definitions")

    names = [x["name"] for x in s.get("constants", []) if x["name"] != "Mut"]
    exprs = ["<<" + ", ".join(names) + ">>"]
    exprs += [d["name"] for d in s.get("definitions", []) if d["level"] == "constant" and d["arity"] == 0][:5]
    for e in exprs:
        v = srv.call("evaluate", {"expression": e, "module": mod, "mut": "none"})
        same("evaluate", module, v.get("value", v.get("error")), cmd_evaluate(b_spec, module, meta, "none", e), e)

    for row in rows[:sample] if sample else rows:
        consts, opts = dict(row["consts"]), row["opts"]
        args = {"module": mod, "mut": row["mut"], "property": row["prop"], "kind": row["kind"],
                "spec": row["spec"], "expect": row["exp"]}
        if consts:
            args["constants"] = consts
        for k in ("states", "constraint"):
            if k in opts:
                args[k] = int(opts[k]) if k == "states" else opts[k]
        if row["kind"] == "SIMULATE":
            continue
        r = srv.call("tlc_run", args)
        cli = [row["mut"], row["prop"]] + [f"{k}={v}" for k, v in list(consts.items()) + list(opts.items())]
        cli += ["--kind", row["kind"], "--spec", row["spec"], "--workers", "1", "--expect", row["exp"]]
        same("tlc_run", module, [r.get("row"), len(r.get("trace", []))], list(cmd_tlc_run(b_spec, module, cli)),
             row["name"])

    inv = next(r["prop"] for r in rows if r["mut"] == "none" and r["kind"] == "INVARIANT" and r["exp"] == "HOLDS")
    r = srv.call("simulate", {"module": mod, "mut": "none", "property": inv, "depth": 20, "num": 200, "seed": 7})
    cli = ["none", inv, "depth=20", "num=200", "seed=7", "--kind", "SIMULATE", "--workers", "1"]
    same("simulate", module, r.get("row"), cmd_tlc_run(b_spec, module, cli)[0], f"{inv}, depth 20, 200, seed 7")

    r = srv.call("coverage", {"module": mod, "mut": "none"})
    mine = [[x["action"], str(x["line"]), str(x["distinct"]), str(x["found"])] for x in r.get("actions", [])]
    out, _ = cmd_tlc(b_spec, module, meta, lambda tmp: ["-coverage", "1"])
    same("coverage", module, mine, coverage_counts(out), f"{len(mine)} actions")

    r = srv.call("state_graph", {"module": mod, "mut": "none", "max_states": 100000})
    out, dot = cmd_tlc(b_spec, module, meta, lambda tmp: ["-dump", "dot,actionlabels", os.path.join(tmp, "g")])
    nodes = set(re.findall(r'^(-?\d+) \[label=', dot, re.M))
    initial = set(re.findall(r'^(-?\d+) \[label=.*style = filled', dot, re.M))
    edges = re.findall(r'^-?\d+ -> -?\d+ ', dot, re.M)
    mine = [len(r.get("nodes", [])), sum(n["initial"] for n in r.get("nodes", [])), len(r.get("edges", []))]
    same("state_graph", module, mine, [len(nodes), len(initial), len(edges)],
         f"{mine[0]} states, {mine[1]} initial, {mine[2]} edges")

    r = srv.call("tlc_rows", {"rows": f"spec/{module}-rows.txt", "jobs": jobs, "date": DATE})
    run([sys.executable, "-B", os.path.join(SCRIPTS, "tlc_rows.py"), f"spec/{module}-rows.txt", "-j", str(jobs),
         "--date", DATE], os.path.dirname(b_spec), env=dict(os.environ, TLA_PROJECT="TOPAK"))
    name = f"{module}-results-{DATE}.txt"
    a_file, b_file = os.path.join(a_spec, name), os.path.join(b_spec, name)
    a_bytes = open(a_file, "rb").read() if os.path.exists(a_file) else None
    b_bytes = open(b_file, "rb").read() if os.path.exists(b_file) else None
    ok = a_bytes is not None and a_bytes == b_bytes
    same("tlc_rows", module, ok, True, f"{name}: {r.get('summary')}" + ("" if ok else
         f" (server wrote {r.get('results_files_written')}; command {'wrote it' if b_bytes else 'wrote nothing'})"))


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("topak")
    ap.add_argument("--sample", type=int, default=0, help="tlc_run on the first N rows of each module only")
    ap.add_argument("--jobs", type=int, default=2)
    a = ap.parse_args(argv)
    topak = os.path.abspath(a.topak)
    tmp = tempfile.mkdtemp(prefix="compare-topak-")
    try:
        a_spec = make_project(topak, os.path.join(tmp, "server"))
        b_spec = make_project(topak, os.path.join(tmp, "command"))
        srv = Server(os.path.dirname(a_spec))
        try:
            s = srv.call("info", {})
            exe = shutil.which("tla-kit-info")
            if exe and s.get("image") is not None:
                same("info", "-", s["image"], json.loads(subprocess.run([exe, "--json"], capture_output=True,
                                                                          text=True).stdout))
            else:
                print("skip    info        -         not in the image", flush=True)
            for module in ("Alone", "Coupling"):
                compare_module(srv, a_spec, b_spec, module, a.sample, a.jobs)
        finally:
            srv.close()
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    bad = [f"{tool} {mod}" for tool, mod, ok in results if not ok]
    tools = sorted({tool for tool, _, _ in results})
    print(f"\ncompare: {len(results)} comparisons over {len(tools)} tools, " +
          ("all the same" if not bad else f"{len(bad)} differ: {', '.join(bad)}"))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
