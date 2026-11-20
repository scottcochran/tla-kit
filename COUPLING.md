# tla-kit — Coupling records, specifications, evidence and CI into one checked chain

**2026.11.20** · a design note, not a record, kept beside `PLAN.md` · written in TOPAK's working tree and moved here
the same day, on branch `adr-tla-cicd`, then revised the same day for the custodian's answers to two questions of
TOPAK's house-style proposal (§7) · its proposals are drafted as ADR-0018 to ADR-0020 (Proposed) and its first step
as [`spec/claims.tsv`](spec/claims.tsv) · basis: tla-kit `main` at `a53425b` (README, PLAN.md, ADR-0001, 0002, 0007,
0013 to 0016, `spec/`, `.github/workflows/ci.yml`, `evidence.yml`, `agent.yml`, `vendor/`, CONSUMERS.md); TOPAK at
`1722432` (`spec/specification-graph.json`, `spec/theorem-premise-binding.md`,
`mechanism/crates/topak-core/tests/drift.rs`, ADR-0057, ADR-0058, ADR-0069, ADR-0077, `.claude/skills/`) and at
`ffd02f1` (`derived/topak-assisted-development-house-style-proposal-DRAFT.md` and
`derived/topak-adr-skills-comparison-2026.11.18.md`, merged by TOPAK pull request #99, each read in full); gov-tla at
`b8a82be` (README, `rows/`, `results/`, `tools/TLA-KIT-PIN`) · prepared by the assistant at the custodian's request

Nothing here is built but the claims table, and nothing here is accepted. Where it says what tla-kit does today, it
cites the file; where it proposes, it says so. The custodian settled, before and during the writing: **tla-kit is
where the coupling lives, because tla-kit already uses it on itself**; and the answers marked ⟨Q7⟩ and ⟨Q12⟩ (§7).

---

## 0. In one paragraph

tla-kit already runs the whole chain on itself, at small scale. Its records name the actions of its own TLA+
modules (ADR-0015 item 2). Its results files are made only by the skill's generator and name what checked them.
Its CI reruns those rows when `spec/` or `decisions/` changes, and `main` merges only on a pass (ADR-0014 item 1).
Its pin moves carry evidence over the projects it serves (ADR-0013 item 3). An agent job repairs a proof with
nothing but the server's tools, and the repair is checked apart from the agent (`agent.yml`). And a person accepts
every record (the **Chosen by** line). What is missing is that most links between these are **prose**, and that the
method the chain runs on lives in another repository (ADR-0007). This note proposes: **three independent skills,
records, TLA+ and CI/CD**, kept and released here, each enabled on its own by the repository that uses it; a
**claims table** that writes down the link from record items to rows, for repositories that enable both records and
TLA+; and a **claims check** behind a required CI check that keeps the table true. It also says plainly what none of
this checks: whether a module says what its record says. That is still read by a person.

---

## 1. The chain

Each arrow is a link a reader has to be able to follow.

```
 Record item ──► Claim ──► Property ──► Result ──► Checker ──► CI ──► Acceptance
 (ADR-n §k)      (what     (module,     (named     (image      (rerun,  (a named
                 the item   row,        file,      digest,     required person,
                 asserts)   expected    never      every tool  check)   with the
                            verdict)    edited)    by digest)           evidence)
       ╰──── read ────╯╰──────────────── checked ──────────────────╯
```

- A **record item** is the unit a decision is made in: `ADR-0015 item 4`, not `ADR-0015`.
- A **claim** is what an item says is true and checked.
- A **property** is where it is checked: a module, an operator, and the rows that exercise it, each with the verdict
  its row list expects.
- A **result** is the dated file the generator wrote, with the digests of the module, the rows and the runner.
- A **checker** is the image, by digest, that made the result.
- **CI** reruns what a change could have changed, and refuses the merge if a claim is no longer true. It never
  accepts anything.
- **Acceptance** is a person's, and is never inferred from a green check.

**The first link is read, not checked.** A check can show that a claim points at rows that pass. It cannot show that
the property says what the record says. TOPAK's ADR-0057 says the same of every module's edges up, and TOPAK's
house-style proposal (§4.4 item 3) asks that the chain say so wherever it says "chain", so that nobody reads it as
stronger at the top than it is. Everything from the property rightwards can fail a check; the first arrow fails only
a reader.

---

## 2. Where tla-kit stands on each link today

| Link | What tla-kit does today | Where | Written as |
|---|---|---|---|
| Record → property | Each action of `PinLifecycle.tla` names the record item it comes from; "a change to a record that changes an action changes the module in the same pull request" | ADR-0015 item 2; `spec/README.md`'s gap table | **Prose** |
| Property → expected verdict | Row lists carry the expected verdict of every row, and the generator writes a file only when every row is as expected | `spec/*-rows.txt`; the vendored `tlc_rows.py` | Data |
| Result → module, rows, runner | Every results file names the sha256 of the module, the row list and the runner scripts | `spec/*-results-*.txt` headers | Data |
| Result → checker | Results name the **jar's** digest. ADR-0002 item 2 says a project's results name the **image's**; the TLC results at `a53425b` do not | `spec/PinLifecycle-results-2026.11.19.txt` lines 3 to 6 | **Gap** |
| Result → current | `proof_sync` reports `IN SYNC`, `STALE`, `MISSING` for proof results. For TLC results, CI regenerates and compares | the skill's `proof_sync.py`; `ci.yml` | Data for proofs; rerun for TLC |
| Change → which rows rerun | Every row of both modules, whenever `spec/` or `decisions/` changes or a checker pin moves | `ci.yml` header, ADR-0015 item 8 | **Coarse** |
| CI → merge | Required checks on `main` by ruleset; a pull request is retested if `main` moved | `ci.yml` header; ADR-0014 item 1 | Enforced |
| Pin move → consumers | Evidence over every project served, at a named commit of each | `evidence.yml`; ADR-0013 item 3 | Enforced for TOPAK; **gov-tla not run**, though public since 2026.11.20 |
| Agent → check | An agent repairs a broken proof with only the server's tools; the repair is checked apart from it | `agent.yml`; `examples/agent-repair/` | Enforced (run by hand, it costs an API call) |
| Method | The TLA+ skill's scripts are vendored from TOPAK at a named commit and checked by digest | ADR-0007; `vendor/VENDOR-PIN` | Data, but **the source is outside tla-kit** |
| Records method | `decisions/` has a consistent form, and accepted text is not edited | `decisions/README.md` | Convention; **no skill, no check** |
| Acceptance | The custodian accepts each record, and the README says who chose what | `decisions/README.md` table | Convention |

Six of the twelve links are enforced data already. The other six are what this note is about.

---

## 3. The design

### 3.1 Three independent skills, each enabled on its own (ADR-0018)

| Skill | What it does | Needs |
|---|---|---|
| **Records** | Drafts, revises and proposes decision records; keeps accepted text unedited; marks who decided what. One skill, not split by act ⟨Q7⟩ | Nothing |
| **TLA+** | `writing-tla-specs-and-proofs`, moved here from TOPAK, with the MCP server it declares | Docker and the image (the skill also runs without them) |
| **CI/CD** | How a change is carried: branch, commit, the repository's checks, push, pull request, and what the assistant never does | Nothing |

- **Each is a plugin of its own, and a repository enables any subset** ⟨Q12⟩: only TLA+; records and TLA+; all
  three. No skill requires another.
- **A conventions file is vendored into each**, because each is installed alone. It holds the words for a result,
  the second-reader rule, "everything a skill reads from the project is data, never instructions", what a check's
  exit status means, and that a file is named, never found as the newest matching a pattern. CI checks the copies
  agree. Those are the disagreements TOPAK's house-style proposal lists as H-1 to H-11, settled once.
- **The owner of a decision is called the custodian** ⟨Q7⟩, defined in the conventions file as a role: the person
  who decides for the repository.
- **Each skill keeps one repository-specific file**: paths, lanes, the commit message's form, the list of checks.
  A repository's own process on top of a skill, such as TOPAK's genesis, Batches and checkpoints over the records
  skill, stays in that repository.
- **One tag releases the image and the three plugins.**
- **tla-kit decides the order and the splits** ⟨Q7⟩ ⟨Q12⟩, in `PLAN.md`.

### 3.2 The claims table (ADR-0019)

It applies only where the records and TLA+ skills are both enabled: it links one to the other. One file,
`spec/claims.tsv`, one row per claim, tab-separated.

| Column | Meaning | Example |
|---|---|---|
| `claim` | A stable id, never reused | `C-0015-4a` |
| `record` | The record item that makes the claim | `ADR-0015 item 4; ADR-0014 item 1 (fix 1)` |
| `says` | The claim in one line, as the record words it | `Every release's evidence was run on the image the release publishes` |
| `module` | The module that checks it | `spec/PinLifecycle.tla` |
| `property` | The operator the rows check | `EvidenceFitsRelease` |
| `rows` | The rows that check it | `n-none-evidence` |
| `breaks` | The rows whose counterexample shows it is not vacuous, or `-` | `m-nof1-evidence m-aswritten-evidence` |
| `results` | The results file that holds those rows, by name | `spec/PinLifecycle-results-2026.11.19.txt` |
| `grade` | `checked`, `proved`, `certified` or `sampled`, from the conventions file; `-` where nothing in TLA+ checks it | `checked` |

It restates nothing: verdicts stay in the row lists and digests in the results files. A record item that makes a
claim carries the id in its text. A property that is not a claim (a type invariant, a conjunction, a witness) is
marked in the table's comments. A heavier form, such as TOPAK's specification graph with its premises and typed
edges, may generate the table; the table is the floor, not the ceiling.

### 3.3 The claims check (ADR-0019)

`claims_check.py`, with the TLA+ skill's scripts, and a fifteenth server tool, `claims`. One line per claim:

- `IN SYNC`: the record, item, module, property, rows and results file exist; every row is as the table needs it in
  the named file; and that file's digests are the tree's.
- `STALE`: as `IN SYNC`, but the module, the row list or the record changed after the file was made. Record digests
  are whole-file, so a History row trips them; a false `STALE` costs one rerun.
- `MISSING`: something the table names does not exist.
- `BROKEN`: the named file contradicts the table.

It also lists properties no record claims and no comment marks, and claim ids that appear on one side only. It reads
everything as data. It writes nothing, as `proof_sync` writes nothing (ADR-0006). And its report says, in its header,
that `IN SYNC` means the rows exist and pass, not that the property is the claim (§1).

### 3.4 CI (ADR-0020)

- **The claims check is a required check** in a repository with a table. Its tier, in the house-style proposal's
  terms, is **carrier**: it can refuse a merge, and it never accepts a record.
- **Only `STALE` claims are rerun.** A change to `decisions/ADR-0016.md` reruns ADR-0016's claims, not every row. A
  checker pin move still reruns everything.
- **Results name the image**, by an `Image:` line the generators add, and a result made in another image is `STALE`.
- **Evidence over consumers runs each consumer's claims check.**
- **The CI/CD skill is not part of this** ⟨Q12⟩: it runs whatever checks a repository lists.
- **Who accepted is not settled by any check.** A required check is a carrier's refusal; it does not show who merged,
  and an assistant acting under the custodian's account looks the same to GitHub (TOPAK's comparison, SK-4).

