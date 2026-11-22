#!/usr/bin/env python3
"""A proof module's lemma graph: its facts, what each proof cites, and what a person has read of it (ADR-0024,
Proposed).

    python3 server/lemma_graph.py spec/Counter_proof.tla             every fact of the module
    python3 server/lemma_graph.py spec/Counter_proof.tla --fact F     one fact, and what it rests on
    python3 server/lemma_graph.py M.tla --readings spec/readings.tsv  with the readings table (the default, if there)
    python3 server/lemma_graph.py M.tla --arrows drawn.txt            compare a drawn graph with the citations
    tla-kit lemma-graph ...                                           the same, in the image, on the project at /work

A fact is a named assumption, lemma, proposition, corollary or theorem of the module. An arrow from A to B says that
B's proof names A after BY, or in a USE step: the name as SANY resolved it, so a step label, a comment or the layout
of the file cannot be mistaken for one. For each fact it lists:

    cites        the facts of this module its proof names
    elsewhere    the facts of other modules it names: the project's own, and the libraries'
    backends     the prover's tactics it names (definitions of the module TLAPS, such as PTL)
    unfolds      the definitions after DEF
    stated with  the project's definitions its statement names
    cited by     the facts of this module whose proofs name it
    assumes      the assumptions it rests on: those its proof names, and those named by a fact below it
    not followed the theorems of other modules it rests on, whose own assumptions are in those modules' reports

and how its proof ends: its steps, and its leaves by kind (BY, OBVIOUS, OMITTED, or stated with no proof).

**What it does not say.** It reads the text of the proofs. It does not run the prover and does not say a proof was
accepted: that is `prove`'s answer, and a results file's. A fact with an OMITTED leaf, or stated with no proof, is
listed as not proved in the text, with every fact that rests on it.

**Readings.** A reading is one line, written by a person, of how a proof goes or what a definition is for. Readings
are rows of a table, by default spec/readings.tsv:

    module   the module, by its path from the project root
    fact     the fact's or the definition's name
    pin      the first 16 hex digits of the sha256 of the fact's lines, as this script prints them
    reading  the reading, in one line
    by       who gave it
    date     when, as YYYY.MM.DD

A lemma or theorem with no row is UNREAD: the script never supplies a reading. A row whose pin is no longer the
fact's is STALE: the text has changed since it was read, and reading it again and moving the pin is the review. A row
that names no fact of its module, or a module that is not there, is BAD. READ says the text has not changed since
the reading was given. Whether the reading is right is read by a person.

**Arrows.** Given a list of arrows someone drew, one `A -> B` to a line, it reports each arrow that is not a
citation and each citation that has no arrow.

It parses a copy of the module with SANY, in a temporary directory, and reads the project as data. It writes nothing
into the project (ADR-0006). Standard library only (ADR-0008 item 1).

Exit status: 0; 1 when a reading is BAD or STALE, when the arrows and the citations differ, or with --strict when a
lemma or theorem is UNREAD; 2 when the module cannot be parsed or a table cannot be read.
"""
import argparse
import hashlib
import json
import os
import re
import sys
import textwrap
import xml.etree.ElementTree as ET

sys.dont_write_bytecode = True

RECORD = "ADR-0024, Proposed"
READINGS = "spec/readings.tsv"
COLUMNS = ["module", "fact", "pin", "reading", "by", "date"]
KEYWORDS = ["THEOREM", "LEMMA", "PROPOSITION", "COROLLARY"]
KINDS = ["assumption"] + [k.lower() for k in KEYWORDS]
LEAVES = ["by", "obvious", "omitted", "none"]
BACKENDS = "TLAPS"                     # the module whose definitions are the prover's tactics
NO_PROOF = ("$Take", "$Witness", "$Have")   # steps that take no proof, so that none is missing from them
NOTES = [
    "Working output: it parses a copy of the module with SANY, reads the project and writes nothing into it.",
    "An arrow from A to B says that B's proof names A after BY or in a USE step, as SANY resolved the name. It is "
    "read from the text. It does not say the prover accepted the proof: that is prove's answer, and a results "
    "file's.",
    "A reading is what a person wrote of a proof. READ says the proof's text has not changed since. Whether the "
    "reading is right is read by a person. UNREAD means none is recorded, and none is supplied.",
    "An assumption is listed for a fact when its proof, or the proof of a fact below it in this module, names it. A "
    "theorem cited from another module is not followed there: it is listed as not followed, and what it assumes is "
    "in that module's report.",
]


