#!/usr/bin/env python3
"""Tests of server/lemma_graph.py and of the server's lemma_graph tool (ADR-0024).

    python3 server/test_lemma_graph.py                  natively, from a checkout
    python3 server/test_lemma_graph.py -- docker run -i --rm -v {project}:/work IMAGE tla-kit mcp

Two kinds of case.

- **The tables, with no parser.** The readings table and a drawn graph's arrows are checked against a small graph
  written here, one fault planted in each case. These need Python and nothing else.
- **The reader, through SANY.** A project is made in a temporary directory with a small proof module in which each
  construct the reader tells apart appears once, and the tool is driven over stdio as a client drives it. With a
  command after `--`, the server is that command, with `{project}` replaced by the project. Natively, the server
  finds the checker as the skill does, so TLA_JAR must be set and `java` be on the path; where they are not, these
  cases are skipped and the run says so. The skill's own fixture, which extends TLAPS, is read in the image, and
  natively when TLAPM or TLA_KIT_TLAPS_STDLIB names the prover's library.
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
FIXTURE = os.path.join(REPO, "vendor", "writing-tla-specs-and-proofs", "assets", "selftest")
sys.dont_write_bytecode = True
sys.path.insert(0, HERE)
import lemma_graph as lg  # noqa: E402

failures = []

TALLY = """------------------------------- MODULE Tally -------------------------------
(* A count that only goes up, by one or two. *)
EXTENDS Naturals

CONSTANT Max
ASSUME MaxNat == Max \\in Nat

VARIABLE n
vars == <<n>>

TypeOK == n \\in Nat
Init   == n = 0
One    == n' = n + 1
Two    == n' = n + 2
Next   == One \\/ Two
Spec   == Init /\\ [][Next]_vars
Small  == n <= Max

ASSUME MaxBig == Max > 1
THEOREM MaxBound == Max > 0
  BY MaxBig
