# tla-kit — Porting the specification graph and the diagram skill

**2026.11.21** · a design note, not a record, kept beside `PLAN.md` as `COUPLING.md` is · basis: tla-kit `main` at
`a53425b` and branch `adr-tla-cicd` at `1c69c1b` (`COUPLING.md`, ADR-0018 to ADR-0020, `PLAN.md` Phases 7 to 9,
`spec/claims.tsv`); TOPAK at `ffd02f1` (`spec/specification-graph.py`, `spec/specification-graph.json`,
`spec/specification-graph-results-2026.11.17.txt`, ADR-0057, ADR-0058, `skills/generating-corpus-diagrams/`,
`diagrams/`) · prepared by the assistant at the custodian's request

Nothing here is built and nothing here is accepted. It proposes two phases after `PLAN.md`'s Phase 9, and two
records. Where it says what exists, it cites the file. One thing was tried while writing it, and §5 records it.

---

## 0. In one paragraph

tla-kit's tools return facts about one run: a trace, a failed obligation, a row's verdict. Nothing in it answers
the question a person signing off actually asks: **which claims hold, on what evidence, and what is still left to a
reader.** TOPAK answers that for itself with two things. Its **specification graph** types every link between two
artifacts by what the link leaves to a person, and computes for each theorem the grade at which it reaches the code
and the route that carried it. Its **diagram skill** draws the records and the evidence as generated pictures that
regenerate byte for byte, so a picture that changes is a finding. Neither can be used outside TOPAK today: the
graph's builder reads TOPAK's crates, floor and Lean files, and the diagram skill ships without its drawing library.
This note proposes to bring the general part of each into tla-kit: a **graph format and checker** with a sixteenth
server tool, built on the claims table of `COUPLING.md`; and the **diagram skill as a fourth plugin**, with its
library, and with one diagram that draws any project's graph from its graph file.

---

## 1. What exists, and what is tied to TOPAK

| Piece | Where | General | Tied to TOPAK |
|---|---|---|---|
| The graph's form | ADR-0057 §1, §3, §5 (Proposed) | Nodes with an open set of layers; eight edge types ordered by what each leaves to a person; pins and freshness; a grade as a threshold | The ten layer names; the theorem numbers |
| The builder | `specification-graph.py build`, about 700 of its 1,248 lines | Pinning an edge from a results file's header or from the tree; keeping an edge's pins until `--repin` | Every edge it finds: it reads `mechanism/` crates, `floor/`, `spec/lean/`, `corpus-pins.sha256`, `drift.rs` |
| The checker | `specification-graph.py check` | Stale edges; clauses no model reads; a guarantee stated twice; each node's edges up | The four lists it compares (`corpus-pins.sha256`, the binding table, `manifests/index.tsv`, the sync scripts) |
| Grades | The checker, through `inventory.py` and `theorem-premise-binding.json` | A grade is the strongest threshold at which a claim still holds | The evaluation is TOPAK's premise inventory, an AND and OR over rows, parameters and gap premises |
| The overlay | ADR-0058 (Proposed) | A project declares its graph against another's, and a supplier publishes a subgraph | Nothing built |
| The diagram skill | `skills/generating-corpus-diagrams/`, plugin `0.1.0` | The method, the content rules, the review checklist, three scripts | The scripts default to `diagrams/topak` and `diagrams/gen-topak-family.py` |
| The drawing library | `diagrams/topak/src/lib.py` (597 lines), `metrics.py` | Text measuring and wrapping, cards, tables, arrows, two themes, the overlap warning | It is **not in the skill**; it holds TOPAK's state-of-record constants (`STATE_G11`, `STATE_G12`) |
| The graph's picture | `diagrams/topak/src/d_h9_specification_graph.py` (1,266 lines) | It reads the graph file at build time | It also quotes ADR-0057 and TOPAK's findings |

`COUPLING.md` already places the graph: the claims table "is the floor, not the ceiling", a heavier form "may
generate the table" (§3.2), and TOPAK is the one project at "more than the floor" (§3.5). This note is the plan for
that ceiling, and for the picture of it.

---

## 2. The graph in tla-kit

### 2.1 What is ported, and what stays

- **Ported: the format.** One file, `spec/specification-graph.json`, of nodes and typed edges, as ADR-0057 §8 has
  it. The eight edge types and their order come over unchanged. Layers stay open, and a project names its own.