class GraphError(Exception):
    """The module's export or a table cannot be read: exit status 2, and a tool error in the server."""


# ---------------------------------------------------------------------------------------------------------------
# Reading SANY's XML export

def _where(node):
    loc = node.find("location")
    if loc is None:
        return None, 0, 0
    line = loc.find("line")
    return loc.findtext("filename"), int(line.findtext("begin")), int(line.findtext("end"))


def _uids(el, tags):
    return [r.findtext("UID") for r in el.iter() if r.tag in tags]


def pin_of(lines, first, last):
    """The pin of the lines first..last of a module: 16 hex digits of the sha256 of their text, without trailing
    blanks, so that only a change to the fact itself moves it."""
    text = "\n".join(l.rstrip() for l in lines[first - 1:last])
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:16]


def read(xml_text, module, source, project_modules=()):
    """The facts and definitions of `module`, from SANY's XML export of it and its source text.

    project_modules names the modules that are files of the project: a fact cited from one of them is the
    project's, and from any other module a library's."""
    try:
        root = ET.fromstring(xml_text)
    except ET.ParseError as e:
        raise GraphError(f"SANY's export of {module} is not XML: {e}")
    context = root.find("context")
    if context is None:
        raise GraphError(f"SANY's export of {module} has no context")
    ctx = {e.findtext("UID"): e[1] for e in context.findall("entry") if len(e) > 1}
    mod = next((n for n in ctx.values() if n.tag == "ModuleNode" and n.findtext("uniquename") == module), None)
    if mod is None:
        raise GraphError(f"SANY's export does not hold a module named {module}")
    lines = source.splitlines()
    project = set(project_modules) | {module}

    def name_of(node):
        """A node's own name, or the name of the definition it makes; None for an unnamed theorem or assumption."""
        own = node.findtext("uniquename")
        if own:
            return own
        d = node.find("definition")
        if d is not None and len(d):
            target = ctx.get(d[0].findtext("UID"))
            return target.findtext("uniquename") if target is not None else None
        return None

    def keyword(first):
        m = re.match(r"\s*(" + "|".join(KEYWORDS) + r")\b", lines[first - 1] if 0 < first <= len(lines) else "")
        return m.group(1).lower() if m else "theorem"

    facts, definitions, use_hide = [], [], []

    def cited(target, kind):
        """A named fact a proof cites: (name, module, kind), or None for a step of the proof itself."""
        name = target.findtext("uniquename") or ""
        if kind == "theorem" and name.startswith("<"):
            return None
        return name, _where(target)[0], kind

    def collect(el, acc):
        """The facts and definitions of one BY, or of one USE step."""
        fs = el.find("facts")
        for f in (fs if fs is not None else []):
            named = []
            for r in f.iter():
                if r.tag in ("TheoremDefRef", "AssumeDefRef") and r.findtext("UID") in ctx:
                    named.append(cited(ctx[r.findtext("UID")], "theorem" if r.tag == "TheoremDefRef" else "assumption"))
            if named:
                acc["named"] += [n for n in named if n]
                continue
            op, operands = f.find("operator"), f.find("operands")
            plain = f.tag == "OpApplNode" and op is not None and len(op) and (operands is None or not len(operands))
            target = ctx.get(op[0].findtext("UID")) if plain and op[0].tag == "UserDefinedOpKindRef" else None
            if target is not None and _where(target)[0] == BACKENDS:
                acc["backends"].append(target.findtext("uniquename"))
            elif target is not None:
                acc["as_facts"].append(target.findtext("uniquename"))
            else:
                acc["expressions"] += 1
        ds = el.find("defs")
        for d in (ds if ds is not None else []):
            target = ctx.get(d.findtext("UID")) if d.tag.endswith("Ref") else None
            if target is not None and target.findtext("uniquename"):
                acc["unfolds"].append((target.findtext("uniquename"), d.findtext("UID")))

    def walk(node, acc):
        by, steps = node.find("by"), node.find("steps")
        if by is not None:
            acc["leaves"]["by"] += 1
            acc["only"] += by.find("only") is not None
            collect(by, acc)
        elif steps is not None:
            for c in steps:
                if c.tag in ("TheoremNodeRef", "TheoremNode"):
                    step = ctx.get(c.findtext("UID")) if c.tag == "TheoremNodeRef" else c
                    if step is not None:
                        acc["steps"] += 1
                        walk(step, acc)
                elif c.tag == "UseOrHideNode" and c.find("hide") is None:
                    collect(c, acc)
        elif node.find("obvious") is not None:
            acc["leaves"]["obvious"] += 1
        elif node.find("omitted") is not None:
            acc["leaves"]["omitted"] += 1
        elif body_operator(node) not in NO_PROOF:
            acc["leaves"]["none"] += 1

    def body_operator(node):
        """The name of the operator a step's body applies: $Take, $Witness and $Have for the steps so written."""
        body = node.find("body")
        op = body[0].find("operator") if body is not None and len(body) else None
        target = ctx.get(op[0].findtext("UID")) if op is not None and len(op) else None
        return target.findtext("uniquename") if target is not None else None

    def proof_kind(node):
        for k in ("by", "steps", "obvious", "omitted"):
            if node.find(k) is not None:
                return k
        return "none"

    top_definitions = {}                    # UID -> name, for the module-level definitions of every module
    for n in ctx.values():
        if n.tag == "ModuleNode":
            for c in n:
                if c.tag == "UserDefinedOpKindRef" and c.findtext("UID") in ctx:
                    top_definitions[c.findtext("UID")] = ctx[c.findtext("UID")].findtext("uniquename")

    def new_acc():
        return {"named": [], "backends": [], "as_facts": [], "expressions": 0, "unfolds": [], "only": 0, "steps": 0,
                "leaves": dict.fromkeys(LEAVES, 0)}

    def unique(xs):
        return list(dict.fromkeys(x for x in xs if x))

    for c in mod:
        node = ctx.get(c.findtext("UID")) if c.tag.endswith("Ref") else c
        if node is None:
            continue
        fn, first, last = _where(node)
        if fn != module:
            continue
        if c.tag == "UseOrHideNode":
            acc = new_acc()
            collect(c, acc)
            use_hide.append({"hide": c.find("hide") is not None, "line": first,
                             "facts": unique(n for n, _, _ in acc["named"]) + unique(acc["as_facts"]),
                             "unfolds": unique(n for n, uid in acc["unfolds"])})
        elif c.tag == "UserDefinedOpKindRef":
            definitions.append({"name": node.findtext("uniquename"), "line": first, "end_line": last,
                                "arity": int(node.findtext("arity") or 0), "pin": pin_of(lines, first, last),
                                "in_statements_of": [], "unfolded_by": [], "_uid": c.findtext("UID")})
        elif c.tag in ("TheoremNodeRef", "AssumeNodeRef"):
            assumption = c.tag == "AssumeNodeRef"
            acc = new_acc()
            if not assumption:
                walk(node, acc)
            body = node.find("body")
            stated = []
            for uid in (_uids(body, ("UserDefinedOpKindRef",)) if body is not None else []):
                if uid in top_definitions and _where(ctx[uid])[0] in project:
                    stated.append((top_definitions[uid], uid))
            facts.append({
                "name": name_of(node), "kind": "assumption" if assumption else keyword(first),
                "line": first, "end_line": last, "pin": pin_of(lines, first, last),
                "proof": "assumed" if assumption else proof_kind(node),
                "steps": acc["steps"], "leaves": acc["leaves"], "only": acc["only"],
                "cites": unique(n for n, m, _ in acc["named"] if m == module),
                "elsewhere": [{"name": n, "module": m, "kind": k, "where": "project" if m in project else "library"}
                              for n, m, k in dict.fromkeys(x for x in acc["named"] if x[1] != module)],
                "backends": unique(acc["backends"]), "as_facts": unique(acc["as_facts"]),
                "expressions": acc["expressions"],
                "unfolds": unique(n for n, uid in acc["unfolds"] if uid in top_definitions),
                "stated_with": unique(n for n, _ in stated),
                "_unfolds": {uid for _, uid in acc["unfolds"]}, "_stated": {uid for _, uid in stated},
            })

    by_name = {f["name"]: f for f in facts if f["name"]}
    for f in facts:
        f["cites"] = [n for n in f["cites"] if n in by_name and n != f["name"]]
        f["cited_by"] = []
    for f in facts:
        for n in f["cites"]:
            by_name[n]["cited_by"].append(f["name"] or f"(unnamed, line {f['line']})")
    for d in definitions:
        uid = d.pop("_uid")
        for f in facts:
            label = f["name"] or f"(unnamed, line {f['line']})"
            if uid in f["_stated"]:
                d["in_statements_of"].append(label)
            if uid in f["_unfolds"]:
                d["unfolded_by"].append(label)

    # What each fact rests on in this module, how deep that goes, and whether any of it is not proved in the text.
    rests, depth = {}, {}

    def close(name, seen=()):
        if name in rests:
            return rests[name]
        if name in seen:                       # SANY refuses a cycle; this only keeps a malformed export finite
            return []
        out = []
        for n in by_name[name]["cites"]:
            out += [x for x in close(n, seen + (name,)) + [n] if x not in out]
        rests[name] = out
        depth[name] = 1 + max((depth.get(n, 0) for n in by_name[name]["cites"]), default=-1)
        return out

    def unproved(f):
        return f["kind"] != "assumption" and (f["leaves"]["omitted"] or f["leaves"]["none"])

    order = [f["name"] for f in facts if f["name"]]
    for f in facts:
        f.pop("_unfolds"), f.pop("_stated")
        if f["name"]:
            below = close(f["name"])
            f["rests_on"] = sorted(below, key=order.index)
            f["depth"] = depth[f["name"]]
            f["not_proved_below"] = [n for n in f["rests_on"] if unproved(by_name[n])]
        else:
            f["rests_on"] = sorted({x for n in f["cites"] for x in close(n) + [n]}, key=order.index)
            f["depth"] = 1 + max((depth.get(n, 0) for n in f["cites"]), default=-1)
            f["not_proved_below"] = [n for n in f["rests_on"] if unproved(by_name[n])]
        f["proved_in_text"] = not unproved(f)
    for f in facts:
        f["assumes"], f["not_followed"] = ([], []) if f["kind"] == "assumption" else assumed(f, by_name, module)
    return {"facts": facts, "definitions": definitions, "use_hide": use_hide}


