#!/usr/bin/env python3
"""Paths not taken, from a record item to a proof, and why each was excluded (ADR-0023, Proposed).

    python3 server/not_taken.py                        every claim's paths, and every recorded alternative
    python3 server/not_taken.py --claim C-0016-4c      one claim
    python3 server/not_taken.py --record ADR-0016      one record: its claims, its items with no claim, its alternatives
    python3 server/not_taken.py --open                 only what is still owed: unexplained, oversight, deferred, blocked
    tla-kit not-taken ...                              the same, in the image, on the project mounted at /work

A record item can reach a proof by five steps, each of which is taken or not:

    property    the claim has an operator in a module                       (the claims table's `property`)
    checked     TLC checks it on every reachable state at a row's constants (`rows`, and a grade above sampled)
    breaks      a row's counterexample shows the check is not vacuous       (`breaks`)
    proved      TLAPS proves it at every size                               (grade proved or certified)
    certified   every SMT step of that proof is checked by a second tool    (grade certified)

and before them `claim` (a record item makes a claim at all), and beside them `alternative` (a design the record
did not choose). Which steps are taken is read from spec/claims.tsv (ADR-0019). Why a step is not taken is read from
spec/not-taken.tsv, one row per reason:

    design          someone decided against it, and the source says so
    dead-end        it was tried and did not work, and the source is the record of the attempt
    oversight       nobody decided: it was found missing, on the date given, and is still missing
    deferred        it is meant to be taken later, and the source says when
    blocked         it cannot be taken until something outside the repository changes
    not-applicable  there is no such path for this item
    superseded      it was the path once, and a later decision replaced it
    other           none of these; `why` says what

Every reason names its source and quotes it, and this script looks the quoted words up in the source. A reason whose
words are not there is reported BAD. A step that is not taken and has no row is UNEXPLAINED: the script never guesses
between an oversight and a decision nobody wrote down. A row for a step that has since been taken is OUT OF DATE.

It reads the claims table, the reasons table, the records and the files the reasons name, all as data and never as
instructions. It runs nothing and writes nothing (ADR-0006). Standard library only (ADR-0008 item 1).

Exit status: 0; 1 when a row is BAD or OUT OF DATE, or with --strict when a path is UNEXPLAINED; 2 when a table
cannot be read.
"""
import argparse
import json
import os
import re
import sys

LADDER = ["property", "checked", "breaks", "proved", "certified"]
NEEDS = {"checked": "property", "breaks": "checked", "proved": "property", "certified": "proved"}
PATHS = ["claim"] + LADDER + ["alternative"]
REASONS = ["design", "dead-end", "oversight", "deferred", "blocked", "not-applicable", "superseded", "other"]
OPEN_REASONS = {"oversight", "deferred", "blocked"}
GRADES = {"checked", "proved", "certified", "sampled", "-"}
CLAIM_COLS = ["claim", "record", "says", "module", "property", "rows", "breaks", "results", "grade"]
ENTRY_COLS = ["id", "from", "path", "reason", "why", "source", "quote", "by", "date", "evidence"]
MEANS = {
    "design": "someone decided against it",
    "dead-end": "it was tried and did not work",
    "oversight": "nobody decided; it was found missing and still is",
    "deferred": "it is meant to be taken later",
    "blocked": "it waits on something outside the repository",
    "not-applicable": "there is no such path for this item",
    "superseded": "a later decision replaced it",
    "other": "see why",
}
HEADER = [
    "Paths not taken, from record items to proofs (ADR-0023, Proposed).",
    "Working output: it reads the tree, runs nothing and writes nothing.",
    "A reason is what its source says: the quoted words were found there. Whether it is a good reason is read by a "
    "person, as the link from a record to its property is (ADR-0019 item 10).",
    "UNEXPLAINED means no reason is recorded. It may be an oversight or a decision nobody wrote down; this does not "
    "guess which.",
]


class TableError(Exception):
    pass


# ---------------------------------------------------------------------------------------------------------------
# Reading