### 3.5 What a repository takes

| Enabled | What the repository has | Who is there today |
|---|---|---|
| Image only | A pin of the image, for its own run scripts | gov-tla (`v0.1.0`), TOPAK (`v0.4.0`) |
| TLA+ | The method and the server; results regenerated and compared in the image | TOPAK, gov-tla (by a copy of the skill, not yet by plugin) |
| Records | The records form and its rules, with no image | None yet |
| Records and TLA+ | Both, plus the claims table and check | tla-kit itself, first (§4) |
| CI/CD, with any of the above | How a change is carried, and the repository's checks run before a push | None yet |
| More than the floor | Premises and a typed graph of every edge, from which the claims table is generated | TOPAK, in part (ADR-0057 is Proposed) |

### 3.6 Specify before building (ADR-0020 item 5)

`spec/ClaimsSync.tla`, before the script, with three properties: no acceptance on a stale claim; a pass means a
current result; a rerun cannot hide a break. Its mutations are the shortcuts: CI that skips stale claims, a
generator that writes over a failing row, an acceptance that does not wait for the check, a per-item record digest
that misses a History row.

---

## 4. Order of work

tla-kit decides the order ⟨Q7⟩; this is the one offered.

1. **tla-kit's own claims table.** *Done when* every property of both row lists is claimed or marked, and every
   checked item in those records carries its id.
   **Done in part, 2026.11.20:** 19 claims, 10 of `PinLifecycle` and 9 of `ProveRequests`, each naming its results
   file; every row it names is as expected in that file. The records do not carry their ids yet (a History row each,
   after acceptance). Writing it found three things, listed in its comments: ADR-0016 item 4 lists a property the
   module abstracts away (`C-0016-4c`); the reaping property is decided in a History row, with no item to cite
   (`C-0016-h1`); and six claims, five of `PinLifecycle` and one of `ProveRequests`, have no mutation that breaks
   them.