def assumed(fact, by_name, module):
    """The named assumptions a fact rests on, as far as this module shows: the assumptions of this module among the
    facts below it, and the assumptions of other modules that it, or any fact below it, names. And the edge of that:
    the theorems of other modules it rests on, which are not followed, so what they assume is not listed here."""
    below = [by_name[n] for n in fact["rests_on"]]
    out = [{"name": b["name"], "module": module, "where": "module"} for b in below if b["kind"] == "assumption"]
    beyond, seen = [], {(a["name"], a["module"]) for a in out}
    for g in below + [fact]:
        for e in g["elsewhere"]:
            if (e["name"], e["module"]) not in seen:
                seen.add((e["name"], e["module"]))
                (out if e["kind"] == "assumption" else beyond).append(
                    {"name": e["name"], "module": e["module"], "where": e["where"]})
    return out, beyond


# ---------------------------------------------------------------------------------------------------------------
# The readings table, and a drawn graph's arrows

def read_table(path, label):
    """The rows of a readings table: [(line number, {column: value})]. A table that cannot be read is an error."""
    try:
        raw = open(path, encoding="utf-8").read().splitlines()
    except OSError as e:
        raise GraphError(f"cannot read {label}: {e.strerror}")
    rows, header = [], None
    for i, line in enumerate(raw, 1):
        if not line.strip() or line.startswith("#"):
            continue
        cells = [c.strip() for c in line.split("\t")]
        if header is None:
            header = cells
            if header != COLUMNS:
                raise GraphError(f"{label} line {i}: the header is {header}, not {COLUMNS}")
            continue
        if len(cells) != len(COLUMNS):
            raise GraphError(f"{label} line {i}: {len(cells)} cells, not {len(COLUMNS)}")
        rows.append((i, dict(zip(COLUMNS, cells))))
    if header is None:
        raise GraphError(f"{label} has no header row")
    return rows