- **Ported: a checker that reads only the format.** `spec_graph.py check`, with the TLA+ skill's scripts. It
  reports stale edges, claims with no edge below them, guarantees stated twice, and each claim's grade with the
  route that carried it and what would lift it one grade.
- **Ported: a builder for what tla-kit can see.** From the claims table and the results files it derives the edges
  inside the record and model layers: a record item to its property (*read*, with the reader named), and a proof
  module to its module (*proved*). It pins each from the results file's header, as TOPAK's builder does.
- **Stays with the project: every edge below the model.** Code, policy, a second prover, traces. A project declares
  those by hand in a file the builder merges, or writes its own builder that emits the format. TOPAK keeps
  `specification-graph.py build` for its crates, floor and Lean files.
- **Stays with TOPAK: the premise inventory.** `inventory.py`, the binding table and the four lists are TOPAK's
  assurance case. tla-kit's checker grades over edges alone (G3 below).

### 2.2 How it sits on the claims table

A claim (`C-0015-4a`) becomes a node's guarantee, and its row in `spec/claims.tsv` becomes edges. A project with a
graph **generates its claims table from it** and the claims check runs unchanged; a project with only a table has
no graph and loses nothing. So the graph adds no second source of truth: where both exist, the table is derived.

The claims check says a claim's rows exist, pass and are current. The graph adds what the check cannot say: how far
down the claim reaches. For tla-kit itself that answer is short and worth stating. `ProveRequests`' properties
reach `server/tla_kit_mcp.py` by `server/test_prove.py`, which would be a *tested* edge. `PinLifecycle`'s reach the
workflows by nothing but reading, a *read* edge. That is the assistant's reading of the tree, to be confirmed when
the graph is built; the point is that the graph would print it.

### 2.3 The server tool

A sixteenth tool, `graph`, after `claims`. It runs the checker and returns the report as data: for one claim, its
grade, its route, each edge's type, pins and freshness, and what each edge leaves to a person. It writes nothing
(ADR-0006). **`build` is not offered by the server**: re-pinning an edge is the review (ADR-0057 §3), and a review
is not something a tool call should make.

This is the tool an agent calls to answer "why should I believe this property". Its header says what
`COUPLING.md` §1 says: every edge up from a module to its record is *read*, so a grade says how a claim reaches the
code, not that the module says what the record says.

### 2.4 Specify before building

tla-kit specifies a process before it builds it (ADR-0015, ADR-0016, ADR-0020 item 5). The graph's process is
pinning: an edge is fresh, goes stale when an end moves, and is fresh again only by a re-pin. If the graph's
freshness is defined as the claims check's, over the same digests, `spec/ClaimsSync.tla` already covers it, with
one property added: **a stale edge never counts toward a grade.** If it is defined apart, it needs a small module
of its own. G4 below.

---

## 3. The diagram skill in tla-kit

### 3.1 What moves

- **The plugin**, to `skills/generating-corpus-diagrams/`, as a fourth plugin beside the three of ADR-0018. It is
  enabled on its own, needs no other skill, and carries the conventions file like the others.
- **The library, which the skill has never shipped.** `lib.py` and `metrics.py` move into the plugin. TOPAK's
  state-of-record constants come out of the library and go to the project's own file. Without this, no project but
  TOPAK can follow the skill's first step.
- **A generator that names no project.** `gen-topak-family.py` is 40 lines and general but for its paths; it ships
  as the skill's `gen_family.py`.
- **The defaults**, out of the scripts and into the one repository-specific file each skill keeps (ADR-0018 item 7):
  the family's directory, its README, its state line.

TOPAK's 58 diagram modules and their SVGs stay in TOPAK. They are TOPAK's content.

### 3.2 The interpreter pin