def inside(root, path):
    """A path named by a table, as a real path inside the project, or None."""
    real = os.path.realpath(os.path.join(root, path))
    return real if real == root or real.startswith(root + os.sep) else None


def read_text(root, path):
    real = inside(root, path)
    if real is None or not os.path.isfile(real):
        return None
    with open(real, encoding="utf-8", errors="replace") as f:
        return f.read()


def read_table(root, path, cols, required=True):
    text = read_text(root, path)
    if text is None:
        if required:
            raise TableError(f"no file {path} in the project")
        return []
    rows, header = [], None
    for n, line in enumerate(text.splitlines(), 1):
        if not line.strip() or line.startswith("#"):
            continue
        cells = [c.strip() for c in line.split("\t")]
        if header is None:
            header = cells
            if header != cols:
                raise TableError(f"{path} line {n}: the header is {header}, not {cols}")
            continue
        if len(cells) != len(cols):
            raise TableError(f"{path} line {n}: {len(cells)} cells, not {len(cols)}")
        rows.append(dict(zip(cols, cells), line=n))
    if header is None:
        raise TableError(f"{path} has no header row")
    return rows


def plain(text):
    """Text for comparing a quote with its source: emphasis marks and comment margins out, and all white space, so
    that a line break or a wrapped comment in the source does not hide the words."""
    return re.sub(r"[\s*`#|]+", "", text).lower()


REF = re.compile(r"^(ADR-\d{4})(?:\s+(.*))?$")


def parse_ref(cell):
    """'ADR-0015 item 4' -> (ADR-0015, '4', 'item 4'); 'ADR-0016 History 2026.11.16' -> (ADR-0016, None, 'History …')."""
    m = REF.match(cell.strip())
    if not m:
        return None
    rest = (m.group(2) or "").strip()
    item = re.match(r"item (\d+)\b", rest)
    return m.group(1), (item.group(1) if item else None), rest


class Record:
    def __init__(self, name, text):
        self.name, self.text = name, text
        self.title = next((l[2:].strip() for l in text.splitlines() if l.startswith("# ")), name)
        status = re.search(r"^\*\*Status:\*\*\s*(.+)$", text, re.M)
        self.status = status.group(1).strip() if status else "?"
        self.items, self.alternatives, self.history = {}, [], []
        section, block = None, None
        for line in text.splitlines():
            if line.startswith("## "):
                section, block = line[3:].strip(), None
                continue
            if section == "Decision":
                m = re.match(r"(\d+)\. (.*)", line)
                if m:
                    block = self.items[m.group(1)] = [m.group(2)]
                elif block is not None:
                    block.append(line)
            elif section == "Alternatives not taken":
                if line.startswith("- "):
                    block = [line[2:]]
                    self.alternatives.append(block)
                elif line.startswith("|") and not re.match(r"\|\s*(-|Alternative)", line):
                    self.alternatives.append([" ".join(c.strip() for c in line.strip("|").split("|"))])
                elif block is not None and line.strip():
                    block.append(line.strip())
            elif section == "History":
                m = re.match(r"\|\s*(\d{4}\.\d{2}\.\d{2})\s*\|", line)
                if m:
                    self.history.append(m.group(1))
        self.items = {k: "\n".join(v) for k, v in self.items.items()}
        self.alternatives = [" ".join(a) for a in self.alternatives]

    def item_title(self, k):
        first = self.items[k].splitlines()[0]
        m = re.match(r"\*\*(.+?)\*\*", first)
        return (m.group(1) if m else first).strip()


def read_records(root, decisions):
    out = {}
    real = inside(root, decisions)
    if real and os.path.isdir(real):
        for f in sorted(os.listdir(real)):
            m = re.match(r"(ADR-\d{4})\.md$", f)
            if m:
                out[m.group(1)] = Record(m.group(1), read_text(root, os.path.join(decisions, f)) or "")
    return out