def check_readings(graph, module_rel, rows, root):
    """Each named fact's and definition's reading from the table's rows, and every row that is BAD."""
    named = {f["name"]: f for f in graph["facts"] if f["name"]}
    named.update({d["name"]: d for d in graph["definitions"]})
    bad, seen = [], {}
    for line, r in rows:
        where = f"line {line}"
        if any(not r[c] for c in COLUMNS):
            bad.append({"row": where, "why": "an empty cell: " + ", ".join(c for c in COLUMNS if not r[c])})
        elif not re.fullmatch(r"[0-9a-f]{16}", r["pin"]):
            bad.append({"row": where, "why": f"the pin {r['pin']} is not 16 hex digits"})
        elif not re.fullmatch(r"\d{4}\.\d{2}\.\d{2}", r["date"]):
            bad.append({"row": where, "why": f"the date {r['date']} is not YYYY.MM.DD"})
        elif os.path.normpath(r["module"]) != os.path.normpath(module_rel):
            real = os.path.realpath(os.path.join(root, r["module"]))
            inside = real == root or real.startswith(root + os.sep)
            if not inside or not os.path.isfile(real):
                bad.append({"row": where, "why": f"no module {r['module']} in the project"})
        elif r["fact"] not in named:
            bad.append({"row": where, "why": f"{r['module']} has no fact or definition named {r['fact']}"})
        elif r["fact"] in seen:
            bad.append({"row": where, "why": f"a second reading of {r['fact']}; the first is at line "
                                             f"{seen[r['fact']]}"})
        else:
            seen[r["fact"]] = line
            item = named[r["fact"]]
            item["reading"] = {"status": "READ" if r["pin"] == item["pin"] else "STALE", "reading": r["reading"],
                               "by": r["by"], "date": r["date"], "row": where}
            if r["pin"] != item["pin"]:
                item["reading"]["pinned"] = r["pin"]
    for f in graph["facts"]:
        if "reading" not in f:
            unread = f["name"] and f["kind"] != "assumption"
            f["reading"] = {"status": "UNREAD" if unread else "NONE"}
    for d in graph["definitions"]:
        d.setdefault("reading", {"status": "NONE"})
    return bad


