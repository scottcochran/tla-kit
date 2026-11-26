#!/usr/bin/env python3
"""Tests of server/not_taken.py and of the server's not_taken tool (ADR-0023). They need Python and nothing else: no
checker runs.

    python3 server/test_not_taken.py                    natively, from a checkout
    python3 server/test_not_taken.py -- docker run -i --rm --user "$(id -u):$(id -g)" -v {project}:/work IMAGE tla-kit mcp

Each case builds a small project in a temporary directory, with one fault planted, and checks that the report names
that fault and no other. The last cases run the script on this repository's own tables, and drive the tool over stdio
as a client does; with a command after `--`, the server is that command, with `{project}` replaced by the project.
"""
import contextlib
import io
import json
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
sys.dont_write_bytecode = True
sys.path.insert(0, HERE)
import not_taken as nt  # noqa: E402

failures = []

RECORD = """# ADR-0001 — A counter is bounded

**Status:** Accepted · 2000.01.01

## Decision

1. **The counter never passes its limit.** It stops there.
2. **The counter starts at zero.**
3. **The limit is printed in the log.** Nothing checks this, by choice:
   logging is outside the model.

## Alternatives not taken

- **No limit.** The row shows the counter running away.
- **A proof.** Not while the limit is still being chosen.

## History

| Date | Change |
|---|---|
| 2000.01.01 | Drafted. |
| 2000.01.02 | The custodian chose to leave the start unchecked. |
"""
CLAIMS = "\t".join(nt.CLAIM_COLS) + """
C-0001-1a	ADR-0001 item 1	The counter never passes its limit	spec/Counter.tla	Bounded	c-bounded	m-nolimit	spec/Counter-results.txt	checked
C-0001-2a	ADR-0001 item 2	The counter starts at zero	spec/Counter.tla	-	-	-	-	-
"""
RESULTS = """Counter
c-bounded | Mut=none | Spec | Bounded | HOLDS | 4 distinct states | as expected
m-nolimit | Mut=M_NOLIMIT | Spec | Bounded | COUNTEREXAMPLE | 5 distinct states | as expected
"""
MODULE = "---- MODULE Counter ----\n(* The start is zero by\n   construction: Init says so. *)\n====\n"
GOOD = [
    "N-0001-1	spec/Counter.tla	proved	design	Not while the limit is still being chosen	ADR-0001 Alternatives	"
    "Not while the limit is still being chosen	the custodian	2000.01.01	-",
    "N-0001-2	C-0001-2a	property	design	Init says so	spec/Counter.tla	zero by construction	the assistant	"
    "2000.01.01	-",
    "N-0001-3	ADR-0001 item 1	alternative	design	No limit	ADR-0001 Alternatives	The row shows the counter running "
    "away	the custodian	2000.01.01	spec/Counter-results.txt: m-nolimit",
    "N-0001-4	ADR-0001 item 3	claim	design	Logging is outside the model	ADR-0001 item 3	Nothing checks this, by "
    "choice: logging is outside the model	the custodian	2000.01.01	-",
]


def run(args):
    """The script's exit status, with what it prints kept off the test's output."""
    with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
        return nt.main(args)


def check(name, cond, detail=""):
    print(("ok    " if cond else "FAIL  ") + name + ("" if cond else f": {detail}"), flush=True)
    if not cond:
        failures.append(name)


def project(entries=GOOD, claims=CLAIMS, table=True):
    root = tempfile.mkdtemp(prefix="tla-kit-not-taken-")
    os.makedirs(os.path.join(root, "spec"))
    os.makedirs(os.path.join(root, "decisions"))
    files = {"decisions/ADR-0001.md": RECORD, "spec/claims.tsv": claims, "spec/Counter-results.txt": RESULTS,
             "spec/Counter.tla": MODULE}
    if table:
        files["spec/not-taken.tsv"] = "# reasons\n" + "\t".join(nt.ENTRY_COLS) + "\n" + "\n".join(entries) + "\n"
    for path, text in files.items():
        with open(os.path.join(root, path), "w", encoding="utf-8") as f:
            f.write(text)
    os.system(f"chmod -R a+rwX {root}")
    return root


