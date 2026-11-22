# tla-kit — A browsable lemma graph, after Lean's Blueprint

**2026.11.22** · a design note, not a record, kept beside `PLAN.md` as `GRAPH-AND-DIAGRAMS.md` is · basis: this
branch at `28e0df5` (`server/lemma_graph.py`, ADR-0024 Proposed, pull request #42), `GRAPH-AND-DIAGRAMS.md` §3,
and the dependency graph of the PFR blueprint (teorth.github.io/pfr/blueprint/dep_graph_document.html) as the
example asked about · prepared by the assistant at the custodian's request

Nothing here is built and nothing here is accepted. No record is written with it. It says what a browsable page of
a proof module's lemmas would be drawn from, how it would be drawn, and what is owed before it is built.

---

## 0. In one paragraph

Lean's Blueprint publishes a page per project on which every definition and lemma is a node, every `\uses` an
arrow, colours say what is stated, formalised and proved, and a click opens the statement, its prose and a link to
the source. tla-kit can give a TLA+ proof module the same page, and most of it already exists on this branch:
`lemma_graph.py --json` returns the facts, the citations SANY resolved, the definitions each proof unfolds, what is
not proved in the text and everything resting on it, and the readings, which are this project's prose and, unlike
Blueprint's, go `STALE` when the proof moves. ADR-0024 item 11 already checks a drawn graph's arrows against the
citations. What is left is a layout, a page generator in the diagram skill, and, if wanted, one join to the
prover's results files. The one real difference from Blueprint is that its layout is done in the browser and is not
a reviewable artifact; here the layout is done at generation time, so the page regenerates byte for byte and a
change in it is a finding, as the diagram skill requires.

---

## 1. What Blueprint shows, and where each comes from here

| Blueprint | Here, from `lemma_graph.py --json` | Left to do |
|---|---|---|
| A node per definition, lemma, theorem | `facts[]`, with `kind`, `line`, `end_line`, `pin`; `definitions[]` likewise | None. A statement is the module's lines `line` to `end_line` |
| An arrow per `\uses`, lemma to lemma | `cites` and `cited_by`, as SANY resolved them (ADR-0024 item 2) | None |
| An arrow per `\uses`, definition to lemma | `unfolds` (after `DEF`) and `stated_with` | None |
| The informal prose | The readings table, `spec/readings.tsv`: `reading`, `by`, `date`, and `READ`, `STALE` or `UNREAD` | None. A reading is pinned to its fact's text, which Blueprint's prose is not |
| "Fully proved", with every ancestor | `not_proved_in_text`, with every fact resting on it; `OMITTED` leaves | None |
| "Proved": Lean accepted it | Not given, on purpose (ADR-0024 item 4) | A join with the module's results file, §3.3, if wanted |
| Nodes from other files | `elsewhere[]`: facts of other modules of the project, and of the libraries | One run per module, joined by the generator (item: "It reads one module at a call") |
| The picture matches the source | Not checked by Blueprint | ADR-0024 item 11: `--arrows` reports an arrow that is not a citation and a citation not drawn |

## 2. What it would be drawn for

tla-kit has no proof module of its own (ADR-0024, Consequences). The modules the page would first be drawn for are
those `lemma_graph.py` has already read:

| Module | Facts | Citations |
|---|---|---|
| The skill's fixture, `Counter_proof.tla` (`examples/agent-repair`) | 6 | 4 |
| TOPAK's `Seats_proof.tla` | 13 | 12 |
| TOPAK's `Workflow_proof.tla` | 44 | 74 |
| All thirty-five of TOPAK's proof modules | 844 | 1,103 |

`Workflow_proof` is the size of one chapter of the PFR blueprint, and is the module the page has to make readable.

## 3. How it would be drawn

### 3.1 A layout at generation time

The skill's rule is that a diagram regenerates byte for byte (`GRAPH-AND-DIAGRAMS.md` §3.2). Blueprint lays its
graph out in the browser with Graphviz, so its picture is whatever the reader's copy of Graphviz draws that day.

- **Rows by depth.** `lemma_graph.py` already computes what each fact rests on and how deep. A fact's row is its
  depth; definitions take a band of their own above the facts that unfold them.
- **Order within a row** by a fixed number of barycentre passes over the arrows, ties broken by name. With the
  library's left-to-right sum, the coordinates are a function of the JSON alone.
- **In the library, not Graphviz.** Pinning `dot` in the image is less code, but its version would move every
  coordinate, and it would be one more tool held by digest. A layered layout over known rows is a few hundred lines.

### 3.2 Three channels of status

Each channel comes from one source, and none is inferred from another:

| Channel | From | Values |
|---|---|---|
| Fill | The text (`proof`, `leaves`, `not_proved_in_text`) | written out; `OMITTED` or stated with no proof; rests on a fact not proved in the text |
| Border | The readings table | `READ`; `STALE`; `UNREAD`; no proof to read (a definition or an assumption) |
| Badge | The module's results file, if §3.3 is done | proved; failed; no current results |

The badge is apart from the fill so that the page keeps ADR-0024's line between what the text says and what
`prove` said. Without §3.3 there is no badge, and the legend says that no node's colour means the prover accepted
it.

### 3.3 The prover's verdict, if wanted

A fact would carry the verdict of the obligations whose lines fall between its `line` and `end_line`, read from the
module's newest results file, and "no current results" when `proof_sync` says that file is not this tree's. Two
things are unconfirmed: that a results file names each obligation's line, which is in the skill's
`proof_results.py` and not in this repository; and how a proof module that `prove` has not run at all is shown.
Both are to be read before this part is built.

### 3.4 The page

One self-contained `browse.html` per project, written by the generator and held to the regression check like any
other diagram:

- the SVG inline, each node with an `id` and a link to its own section of the page;
- a JSON block of each node's details: its statement lines, what it cites and what cites it, what it unfolds, its
  reading with `by`, `date` and status, its badge, and a link to the `.tla` file at its line;
- a script kept in the skill, not fetched from a CDN, for pan and zoom, search by name, a side panel, the marking
  of every fact a node rests on or that rests on it, and a choice of module;
- with the script off, the links still go to each fact's section below the picture.

Everything on the page is generated from the JSON and the source, so a changed page is a changed input.

### 3.5 The order the generator works in

1. Run `lemma_graph.py --json` on each proof module of the project (`tla-kit lemma-graph` in the image).
2. Lay out (§3.1), and write the arrows it will draw.
3. Check those arrows with `lemma_graph.py --arrows`. On any difference, stop and write nothing.
4. Write the static SVG, ADR-0024's "diagram of a proof module, lemma by lemma", and the page around it.

## 4. Where it sits

- **In the diagram skill,** `skills/generating-corpus-diagrams/`, as a generator beside the two of
  `GRAPH-AND-DIAGRAMS.md` §3.4. If that skill and its library have not moved here when this is built, the generator
  starts with a small SVG writer of its own and moves onto the library when it arrives (O2); what it reads does not
  change.
- **Not a server tool.** Drawing writes files, and `GRAPH-AND-DIAGRAMS.md` §3.5 gives the server nothing for
  diagrams. An agent asks `lemma_graph` for the data; the page is for people.
- **`server/lemma_graph.py` is read, not changed.** The generator uses `--json` and `--arrows` as they are.
- **Later, the specification graph's view above it.** When Phase 11 builds the graph, each *proved* edge from a
  proof module to its module would open that module's page, which is the link ADR-0024's Consequences foresee.

## 5. How it would be checked

- Generated twice, in the image and natively, for `Counter_proof` and for `Workflow_proof`: the same bytes.
- A dropped arrow planted in the generator: step 3 of §3.5 stops it.
- In Chromium, through Playwright: a click on a lemma shows its statement lines, citations and reading; the marking
  of what it rests on is exactly `lemma_graph.py`'s set; with the script off, the links still work; both themes.
- A reading added, then its lemma's text changed: the page's diff is that node's border, `READ` to `STALE`, and
  nothing else.
- An `OMITTED` leaf in a fixture: that fact and every fact resting on it change fill, and no other.
- All thirty-five of TOPAK's proof modules generate without an error.

## 6. Decisions owed

| | Decision | Recommendation |
|---|---|---|
| O1 | Built on this branch before pull request #42 merges, or after | After. The page reads the JSON of a script that is still Proposed, and a change to ADR-0024 would move it |
| O2 | A small SVG writer of its own first, or wait for the diagram skill's library (Phase 10) | Its own first, if this comes before Phase 10: the layout and the page do not depend on the library's cards |
| O3 | The prover's badge (§3.3) in the first version, or the text and the readings only | Text and readings first. The badge needs §3.3's two questions answered, and the page is useful without it |
| O4 | The library's layout, or Graphviz pinned in the image (§3.1) | The library's |
| O5 | Where a project publishes its page: GitHub Pages, a release asset, or neither | The project's choice; tla-kit's CI builds the fixture's page and compares it, and publishes nothing |
| O6 | The record this needs before it is built | A line in ADR-0024's Consequences, and the generator's rule in the diagram skill's record (`GRAPH-AND-DIAGRAMS.md` G2). None is written with this note |

## 7. What this does not do

- **It does not say a proof is right.** A graph of citations is the shape of an argument as written, as ADR-0024
  says. A green badge, if §3.3 is built, is the results file's verdict, dated, and nothing more.
- **It does not write a reading.** A node without one is drawn `UNREAD` (ADR-0024 item 8).
- **It does not explain a statement.** Whether a theorem says what its record says is still read by a person.
- **It does not lay out a whole project at once.** One module is one picture; the page chooses between them, and an
  arrow to another module goes to that module's picture.