def read_arrows(text):
    """Arrows from a file: one `A -> B` to a line (or `A --> B`), with # for comments."""
    out = []
    for i, line in enumerate(text.splitlines(), 1):
        line = line.split("#", 1)[0].strip()
        if not line:
            continue
        m = re.fullmatch(r"(\S+)\s*-+>\s*(\S+)", line)
        if not m:
            raise GraphError(f"arrows line {i}: not `A -> B`: {line!r}")
        out.append([m.group(1), m.group(2)])
    return out


def check_arrows(graph, arrows):
    """A drawn graph against the citations: every arrow that is not a citation, and every citation not drawn."""
    names = {f["name"] for f in graph["facts"] if f["name"]}
    drawn = []
    for a in arrows:
        if not (isinstance(a, (list, tuple)) and len(a) == 2 and all(isinstance(x, str) for x in a)):
            raise GraphError(f"an arrow is a pair of names, not {a!r}")
        if tuple(a) not in drawn:
            drawn.append(tuple(a))
    want = [(c, f["name"]) for f in graph["facts"] if f["name"] for c in f["cites"]]
    unknown = sorted({x for a in drawn for x in a if x not in names})
    return {"drawn": len(drawn), "citations": len(want),
            "not_a_citation": [list(a) for a in drawn if a not in want and not set(a) & set(unknown)],
            "not_drawn": [list(a) for a in want if a not in drawn], "unknown": unknown}


# ---------------------------------------------------------------------------------------------------------------
# The report