def result_rows(root, path):
    """A results file's rows, name -> (verdict, as expected). The generator's form: cells separated by ' | '."""
    text = read_text(root, path)
    if text is None:
        return None
    out = {}
    for line in text.splitlines():
        cells = [c.strip() for c in line.split(" | ")]
        if len(cells) >= 5 and re.match(r"[\w.-]+$", cells[0]):
            verdict = next((c for c in cells if re.match(r"[A-Z][A-Z-]+$", c) and c not in ("PROPERTY", "INVARIANT")),
                           "?")
            out[cells[0]] = (verdict, cells[-1])
    return out


# ---------------------------------------------------------------------------------------------------------------
# Which paths a claim takes, from the claims table alone

def taken(claim):
    g = claim["grade"]
    t = {
        "property": claim["property"] != "-",
        "checked": claim["rows"] != "-" and g in ("checked", "proved", "certified"),
        "breaks": claim["breaks"] != "-",
        "proved": g in ("proved", "certified"),
        "certified": g == "certified",
    }
    how = {
        "property": f"{claim['property']} in {claim['module']}",
        "checked": f"{claim['rows']} in {claim['results']}",
        "breaks": f"{claim['breaks']} in {claim['results']}",
        "proved": f"grade {g}",
        "certified": f"grade {g}",
    }
    return t, how


# ---------------------------------------------------------------------------------------------------------------
# Checking one row of the reasons table

def check_entry(e, root, claims, records, modules):
    """The faults of one row, as a list; empty when the row is sound. Also sets e['scope'] and e['evidence_rows']."""
    bad = []
    if not re.match(r"N-\d{4}-\d+$", e["id"]):
        bad.append(f"the id {e['id']!r} is not N-<record>-<n>")
    if e["path"] not in PATHS:
        bad.append(f"the path {e['path']!r} is not one of {', '.join(PATHS)}")
    if e["reason"] not in REASONS:
        bad.append(f"the reason {e['reason']!r} is not one of {', '.join(REASONS)}")
    if not re.match(r"\d{4}\.\d{2}\.\d{2}$", e["date"]):
        bad.append(f"the date {e['date']!r} is not YYYY.MM.DD")
    for col in ("why", "by", "quote"):
        if e[col] in ("", "-"):
            bad.append(f"no {col} is given")

    src, ref = e["from"], parse_ref(e["from"])
    e["scope"] = None
    if src in claims:
        e["scope"] = ("claim", src)
    elif ref:
        if ref[0] not in records:
            bad.append(f"from: no record {ref[0]}")
        elif ref[1] and ref[1] not in records[ref[0]].items:
            bad.append(f"from: {ref[0]} has no item {ref[1]}")
        elif ref[2] and not ref[1]:
            bad.append(f"from: {src!r} is neither a record nor a record's item")
        else:
            e["scope"] = ("item", ref[0], ref[1]) if ref[1] else ("record", ref[0])
    elif src in modules:
        e["scope"] = ("module", src)
    else:
        bad.append(f"from: {src!r} is not a claim, a record, a record's item or a module the claims table names")
    if e["scope"] and e["path"] in PATHS:
        kind = e["scope"][0]
        if e["path"] in LADDER and kind not in ("claim", "module"):
            bad.append(f"a {e['path']} path starts from a claim or a module, not from a {kind}")
        if e["path"] in ("claim", "alternative") and kind not in ("item", "record"):
            bad.append(f"{'a claim' if e['path'] == 'claim' else 'an alternative'} path starts from a record or its "
                       f"item, not from a {kind}")

    # The source, and the words quoted from it.
    sref = parse_ref(e["source"])
    path, where = None, ""
    if sref:
        if sref[0] not in records:
            bad.append(f"source: no record {sref[0]}")
        else:
            rec = records[sref[0]]
            text = rec.text
            if sref[1]:
                if sref[1] not in rec.items:
                    bad.append(f"source: {sref[0]} has no item {sref[1]}")
                    text = None
                else:
                    text, where = rec.items[sref[1]], f" item {sref[1]}"
            else:
                h = re.match(r"History (\S+)", sref[2])
                if h and h.group(1) not in rec.history:
                    bad.append(f"source: {sref[0]} has no History row of {h.group(1)}")
            if text is not None and e["quote"] not in ("", "-") and plain(e["quote"]) not in plain(text):
                bad.append(f"source: {sref[0]}{where} does not say \"{e['quote']}\"")
    else:
        path = e["source"].split()[0] if e["source"].split() else ""
        text = read_text(root, path) if path else None
        if not path or path == "-":
            bad.append("no source is given")
        elif inside(root, path) is None:
            bad.append(f"source: {path} is outside the project")
        elif text is None:
            bad.append(f"source: no file {path}")
        elif e["quote"] not in ("", "-") and plain(e["quote"]) not in plain(text):
            bad.append(f"source: {path} does not say \"{e['quote']}\"")

    # Evidence: rows of a named results file that show what the path would have cost.
    e["evidence_rows"] = []
    if e["evidence"] not in ("", "-"):
        m = re.match(r"(\S+):\s*(.+)$", e["evidence"])
        if not m:
            bad.append("evidence is not '<results file>: row row ...'")
        else:
            rows = result_rows(root, m.group(1))
            if rows is None:
                bad.append(f"evidence: no file {m.group(1)}")
            else:
                for name in m.group(2).split():
                    if name not in rows:
                        bad.append(f"evidence: {m.group(1)} has no row {name}")
                    else:
                        e["evidence_rows"].append({"row": name, "verdict": rows[name][0], "outcome": rows[name][1],
                                                   "results": m.group(1)})
    return bad


