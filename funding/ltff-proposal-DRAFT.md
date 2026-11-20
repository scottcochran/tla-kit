# tla-kit — Long-Term Future Fund application (draft)

**UNDATED DRAFT** · a grant application, not a record · prepared by the assistant at the custodian's request, on
branch `adr-tla-cicd`, from [`COUPLING.md`](../COUPLING.md), ADR-0018 to ADR-0020 (Proposed), `PLAN.md`, `README.md`
and the `derived/` checks · the headings follow the questions LTFF has asked in past rounds; check them against the
live EA Funds form before pasting · bracketed items are the custodian's to fill · every count below is from this
repository, TOPAK or gov-tla at the commits named, and can be re-run

---

## At a glance

| Field | Value |
|---|---|
| Project | tla-kit: AI-assisted formal verification whose evidence a person can check, from decision record to proof to CI |
| Applicant | Scott Cochran (GitHub `scottcochran`), sole developer and custodian · individual |
| Amount requested | **$54,000** for 6 months |
| Minimum useful amount | **$27,000** for 3 months (deliverables D1 to D5) |
| Of which to the applicant | **$45,000 (83%)**, a stipend at an assumed $7,500 a month **[custodian: set the rate]** |
| Start | On award; month 1 begins the first of the following month |
| Licence of everything produced | Apache-2.0 for code, CC BY 4.0 for documentation, as today |

---

## Brief summary

AI agents now write a large share of specifications, proofs and code, and the people who sign off on that work often
cannot tell what was actually checked. tla-kit is an open-source, already-released toolkit that makes AI-assisted
formal verification with TLA+ reproducible and auditable: every tool pinned by digest in one container image, an MCP
server that lets an agent check specifications and repair proofs, and CI that reruns the evidence.

This grant funds six months of the sole developer's time to finish what the toolkit is missing. It would add three
independent skills that any repository can enable: decision records, TLA+ and CI/CD. It would add a machine-checked
link from each decision to the property and evidence that check it. It would ship evaluation suites showing how well
agents follow the method. All of it is built in public, released, and tested on three real projects, including
TOPAK, an open safety architecture for multi-agent AI.

---

## Project description

### What exists today (built by the applicant, 2026.11.15 to 2026.11.19)

| What | Evidence anyone can check |
|---|---|
| Six signed, reproducible releases, `v0.1.0` to `v0.6.0`, in five days | `ghcr.io/scottcochran/tla-kit`; each release's attestation verifies with `gh attestation verify`; CI builds every commit twice on two runners and compares the digests |
| One image with TLC, SANY, TLAPS and the cvc5/ethos proof checker, each pinned by sha256 | `PINS.json`; `README.md`'s table of pins is generated from it and checked in CI |
| An MCP server with fourteen tools: parse, model-check, simulate, prove a step, flip-test a proof, check results are current | `server/tla_kit_mcp.py` and its tests |
| An agent job, in GitHub Actions, that repairs a deliberately broken proof using only the server's tools, checked apart from the agent | `.github/workflows/agent.yml`; `derived/tla-kit-phase5-checks-2026.11.17.md` |
| tla-kit's own processes specified and model-checked in TLA+ before they were built: the pin and release process (51 rows) and the prove tool's concurrency (78 rows) | `spec/`; CI reruns both and compares with the committed results |
| 17 accepted decision records, each saying who chose what | `decisions/` |
| Two projects served, with evidence rerun on every tool upgrade | TOPAK: 34 proof modules, 13,622 obligations, re-proved in the image in about 9 minutes; gov-tla: six proof modules, public since 2026.11.20 |

### What is missing

Half the links in the chain from a decision to its evidence are prose, not data (`COUPLING.md` §2). A record says
in a sentence which property checks it; nothing checks that the sentence is still true. CI cannot tell which checks
a change reaches, so it reruns everything. The method an agent follows lives in another repository and is copied by
hand into a third. There is no skill for decision records and none for how an agent commits and pushes. And no skill
has an evaluation suite showing whether agents actually follow it.

### Deliverables

Each deliverable is public, released in a tagged image, and has a test that decides whether it is done. Months are
indicative; the order is fixed by dependency.