def build(xml_text, module, source, module_rel, project_modules=(), root=None, readings=None, readings_label=None,
          arrows=None, fact=None):
    """The report, as data. readings is a table's path, or None for no table."""
    graph = read(xml_text, module, source, project_modules)
    facts, definitions = graph["facts"], graph["definitions"]
    rep = {"record": RECORD, "notes": list(NOTES), "module": module_rel,
           "sha256": hashlib.sha256(source.encode("utf-8")).hexdigest()[:16]}
    bad = []
    if readings:
        bad = check_readings(graph, module_rel, read_table(readings, readings_label or readings), root or os.getcwd())
    else:
        for f in facts:
            f["reading"] = {"status": "UNREAD" if f["name"] and f["kind"] != "assumption" else "NONE"}
        for d in definitions:
            d["reading"] = {"status": "NONE"}
    proofs = [f for f in facts if f["kind"] != "assumption"]
    counts = {s: sum(1 for x in facts + definitions if x["reading"]["status"] == s) for s in ("READ", "STALE")}
    counts["UNREAD"] = sum(1 for f in facts if f["reading"]["status"] == "UNREAD")
    rep["readings"] = {"table": readings_label if readings else None, "read": counts["READ"],
                       "stale": counts["STALE"], "unread": counts["UNREAD"], "bad": bad}
    rep["edges"] = [[c, f["name"]] for f in facts if f["name"] for c in f["cites"]]
    rep["uncited"] = [f["name"] for f in proofs if f["name"] and not f["cited_by"]]
    rep["not_proved_in_text"] = [{"name": f["name"] or f"(unnamed, line {f['line']})",
                                  "why": "OMITTED" if f["leaves"]["omitted"] else "stated with no proof"}
                                 for f in proofs if not f["proved_in_text"]]
    outside, backends = {}, {}
    for f in facts:
        label = f["name"] or f"(unnamed, line {f['line']})"
        for e in f["elsewhere"]:
            outside.setdefault((e["name"], e["module"]), dict(e, cited_by=[]))["cited_by"].append(label)
        for b in f["backends"]:
            backends.setdefault(b, []).append(label)
    rep["elsewhere"] = list(outside.values())
    rep["backends"] = [{"name": b, "cited_by": who} for b, who in backends.items()]
    rested = {}
    for f in facts:
        for a in f["assumes"]:
            rested.setdefault((a["name"], a["module"]), dict(a, rested_on_by=[]))["rested_on_by"].append(
                f["name"] or f"(unnamed, line {f['line']})")
    rep["assumptions"] = list(rested.values())
    rep["use_hide"] = graph["use_hide"]
    kinds = {k: sum(1 for f in facts if f["kind"] == k) for k in KINDS}
    rep["counts"] = {"facts": len(facts), "kinds": {k: v for k, v in kinds.items() if v},
                     "definitions": len(definitions), "citations": len(rep["edges"]),
                     "uncited": len(rep["uncited"]), "not_proved_in_text": len(rep["not_proved_in_text"]),
                     "assumptions_rested_on": len(rep["assumptions"])}
    if arrows is not None:
        rep["arrows"] = check_arrows(graph, arrows)
    if fact is not None:
        named = {f["name"]: f for f in facts if f["name"]}
        if fact not in named:
            raise GraphError(f"{module_rel} has no fact named {fact}")
        keep = set(named[fact]["rests_on"]) | {fact}
        rep["fact"] = fact
        facts = [f for f in facts if f["name"] in keep]
        definitions = [d for d in definitions
                       if fact in d["in_statements_of"] or fact in d["unfolded_by"]]
    rep["facts"], rep["definitions"] = facts, definitions
    rep["summary"] = summary(rep)
    rep["exit"] = 1 if (bad or counts["STALE"] or (arrows is not None and (
        rep["arrows"]["not_a_citation"] or rep["arrows"]["not_drawn"] or rep["arrows"]["unknown"]))) else 0
    return rep


def summary(rep):
    c = rep["counts"]
    kinds = ", ".join(f"{v} {k}{'' if v == 1 else 's'}" for k, v in c["kinds"].items())
    out = [f"{rep['module']}: {c['facts']} fact{'' if c['facts'] == 1 else 's'} ({kinds or 'none'}), "
           f"{c['definitions']} definition{'' if c['definitions'] == 1 else 's'}, {c['citations']} "
           f"citation{'' if c['citations'] == 1 else 's'} between them; {c['uncited']} cited by none; "
           f"{c['not_proved_in_text']} not proved in the text; {c['assumptions_rested_on']} named "
           f"assumption{'' if c['assumptions_rested_on'] == 1 else 's'} rested on."]
    r = rep["readings"]
    table = r["table"] or "no table"
    out.append(f"Readings ({table}): {r['read']} READ, {r['stale']} STALE, {r['unread']} UNREAD, {len(r['bad'])} BAD.")
    if "arrows" in rep:
        a = rep["arrows"]
        out.append(f"Arrows: {a['drawn']} drawn against {a['citations']} citations: {len(a['not_a_citation'])} not a "
                   f"citation, {len(a['not_drawn'])} not drawn, {len(a['unknown'])} unknown "
                   f"name{'' if len(a['unknown']) == 1 else 's'}.")
    return " ".join(out)


def _wrap(label, text, width=112):
    lead = f"  {label:<12} "
    return textwrap.fill(text, width=width, initial_indent=lead, subsequent_indent=" " * len(lead),
                         break_long_words=False, break_on_hyphens=False)