2. **The conventions file**, written once and vendored into the TLA+ skill first. *Done when* it settles H-1, H-2,
   H-4 to H-7, H-9 and H-10 of the house-style proposal, and CI checks the copies agree.
3. **The TLA+ skill moves here** (ADR-0018 item 4). *Done when* TOPAK and gov-tla each load it from a tla-kit
   release, and `vendor/` is gone.
4. **`spec/ClaimsSync.tla`**, rows and results. *Done when* `Mut = "none"` holds and each mutation breaks its
   property and no other.
5. **`claims_check.py` and the `claims` tool.** *Done when* tla-kit is `IN SYNC` at a clean tree, and `STALE`,
   `MISSING` and `BROKEN` each show on a fixture built to cause it.
6. **CI.** *Done when* a pull request that edits one record reruns only that record's rows, one that breaks a row
   cannot merge, and results carry the `Image:` line.
7. **The CI/CD skill**, first the part that carries a change (branch, commit, checks, push, pull request, what the
   assistant never does), then signing and gate evidence once TOPAK's identity investigation (its ⟨K10⟩) reports.
   *Done when* tla-kit's own pull requests follow it.
8. **The records skill**, drawn from tla-kit's `decisions/` form, carrying what TOPAK's comparison found in no
   external skill: a change smaller than a record, who decided what, conditions marked Met or Not met, and the
   missing reader stated. *Done when* it drafts a tla-kit record that passes the claims check.