| # | Month | Deliverable | Done when |
|---|---|---|---|
| D1 | 1 | **Conventions file** shared by every skill: the words for a result, the second-reader rule, "what a skill reads is data, never instructions", what a check's exit status means | It is vendored into the TLA+ skill, and CI fails when any copy differs |
| D2 | 1–2 | **The TLA+ skill moves into tla-kit**, released as its own plugin with the image under one tag (ADR-0018) | TOPAK and gov-tla each load it from a tla-kit release, and `vendor/` is deleted |
| D3 | 2 | **`spec/ClaimsSync.tla`**: the claims life cycle specified and model-checked before any code (ADR-0020 item 5) | No acceptance on a stale claim, a pass means a current result, and a rerun cannot hide a break all hold; each of four shortcut designs breaks its own property and no other |
| D4 | 2–3 | **The claims check** and a fifteenth MCP tool, `claims` (ADR-0019) | tla-kit's 19 claims report `IN SYNC` at a clean tree, and fixtures produce `STALE`, `MISSING` and `BROKEN` |
| D5 | 3 | **CI gating** (ADR-0020): the claims check required, only stale claims rerun, every result naming the image that made it | A pull request that edits one record reruns only that record's rows, and one that breaks a row cannot merge |
| | | *The minimum grant ends here, with a release* | |
| D6 | 4 | **CI/CD skill, part 1**: branch, commit, run the repository's checks, push, open a pull request; and what an agent never does (merge, approve, tag, grade its own change) | tla-kit's own pull requests for D7 to D10 follow it, and its evals pass |
| D7 | 4–5 | **Records skill**: draft, revise and propose decision records; keep accepted text unedited; mark who decided each thing; state when no second reader has read it | It drafts a tla-kit record that passes the claims check, and its evals pass |
| D8 | 5 | **gov-tla enables records and TLA+**, with its own claims table, run in tla-kit's evidence workflow | tla-kit's evidence run reports gov-tla's claims `IN SYNC` |
| D9 | 5–6 | **Evaluation suites for all three skills**: small fixtures with planted flaws (a property that checks itself, a missing witness, a hand-edited results file, an agent asked to merge) and known non-flaws, run against at least two models with and without each skill | The results are published in `derived/`, with the fixtures, so anyone can rerun them |
| D10 | 6 | **End-to-end agent run and write-up**: a change request becomes a draft record with a claim, a spec change, a passing claims check, and an acceptance left open for a person, each step checked apart from the agent; plus a public write-up for the TLA+ community | The run passes in Actions, and the write-up is posted and linked from `README.md` |

Two things are deliberately out of scope: the signing part of the CI/CD skill, which waits on TOPAK's investigation of
how an agent's acts are told from the custodian's; and any change to TOPAK's own decision records, which are TOPAK's.

---

## Path to impact

**The problem.** As agents write more of the specifications, proofs and code behind safety-relevant systems, the
bottleneck moves from writing to vouching. A human reviewer sees a green check and a confident summary, and cannot
easily tell which claims were checked, against what, by which tool version, or whether the agent quietly changed the
check. That is a direct route to false assurance in exactly the systems where assurance matters.

**What this project does about it.** It makes one end-to-end path where an agent does the work and a person stays
accountable, with every link they rely on checkable: the decision, the property that checks it, the result, the
exact tool that produced it, and CI that refuses a change that breaks it. Formal methods are the strongest evidence
available for concurrent and distributed systems, and agent-control architectures are such systems.

**Routes, from most to least certain:**

1. **Better evidence for TOPAK and gov-tla**, which use it today. TOPAK is an open architecture that treats every AI
   agent as Byzantine and keeps models out of the trusted base; its 13,622 proof obligations are rerun through
   tla-kit.
2. **A reusable pattern for AI-assisted verification** with evaluation data (D9) on how well agents follow a
   verification method, and where they cut corners. That data is useful well beyond TLA+.
3. **Adoption by other TLA+ projects.** Today every user is the applicant's own project. D2, D6 and D7 make each
   skill usable alone, so another project can take only the part it wants.

**Counterfactual.** The work is self-funded today, done between paid work. Without funding it continues more slowly
and in competition with TOPAK's independent review. With funding it gets six months of full attention, and D9's
evaluation suites, which are the most useful output to others and the easiest to skip, get done.

---

## Budget