=============================================================================
"""
# Each construct the reader tells apart appears once. SANY parses it. It is not offered as a proof the prover
# accepts: the prover is not run by these tests, and one theorem is OMITTED on purpose.
TALLY_PROOF = """---------------------------- MODULE Tally_proof ----------------------------
(* A fixture of tla-kit's lemma-graph reader (ADR-0024). Not offered as a proof the prover accepts. *)
EXTENDS Tally

Grows == n' >= n
Inv   == TypeOK /\\ n >= 0

ASSUME MaxPositive == Max > 0

LEMMA InitType == Init => TypeOK
  BY DEF Init, TypeOK

LEMMA OneGrows == TypeOK /\\ One => Grows
  BY DEF TypeOK, One, Grows

LEMMA TwoGrows == TypeOK /\\ Two => Grows
  BY ONLY TypeOK, Two DEF TypeOK, Two, Grows

PROPOSITION StepGrows == TypeOK /\\ [Next]_vars => Grows
<1>a. CASE One
  BY <1>a, OneGrows
<1>b. CASE Two
  BY <1>b, TwoGrows
<1>c. CASE UNCHANGED vars
  <2> USE DEF Grows
  <2>1. n' = n
    BY <1>c DEF vars
  <2> QED
    BY <2>1
<1> QED
  BY <1>a, <1>b, <1>c DEF Next

LEMMA TypeNext == TypeOK /\\ [Next]_vars => TypeOK'
<1> SUFFICES ASSUME TypeOK, [Next]_vars PROVE TypeOK'
  OBVIOUS
<1>1. Grows
  BY StepGrows
<1> HIDE DEF Next
<1> QED
  BY <1>1, n \\in Nat DEF TypeOK, Grows

LEMMA InvNext == Inv /\\ [Next]_vars => Inv'
  BY TypeNext, MaxNat, MaxPositive DEF Inv

COROLLARY InvInit == Init => Inv
  BY InitType DEF Inv, Init

THEOREM Safe == Spec => []Inv
  OMITTED

THEOREM Init => n = 0
  BY DEF Init

LEMMA Unused == TypeOK => n \\in Nat
  OBVIOUS

LEMMA Stated == Max \\in Nat

LEMMA Forms == \\A k \\in Nat : \\E m \\in Nat : k <= m
<1> TAKE k \\in Nat
<1> WITNESS k \\in Nat
<1> QED
  OBVIOUS

LEMMA Having == TypeOK => n >= 0
<1> HAVE TypeOK
<1> QED
  BY DEF TypeOK

LEMMA InvKept == Inv /\\ [Next]_vars => Inv'
  BY InvNext, MaxBound
=============================================================================
"""
BROKEN = "---- MODULE Broken_proof ----\nEXTENDS Naturals\nLEMMA L == 1 + 1 = 2\n  BY Nowhere\n====\n"
# What the reader must find in TALLY_PROOF: every arrow, from the cited fact to the fact whose proof cites it.
EDGES = [["OneGrows", "StepGrows"], ["TwoGrows", "StepGrows"], ["StepGrows", "TypeNext"], ["TypeNext", "InvNext"],
         ["MaxPositive", "InvNext"], ["InitType", "InvInit"], ["InvNext", "InvKept"]]


def check(name, cond, detail=""):
    print(("ok    " if cond else "FAIL  ") + name + ("" if cond else f": {str(detail)[:600]}"), flush=True)
    if not cond:
        failures.append(name)


def snapshot(root):
    out = {}
    for d, _, files in os.walk(root):
        for f in files:
            p = os.path.join(d, f)
            if not os.path.islink(p):
                out[os.path.relpath(p, root)] = open(p, "rb").read()
    return out


# ---------------------------------------------------------------------------------------------------------------
# The tables, with no parser

def graph():
    """A graph as lemma_graph.read returns it, with only what the two checks use: A and B are cited by C."""
    def fact(name, kind, cites, pin):
        return {"name": name, "kind": kind, "line": 1, "end_line": 1, "pin": pin, "cites": cites}
    return {"facts": [fact("Ax", "assumption", [], "a" * 16), fact("A", "lemma", [], "1" * 16),
                      fact("B", "lemma", ["Ax"], "2" * 16), fact("C", "theorem", ["A", "B"], "3" * 16),
                      fact(None, "theorem", [], "4" * 16)],
            "definitions": [{"name": "D", "line": 1, "end_line": 1, "pin": "d" * 16}]}


GOOD = ["spec/M_proof.tla\tA\t" + "1" * 16 + "\tBy unfolding.\tthe assistant\t2000.01.01",
        "spec/M_proof.tla\tC\t" + "3" * 16 + "\tFrom A and B.\tthe custodian\t2000.01.02",
        "spec/M_proof.tla\tD\t" + "d" * 16 + "\tWhat the proof carries.\tthe assistant\t2000.01.01"]


def table(root, rows, header="\t".join(lg.COLUMNS)):
    path = os.path.join(root, "spec", "readings.tsv")
    with open(path, "w", encoding="utf-8") as f:
        f.write("# readings\n" + header + "\n" + "".join(r + "\n" for r in rows))
    return path


def readings(root, rows, **kw):
    g = graph()
    bad = lg.check_readings(g, "spec/M_proof.tla", lg.read_table(table(root, rows, **kw), "spec/readings.tsv"), root)
    by = {f["name"]: f["reading"] for f in g["facts"]}
    by.update({d["name"]: d["reading"] for d in g["definitions"]})
    return bad, by


def row(i, **change):
    cells = dict(zip(lg.COLUMNS, GOOD[i].split("\t")))
    cells.update(change)
    return "\t".join(cells[c] for c in lg.COLUMNS)


def tables():
    root = tempfile.mkdtemp(prefix="tla-kit-lemma-tables-")
    os.makedirs(os.path.join(root, "spec"))
    open(os.path.join(root, "spec", "M_proof.tla"), "w").close()
    open(os.path.join(root, "spec", "Other_proof.tla"), "w").close()

    bad, by = readings(root, GOOD)
    check("readings: three good rows are READ, and nothing is BAD",
          not bad and [by[k]["status"] for k in ("A", "C", "D")] == ["READ"] * 3, (bad, by))
    check("readings: a lemma with no row is UNREAD, and nothing is supplied",
          by["B"] == {"status": "UNREAD"}, by["B"])
    check("readings: an assumption or an unnamed theorem with no row is not counted as unread",
          by["Ax"]["status"] == "NONE" and by[None]["status"] == "NONE", by)
    bad, by = readings(root, GOOD[:2])
    check("readings: a definition with no row is not counted as unread", by["D"]["status"] == "NONE", by["D"])

    bad, by = readings(root, [row(0, pin="9" * 16)] + GOOD[1:])
    check("STALE: a pin that is no longer the fact's, with both pins", not bad and by["A"]["status"] == "STALE"
          and by["A"]["pinned"] == "9" * 16 and by["C"]["status"] == "READ", (bad, by["A"]))

    def one_bad(name, rows, why, **kw):
        bad, by = readings(root, rows, **kw)
        check(name, len(bad) == 1 and why in bad[0]["why"] and bad[0]["row"].startswith("line "), bad)
        return by

    by = one_bad("BAD: a row for a fact the module does not have", GOOD + [row(0, fact="Gone")],
                 "no fact or definition")
    check("BAD: the faulty row gives no fact a reading", "Gone" not in by and by["A"]["status"] == "READ", by)
    by = one_bad("BAD: a second reading of one fact", GOOD + [row(0, reading="Again.")], "a second reading of A")
    check("BAD: the first reading stands", by["A"]["reading"] == "By unfolding.", by["A"])
    one_bad("BAD: a pin that is not 16 hex digits", [row(0, pin="12345")], "not 16 hex digits")
    one_bad("BAD: a date that is not YYYY.MM.DD", [row(0, date="2000-01-01")], "not YYYY.MM.DD")
    one_bad("BAD: an empty cell", [row(0, by="")], "an empty cell: by")
    one_bad("BAD: a module that is not in the project", GOOD + [row(0, module="spec/Absent_proof.tla")],
            "no module spec/Absent_proof.tla")
    one_bad("BAD: a module outside the project", GOOD + [row(0, module="../../etc/hostname")], "no module")
    bad, by = readings(root, GOOD + [row(0, module="spec/Other_proof.tla", fact="Elsewhere")])
    check("readings: a row for another module of the project is left to that module's run", not bad, bad)

    for name, kw, rows, why in (("a wrong header", {"header": "module\tfact\tpin"}, GOOD, "the header is"),
                                ("a row with a cell missing", {}, ["spec/M_proof.tla\tA\t" + "1" * 16],
                                 "cells, not 6")):
        try:
            readings(root, rows, **kw)
            check(f"unreadable: {name}", False, "no error")
        except lg.GraphError as e:
            check(f"unreadable: {name}", why in str(e), e)
    try:
        lg.read_table(os.path.join(root, "spec", "absent.tsv"), "spec/absent.tsv")
        check("unreadable: no such table", False, "no error")
    except lg.GraphError as e:
        check("unreadable: no such table", "cannot read spec/absent.tsv" in str(e), e)

    drawn = [["A", "C"], ["B", "C"], ["Ax", "B"]]
    a = lg.check_arrows(graph(), drawn)
    check("arrows: a drawing that is the citations", a == {"drawn": 3, "citations": 3, "not_a_citation": [],
                                                           "not_drawn": [], "unknown": []}, a)
    a = lg.check_arrows(graph(), drawn + [["A", "B"]])
    check("arrows: an arrow that is not a citation", a["not_a_citation"] == [["A", "B"]] and not a["not_drawn"], a)
    a = lg.check_arrows(graph(), drawn[:2])
    check("arrows: a citation with no arrow", a["not_drawn"] == [["Ax", "B"]] and not a["not_a_citation"], a)
    a = lg.check_arrows(graph(), drawn + [["Lost", "C"]])
    check("arrows: a name the module does not have", a["unknown"] == ["Lost"] and not a["not_a_citation"], a)
    a = lg.check_arrows(graph(), drawn + [["A", "C"]])
    check("arrows: an arrow drawn twice is one arrow", a["drawn"] == 3 and not a["not_a_citation"], a)
    check("arrows: read from a file, with comments and either arrow",
          lg.read_arrows("# drawn by hand\nA -> C\nB --> C   # the second\n\nAx->B\n") == drawn)
    for text in ("A C\n", "A -> B -> C\n"):
        try:
            lg.read_arrows(text)
            check(f"arrows: {text.strip()!r} is refused", False, "no error")
        except lg.GraphError as e:
            check(f"arrows: {text.strip()!r} is refused", "not `A -> B`" in str(e), e)

    lines = ["LEMMA L == TRUE", "  OBVIOUS", "", "LEMMA M == TRUE"]
    check("pin: trailing blanks do not move it", lg.pin_of(lines, 1, 2) == lg.pin_of(["LEMMA L == TRUE  ",
                                                                                    "  OBVIOUS\t"], 1, 2))
    check("pin: a changed character moves it", lg.pin_of(lines, 1, 2) != lg.pin_of(["LEMMA L == TRUE", "  OMITTED"],
                                                                                    1, 2))
    check("pin: a line outside the fact does not move it", lg.pin_of(lines, 1, 2) == lg.pin_of(lines[:2] + ["x"], 1, 2))
    shutil.rmtree(root, ignore_errors=True)


# ---------------------------------------------------------------------------------------------------------------
# The reader, through SANY

class Client:
    def __init__(self, cmd, env):
        self.p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, env=env, bufsize=1)
        self.next_id = 0

    def request(self, method, params=None):
        self.next_id += 1
        self.p.stdin.write(json.dumps({"jsonrpc": "2.0", "id": self.next_id, "method": method,
                                       "params": params or {}}) + "\n")
        self.p.stdin.flush()
        line = self.p.stdout.readline()
        if not line:
            raise SystemExit(f"the server closed its output during {method}")
        return json.loads(line)

    def call(self, args):
        r = self.request("tools/call", {"name": "lemma_graph", "arguments": args})["result"]
        return r.get("structuredContent"), r.get("isError"), r["content"][0]["text"]

    def close(self):
        self.p.stdin.close()
        self.p.wait(timeout=60)


def make_project():
    root = tempfile.mkdtemp(prefix="tla-kit-lemma-graph-")
    os.makedirs(os.path.join(root, "spec"))
    for name, text in (("Tally.tla", TALLY), ("Tally_proof.tla", TALLY_PROOF), ("Broken_proof.tla", BROKEN)):
        with open(os.path.join(root, "spec", name), "w", encoding="utf-8") as f:
            f.write(text)
    for f in ("Counter.tla", "Counter_proof.tla"):
        shutil.copy(os.path.join(FIXTURE, f), os.path.join(root, "spec"))
    os.symlink("/etc", os.path.join(root, "spec", "outside"))
    os.system(f"chmod -R a+rwX {root}")
    os.chmod(root, 0o777)
    return root


def reader(argv):
    in_image = "--" in argv
    if not in_image and not (os.environ.get("TLA_JAR") and shutil.which("java")):
        print("skip  the reader through SANY: natively it needs TLA_JAR and java; CI runs it in the image", flush=True)
        return
    root = make_project()
    if in_image:
        cmd = [x.replace("{project}", root) for x in argv[argv.index("--") + 1:]]
        env = dict(os.environ)
    else:
        cmd = [sys.executable, "-B", os.path.join(HERE, "tla_kit_mcp.py")]
        env = dict(os.environ, TLA_KIT_PROJECT=root)
    print("server: " + " ".join(cmd), flush=True)
    before = snapshot(root)
    c = Client(cmd, env)
    try:
        c.request("initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                                 "clientInfo": {"name": "tla-kit-test", "version": "0"}})
        tools = [t["name"] for t in c.request("tools/list")["result"]["tools"]]
        check("the server lists lemma_graph", "lemma_graph" in tools, tools)

        s, err, text = c.call({"module": "spec/Tally_proof.tla"})
        check("the module is read, and the answer is labelled working output", not err and s
              and "working output" in s.get("label", "") and s["module"] == "spec/Tally_proof.tla", text)
        if err or not s:
            return
        facts = {f["name"]: f for f in s["facts"]}
        check("every fact, in the module's order, the unnamed theorem among them",
              [f["name"] for f in s["facts"]] == ["MaxPositive", "InitType", "OneGrows", "TwoGrows", "StepGrows",
                                                  "TypeNext", "InvNext", "InvInit", "Safe", None, "Unused", "Stated",
                                                  "Forms", "Having", "InvKept"],
              [f["name"] for f in s["facts"]])
        check("each fact's kind is the keyword it was written with",
              [f["kind"] for f in s["facts"]] == ["assumption", "lemma", "lemma", "lemma", "proposition", "lemma",
                                                  "lemma", "corollary", "theorem", "theorem", "lemma", "lemma",
                                                  "lemma", "lemma", "lemma"],
              [f["kind"] for f in s["facts"]])
        check("every citation, and no other", sorted(s["edges"]) == sorted(EDGES), s["edges"])
        f = facts["StepGrows"]
        check("a step's label is not a citation, lettered or numbered: <1>a, <1>c and <2>1 are none",
              f["cites"] == ["OneGrows", "TwoGrows"] and f["steps"] == 6 and f["leaves"]["by"] == 5, f)
        check("a USE step's DEF is an unfolding", "Grows" in f["unfolds"] and "vars" in f["unfolds"], f["unfolds"])
        f = facts["TypeNext"]
        check("a HIDE step's DEF is not", "Next" not in f["unfolds"] and f["unfolds"] == ["TypeOK", "Grows"],
              f["unfolds"])
        check("a fact that is an expression is counted and is not a citation",
              f["expressions"] == 1 and f["cites"] == ["StepGrows"] and f["leaves"] == {"by": 2, "obvious": 1,
                                                                                     "omitted": 0, "none": 0}, f)
        f = facts["TwoGrows"]
        check("BY ONLY, and definitions named as facts", f["only"] == 1 and f["as_facts"] == ["TypeOK", "Two"]
              and not f["cites"], f)
        f = facts["InvNext"]
        check("an assumption of this module is cited as a fact of it", "MaxPositive" in f["cites"]
              and facts["MaxPositive"]["cited_by"] == ["InvNext"], f)
        check("a fact of another module of the project is listed apart, with its module",
              f["elsewhere"] == [{"name": "MaxNat", "module": "Tally", "kind": "assumption", "where": "project"}],
              f["elsewhere"])
        check("what a fact rests on, in the module's order, and how deep",
              f["rests_on"] == ["MaxPositive", "OneGrows", "TwoGrows", "StepGrows", "TypeNext"] and f["depth"] == 3
              and facts["OneGrows"]["depth"] == 0, (f["rests_on"], f["depth"]))
        own, far = ({"name": "MaxPositive", "module": "Tally_proof", "where": "module"},
                    {"name": "MaxNat", "module": "Tally", "where": "project"})
        check("the assumptions a fact names: this module's first, then another module's", f["assumes"] == [own, far],
              f["assumes"])
        check("the assumptions a fact rests on only through a fact below it",
              facts["InvKept"]["assumes"] == [own, far] and facts["InvKept"]["cites"] == ["InvNext"]
              and facts["InvKept"]["depth"] == 4, facts["InvKept"])
        bound = {"name": "MaxBound", "module": "Tally", "where": "project"}
        check("a theorem of another module is not followed: it is listed as that, and what it assumes is not",
              facts["InvKept"]["not_followed"] == [bound] and facts["InvNext"]["not_followed"] == []
              and facts["InvKept"]["elsewhere"] == [dict(bound, kind="theorem")]
              and "MaxBig" not in json.dumps(s["assumptions"]), facts["InvKept"])
        check("a fact that names none and rests on none assumes none, and an assumption assumes none",
              facts["TypeNext"]["assumes"] == [] and facts["MaxPositive"]["assumes"] == [], facts["TypeNext"])
        check("the module's assumptions, each with every fact that rests on it",
              s["assumptions"] == [dict(own, rested_on_by=["InvNext", "InvKept"]),
                                   dict(far, rested_on_by=["InvNext", "InvKept"])]
              and s["counts"]["assumptions_rested_on"] == 2, s["assumptions"])
        check("the statement's definitions", facts["InvInit"]["stated_with"] == ["Init", "Inv"]
              and facts["Stated"]["stated_with"] == [], facts["InvInit"]["stated_with"])
        check("OMITTED and a statement with no proof are listed as not proved in the text",
              s["not_proved_in_text"] == [{"name": "Safe", "why": "OMITTED"},
                                          {"name": "Stated", "why": "stated with no proof"}]
              and not facts["Safe"]["proved_in_text"] and facts["InvNext"]["proved_in_text"], s["not_proved_in_text"])
        check("TAKE, WITNESS and HAVE take no proof, and none is counted as missing from them",
              facts["Forms"]["steps"] == 3 and facts["Forms"]["leaves"] == {"by": 0, "obvious": 1, "omitted": 0,
                                                                         "none": 0}
              and facts["Having"]["leaves"] == {"by": 1, "obvious": 0, "omitted": 0, "none": 0}
              and facts["Forms"]["proved_in_text"] and facts["Having"]["proved_in_text"],
              (facts["Forms"], facts["Having"]))
        check("the facts no fact cites", s["uncited"] == ["InvInit", "Safe", "Unused", "Stated", "Forms", "Having",
                                                    "InvKept"],
              s["uncited"])
        defs = {d["name"]: d for d in s["definitions"]}
        check("the module's own definitions, with the statements and proofs that use each",
              list(defs) == ["Grows", "Inv"]
              and defs["Inv"]["in_statements_of"] == ["InvNext", "InvInit", "Safe", "InvKept"]
              and defs["Grows"]["unfolded_by"] == ["OneGrows", "TwoGrows", "StepGrows", "TypeNext"], defs)
        check("with no table every lemma and theorem is UNREAD, and the assumption is not counted",
              s["readings"] == {"table": None, "read": 0, "stale": 0, "unread": 13, "bad": []}
              and facts["MaxPositive"]["reading"]["status"] == "NONE", s["readings"])
        check("the pin is the pin of the fact's own lines",
              facts["OneGrows"]["pin"] == lg.pin_of(TALLY_PROOF.splitlines(), 13, 14)
              and (facts["OneGrows"]["line"], facts["OneGrows"]["end_line"]) == (13, 14), facts["OneGrows"])

        s2, err, text = c.call({"module": "spec/Tally_proof.tla", "fact": "TypeNext"})
        check("one fact: itself and what it rests on", not err
              and [f["name"] for f in s2["facts"]] == ["OneGrows", "TwoGrows", "StepGrows", "TypeNext"], text)
        _, err, text = c.call({"module": "spec/Tally_proof.tla", "fact": "Nowhere"})
        check("an unknown fact is a tool error", err and "no fact named Nowhere" in text, text)

        s2, err, text = c.call({"module": "spec/Tally_proof.tla", "arrows": EDGES})
        check("arrows: the citations, drawn, agree", not err and s2["exit"] == 0
              and not s2["arrows"]["not_a_citation"] and not s2["arrows"]["not_drawn"], text)
        wrong = [e for e in EDGES if e != ["MaxPositive", "InvNext"]] + [["InitType", "TypeNext"]]
        s2, err, text = c.call({"module": "spec/Tally_proof.tla", "arrows": wrong})
        check("arrows: one arrow that is no citation and one citation not drawn are both named", not err
              and s2["exit"] == 1 and s2["arrows"]["not_a_citation"] == [["InitType", "TypeNext"]]
              and s2["arrows"]["not_drawn"] == [["MaxPositive", "InvNext"]], text)

        # A readings table: one reading that stands, one of a fact that is not there.
        rows = [f"spec/Tally_proof.tla\t{n}\t{facts[n]['pin']}\tA reading of {n}.\tthe test\t2000.01.01"
                for n in ("OneGrows", "TypeNext")]
        rows.append("spec/Tally_proof.tla\tGrows\t" + defs["Grows"]["pin"] + "\tThe count never falls.\tthe test"
                    "\t2000.01.01")
        with open(os.path.join(root, "spec", "readings.tsv"), "w", encoding="utf-8") as f:
            f.write("\t".join(lg.COLUMNS) + "\n" + "".join(r + "\n" for r in rows))
        s2, err, text = c.call({"module": "spec/Tally_proof.tla"})
        f2 = {f["name"]: f for f in (s2 or {}).get("facts", [])}
        check("readings: the default table is found, and its rows are READ", not err and s2["exit"] == 0
              and s2["readings"] == {"table": "spec/readings.tsv", "read": 3, "stale": 0, "unread": 11, "bad": []}
              and f2["OneGrows"]["reading"]["reading"] == "A reading of OneGrows.", text)
        # The proof of TypeNext is changed, and nothing else: its reading is stale, and OneGrows's still stands.
        changed = TALLY_PROOF.replace("  BY <1>1, n \\in Nat DEF TypeOK, Grows", "  BY <1>1 DEF TypeOK, Grows")
        assert changed != TALLY_PROOF
        with open(os.path.join(root, "spec", "Tally_proof.tla"), "w", encoding="utf-8") as f:
            f.write(changed)
        s2, err, text = c.call({"module": "spec/Tally_proof.tla"})
        f2 = {f["name"]: f for f in (s2 or {}).get("facts", [])}
        check("STALE: a proof changed after it was read, and only that one", not err and s2["exit"] == 1
              and f2["TypeNext"]["reading"]["status"] == "STALE" and f2["OneGrows"]["reading"]["status"] == "READ"
              and s2["readings"]["stale"] == 1 and f2["TypeNext"]["expressions"] == 0, text)
        with open(os.path.join(root, "spec", "Tally_proof.tla"), "w", encoding="utf-8") as f:
            f.write(TALLY_PROOF)
        with open(os.path.join(root, "spec", "readings.tsv"), "a", encoding="utf-8") as f:
            f.write("spec/Tally_proof.tla\tRenamed\t" + "0" * 16 + "\tOf a lemma that is gone.\tthe test\t2000.01.01\n")
        s2, err, text = c.call({"module": "spec/Tally_proof.tla"})
        check("BAD: a reading of a fact that is not there", not err and s2["exit"] == 1
              and len(s2["readings"]["bad"]) == 1 and "named Renamed" in s2["readings"]["bad"][0]["why"], text)
        os.remove(os.path.join(root, "spec", "readings.tsv"))

        _, err, text = c.call({"module": "spec/Tally_proof.tla", "readings": "../../etc/hostname"})
        check("a table outside the project is refused", err and "outside the project" in text, text)
        _, err, text = c.call({"module": "spec/outside/hostname"})
        check("a module outside the project is refused", err and "outside the project" in text, text)
        _, err, text = c.call({"module": "spec/Broken_proof.tla"})
        check("a module SANY does not accept is a tool error, with SANY's message", err
              and "could not export Broken_proof" in text, text)

        # The skill's own fixture extends TLAPS, which SANY finds only in the prover's library.
        if in_image or os.environ.get("TLAPM") or os.environ.get("TLA_KIT_TLAPS_STDLIB"):
            s3, err, text = c.call({"module": "spec/Counter_proof.tla"})
            f3 = {f["name"]: f for f in (s3 or {}).get("facts", [])}
            check("the skill's fixture: its citations", not err and sorted(s3["edges"]) == sorted(
                [["TypeNext", "BoundedAlways"], ["NextBounded", "BoundedAlways"], ["TypeInit", "BoundedAlways"],
                 ["BoundedAlways", "SafeAlways"]]), text)
            check("the skill's fixture: the prover's tactics are backends, not facts",
                  not err and f3["BoundedAlways"]["backends"] == ["PTL"]
                  and f3["MutNoLimitAllowsStep"]["backends"] == ["ExpandENABLED"]
                  and sorted(b["name"] for b in s3["backends"]) == ["ExpandENABLED", "PTL"], text)
            check("the skill's fixture: the specification's assumption is cited from elsewhere in the project",
                  not err and f3["NextBounded"]["elsewhere"] == [{"name": "LimitNat", "module": "Counter",
                                                                  "kind": "assumption", "where": "project"}], text)
            limit = {"name": "LimitNat", "module": "Counter", "where": "project"}
            check("the skill's fixture: its theorems rest on the specification's assumption through a lemma",
                  not err and f3["NextBounded"]["assumes"] == [limit] and f3["BoundedAlways"]["assumes"] == [limit]
                  and f3["SafeAlways"]["assumes"] == [limit] and f3["TypeNext"]["assumes"] == []
                  and s3["assumptions"] == [dict(limit, rested_on_by=["NextBounded", "BoundedAlways",
                                                                     "SafeAlways"])], text)
        else:
            print("skip  the skill's fixture: natively, neither TLAPM nor TLA_KIT_TLAPS_STDLIB names the prover's "
                  "library", flush=True)
        check("lemma_graph wrote nothing into the project (ADR-0006)", snapshot(root) == before,
              sorted(set(snapshot(root)) ^ set(before)))
    finally:
        c.close()

    if not in_image:
        # The command, as `tla-kit lemma-graph` runs it in the image.
        def run(args):
            p = subprocess.run([sys.executable, "-B", os.path.join(HERE, "lemma_graph.py")] + args, env=env,
                               capture_output=True, text=True, timeout=600)
            return p.returncode, p.stdout, p.stderr
        code, out, _ = run(["spec/Tally_proof.tla"])
        check("the command: exit 0, with the report's notes and its summary", code == 0
              and "It does not say the prover accepted the proof" in out and "7 citations between them" in out
              and "2 named assumptions rested on" in out and "MaxNat (of Tally, project), by InvNext, InvKept" in out
              and "  not followed MaxBound (of Tally, project)" in out, out)
        code, out, _ = run(["spec/Tally_proof.tla", "--json"])
        check("the command: --json is the tool's report", code == 0 and sorted(json.loads(out)["edges"]) ==
              sorted(EDGES), out)
        check("the command: --strict exits 1 on an unread fact", run(["spec/Tally_proof.tla", "--strict"])[0] == 1)
        drawn = os.path.join(root, "drawn.txt")
        with open(drawn, "w") as f:
            f.write("".join(f"{a} -> {b}\n" for a, b in EDGES[1:]))
        code, out, _ = run(["spec/Tally_proof.tla", "--arrows", drawn])
        check("the command: exit 1 when a citation is not drawn, and the text names it", code == 1
              and "NOT DRAWN OneGrows -> StepGrows: the proof of StepGrows names OneGrows" in out, out)
        os.remove(drawn)
        code, _, errs = run(["spec/Absent_proof.tla"])
        check("the command: exit 2 for a module that is not there", code == 2 and "no file" in errs, errs)
        code, _, errs = run(["spec/Tally_proof.tla", "--fact", "Nowhere"])
        check("the command: exit 2 for an unknown fact", code == 2 and "no fact named Nowhere" in errs, errs)
        check("the command wrote nothing into the project (ADR-0006)", snapshot(root) == before)
    shutil.rmtree(root, ignore_errors=True)


def main(argv):
    with contextlib.redirect_stderr(io.StringIO()):
        tables()
    reader(argv)
    print(f"\n{'FAILED: ' + ', '.join(failures) if failures else 'lemma_graph: every check passed'}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