def entry_view(e):
    v = {k: e[k] for k in ENTRY_COLS}
    v["means"] = MEANS.get(e["reason"], "")
    v["open"] = e["reason"] in OPEN_REASONS
    v["status"] = e["status"]
    if e["faults"]:
        v["faults"] = e["faults"]
    if e["evidence_rows"]:
        v["evidence_rows"] = e["evidence_rows"]
    return v


# ---------------------------------------------------------------------------------------------------------------
# The report

def build(root, claims_path="spec/claims.tsv", table_path="spec/not-taken.tsv", decisions="decisions",
          claim=None, record=None, item=None, path=None, reason=None, only_open=False):
    root = os.path.realpath(root)
    claim_rows = read_table(root, claims_path, CLAIM_COLS)
    entries = read_table(root, table_path, ENTRY_COLS, required=False)
    records = read_records(root, decisions)
    claims = {c["claim"]: c for c in claim_rows}
    modules = {c["module"] for c in claim_rows}
    if len(claims) != len(claim_rows):
        raise TableError(f"{claims_path} gives a claim id twice")
    for c in claim_rows:
        if c["grade"] not in GRADES:
            raise TableError(f"{claims_path} line {c['line']}: the grade {c['grade']!r} is not one of {sorted(GRADES)}")
    if claim and claim not in claims:
        raise TableError(f"{claims_path} has no claim {claim}")
    if record and record not in records:
        raise TableError(f"no record {record} in {decisions}/")
    if item and not record:
        raise TableError("an item needs its record")
    if item and item not in records[record].items:
        raise TableError(f"{record} has no item {item}")
    if path and path not in PATHS:
        raise TableError(f"the path {path!r} is not one of {', '.join(PATHS)}")
    if reason and reason not in REASONS:
        raise TableError(f"the reason {reason!r} is not one of {', '.join(REASONS)}")

    seen = set()
    for e in entries:
        e["faults"] = check_entry(e, root, claims, records, modules)
        if e["id"] in seen:
            e["faults"].append(f"the id {e['id']} is given twice")
        seen.add(e["id"])
        e["status"], e["used"] = ("BAD" if e["faults"] else "OK"), False

    def cites(c):
        """The (record, item) pairs a claim's record cell names."""
        out = []
        for part in c["record"].split(";"):
            r = parse_ref(part)
            if r:
                out.append((r[0], r[1]))
        return out

    def entry_for(c, p):
        own = [e for e in entries if e["scope"] == ("claim", c["claim"]) and e["path"] == p]
        wide = [e for e in entries if e["scope"] == ("module", c["module"]) and e["path"] == p]
        return (own or wide or [None])[0]

    # Every claim's ladder. A row for a path the claims table shows as taken is out of date: for a claim's own row,
    # at once; for a module's row, when no claim of the module is left without that path.
    ladders = {}
    for c in claim_rows:
        t, how = taken(c)
        steps = []
        for p in LADDER:
            e = entry_for(c, p)
            if t[p]:
                steps.append({"path": p, "status": "TAKEN", "by": how[p]})
                if e and e["scope"][0] == "claim" and e["status"] == "OK":
                    e["status"] = "OUT OF DATE"
                    e["faults"] = [f"{c['claim']} takes the {p} path now ({how[p]})"]
            elif e:
                e["used"] = True
                steps.append({"path": p, "status": "NOT TAKEN", "reason": e["reason"], "entry": e})
            elif NEEDS.get(p) and not t[NEEDS[p]]:
                steps.append({"path": p, "status": "FOLLOWS", "follows": NEEDS[p]})
            else:
                steps.append({"path": p, "status": "UNEXPLAINED"})
        ladders[c["claim"]] = steps
    for e in entries:
        if e["scope"] and e["scope"][0] == "module" and e["path"] in LADDER and e["status"] == "OK" and not e["used"]:
            e["status"] = "OUT OF DATE"
            e["faults"] = [f"every claim of {e['from']} takes the {e['path']} path now"]

    # What the question selects.
    def wanted(c):
        if claim:
            return c["claim"] == claim
        if record:
            return any(r == record and (not item or k == item) for r, k in cites(c))
        return True

    def keep(step):
        if path and step["path"] != path:
            return False
        if reason and step.get("reason") != reason:
            return False
        if only_open:
            return step["status"] == "UNEXPLAINED" or step.get("reason") in OPEN_REASONS \
                or (step.get("entry") or {}).get("status") in ("BAD", "OUT OF DATE")
        return True

    out_claims = []
    for c in claim_rows:
        if not wanted(c):
            continue
        steps = [dict(s, entry=entry_view(s["entry"])) if "entry" in s else s for s in ladders[c["claim"]] if keep(s)]
        if steps or not (path or reason or only_open):
            out_claims.append({k: c[k] for k in ("claim", "record", "says", "module", "grade")} | {"paths": steps})

    # A record's items that no claim cites, and its alternatives. Asked for by record, since most items of most
    # records decide something that is not a claim about behaviour.
    out_items, out_alts = [], []
    cited = {(r, k) for c in claim_rows for r, k in cites(c)}
    show_claim_path = not claim and (not path or path == "claim")
    show_alts = not claim and (not path or path == "alternative")
    for e in entries:
        if e["path"] == "claim" and e["scope"] and e["status"] == "OK":
            rec, k = e["scope"][1], (e["scope"][2] if e["scope"][0] == "item" else None)
            if (rec, k) in cited if k else False:
                e["status"] = "OUT OF DATE"
                e["faults"] = [f"{e['from']} has a claim now"]
    if record and show_claim_path:
        rec = records[record]
        for k in rec.items:
            if item and k != item:
                continue
            ids = [c["claim"] for c in claim_rows if (record, k) in cites(c)]
            es = [e for e in entries if e["path"] == "claim" and e["scope"] in (("item", record, k), ("record", record))]
            row = {"item": f"{record} item {k}", "title": rec.item_title(k), "claims": ids}
            if es:
                row["status"], row["entries"] = "NOT TAKEN", [entry_view(e) for e in es]
            elif ids:
                row["status"] = "TAKEN"
            else:
                row["status"] = "NO CLAIM"
            if reason and not any(e["reason"] == reason for e in es):
                continue
            if only_open and not any(e["reason"] in OPEN_REASONS or e["status"] != "OK" for e in es):
                continue
            out_items.append(row)
    if show_alts:
        for e in entries:
            if e["path"] != "alternative" or not e["scope"]:
                continue
            if record and (e["scope"][1] != record or (item and e["scope"][0] == "item" and e["scope"][2] != item)):
                continue
            if (reason and e["reason"] != reason) or (only_open and e["reason"] not in OPEN_REASONS
                                                       and e["status"] == "OK"):
                continue
            out_alts.append({"from": e["from"], "status": "NOT TAKEN", "reason": e["reason"],
                             "entry": entry_view(e)})
        if record and not item and not only_open and reason in (None, "design"):
            rec = records[record]
            quoted = [plain(e["quote"]) for e in entries if e["path"] == "alternative" and parse_ref(e["source"])
                      and parse_ref(e["source"])[0] == record]
            for alt in rec.alternatives:
                if not any(q and q in plain(alt) for q in quoted):
                    out_alts.append({"from": record, "status": "NOT TAKEN", "reason": "design",
                                     "in_record": alt, "source": f"{record} Alternatives not taken"})

    faulty = [entry_view(e) for e in entries if e["status"] != "OK"]
    counts = {"TAKEN": 0, "NOT TAKEN": 0, "UNEXPLAINED": 0, "FOLLOWS": 0}
    by_reason = {}
    for c in claim_rows:
        for s in ladders[c["claim"]]:
            counts[s["status"]] += 1
            if "reason" in s:
                by_reason[s["reason"]] = by_reason.get(s["reason"], 0) + 1
    summary = {
        "claims": len(claim_rows), "paths_taken": counts["TAKEN"], "paths_not_taken_with_a_reason": counts["NOT TAKEN"],
        "by_reason": by_reason, "paths_unexplained": counts["UNEXPLAINED"],
        "paths_that_follow_from_another": counts["FOLLOWS"], "rows": len(entries),
        "rows_bad": sum(e["status"] == "BAD" for e in entries),
        "rows_out_of_date": sum(e["status"] == "OUT OF DATE" for e in entries),
        "alternatives_recorded": sum(e["path"] == "alternative" for e in entries),
    }
    return {"header": HEADER, "reads": {"claims": claims_path, "reasons": table_path, "records": decisions,
                                        "reasons_table_exists": read_text(root, table_path) is not None},
            "claims": out_claims, "items": out_items, "alternatives": out_alts, "faulty_rows": faulty,
            "summary": summary, "ok": not faulty}


