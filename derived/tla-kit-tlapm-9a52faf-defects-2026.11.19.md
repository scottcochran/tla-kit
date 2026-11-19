# tla-kit: TOPAK's defect run under `tlapm` 9a52faf, compared with ff40755, 2026.11.19

> **Provenance note.** Written 2026.11.19 by the assistant, at the custodian's direction to commit the defect run
> to `derived/`. It was written on branch `ccr-42e474a8-7s13f7`, after `c92220b`. It records the defect run that
> ADR-0005 item 4 asks of the prover move in pull request #34, from `ff40755` to `9a52faf`, and compares it with
> the same run under `ff40755`.
>
> CI ran the defect run on pull request #34 (run 44602423185). Its output went only to the run's step summary,
> which could not be read from here. So the run was repeated in an image built here from `c92220b`, as CI builds
> it, from the kept copies:
> - `tlapm` `9a52faf` (`faa92f26…2cc0`), from release `tlapm-9a52faf`;
> - the Ubuntu 26.04 base of pull request #36, which `9a52faf` needs for glibc 2.42.
>
> The image was not published. TOPAK is at `6a26310`, the commit CI's run used. The annex beside it,
> [`tla-kit-tlapm-9a52faf-defects-annex-2026.11.19/`](tla-kit-tlapm-9a52faf-defects-annex-2026.11.19/), holds the
> commands and every output. It decides nothing.

## 1. What was compared

- **This run:** TOPAK's `spec/defects/defects-run.sh`, as the evidence workflow runs it (`topak-defects`):
  - TOPAK mounted read-only;
  - `TLAPM_UNPINNED=1`;
  - under emulation on Apple Silicon.
- **The baseline:** the same run in `v0.4.0`, under `ff40755`, at TOPAK `0dfdfcd`
  ([`tla-kit-phase6-checks-annex-2026.11.18/defects.txt`](tla-kit-phase6-checks-annex-2026.11.18/defects.txt),
  that record's F-3).
- **What is the same in both runs:** every module's sha256, `proof-cert.sh`, the TLC jar, the JRE (Temurin
  25.0.5) and the other backends.
- **What differs:**
  - the prover;
  - `defects-run.sh`, which TOPAK changed in `d92de7d` (`76a60927…` → `52fc7858…`);
  - the base, Ubuntu 26.04 here and 24.04 there.

## 2. Findings

**F-1. Under `tlapm` and under the certified run, `9a52faf` gives what `ff40755` gave, line for line.** Section 1
and section 2 of the two runs are the same text: each lemma's outcome, the backend that closed or last tried it, and
its obligation counts. The run therefore differs from TOPAK's §8 record, made under `7824dab`, where `ff40755`'s
did:

| Section | As §8 says | Differs from §8 |
|---|---|---|
| 1, under `tlapm` | 18 | 13 |
| 2, under the certified run | 3 | 9 |
| 3, under TLC | 8 | 0 |

- **What §8 records as proved fails.** Each of section 1's 13 differing lines is a lemma that §8 records as proved
  under `7824dab`:
  - 12 by SMT: `Bad`, `BadEventually`, `BadLeadsTo`, `BadCdot`, `AllFromOne`, `InvBigAlways`, `BigBad`, `BigI`,
    `SmallE`, `FalseBySMT`, `TwoNew` and `Capture`;
  - 1 by LS4: `FalseByPTL`.

  Here each fails, last tried by Isabelle, or by LS4 for `FalseByPTL`. The false statements are among them, as
  `PLAN.md` recorded for `ff40755`.
- **The required failures still fail.** `SuperBad`, `OutsideBad` and `BigPTL` fail, as §10's rule requires.
- **The two unsound cases are unchanged.** `9a52faf` neither reopens nor closes either of them. Explaining the
  differences from §8 is TOPAK's (its ADR-0077 §5), as it was for `ff40755`.

**F-2. Under TLC, every statement is violated in both runs. Two state counts differ, as between any two runs.**
All 8 statements of `BinderDefectTLC` are violated, as §8 says. The three invariants stop at 46 states, and
`AllTools`, `SmallE` and `AllHas` at 25,728, in every run. `BadEventually` and `BadLeadsTo` stop at a different
count in each:

| Run | `BadEventually` | `BadLeadsTo` |
|---|---|---|
| TOPAK's record, `7824dab` | 25,728 | 12,390 |
| The candidate of pull request #27, `ff40755` | 21,038 | 7,978 |
| `v0.4.0`, `ff40755` | 20,473 | 7,422 |
| Here, `9a52faf` | 20,929 | 8,456 |

The two `ff40755` runs differ from each other as much as either differs from this one. The point at which TLC's
liveness search stops varies with the machine. The Phase 6 record found the same (its F-3), as did
`spec/PinLifecycle.tla` (`spec/README.md`). The prover takes no part in this section, and the run compares the
verdict only.

**F-3. With the proof run, the move changes no outcome TOPAK records.** CI's full proof run on pull request #34
proved 13,622 obligations in the modules that match their baseline, under `9a52faf`. That is TOPAK's committed
count, and `ff40755`'s (pull request #36's run, 44598664763). This run adds that the defect lemmas fail or prove as
they did under `ff40755`.

## 3. Not done

- **CI's own defect run was not read.** Run 44602423185 passed, as `topak-defects` always does: a person compares
  its output. Its output is only in the run's step summary, which `gh` does not return, so this run stands in for
  it. The two are the same build of the same commit, from the same kept copies, on different machines.
- **The 13 upstream commits between `ff40755` and `9a52faf` were not read for the defect cases.** The comparison is
  of outcomes only.

## 4. The annex

| File | What it is |
|---|---|
| `run.sh` | The commands: the kept copies fetched, the image built from `c92220b` as CI builds it, and the run |
| `info.txt` | `tla-kit-info` in that image |
| `defects.txt` | `defects-run.sh` in that image, at TOPAK `6a26310` (F-1, F-2) |
| `defects-ff40755-vs-9a52faf.diff` | Its difference from `v0.4.0`'s run: the runner line and the two state counts of F-2 |