def render(rep):
    """The report as text."""
    out = [f"Lemma graph of {rep['module']} (sha256 {rep['sha256']}), from the text of its proofs ({rep['record']})."]
    out += [textwrap.fill(n, width=112) for n in rep["notes"]]
    out.append("")
    for u in rep["use_hide"]:
        what = ", ".join(u["facts"] + [f"DEF {d}" for d in u["unfolds"]]) or "nothing named"
        out.append(f"{'HIDE' if u['hide'] else 'USE'} at line {u['line']}, for every proof after it: {what}")
    if rep["use_hide"]:
        out.append("A module-level USE is not counted as a citation of any one fact below.")
        out.append("")
    for d in rep["definitions"]:
        span = f"line {d['line']}" if d["line"] == d["end_line"] else f"lines {d['line']}-{d['end_line']}"
        out.append(f"definition {d['name']}   {span}   pin {d['pin']}")
        if d["in_statements_of"]:
            out.append(_wrap("states", ", ".join(d["in_statements_of"])))
        if d["unfolded_by"]:
            out.append(_wrap("unfolded by", ", ".join(d["unfolded_by"])))
        out += _reading_lines(d)
    if rep["definitions"]:
        out.append("")
    for f in rep["facts"]:
        name = f["name"] or "(unnamed)"
        span = f"line {f['line']}" if f["line"] == f["end_line"] else f"lines {f['line']}-{f['end_line']}"
        head = f"{f['kind']} {name}   {span}   pin {f['pin']}"
        if f["kind"] == "assumption":
            out.append(head)
        else:
            leaves = ", ".join(f"{v} {k.upper() if k != 'none' else 'with no proof'}" for k, v in f["leaves"].items()
                               if v)
            steps = f"{f['steps']} step{'' if f['steps'] == 1 else 's'}, " if f["steps"] else ""
            out.append(f"{head}   {steps}{leaves}")
        if f["stated_with"]:
            out.append(_wrap("stated with", ", ".join(f["stated_with"])))
        if f["kind"] != "assumption":
            out.append(_wrap("cites", ", ".join(f["cites"]) or "no fact of this module"))
            if f["elsewhere"]:
                out.append(_wrap("elsewhere", ", ".join(
                    f"{e['name']} ({e['kind']} of {e['module']}, {e['where']})" for e in f["elsewhere"])))
            if f["backends"]:
                out.append(_wrap("backends", ", ".join(f["backends"])))
            extra = [f"{len(f['as_facts'])} definition{'' if len(f['as_facts']) == 1 else 's'} named as a fact ("
                     + ", ".join(f["as_facts"]) + ")"] if f["as_facts"] else []
            if f["expressions"]:
                extra.append(f"{f['expressions']} expression{'' if f['expressions'] == 1 else 's'}")
            extra += [f"{f['only']} BY ONLY"] if f["only"] else []
            if extra:
                out.append(_wrap("also given", "; ".join(extra)))
            if f["unfolds"]:
                out.append(_wrap("unfolds", ", ".join(f["unfolds"])))
        if f["assumes"]:
            out.append(_wrap("assumes", ", ".join(_assumption(a) for a in f["assumes"])))
        if f["not_followed"]:
            out.append(_wrap("not followed", ", ".join(_assumption(a) for a in f["not_followed"])))
        if f["name"]:
            out.append(_wrap("cited by", ", ".join(f["cited_by"]) or "no fact of this module"))
        if f["kind"] != "assumption" and not f["proved_in_text"]:
            out.append(_wrap("NOT PROVED", "in the text: " + ("OMITTED" if f["leaves"]["omitted"]
                                                              else "stated with no proof")))
        if f["not_proved_below"]:
            out.append(_wrap("rests on", "a fact not proved in the text: " + ", ".join(f["not_proved_below"])))
        out += _reading_lines(f)
        out.append("")
    if rep.get("fact"):
        f = next(x for x in rep["facts"] if x["name"] == rep["fact"])
        out.append(f"{rep['fact']} rests on {len(f['rests_on'])} fact{'' if len(f['rests_on']) == 1 else 's'} of this "
                   f"module, shown above with it" + (": " + ", ".join(f["rests_on"]) if f["rests_on"] else "") + ".")
    if rep["elsewhere"]:
        out.append("Cited from other modules:")
        for e in rep["elsewhere"]:
            out.append(textwrap.fill(f"{e['name']} ({e['kind']} of {e['module']}, {e['where']}), by "
                                     + ", ".join(e["cited_by"]), width=112, initial_indent="  ",
                                     subsequent_indent="    ", break_long_words=False, break_on_hyphens=False))
    if rep["assumptions"]:
        out.append("Assumptions rested on, by the facts that name them and by every fact above those:")
        for a in rep["assumptions"]:
            out.append(textwrap.fill(f"{_assumption(a)}, by " + ", ".join(a["rested_on_by"]), width=112,
                                     initial_indent="  ", subsequent_indent="    ", break_long_words=False,
                                     break_on_hyphens=False))
    if rep["backends"]:
        out.append("Backends named: " + "; ".join(f"{b['name']} by {', '.join(b['cited_by'])}"
                                                  for b in rep["backends"]))
    if rep["uncited"]:
        out.append(textwrap.fill("Cited by no fact of this module, so a result of it or a lemma nothing uses: "
                                 + ", ".join(rep["uncited"]), width=112, subsequent_indent="  "))
    for b in rep["readings"]["bad"]:
        out.append(f"BAD reading, {rep['readings']['table']} {b['row']}: {b['why']}")
    if "arrows" in rep:
        a = rep["arrows"]
        for x, y in a["not_a_citation"]:
            out.append(f"ARROW {x} -> {y} is not a citation: the proof of {y} does not name {x}")
        for x, y in a["not_drawn"]:
            out.append(f"NOT DRAWN {x} -> {y}: the proof of {y} names {x}")
        for n in a["unknown"]:
            out.append(f"UNKNOWN {n}: an arrow names it, and the module has no fact of that name")
    out.append("")
    out.append(rep["summary"])
    return "\n".join(out)