# ---------------------------------------------------------------------------------------------------------------
# As text

def wrap(text, width, indent):
    """Wrap at spaces, keeping the first line's own leading and inner spacing."""
    lines, cur = [], ""
    for w in re.findall(r"\s*\S+", text):
        if cur.strip() and len(cur) + len(w) > width:
            lines.append(cur)
            cur = w.lstrip()
        else:
            cur += w
    return ("\n" + " " * indent).join(lines + [cur])


def entry_lines(e, indent):
    pad = " " * indent
    out = [pad + wrap(e["why"], 112 - indent, indent)]
    out.append(pad + wrap(f"source: {e['source']} \"{e['quote']}\" · given by {e['by']}, {e['date']} · {e['id']}",
                          112 - indent, indent))
    for r in e.get("evidence_rows", []):
        out.append(pad + f"evidence: {r['row']} {r['verdict']} ({r['outcome']}) in {r['results']}")
    for f in e.get("faults", []):
        out.append(pad + f"{e['status']}: {f}")
    return out


def as_text(rep):
    out = [wrap(h, 112, 0) for h in rep["header"]]
    r = rep["reads"]
    out.append(f"Read: {r['claims']}, {r['reasons']}{'' if r['reasons_table_exists'] else ' (absent)'}, {r['records']}/")
    for c in rep["claims"]:
        out += ["", f"{c['claim']}  {c['says']}", f"    {c['record']} · {c['module']} · grade {c['grade']}"]
        for s in c["paths"]:
            head = f"  {s['path']:<10}"
            if s["status"] == "TAKEN":
                out.append(wrap(f"{head}TAKEN        {s['by']}", 112, 25))
            elif s["status"] == "FOLLOWS":
                out.append(f"{head}not taken    follows from {s['follows']}")
            elif s["status"] == "UNEXPLAINED":
                out.append(f"{head}UNEXPLAINED  no reason is recorded")
            else:
                e = s["entry"]
                out.append(f"{head}NOT TAKEN    {e['reason']}: {e['means']}")
                out += entry_lines(e, 25)
    if rep["items"]:
        out += ["", "Items of the record, and whether each makes a claim"]
        for i in rep["items"]:
            what = {"TAKEN": "claims " + " ".join(i["claims"]), "NO CLAIM": "no claim, and no reason recorded",
                    "NOT TAKEN": "no claim" + (": claims " + " ".join(i["claims"]) if i["claims"] else "")}[i["status"]]
            out.append(wrap(f"  {i['item']}  {i['title']}", 112, 4))
            out.append(f"      {what}")
            for e in i.get("entries", []):
                out.append(f"      {e['reason']}: {e['means']}")
                out += entry_lines(e, 8)
    if rep["alternatives"]:
        out += ["", "Alternatives not taken"]
        for a in rep["alternatives"]:
            if "entry" in a:
                e = a["entry"]
                out.append(f"  {a['from']}  {e['reason']}: {e['means']}")
                out += entry_lines(e, 6)
            else:
                out.append(f"  {a['from']}  design: the record's own section, Alternatives not taken")
                out.append("      " + wrap(a["in_record"], 106, 6))
    listed = {s["entry"]["id"] for c in rep["claims"] for s in c["paths"] if "entry" in s} \
        | {a["entry"]["id"] for a in rep["alternatives"] if "entry" in a} \
        | {e["id"] for i in rep["items"] for e in i.get("entries", [])}
    rest = [e for e in rep["faulty_rows"] if e["id"] not in listed]
    if rest:
        out += ["", "Rows of the reasons table that do not stand"]
        for e in rest:
            out.append(f"  {e['id']}  {e['from']} · {e['path']} · {e['reason']}")
            out += [f"      {e['status']}: {f}" for f in e["faults"]]
    s = rep["summary"]
    reasons = ", ".join(f"{k} {v}" for k, v in sorted(s["by_reason"].items())) or "none"
    out += ["", f"The whole table: {s['claims']} claims, {5 * s['claims']} paths: {s['paths_taken']} taken; "
                f"{s['paths_not_taken_with_a_reason']} not taken with a reason ({reasons}); "
                f"{s['paths_unexplained']} UNEXPLAINED; {s['paths_that_follow_from_another']} that follow from another.",
            f"{s['rows']} rows in the reasons table, {s['alternatives_recorded']} of them alternatives: "
            f"{s['rows_bad']} BAD, {s['rows_out_of_date']} OUT OF DATE."]
    return "\n".join(out)