def snapshot(root):
    out = {}
    for d, _, files in os.walk(root):
        for f in files:
            p = os.path.join(d, f)
            out[os.path.relpath(p, root)] = (open(p, "rb").read(), os.stat(p).st_mtime_ns)
    return out


def steps(rep, claim):
    return {s["path"]: s for c in rep["claims"] if c["claim"] == claim for s in c["paths"]}


def faults(rep):
    return {e["id"]: (e["status"], " ".join(e["faults"])) for e in rep["faulty_rows"]}


def row(n, **change):
    cells = dict(zip(nt.ENTRY_COLS, GOOD[n].split("\t")))
    cells.update(change)
    return "\t".join(cells[c] for c in nt.ENTRY_COLS)


def one_fault(name, entries, status, words, claims=CLAIMS):
    root = project(entries, claims)
    try:
        f = faults(nt.build(root))
        check(name, len(f) == 1 and list(f.values())[0][0] == status and words in list(f.values())[0][1], f)
    finally:
        shutil.rmtree(root, ignore_errors=True)


def main(argv):
    # A sound table: every path is taken, explained, or follows from one that is.
    root = project()
    before = snapshot(root)
    rep = nt.build(root)
    a, b = steps(rep, "C-0001-1a"), steps(rep, "C-0001-2a")
    check("a sound table has no faulty row", rep["ok"] and not rep["faulty_rows"], rep["faulty_rows"])
    check("taken paths are read from the claims table", [a[p]["status"] for p in ("property", "checked", "breaks")]
          == ["TAKEN"] * 3 and "c-bounded" in a["checked"]["by"], a)
    check("a module's reason covers each of its claims", a["proved"]["status"] == "NOT TAKEN"
          and a["proved"]["entry"]["id"] == "N-0001-1" and a["proved"]["reason"] == "design", a["proved"])
    check("a path below one not taken follows from it", a["certified"] == {"path": "certified", "status": "FOLLOWS",
                                                                           "follows": "proved"}, a["certified"])
    check("a claim's own reason, quoted across a line break of its source", b["property"]["status"] == "NOT TAKEN"
          and b["property"]["entry"]["id"] == "N-0001-2" and b["checked"]["status"] == "FOLLOWS", b)
    check("nothing is unexplained", rep["summary"]["paths_unexplained"] == 0, rep["summary"])
    rec = nt.build(root, record="ADR-0001")
    items = {i["item"]: i for i in rec["items"]}
    check("a record's items: one with a claim, one with a reason for none", items["ADR-0001 item 1"]["status"]
          == "TAKEN" and items["ADR-0001 item 3"]["status"] == "NOT TAKEN"
          and items["ADR-0001 item 3"]["entries"][0]["id"] == "N-0001-4", items)
    alts = rec["alternatives"]
    check("a record's alternatives: the row with its evidence, and the record's own bullets not repeated",
          [x.get("entry", {}).get("id") for x in alts] == ["N-0001-3", None]
          and alts[0]["entry"]["evidence_rows"] == [{"row": "m-nolimit", "verdict": "COUNTEREXAMPLE",
                                                     "outcome": "as expected", "results": "spec/Counter-results.txt"}]
          and "A proof." in alts[1]["in_record"], alts)
    check("one claim, one path", [s["path"] for c in nt.build(root, claim="C-0001-1a", path="proved")["claims"]
                                 for s in c["paths"]] == ["proved"])
    check("the text report names each reason", all(w in nt.as_text(rec) for w in (
        "NOT TAKEN    design", "follows from proved", "evidence: m-nolimit COUNTEREXAMPLE", "N-0001-4")),
        nt.as_text(rec))
    check("it writes nothing", snapshot(root) == before)
    check("exit 0 on a sound table", run(["--root", root, "--json"]) == 0)
    shutil.rmtree(root, ignore_errors=True)

    # No reasons at all: every path not taken is unexplained, and that is not a fault of a row.
    root = project(table=False)
    rep = nt.build(root)
    a, b = steps(rep, "C-0001-1a"), steps(rep, "C-0001-2a")
    check("with no reasons table, a path not taken is UNEXPLAINED, never given a reason", a["proved"]["status"]
          == "UNEXPLAINED" and b["property"]["status"] == "UNEXPLAINED" and b["proved"]["status"] == "FOLLOWS"
          and rep["summary"]["paths_unexplained"] == 2 and rep["ok"], rep["summary"])
    check("--open lists what is owed", [c["claim"] for c in nt.build(root, only_open=True)["claims"]]
          == ["C-0001-1a", "C-0001-2a"])
    check("exit 0 with unexplained paths, and 1 with --strict", run(["--root", root, "--json"]) == 0
          and run(["--root", root, "--json", "--strict"]) == 1)
    check("an item with no claim and no row is reported as that, not as a fault",
          {i["item"]: i["status"] for i in nt.build(root, record="ADR-0001")["items"]}["ADR-0001 item 3"]
          == "NO CLAIM")
    shutil.rmtree(root, ignore_errors=True)

    # One fault each.
    one_fault("BAD: the source no longer says the quoted words", GOOD[:1] + [row(1, quote="zero by decree")] + GOOD[2:],
              "BAD", "does not say")
    one_fault("BAD: the quoted words are in another item of the record",
              GOOD[:3] + [row(3, source="ADR-0001 item 2")], "BAD", "item 2 does not say")
    one_fault("BAD: a source outside the project", [row(1, source="../../etc/hostname")] + GOOD[2:], "BAD",
              "outside the project")
    one_fault("BAD: a source that does not exist", [row(1, source="spec/Gone.tla")] + GOOD[2:], "BAD", "no file")
    one_fault("BAD: a History row that does not exist", [row(0, source="ADR-0001 History 1999.01.01")], "BAD",
              "no History row")
    one_fault("a History row that exists is a source", [row(0, source="ADR-0001 History 2000.01.02",
                                                           quote="leave the start unchecked"),
                                                       row(1, reason="nonsense")], "BAD", "the reason")
    one_fault("BAD: a claim the table does not have", [row(1, **{"from": "C-0001-9z"})], "BAD", "is not a claim")
    one_fault("BAD: an evidence row the results file lacks", [row(2, evidence="spec/Counter-results.txt: m-gone")],
              "BAD", "has no row m-gone")
    one_fault("BAD: a proved path cannot start from a record", [row(0, **{"from": "ADR-0001"})], "BAD",
              "starts from a claim or a module")
    one_fault("BAD: no quote", [row(1, quote="-")], "BAD", "no quote")
    one_fault("BAD: an id given twice", GOOD[:1] + [row(1, id="N-0001-1")], "BAD", "given twice")
    one_fault("OUT OF DATE: a claim's reason for a path it now takes",
              [row(1, **{"from": "C-0001-1a", "path": "breaks"})], "OUT OF DATE", "takes the breaks path now")
    proved = CLAIMS.replace("\tchecked\n", "\tproved\n").replace("C-0001-2a\tADR-0001 item 2\tThe counter starts at "
                                                                 "zero\tspec/Counter.tla", "C-0001-2a\tADR-0001 item "
                                                                 "2\tThe counter starts at zero\tspec/Other.tla")
    one_fault("OUT OF DATE: a module's reason when every claim of it takes the path", GOOD[:1], "OUT OF DATE",
              "every claim of spec/Counter.tla takes the proved path now", claims=proved)
    one_fault("OUT OF DATE: a reason for no claim, on an item that has one now",
              [row(3, **{"from": "ADR-0001 item 2", "source": "ADR-0001 item 3"})], "OUT OF DATE", "has a claim now")
    root = project([row(1, quote="zero by decree")])
    check("exit 1 on a faulty row, and the text names it", run(["--root", root, "--json"]) == 1
          and "BAD: source: spec/Counter.tla does not say" in nt.as_text(nt.build(root)))
    os.remove(os.path.join(root, "spec", "claims.tsv"))
    check("exit 2 with no claims table", run(["--root", root]) == 2)
    shutil.rmtree(root, ignore_errors=True)

    # This repository's own tables.
    rep = nt.build(REPO)
    check("tla-kit's own reasons table has no faulty row", rep["ok"], rep["faulty_rows"])
    s = rep["summary"]
    check("tla-kit's paths add up", s["paths_taken"] + s["paths_not_taken_with_a_reason"] + s["paths_unexplained"]
          + s["paths_that_follow_from_another"] == 5 * s["claims"], s)
    check("C-0016-4c has no property, by design, and the module still says why",
          steps(rep, "C-0016-4c")["property"].get("reason") == "design")

    # The tool, over stdio, as a client calls it.
    root = project()
    before = snapshot(root)
    if "--" in argv:
        cmd = [x.replace("{project}", root) for x in argv[argv.index("--") + 1:]]
        env = dict(os.environ)
    else:
        cmd = [sys.executable, "-B", os.path.join(HERE, "tla_kit_mcp.py")]
        env = dict(os.environ, TLA_KIT_PROJECT=root)
    print("server: " + " ".join(cmd), flush=True)

    def call(n, args):
        return {"jsonrpc": "2.0", "id": n, "method": "tools/call", "params": {"name": "not_taken", "arguments": args}}

    msgs = [{"jsonrpc": "2.0", "id": 1, "method": "initialize",
             "params": {"protocolVersion": "2025-06-18", "capabilities": {}, "clientInfo": {"name": "test"}}},
            {"jsonrpc": "2.0", "method": "notifications/initialized"},
            {"jsonrpc": "2.0", "id": 2, "method": "tools/list"},
            call(3, {"claim": "C-0001-2a"}), call(4, {"record": "ADR-0001", "item": "1", "path": "alternative"}),
            call(5, {"claim": "C-0001-9z"}), call(6, {"table": "../../etc/hostname"}),
            call(7, {"claims": "spec/absent.tsv"})]
    p = subprocess.run(cmd, input="".join(json.dumps(m) + "\n" for m in msgs), capture_output=True, text=True, env=env,
                       timeout=300)
    replies = {r.get("id"): r for r in map(json.loads, p.stdout.splitlines())}
    check("the server lists not_taken", "not_taken" in [t["name"] for t in replies[2]["result"]["tools"]], p.stderr)
    r = replies[3]["result"]
    check("not_taken: one claim, with its reason and the working-output label", not r["isError"]
          and r["structuredContent"]["claims"][0]["paths"][0]["entry"]["id"] == "N-0001-2"
          and "working output" in r["structuredContent"]["label"], r["content"][0]["text"][:400])
    r = replies[4]["result"]
    check("not_taken: one item's alternative", not r["isError"]
          and [x["entry"]["id"] for x in r["structuredContent"]["alternatives"]] == ["N-0001-3"],
          r["content"][0]["text"][:400])
    check("not_taken: an unknown claim is a tool error", replies[5]["result"]["isError"]
          and "no claim C-0001-9z" in replies[5]["result"]["content"][0]["text"], replies[5])
    check("not_taken: a table outside the project is refused", replies[6]["result"]["isError"]
          and "outside the project" in replies[6]["result"]["content"][0]["text"], replies[6])
    check("not_taken: a missing claims table is a tool error", replies[7]["result"]["isError"], replies[7])
    check("not_taken wrote nothing into the project (ADR-0006)", snapshot(root) == before)
    shutil.rmtree(root, ignore_errors=True)

    print(f"\n{'FAILED: ' + ', '.join(failures) if failures else 'not_taken: every check passed'}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