def _assumption(a):
    return a["name"] if a["where"] == "module" else f"{a['name']} (of {a['module']}, {a['where']})"


def _reading_lines(item):
    r = item.get("reading") or {}
    s = r.get("status")
    if s == "UNREAD":
        return [_wrap("reading", "UNREAD  no reading is recorded")]
    if s in ("READ", "STALE"):
        tail = f"  ({r['by']}, {r['date']})"
        if s == "STALE":
            tail += f"; the text has changed since: pinned {r['pinned']}, now {item['pin']}"
        return [_wrap("reading", f"{s}  {r['reading']}{tail}")]
    return []


# ---------------------------------------------------------------------------------------------------------------
# The command

def main(argv):
    ap = argparse.ArgumentParser(prog="lemma_graph.py", description="A proof module's lemma graph, from the text of "
                                 "its proofs (ADR-0024, Proposed). It writes nothing into the project.")
    ap.add_argument("module", help="the module, by its path from the project root, e.g. spec/Counter_proof.tla")
    ap.add_argument("--fact", help="one fact, with the facts it rests on")
    ap.add_argument("--readings", help=f"the readings table (default {READINGS}, when it is there)")
    ap.add_argument("--arrows", help="a file of drawn arrows, one `A -> B` to a line, to compare with the citations")
    ap.add_argument("--strict", action="store_true", help="exit 1 when a lemma or theorem is UNREAD")
    ap.add_argument("--json", action="store_true", help="the report as JSON")
    ap.add_argument("--xml", help="read this SANY XML export of the module, and do not run SANY")
    ap.add_argument("--timeout", type=int, default=600, help="seconds before SANY is stopped")
    a = ap.parse_args(argv)
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import tla_kit_mcp as srv          # the server beside this file: its path rules, its checker and its SANY export
    root = srv.project_root()
    try:
        spec_dir, module = srv.module_path(a.module)
        module_rel = srv.rel(os.path.join(spec_dir, module + ".tla"))
        source = open(os.path.join(spec_dir, module + ".tla"), encoding="utf-8").read()
        xml_text = open(a.xml, encoding="utf-8").read() if a.xml else srv.export_xml(spec_dir, module, a.timeout)
        table = None
        if a.readings:
            table = srv.resolve(a.readings)
        elif os.path.isfile(os.path.join(root, READINGS)):
            table = os.path.join(root, READINGS)
        arrows = read_arrows(open(a.arrows, encoding="utf-8").read()) if a.arrows else None
        rep = build(xml_text, module, source, module_rel, srv.t.module_chain(module, spec_dir), root=root,
                    readings=table, readings_label=srv.rel(table) if table else None, arrows=arrows, fact=a.fact)
    except (GraphError, srv.ToolError, OSError) as e:
        print(f"lemma_graph: {e}", file=sys.stderr)
        return 2
    print(json.dumps(rep, indent=1) if a.json else render(rep))
    if rep["exit"] == 0 and a.strict and rep["readings"]["unread"]:
        return 1
    return rep["exit"]


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