def default_root():
    return os.environ.get("TLA_KIT_PROJECT") or ("/work" if os.path.isdir("/work") else os.getcwd())


def main(argv=None):
    ap = argparse.ArgumentParser(description="Paths not taken, from a record item to a proof, and why (ADR-0023).")
    ap.add_argument("--root", default=default_root(), help="the project (default: TLA_KIT_PROJECT, /work, or here)")
    ap.add_argument("--claims", default="spec/claims.tsv")
    ap.add_argument("--table", default="spec/not-taken.tsv")
    ap.add_argument("--decisions", default="decisions")
    ap.add_argument("--claim", help="one claim, by id")
    ap.add_argument("--record", help="one record, e.g. ADR-0016: its claims, its items and its alternatives")
    ap.add_argument("--item", help="with --record, one item of it")
    ap.add_argument("--path", help="one path: " + ", ".join(PATHS))
    ap.add_argument("--reason", help="one reason: " + ", ".join(REASONS))
    ap.add_argument("--open", action="store_true", help="only unexplained, oversight, deferred and blocked")
    ap.add_argument("--strict", action="store_true", help="exit 1 when any path is UNEXPLAINED")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args(argv)
    try:
        rep = build(a.root, a.claims, a.table, a.decisions, a.claim, a.record, a.item, a.path, a.reason, a.open)
    except TableError as e:
        print(f"not_taken: {e}", file=sys.stderr)
        return 2
    print(json.dumps(rep, indent=1) if a.json else as_text(rep))
    if not rep["ok"] or (a.strict and rep["summary"]["paths_unexplained"]):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