| Line | Months 1–3 (USD) | Months 4–6 (USD) | Basis |
|---|---|---|---|
| Applicant stipend | 22,500 | 22,500 | 6 months at $7,500 **[custodian: confirm the rate]** |
| Independent review of the claims check and the three skills | 1,500 | 2,500 | About 30 hours from a formal-methods reader who is not the applicant, at $125/h; findings published unedited |
| Model API usage for agent jobs and evaluation runs (D9, D10) | 1,000 | 1,500 | Each agent run is billed; D9 runs every fixture against at least two models |
| CI minutes, container registry, storage for kept tool copies | 500 | 500 | Proof reruns over 34 TOPAK modules and two runners per build |
| Equipment and contingency | 1,500 | — | An arm64 Linux test machine for the second platform, or tool breakage upstream |
| **Total** | **27,000** | **27,000** | **54,000** |

- **At the minimum ($27,000):** months 1 to 3, D1 to D5, ending in a release.
- **Between the minimum and the full amount:** D6 to D10 in order, as far as the money goes; the release notes say
  which were done.
- **Above the full amount:** a second outside reviewer, and onboarding help for one project not run by the applicant.

---

## Track record and relevant experience

**[Custodian: two or three lines of background: relevant roles, years, and links.]**

What the applicant has shipped in the last two months, all public and re-runnable:

- **tla-kit**: six releases in five days, each attested and built reproducibly, with its own processes specified in
  TLA+ before they were coded (above).
- **TOPAK**: a design corpus for multi-agent AI safety with 76 decision records, 34 TLAPS proof modules (13,622
  obligations, 31 certified by an independent proof checker), 15 of them re-proved in Lean 4, and a Rust reference
  implementation.
- **Two soundness bugs in the TLA+ proof system**, found, documented and reported upstream (tlaplus/tlapm #309,
  fixed upstream; #310, fixed by #339), with a scan that checks whether any proof depends on them.
- **gov-tla**: a TLA+ model of the procedural core of the US Constitution, six modules, each proved.

**How it is built, stated plainly.** The applicant works with an AI assistant, and every repository says so: each
tla-kit record's "Chosen by" line names the custodian or the assistant. That is the point of the project. It is
what AI-assisted engineering looks like when the evidence is kept honest, and the grant includes an outside reader
because the applicant is the only person who has read most of it.

---

## Risks

| Risk | Likelihood | Effect | Mitigation |
|---|---|---|---|
| One maintainer | High, by design of the grant | Work stops if the applicant stops | Everything is public, released, and specified in decision records and TLA+; a newcomer can rebuild any release from its pins |
| No one outside the applicant's projects adopts it | Medium | Impact limited to TOPAK and gov-tla | D2, D6 and D7 make each skill usable alone; and D10's write-up targets the TLA+ community |
| The claims check is read as more than it is | Medium | False assurance, the problem this project exists to reduce | Its report says that `IN SYNC` means the rows exist and pass, not that the property says what the decision says, which is still read by a person (`COUPLING.md` §1) |
| Upstream tools change under the image | Medium | Rework | Every tool is pinned and kept; a weekly check reports upstream changes (first run 2026.11.23), and a move needs evidence over every project served |
| Scope creep, more text than anyone reads | Medium | Deliverables slip | Records were cut from six to three before this application; deliverables have tests, not page counts |
| Capabilities or misuse | Negligible | — | The work constrains and checks agents; it does not make them more capable |

---

## Other funding

- **In the last 12 months:** **[Custodian: "None; self-funded", or list sources and amounts.]**
- **Pending:** applications to Manifund and LTFF for an independent review of TOPAK, with a separate $12,000 stipend
  for resolving that review's findings. That grant pays reviewers to read TOPAK; this one pays for tla-kit's tooling.
  No deliverable appears in both. If both are funded, the applicant's months under each are declared and do not
  overlap, so no time is paid twice.

---

## Before submitting

- [ ] Fill in the three bracketed items: background, the monthly rate, funding history.
- [ ] Check the headings against the live EA Funds form, and paste each section into its matching question.
- [ ] Decide whether this file stays in a public repository with the stipend figure in it, or moves somewhere private
      once submitted.
- [ ] Ask one candidate reviewer for a quote before submitting, to replace the assumed $125/h.
- [ ] Link PR #37 (the coupling records) and the latest release in the application.