The skill pins Python 3.9, through `uv`, because Python 3.12 changed `sum()` over floats and every coordinate moved
(the skill's "the interpreter is part of the input"). The image carries Python 3.14.4 and no `uv`. §5 shows the pin
is not needed: with a plain left-to-right sum in the library, a newer interpreter writes the pinned one's bytes.
So the library takes that sum, the `uv` step goes, and the regression check runs in the image, whose interpreter is
held by digest anyway.

### 3.3 Looking at a diagram

The skill's rule is that a diagram is looked at in both themes. `render.py` needs `rsvg-convert` for light and a
headless Chrome for dark, because the dark theme is CSS that `rsvg` does not read. Neither is in the image, and
Chrome is large. Three ways, G6 below:

1. Generation and the regression check in the base image; rendering stays on the host, as today.
2. A variant image by tag with both, as ADR-0012 allows for large optional tools.
3. `render.py` resolves the dark theme's colours into the SVG itself, so `rsvg-convert` draws both themes, and the
   base image gains one small package. Whether that matches what a browser shows has to be checked by eye first.

### 3.4 Diagrams that come with the skill

- **The specification graph**, drawn from any project's graph file: layers as regions, edges coloured by type,
  stale edges marked, each claim's grade. It is TOPAK's H9 with the TOPAK prose taken out.
- **The claims table**, drawn whole, one row per claim with its status from the claims check.

These two make the skill useful to a project on its first day, and they are the picture of §2's report. A project's
other diagrams are its own.

### 3.5 No server tool for drawing

Drawing writes files, and looking is a person's or an agent's own act. The skill's scripts run from the command
line in the image. The server gains nothing for diagrams in this plan.

---

## 4. Phases offered

After `PLAN.md`'s Phase 9. Phase 10's step 1 could instead ride with Phase 7's step 2, which moves the TLA+ skill
by the same mechanism; that is G1.

### Phase 10: the diagram skill

1. **The plugin moves here**, with the library and the generator inside it, and TOPAK's constants taken out.
2. **The left-to-right sum**, and the regression check run in the image without `uv`.
3. **Rendering**, by whichever of §3.3 is chosen.
4. **tla-kit's own small family**: the chain of `COUPLING.md` §1, the pin and release process, the `prove` tool's
   requests. Each cites its record items.
5. **TOPAK takes the skill from a tla-kit release**, by a TOPAK record, and retires its copy as the source.

**Done when:**
- TOPAK's family regenerates byte for byte in the image with the skill's library, with no change but the diagrams
  that are already out of date in TOPAK (§5);
- a project that is not TOPAK scaffolds, generates and checks a diagram with nothing but the plugin and the image;
- tla-kit's family is in CI's regression check, and a pull request that moves a record a diagram reads fails it
  until the diagram is amended;
- all of it is in a release.

### Phase 11: the specification graph

Needs Phase 7's claims table and check. TOPAK's side of step 5 needs ADR-0057 decided there.

1. **A record for the format** (ADR-0021 below), and `ClaimsSync`'s added property or a module of its own.
2. **`spec_graph.py check`**, over the format alone, with fixtures.
3. **`spec_graph.py build`** for the record and model layers, and tla-kit's own graph, with its edges below the
   model declared by hand.
4. **The `graph` tool.**
5. **The comparison with TOPAK**: tla-kit's checker on TOPAK's graph file, beside TOPAK's own, as
   `server/compare_topak.py` did for Phase 3.
6. **The two diagrams of §3.4.**
7. **gov-tla's graph**, small, after its claims table (`COUPLING.md` §4 step 9).

**Done when:**
- tla-kit's graph is built and checked in CI, its claims table is generated from it, and the claims check still
  reports `IN SYNC`;
- fixtures produce a stale edge, a claim with no edge below it, a guarantee stated twice and a malformed graph, and
  the checker names each;
- on TOPAK's graph file, tla-kit's checker lists the same stale edges as TOPAK's, and the same grade for every
  theorem whose route is edges alone; the theorems it cannot grade without the premise inventory are listed, not
  guessed;
- the `graph` tool answers for one claim with its grade and route, and `server/test_mcp.py` drives it;
- the graph diagram regenerates from tla-kit's and from TOPAK's graph file.

---

## 5. What was tried: the interpreter pin

On 2026.11.21, in a scratch copy of TOPAK at `ffd02f1`, the whole family was regenerated three ways.

| Interpreter | `sum()` | Diagrams changed, of 58 |
|---|---|---|
| Python 3.9, as the skill pins | the interpreter's | 2 |
| Python 3.13.18 | the interpreter's | 39 |
| Python 3.13.18 | replaced by a plain left-to-right sum | 2, the same two, with the same bytes as under 3.9 |

So a left-to-right sum removes the dependence on the interpreter, with no regeneration of the family. It was tried
on 3.13.18, not on the image's 3.14.4; Phase 10's first "Done when" is that test. The replacement was made by
overriding `sum` for the whole run, not by editing the 102 call sites in 31 files.

**The two that change are findings for TOPAK**, by the skill's own rule that an unexpected change means an input
moved:

- **H9**, the specification graph, was drawn at 419 nodes and 435 edges. The graph file now has 529 and 495.
- **B11**, the build and run pipeline, shows a digest as matching that now differs.

Neither is tla-kit's to amend. They are leads for the custodian, and the first is the picture this note proposes
to make general.

---

## 6. Records this needs

| Record | Title, short | Notes |
|---|---|---|
| ADR-0021 | A project's specification graph is one file of typed edges, checked by a tool that reads only the file, and the claims table is generated from it where both exist | Takes ADR-0057's §1, §3, §5 and §8 as its form. Says what happens here if TOPAK's ratification changes them |
| ADR-0022 | The diagram skill is a fourth plugin, with its library, and its regression check runs in the image | Or an edit to ADR-0018 before it is accepted, which is still possible while it is Proposed (G2) |

In TOPAK: one record to take the diagram skill from tla-kit; and, after ADR-0057 is decided, one to check its graph
with tla-kit's checker beside its own.

---

## 7. Decisions owed

| | Decision | Recommendation |
|---|---|---|
| G1 | Does the diagram skill move with the TLA+ skill in Phase 7, or after Phase 9 | With Phase 7. It is the same move, it depends on nothing else, and it is the cheaper half of this note |
| G2 | A fourth plugin by a new record, or by editing ADR-0018 while it is Proposed | Edit ADR-0018: "three skills" is in its title, and a record accepted with a known fourth is wrong on its first day |
| G3 | Does TOPAK's premise inventory come over, or only edges and grades | Edges and grades first. The inventory is TOPAK's assurance case; port it only if a second project needs AND and OR over premises |
| G4 | Graph freshness as the claims check's, or its own | The claims check's, with one property added to `ClaimsSync.tla`. Two definitions of stale would disagree |
| G5 | Does tla-kit adopt the format before TOPAK decides ADR-0057 | Yes, as tla-kit's own record, saying it follows ADR-0057 as Proposed. Waiting ties tla-kit to another repository's schedule, which `COUPLING.md` §7 already chose not to do for signing |
| G6 | How a diagram is rendered for looking (§3.3) | Option 1 now, and try option 3; a variant image with Chrome only if option 3 does not match a browser |
| G7 | How the claims table's grade words (*checked*, *proved*, *certified*, *sampled*) relate to the graph's eight edge types | Keep both. The words grade the evidence for a property inside the model; an edge type grades a relation between two artifacts. The record should say so in one table |

---

## 8. What this does not do

- **It does not check the first link.** Every edge up from a module to its record is *read*. The graph prints that
  on every report; it does not change it.
- **It does not explain one trace or one failed obligation.** `tlc_run` still returns states and `prove` still
  returns obligations, for the agent to explain. A diff between consecutive states, which other TLA+ skills offer,
  is a small addition to `tlc_run` and is not part of this note.
- **It does not grade code.** tla-kit's builder stops at the model. What reaches the code is declared by the
  project, by hand or by its own builder, and a hand-declared edge is as good as the person who declared it.
- **It does not move TOPAK's graph or diagrams.** Both are TOPAK's content and stay under its records.
- **A diagram decides nothing.** Where a diagram and a record disagree, the record wins, as the skill says.

---

## 9. Risks

| Risk | What follows | What limits it |
|---|---|---|
| ADR-0057 changes at ratification | The format here moves after projects use it | ADR-0021 names the sections it takes; a change is one record here and a rebuild of each graph |
| A grade is read as more than it is | False assurance, which is what tla-kit exists to reduce | The report's header, and the grade word beside every claim; *read* by the drafter is printed as that |
| The graph becomes a second place to keep claims | The table and the graph drift | The table is generated where a graph exists, and CI compares them |
| The library's move breaks TOPAK's bytes | 58 diagrams change at once | Phase 10's first test is that they do not |
| The work grows past its use | A graph for projects with nineteen claims | Phase 10 stands alone. Phase 11 can stop after step 4 and still be useful to tla-kit and TOPAK |
