#!/usr/bin/env python3
"""An MCP client test of tla-kit's server: it starts the server as a client does, over stdio, and drives every tool
against the skill's fixture (ADR-0008 item 5). It also checks what ADR-0006 and ADR-0008 item 3 promise: no tool but
tlc_rows writes into the project, and a path outside the project is refused.

    python3 server/test_mcp.py                                     the server run natively from this checkout
    python3 server/test_mcp.py -- docker run -i --rm --user "$(id -u):$(id -g)" -v {project}:/work IMAGE tla-kit mcp

The test makes a project in a temporary directory (the fixture under spec/, with a module that does not parse and a
link that leads out of the project), and `{project}` in the command is replaced by its path. Natively, the server
finds the checker as the skill does: TLA_JAR, else tools/tla2tools.jar above the spec, so TLA_JAR must be set.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
FIXTURE = os.path.join(os.path.dirname(HERE), "vendor", "writing-tla-specs-and-proofs", "assets", "selftest")
BAD = "---- MODULE Bad ----\nEXTENDS Naturals\nVARIABLE x\nInit == x = 0\nNext == x' = y + 1\n====\n"

failures = []


def check(name, cond, detail=""):
    print(("ok    " if cond else "FAIL  ") + name + ("" if cond else f": {detail}"), flush=True)
    if not cond:
        failures.append(name)


class Client:
    def __init__(self, cmd, env):
        self.p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, env=env, bufsize=1)
        self.next_id = 0

    def send(self, msg):
        self.p.stdin.write(json.dumps(msg) + "\n")
        self.p.stdin.flush()

    def request(self, method, params=None):
        self.next_id += 1
        self.send({"jsonrpc": "2.0", "id": self.next_id, "method": method, "params": params or {}})
        line = self.p.stdout.readline()
        if not line:
            raise SystemExit(f"the server closed its output during {method}")
        reply = json.loads(line)
        assert reply.get("id") == self.next_id, reply
        return reply

    def call(self, name, args):
        r = self.request("tools/call", {"name": name, "arguments": args})["result"]
        return r.get("structuredContent"), r.get("isError"), r["content"][0]["text"]

    def close(self):
        self.p.stdin.close()
        self.p.wait(timeout=60)


def snapshot(root):
    out = {}
    for d, _, files in os.walk(root):
        for f in files:
            p = os.path.join(d, f)
            if not os.path.islink(p):
                out[os.path.relpath(p, root)] = open(p, "rb").read()
    return out


def main(argv):
    project = tempfile.mkdtemp(prefix="tla-kit-mcp-test-")
    os.chmod(project, 0o777)
    spec = os.path.join(project, "spec")
    os.makedirs(spec)
    for f in ("Counter.tla", "Counter-rows.txt", "Counter_proof.tla"):
        shutil.copy(os.path.join(FIXTURE, f), spec)
    with open(os.path.join(spec, "Bad.tla"), "w") as f:
        f.write(BAD)
    os.symlink("/etc", os.path.join(spec, "outside"))
    os.system(f"chmod -R a+rwX {project}")

    in_image = "--" in argv
    if in_image:
        cmd = [a.replace("{project}", project) for a in argv[argv.index("--") + 1:]]
        env = dict(os.environ)
    else:
        cmd = [sys.executable, "-B", os.path.join(HERE, "tla_kit_mcp.py")]
        env = dict(os.environ, TLA_KIT_PROJECT=project)
    print("server: " + " ".join(cmd), flush=True)
    c = Client(cmd, env)
    try:
        r = c.request("initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                                     "clientInfo": {"name": "tla-kit-test", "version": "0"}})["result"]
        check("initialize names the protocol version and the server", r["protocolVersion"] == "2025-06-18"
              and r["serverInfo"]["name"] == "tla-kit", r)
        c.send({"jsonrpc": "2.0", "method": "notifications/initialized"})
        check("ping", c.request("ping")["result"] == {})
        tools = [t["name"] for t in c.request("tools/list")["result"]["tools"]]
        check("tools/list has the nine tools of Phase 3, the five of Phase 4 and lemma_graph", sorted(tools) == sorted(
            ["info", "parse", "symbols", "evaluate", "tlc_run", "simulate", "coverage", "state_graph", "tlc_rows",
             "prove", "proof_check", "proof_results", "flip_test", "proof_sync", "lemma_graph"]), tools)
        check("an unknown method is an error", c.request("nonesuch")["error"]["code"] == -32601)

        before = snapshot(project)

        s, err, text = c.call("info", {})
        check("info", not err and (s.get("image") or s.get("checker", {}).get("pinned")), text)

        s, err, text = c.call("parse", {"module": "spec/Counter.tla"})
        check("parse: Counter parses", not err and s["ok"] and "Counter" in s["modules_parsed"], text)
        s, err, text = c.call("parse", {"module": "spec/Bad"})
        check("parse: Bad's unknown operator, with its location", not err and not s["ok"] and any(
            e["line"] == 5 and "Unknown operator" in e["message"] for e in s["errors"]), text)

        # A proof module extends TLAPS, which SANY finds only in the prover's library. The image has one; natively the
        # server finds it only when TLAPM names a prover.
        if in_image or os.environ.get("TLAPM"):
            s, err, text = c.call("parse", {"module": "spec/Counter_proof.tla"})
            check("parse: a proof module, with TLAPS from the prover's library", not err and s["ok"]
                  and "TLAPS" in s["modules_parsed"], text)
            s, err, text = c.call("symbols", {"module": "spec/Counter_proof.tla"})
            names = {x["name"] for x in (s or {}).get("theorems", [])}
            check("symbols: a proof module's theorems", not err and {"TypeInit", "NextBounded", "BoundedAlways",
                                                                      "SafeAlways", "MutNoLimitAllowsStep"} <= names,
                  text)
            s, err, text = c.call("lemma_graph", {"module": "spec/Counter_proof.tla"})
            check("lemma_graph: the fixture's citations (its own tests are test_lemma_graph.py)", not err
                  and ["BoundedAlways", "SafeAlways"] in s["edges"] and len(s["edges"]) == 4
                  and "working output" in s["label"], text)
        else:
            print("skip  parse, symbols and lemma_graph on a proof module: natively, TLAPM names no prover",
                  flush=True)

        s, err, text = c.call("symbols", {"module": "spec/Counter.tla"})
        ok = not err and [v["name"] for v in s["variables"]] == ["n", "over"] and \
            [x["name"] for x in s["constants"]] == ["Mut", "Limit"]
        levels = {d["name"]: d["level"] for d in (s or {}).get("definitions", [])}
        check("symbols: Counter's constants, variables and the levels of its definitions",
              ok and levels.get("Step") == "action" and levels.get("Reaches") == "temporal"
              and levels.get("TypeOK") == "state", text)

        s, err, text = c.call("evaluate", {"expression": "{x * 2 : x \\in 1..4}"})
        check("evaluate: a constant expression", not err and s["value"] == "{2, 4, 6, 8}", text)
        s, err, text = c.call("evaluate", {"expression": "Limit + 1", "module": "spec/Counter.tla", "mut": "none"})
        check("evaluate: with a module, at its row list's constants", not err and s["value"] == "4", text)
        s, err, text = c.call("evaluate", {"expression": "1 \\div 0"})
        check("evaluate: an error is reported as one", err and "div" in text, text)

        s, err, text = c.call("tlc_run", {"module": "spec/Counter.tla", "mut": "none", "property": "Bounded",
                                          "states": 4})
        check("tlc_run: c-none-bounded HOLDS in 4 states", not err and s["verdict"] == "HOLDS"
              and s["count"] == "4 distinct states" and s["as_expected"], text)
        s, err, text = c.call("tlc_run", {"module": "spec/Counter.tla", "mut": "M_NOLIMIT", "property": "Bounded",
                                          "constraint": "Small", "expect": "COUNTEREXAMPLE"})
        trace = (s or {}).get("trace", [])
        check("tlc_run: c-nolimit-bounded COUNTEREXAMPLE, with its trace as states", not err
              and s["verdict"] == "COUNTEREXAMPLE" and trace and trace[0]["action"] == "Initial predicate"
              and trace[-1]["vars"].get("over") == "TRUE" and trace[1]["action"] == "Step", text)
        s, err, text = c.call("tlc_run", {"module": "spec/Counter.tla", "mut": "none", "property": "TypeOK",
                                          "kind": "DEADLOCK"})
        check("tlc_run: d-none-terminal DEADLOCK", not err and s["verdict"] == "DEADLOCK", text)
        s, err, text = c.call("tlc_run", {"module": "spec/Counter.tla", "mut": "none", "property": "Reaches",
                                          "kind": "PROPERTY"})
        trace = (s or {}).get("trace", [])
        check("tlc_run: l-nofair-reaches COUNTEREXAMPLE, ending in stuttering", not err
              and s["verdict"] == "COUNTEREXAMPLE" and trace and trace[-1]["action"] == "Stuttering", text)

        s, err, text = c.call("simulate", {"module": "spec/Counter.tla", "mut": "none", "property": "Bounded",
                                           "depth": 10, "num": 50, "seed": 7})
        check("simulate: s-none-bounded NO-ERROR-SAMPLED, labelled as sampling", not err
              and s["verdict"] == "NO-ERROR-SAMPLED" and s["sampling"] and "sampling" in s["label"], text)

        s, err, text = c.call("coverage", {"module": "spec/Counter.tla", "mut": "none"})
        acts = {x["action"]: x for x in (s or {}).get("actions", [])}
        check("coverage: Init and Step fire", not err and set(acts) >= {"Init", "Step"} and not s["never_fired"], text)
        s, err, text = c.call("coverage", {"module": "spec/Counter.tla", "mut": "none", "constants": {"Limit": "0"}})
        check("coverage: at Limit = 0, Step never fires", not err and s["never_fired"] == ["Step"], text)

        s, err, text = c.call("state_graph", {"module": "spec/Counter.tla", "mut": "none"})
        check("state_graph: 4 states, 1 initial, 3 Step edges", not err and len(s["nodes"]) == 4
              and sum(n["initial"] for n in s["nodes"]) == 1 and len(s["edges"]) == 3
              and {e["action"] for e in s["edges"]} == {"Step"}, text)
        s, err, text = c.call("state_graph", {"module": "spec/Counter.tla", "mut": "none", "max_states": 2})
        check("state_graph: refuses a model above max_states", err and "max_states" in text, text)

        s, err, text = c.call("parse", {"module": "../../etc/passwd"})
        check("a path outside the project is refused", err and "outside the project" in text, text)
        s, err, text = c.call("parse", {"module": "spec/outside/hosts"})
        check("a link leading out of the project is refused", err and "outside the project" in text, text)
        s, err, text = c.call("tlc_run", {"module": "spec/Counter.tla", "property": "Bounded", "path": "x"})
        check("an unknown argument is refused", err and "unknown arguments" in text, text)

        s, err, text = c.call("tlc_rows", {"rows": "spec/Counter-rows.txt", "jobs": 2, "dry_run": True})
        check("tlc_rows: dry run, every row as expected, nothing written", not err and s["exit"] == 0
              and s["summary"].startswith("11 rows: 11 as expected") and not s["results_files_written"], text)

        check("no tool but tlc_rows wrote into the project (ADR-0006)", snapshot(project) == before,
              sorted(set(snapshot(project)) ^ set(before)))

        s, err, text = c.call("tlc_rows", {"rows": "spec/Counter-rows.txt", "jobs": 2, "date": "2000.01.01"})
        written = (s or {}).get("results_files_written", [])
        check("tlc_rows: writes the generator's results file", not err and s["exit"] == 0
              and written == ["spec/Counter-results-2000.01.01.txt"], text)
        if written:
            body = open(os.path.join(project, written[0])).read()
            check("tlc_rows: the file is the generator's", body.splitlines()[1].startswith("TLC results 2000.01.01, "
                                                                                          "generated by tlc_rows.py"),
                  body[:300])
        s, err, text = c.call("unknown_tool", {})
        check("an unknown tool is a tool error", err, text)
    finally:
        c.close()
        shutil.rmtree(project, ignore_errors=True)
    print(f"\n{'FAILED: ' + ', '.join(failures) if failures else 'mcp: every check passed'}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