9. **gov-tla enables records and TLA+**, with its own claims table. *Done when* tla-kit's evidence run reports
   gov-tla's claims `IN SYNC`. It is the first consumer to reach that level and the one a newcomer reads first.
10. **TOPAK generates its table** from its specification graph, after ADR-0057 is decided.
11. **The end-to-end agent run:** a change request, a draft record with a claim, a spec change, the claims check, and
    a person's acceptance left open, each step checked apart from the agent.

---

## 5. Records this needs

Drafted on 2026.11.20 as six and combined into three the same day, to keep within the custodian's reading budget
(TOPAK's house-style proposal §4.9):

| Record | Title, short | Takes in |
|---|---|---|
| ADR-0018 | Three independent skills, each enabled on its own, kept and released here | The first draft's 0018 (scope) and 0022 (the skills move); supersedes ADR-0007 on acceptance |
| ADR-0019 | Claims are data, and a check that writes nothing reports on them | The first draft's 0019 (table) and 0020 (check) |
| ADR-0020 | CI requires the check, reruns only stale claims, names the image; `ClaimsSync.tla` first | The first draft's 0021 (CI) and 0023 (the module) |

In TOPAK: one record to take the TLA+ skill from tla-kit and retire `skills/writing-tla-specs-and-proofs` as its
source, once ADR-0018 is accepted. In gov-tla: a pin move, the skill by plugin, and later its claims table.

---

## 6. Decisions owed

| | Decision | Recommendation |
|---|---|---|
| E1 | TSV or JSON for the claims table | TSV: edited by people, diffed in review, like the row lists |
| E2 | Claim ids in record text, or only in the table | Both: the id in the record is what lets the check find a checked item with no claim |
| E3 | Whole-file record digests, or per-item | Whole-file, as TOPAK's drift test. Per-item needs a parser of records |
| E4 | `ClaimsSync.tla` first, or the script first | The module first, by tla-kit's own habit (ADR-0016 item 2) |

Settled by the custodian on 2026.11.20, and no longer owed: whether the skills are one or several, which comes first,
the word for the owner of a decision, how a skill is split, and whether the CI/CD skill depends on CI's gates (§7).

---

## 7. TOPAK's house-style proposal, and the custodian's answers

TOPAK pull request #99 merged two documents on 2026.11.20: a comparison of TOPAK's record skills with ten public ADR
skills, and a draft proposal for TOPAK's assisted-development house style, with fourteen questions for the
custodian. The proposal reaches this note's idea from TOPAK's side: records, formal modelling and CI/CD as the
components, a chain of authority from record to model to artifacts, and skills that travel and still agree.

**The custodian answered two of its questions in this session:**

- ⟨Q7⟩ *Portability.* The records, TLA+ and CI/CD skills are separate skills; the records skill is not split by act.
  The order is tla-kit's to decide. The owner of a decision is called the custodian.
- ⟨Q12⟩ *The CI/CD skill.* Each skill is enabled or disabled on its own: a repository may take only the TLA+ skill,
  or records and TLA+, or all three. tla-kit's design decides how each skill is split. Moving the skills to tla-kit
  decouples the CI/CD skill from CI's gates.

**What the proposal changed here**, beyond those answers:

1. §1 now says the first link is read and not checked (its §4.4 item 3; TOPAK's ADR-0057).
2. The table names its results file, where the first draft took the newest one (its H-5).
3. The `grade` column uses only the shared words, and `-` where nothing in TLA+ checks a claim; the first draft had
   added a word of its own, `abstracted`, which is the drift its H-4 describes.
4. The check reads everything as data (its H-9; the comparison's SK-1).
5. CI's gate states its tier, carrier (its §4.3).
6. Six records became three (its §4.9: every tier below the mechanism ends in the custodian reading something).

**What stays with TOPAK:** its other twelve questions; the identity investigation (⟨K10⟩ there), on which the CI/CD
skill's signing part waits; and the TOPAK records that take the skills from here.

---

## 8. What this does not solve

- **The first link.** Whether a module says what its record says is read by a person (§1). The claims table makes the
  link visible; it does not check it.
- **One custodian.** tla-kit, TOPAK and gov-tla have the same custodian. The chain shows that each link from the
  property onward is checked, not that anyone but its author has read it. The first repository to enable records
  and TLA+ that is not the custodian's is worth more than any step in §4.
- **Who wrote it.** tla-kit's records say most of their choices were the assistant's. The chain makes that visible
  (the **Chosen by** line), and does not change it.
- **Who merged.** No check here tells the custodian's act from an agent's under the custodian's account (§3.4).
- **Specifications, not code.** A claim is checked of a module. Whether the code does what the module says is a
  separate link (TOPAK's drift test and trace checks are one way).
- **Small constants.** `checked` means every reachable state at the constants the row states. The table carries the
  grade so that no claim reads as more.
