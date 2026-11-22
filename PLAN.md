# Development plan

Written 2026.11.15, after the spike the README records, updated the same day for ADR-0013 to ADR-0016, and kept
up to date since: Phases 1 and 3 are done (2026.11.16), Phases 4 and 5 (2026.11.17), and Phase 6's cvc5 and ethos
(2026.11.18). It is a plan, not a record: nothing below is built unless the README says so.

## Goal

One image of the TLA+ tool family, referenced by digest, that a project uses the same way on a laptop and in
CI, with two ways in:

- **The command line**, for evidence: a project's own run scripts and results generators, unchanged.
- **An MCP server**, for working: the same binaries offered to an agent, to pair with the
  `writing-tla-specs-and-proofs` skill.

TOPAK is the first project it has to serve and gov-tla the second. Nothing in the image is specific to either.

## Rules the design keeps

1. **Every tool is held to a digest, and every result names it.** The image's digest is what a project cites.
2. **The server has no way of its own to write a results file.** It may run a project's generator or one of
   the skill's; anything else it returns is working output and is labelled so.
3. **The skill is the source of the method.** The server calls the skill's scripts; it does not reimplement
   them.
4. **One prover build per image.** A project that moves to a new image moves its pin, knowingly.
5. **Borrow before building.** The proof tools follow the design of
   [marco6/tlapm-mcp](https://github.com/marco6/tlapm-mcp) (MIT) where it fits.
6. **Every pin moves by one rule.** One pull request per pin, with evidence that fits what the pin can change
   (ADR-0013).
7. **A released digest is never deleted.** A citation in a project's history has to resolve, whatever the
   project pins today (ADR-0014 item 5).

## What the spike settled

- The image builds, at 806 MB, and the skill's setup check passes in it for model checking and proofs.
- TOPAK's 34 proof modules prove in it with the committed obligation counts (13,622), in about 9 minutes on
  4 CPUs; its 14 `pr`-tier TLC modules regenerate with no differences (490 rows), in about 56 minutes run one
  after another.
- The current `tlapm` needs glibc 2.38, so the base is Ubuntu 24.04.
- The three projects are on three prover builds: TOPAK on 7824dab (arm64-darwin), gov-tla on c8ddc44
  (x86_64-linux), this image on ff40755 (x86_64-linux). Upstream serves only the last.
- TOPAK's `spec/defects/defects-run.sh`, run in the image, does not reproduce its record. Of the lemmas the
  record expects to prove, 13 fail under ff40755 (12 it expects SMT to prove, 1 LS4), the false statements
  among them; 5 others it expects SMT to prove still prove; TLC still finds all 8 statements false. This
  fits upstream having closed the prover's two unsound cases since 7824dab, but the upstream issues were not
  checked. The certified step could not run (no cvc5 or ethos in the image).

## Decisions owed

Drafted as records in [decisions/](decisions/): D2 is ADR-0007, D3 ADR-0010, D4 ADR-0011, D5 ADR-0012 and D6
ADR-0009. D1 is TOPAK's and has no record here. D7 is a check, and its outcome goes into ADR-0005 and ADR-0011.

| | Decision | Recommendation | Blocks |
|---|---|---|---|
| D1 | Does TOPAK move `tools/TLAPS-PIN` to the image's Linux prover? TOPAK's decision, made there. gov-tla faces the same question in its own repository. | Yes: it is the only route to proofs rerun in CI, and the newer build rejects the two unsound cases. It means regenerating 34 proof results files, and the records that cite the two cases need a look. | Phase 2 as evidence |
| D2 | Where do the skill's scripts live for the server to call? | Chosen 2026.11.15: vendor them here at a named TOPAK commit, checked by digest in CI. The skill stays usable without Docker. ADR-0007 records it, accepted 2026.11.15. | Nothing now. The vendoring is Phase 1a work, because Phase 1b's results come from the skill's generator (ADR-0015 items 1 and 8). |
| D3 | Registry and visibility for the image. | Chosen 2026.11.16: `ghcr.io/scottcochran/tla-kit`, public, published from a tag. ADR-0010 records it, accepted 2026.11.16. | Nothing now |
| D4 | Licence for this repository. | Chosen 2026.11.15: Apache-2.0 for code and CC BY 4.0 for documentation, as in TOPAK. `LICENSE`, `LICENSE-DOCS` and `NOTICE` are added. ADR-0011 records it, accepted 2026.11.15. | Nothing now |
| D5 | One image, or a small one with variants for the large optional tools? | Chosen 2026.11.17: one base image; variants by tag for Apalache and TLATeX; cvc5 and ethos in the base. ADR-0012 records it, with its item 8, accepted 2026.11.17. | Nothing now |
| D6 | Take `marco6/tlapm-mcp` as a design to follow, a dependency, or neither? (session record, §9 item 6) | Chosen 2026.11.16: a design to follow, with named changes, and no dependency on it. ADR-0009 records it, accepted 2026.11.16. | Nothing now |
| D7 | May tla-kit redistribute what the TLAPS tarball bundles (Isabelle, Poly/ML, GMP, `libsha1`, Z3, Zenon, LS4)? | Settled 2026.11.15, as `derived/tla-kit-licence-check-2026.11.15.md` recommends: yes, on three conditions. (1) Every redistribution carries the notices: the image does, in `licenses/`. (2) The release offers the source of Poly/ML, GMP and `libsha1` beside the kept tarball. (3) The bundled GMP release and `libsha1`'s licence are settled before the first public release. | Nothing now. Condition 3 was settled on 2026.11.16 (`derived/tla-kit-copyleft-sources-2026.11.16.md`): GMP 6.1.2, and `libsha1` under GPL-3.0-or-later. Condition 2's release, `tlapm-ff40755`, was made by `tools/keep-tlapm.sh` on 2026.11.15, before anything was published |

### Records to accept, and when

This is the order in which the phases need the records. The Phase 1a and 1b rows were accepted on 2026.11.15,
and so were ADR-0005, 0013 and 0014. ADR-0010, ADR-0006, ADR-0008, ADR-0009 and ADR-0016 were accepted on
2026.11.16, and ADR-0012 and ADR-0017 on 2026.11.17. One record is Proposed: ADR-0024, drafted 2026.11.22, which
no phase waits on (see *Outside the phases*, after Phase 6).

| Before | Accept | Why then |
|---|---|---|
| Phase 1a | ADR-0001, 0002, 0003, 0004, 0011; ADR-0007 (D2) | The first five are mostly built. ADR-0007 is pulled forward from Phase 3 (D2). All six accepted 2026.11.15. |
| Phase 1b | ADR-0015 | Its scope, so that `spec/PinLifecycle.tla` can be written. Accepted 2026.11.15. |
| Phase 1c | ADR-0005, 0013, 0014; ADR-0010 (D3) | ADR-0015 item 7: the first three are accepted only when every row of Phase 1b has its expected outcome, and they will probably change before then. ADR-0005, 0013 and 0014 accepted 2026.11.15, and ADR-0010 2026.11.16. ADR-0010 item 5 now says "always", as ADR-0014 item 5 does, where it first said "while any project's pin names them". |
| Phase 3 | ADR-0006, 0008 | Both accepted 2026.11.16. ADR-0008 item 1 was changed first to the standard library, at the custodian's choice. |
| Phase 4 | ADR-0009 (D6); then ADR-0016 | ADR-0009 accepted 2026.11.16. Its item 5's comparison was made the same day, and the custodian chose `tlapm` per request; ADR-0016 was brought into line with it and accepted the same day. |
| Phase 6 | ADR-0012 (D5); then ADR-0017 | ADR-0012 accepted 2026.11.17, with item 8, which places cvc5 and ethos in the base. ADR-0017, which keeps their zips, accepted 2026.11.17, after its rows of `spec/PinLifecycle.tla`. Both built, and released in `v0.4.0`, 2026.11.18. |

## Phases

Each phase ends with a check that can fail. Later phases do not start on an earlier one's assumption.

### Phase 1: an image that can be cited

Phase 1 has three parts. The image comes first, then the model of the pin and release process, then the workflows
and the first release. ADR-0015 puts the model before the workflows, so that the records it covers are checked
before anything is built on them.

#### 1a: the image

- Build with plain `docker build .` on a stock machine. The spike built on a derived base through a mirror, so
  the default path is untested.
- Pin the base image by digest. Look at Ubuntu's snapshot archive to fix the `apt` packages by date.
- Run as a non-root user, so files written to a mounted project are not owned by root. Check mounts owned by
  another uid, on Linux and on Docker Desktop.
- A self-test in the image: a fixture module and proof, a row list, a flip test. It exercises `TLA_JAR` and
  `TLAPM` (ADR-0004). `tla-kit-info` as JSON.
- Vendor the skill's scripts at a named TOPAK commit, with a pin file holding each file's sha256 (D2).
- Check the licences of what the TLAPS tarball bundles (D7).

**Done when** the default build passes on a stock machine, the self-test passes in it, and D7's result is
written down.

#### 1b: the pin and release process, in TLA+

- Write `spec/PinLifecycle.tla` as ADR-0015 describes: a row for the records as written, expected to violate the
  properties behind its four gaps, and one row per fix, expected to pass.
- Check it with TLC in a 1a image, and make its results with the vendored generator. That image's digest is not
  published, so the results are working output, not evidence (ADR-0002 items 5 and 7). They are regenerated in
  the first published image in 1c.
- Make each fix in the record it belongs to, by a History row: probably ADR-0005 item 2 (when the kept copy is
  uploaded), ADR-0013 (what `Durable` names, and log entries that name their value) and ADR-0014 item 1 (a pull
  request tested against the `main` it merges into). Then accept ADR-0005, 0013 and 0014.
- ADR-0015 says the module is checked "in the image", before Phase 1c's workflows. Since no published image exists
  before 1c, its item 1 says which image that is, and that the results are working output until then.

**Done when** every row has its expected outcome and ADR-0005, 0013 and 0014 are accepted.

#### 1c: workflows and the first release

- Pull request CI, as ADR-0014 item 1 says: the default build and every variant, the self-test, the vendored
  scripts' digest check, and the evidence for a pin move. Pushes nothing. `main` protected, its history never
  rewritten.
- The `PinLifecycle` rows regenerated on every pull request that changes `spec/` or `decisions/`, and compared
  with the committed file (ADR-0015 item 8).
- The inventory `PINS.json` and its four checks: it agrees with the `Dockerfile`, it is in the image at
  `/opt/tla-kit/PINS.json` and checked by the self-test, the README's table is generated from it, and the release
  copies it (ADR-0013 item 7).
- The pinned TLAPS tarball kept as a release asset here, so the image can be rebuilt after upstream has moved the
  tag. Build from the copy; compare with upstream as a separate, reporting check (the analogue of TOPAK's
  `sources.yml`). The release holds `licenses/` and the source of Poly/ML, GMP and `libsha1` beside it (D7).
- Before the first publish, settle which GMP release and which `libsha1` licence the tarball carries, from
  Isabelle2025's `polyml-5.9.1` and `sha1` components (D7 condition 3).
- The weekly check: a new jar, a change to what the `tlapm` tag serves, a new digest behind the base's tag, and
  a vulnerability scan with a pinned scanner (Trivy is the proposal). It reports in one issue and moves nothing
  (ADR-0013 items 4 and 5).
- `CONSUMERS.md`, naming TOPAK and gov-tla and the file in each that will hold its tla-kit pin (ADR-0014 item 6).
- Releases: `vMAJOR.MINOR.PATCH` tags, protected and never moved; `0.x` until Phase 2 is done. Only the
  custodian pushes them.
- A release workflow that builds from the tag, runs the self-test, publishes, and records in the release what
  ADR-0014 item 3 lists. Build-provenance and SBOM attestations. Least-privilege permissions, every Action pinned
  by commit sha, Dependabot for the Actions only.
- `SOURCE_DATE_EPOCH` set to the commit's time, and the OCI labels for created, revision and source, with no
  version label (ADR-0014 item 8). Build one commit twice, on two runners, and compare the digests. If they
  differ, record why. The attestation is then the only check of a digest.
- Repeat the spike's TOPAK checks from the published image.

**Done when** a published digest reproduces the README's spike table, `gh attestation verify` passes on it, and
the `PinLifecycle` results regenerated in it match the committed file.

**Done 2026.11.16.** Release `v0.1.0` is
`ghcr.io/scottcochran/tla-kit@sha256:454328cd7464efcf8a27a063c51c10086e09571c462c73d085b4a249e44950c6`, built from
`bfeecc8`. All three conditions hold for it
([`derived/tla-kit-phase1c-checks-2026.11.16.md`](derived/tla-kit-phase1c-checks-2026.11.16.md)):
1. **The spike table:** it reproduces the README's spike table against TOPAK at `0ad9f88`. The defect run's two
   clock-dependent state counts differ, and its verdicts do not.
2. **The attestations:** `gh attestation verify` passes for the provenance and the SBOM.
3. **The `PinLifecycle` results:** regenerated in it, they reproduce the committed file byte for byte.

Along the way:
- **The model:** CI found that the skill's generator printed a state count that depends on the machine. It was
  fixed in TOPAK first and then vendored (ADR-0007), and gov-tla's own generator was fixed too.
- **The repository:** it was made public with the `publishing-private-repos` skill. Its five rulesets are active,
  including the required checks.
- **Still open:** gov-tla has no evidence run here, because tla-kit has no token to read it. The weekly check
  has not run yet; it first runs on its Monday schedule.

### Phase 2: the image in the projects' CI

Changes in TOPAK and gov-tla, each made in its own repository and asked for there.

- TOPAK: run the `tlc` job in the image; add a `proofs` job that reruns every proof module; fix the pin key
  the skill's scripts read (`binary_sha256`, where `tools/TLAPS-PIN` has `binary_sha256_16`).
- gov-tla: the same two jobs. Its pinned prover (c8ddc44) is no longer served, so it faces D1 as well.
- Before D1 the proofs job reports counts only. After it, the results files are regenerated in the image.
- Each project's tla-kit pin is recorded in `CONSUMERS.md`'s log (ADR-0014 item 6).

**Done when** a pull request in TOPAK shows its proofs rerun in CI. The next release can then be `1.0`.

### Phase 3: the MCP server, model checking

A Python server over stdio, started as `tla-kit mcp`, so it can import the skill's `tla_common.py`, vendored in
Phase 1a. Paths are confined to the mounted project. It speaks MCP with the standard library only, so the image
gains no package for it (ADR-0008 item 1).

| Tool | Does | Writes a results file |
|---|---|---|
| `info` | Every tool in the image with its digest | no |
| `parse` | SANY, errors with locations | no |
| `symbols` | A module's definitions, from SANY's XML exporter | no |
| `evaluate` | A constant expression, through a scratch module | no |
| `tlc_run` | One row, as the skill's `tlc_run.py`; the counterexample as structured states | no |
| `simulate` | Random behaviours to a depth, labelled as sampling | no |
| `coverage` | Per-action counts, to find actions that never fire at the row list's constants | no |
| `state_graph` | The reachable graph of a small model as JSON | no |
| `tlc_rows` | The skill's generator on a row list | yes, the generator's |

**Done when** each tool returns the same verdict as the script it wraps on TOPAK's `Alone` and `Coupling`, and
an MCP client test in CI drives every tool against the fixture.

**Done 2026.11.16**, by pull request #11, merged as `6624534`. In CI run 43921629481, in the image built from the
pull request:
1. **The comparison:** `server/compare_topak.py` compared each of the nine tools with the command it stands for, on
   TOPAK at `5ade81e`. All 84 comparisons were the same: every row of `Alone` (47) and `Coupling` (15) through
   `tlc_run` and `tlc_run.py`, and the results file of each, byte for byte, from `tlc_rows` and `tlc_rows.py`.
   Neither module has a row list in the skill's format, so the script writes one from TOPAK's own files.
2. **The client test:** `server/test_mcp.py` drove every tool against the fixture, with the server started as
   ADR-0008 item 2 says. It also checked that nothing but `tlc_rows` writes into the project (ADR-0006) and that a
   path outside it is refused, links included.

Along the way:
- **The SDK:** the server uses the standard library only (ADR-0008 item 1, the custodian's choice), so the image
  gained no package.
- **The tools:** what each one is compared with is named in ADR-0008 item 5, since only `tlc_run` and `tlc_rows`
  wrap a script.
- **Released:** `v0.1.0` has no server. `v0.2.0`, a MINOR (ADR-0014 item 2) that moves no pin, was published on
  2026.11.16 from `2bea23e` as `sha256:5554015f…1e5d`, the digest CI's two runners reproduced, with both
  attestations verified.

### Phase 4: the MCP server, proofs

In this order: the comparison, the tests of `tlapm`, the module, then the tools.

- Compare driving `tlapm` per request with driving `tlapm_lsp`, which already resolves a cursor position to its
  obligations (ADR-0009 item 5). The choice decides which processes exist. **Done 2026.11.16**
  (`derived/tla-kit-prove-comparison-2026.11.16.md`): the custodian chose `tlapm` per request. It also found that
  Phase 3's `parse` and `symbols` did not give SANY the prover's library, so they failed on a proof module. They
  now do, from beside the prover `TLAPM` names, and the client test parses the fixture's proof module.
- Test three assumptions about `tlapm` in the image: whether two processes can share a cache directory, whether
  every backend stays in `tlapm`'s process group, and what a kill leaves in the cache (ADR-0016 item 6). **Done
  2026.11.16** (`derived/tla-kit-tlapm-assumptions-2026.11.16.md`): backends stay in the group; a kill of `tlapm`
  alone leaves `z3` running; a kill empties the module's cache without making the next run wrong; one writer per
  module directory stands; and a server at PID 1 has to reap, or the client command needs `--init`.
- Write `spec/ProveRequests.tla` for the chosen option, before the tool's code: a row for a naive design, one for
  the chosen design, and one with a backend that leaves the process group (ADR-0016). **Done 2026.11.16**: 78
  rows, all as expected, reproduced in `v0.2.0`, and regenerated by CI with the PinLifecycle rows (`spec/README.md`).
- `proof_check`: parse and count obligations without backends (`tlapm --summary`).
- `prove`: one step, a line range, or a theorem by name, resolved to lines by the server. It reads `tlapm`'s
  Toolbox protocol, not log text, and returns only the unresolved obligations, each with its text, the backends
  tried and the reason. Success needs exit 0, no error line and a non-zero obligation count.
- Warnings on success when a later backend closed what an earlier one failed, naming the `BY` tactic.
- A cache directory the server owns, never beside the module; the whole process group killed on cancel or
  timeout; threads, timeout stretch and Isabelle checking of Zenon's proofs as options.
- `proof_results`, `flip_test` and `proof_sync`: the skill's scripts, as tools.
- For each invariant of `ProveRequests` that a test can exercise, a test that tries to break it: two concurrent
  `prove` calls on one module, a cancel during a run, a timeout while backends run, a cancel after the response
  (ADR-0016 item 7).

**Done when** an agent using only these tools repairs a deliberately broken step in the fixture,
`proof_results` through the server writes the file the script writes, every `ProveRequests` row has its expected
outcome, and the tests of ADR-0016 item 7 pass.

**Done 2026.11.17**, by pull requests #21 and #22, merged as `d13b0dd` and `4aee1f5`, and released in `v0.3.0`
(`derived/tla-kit-phase4-checks-2026.11.17.md`):
1. **The agent:** `claude-opus-5-5`, with the server's 14 tools and `Read` and `Edit` only, at the custodian's
   choice, against the published digest, repaired the fixture's broken `NextBounded` step without being told which
   step it was. It took three `prove` calls and two edits, led by the failed obligation's text, and its module is
   the fixture byte for byte.
2. **`proof_results`:** in `server/test_prove.py`, the script run directly reproduced the server's file byte for
   byte, in CI for pull request #22 and for `main` at `4aee1f5`.
3. **The rows:** all 78 `ProveRequests` rows as expected, and their results file reproduced byte for byte in
   `v0.3.0`, as in `v0.2.0`.
4. **The tests:** ADR-0016 item 7's tests in `server/test_prove.py` passed in CI for both pull requests and for
   `main` at `4aee1f5`.

Along the way:
- **The design:** `tlapm` per request, not `tlapm_lsp` (ADR-0009 item 5, the custodian's choice), with
  `spec/ProveRequests.tla` written before the code. The server reaps every child, at the custodian's choice, since
  under `docker run` it is PID 1.
- **The server:** requests run concurrently, and a cancelled request gets no response (MCP 2025-06-18). End of input
  answers what is in flight, and `SIGTERM` cancels it. `parse` and `symbols` now read proof modules.
- **A test's fault, not the server's:** pull request #21's first CI run stalled in "two modules". A thread dump
  showed no worker and no `tlapm` alive: the test had dropped a response that came out of order. The client now
  keeps every response by id, and dumps processes and threads on a stall.
- **Released:** `v0.3.0`, a MINOR (ADR-0014 item 2) that moves no pin, was published on 2026.11.17 from `4aee1f5`
  as `sha256:948e6d1f…257f`, the digest CI's two runners reproduced, with both attestations verified.

### Phase 5: pairing with the skill

- The skill's plugin declares the server, by image digest. The skill says which tool answers which step of
  its workflow, and what to do when Docker is absent.
- An example workflow for an agent job in GitHub Actions (`--mcp-config`, each tool in `--allowedTools`).

**Done when** one configuration serves a local session and an Actions job against the same project.

**Done 2026.11.17**, by TOPAK pull request #88, merged as `2db08ff`, and pull request #24, merged as `e80350f`
(`derived/tla-kit-phase5-checks-2026.11.17.md`):
1. **The configuration:** the `writing-tla-specs-and-proofs` plugin at `2db08ff`. Its `.mcp.json` declares the
   server by `v0.3.0`'s digest, and its `SKILL.md` says which tool answers which step and what to do without Docker.
2. **The job:** `examples/agent-repair/` makes the fixture's project with one proof step broken, runs an agent with
   the plugin and only `Read`, `Edit` and each of the fourteen tools allowed, and checks the repair apart from the
   agent. `.github/workflows/agent.yml` runs the same scripts, and is the example a project copies.
3. **The runs:** locally and in Actions (run 44080090637), the server connected, the agent repaired the step, and
   every check passed. Two earlier runs in Actions repaired it too, and failed on faults in the check that their own
   commits fixed.

Along the way:
- **ADR-0008's two recollections hold:** a plugin's `.mcp.json` declares the server, and a `docker run` command
  serves as one, on macOS and on GitHub's runner.
- **The project is the repository's root:** `CLAUDE_PROJECT_DIR` is the session's starting directory, so the
  declaration runs `sh -c` and asks git.
- **The confinement is the allowlist:** `--strict-mcp-config` would drop the plugin's server, so an agent is
  confined by `--allowedTools` and `--permission-mode dontAsk`, with the tools named
  `mcp__plugin_writing-tla-specs-and-proofs_tla-kit__<tool>`.
- **What a check can rely on:** a session's first message can come before the server connects, and one agent of
  four wrote a structured proof where the others extended a `BY`. So the check looks at the calls the server
  answered, and at what lies outside the proofs.
- **Each release reaches the plugin by a TOPAK pull request** that moves the digest in `.mcp.json`.

### Phase 6: more of the family

Each is optional, pinned like the rest, and added only with a check that uses it.

**cvc5 and ethos come first,** so that TOPAK's certified runs (`spec/proof-cert.sh`) and the rest of
`defects-run.sh` work. TOPAK's ADR-0077 waits on them: the custodian chose there (Q2) to move TOPAK's prover pin
only after a certified rerun in the image. In this order:

- **Place them.** ADR-0012 item 8, added 2026.11.17, puts them in the base: `cvc5` 1.4.0, `ethos` 0.2.4 at
  `8dc85c4`, and cvc5 1.4.0's CPC signature, all from upstream's releases and source by digest. Both binaries ran
  in `v0.3.0`, and `ethos` accepted a proof `cvc5` gave and refused a changed one. **Done 2026.11.17:** the
  custodian accepted ADR-0012 (D5) with item 8, and ADR-0013 item 1's table gained the three pins by a History row.
- **Check the licences.** Both link LGPL-3.0 libraries statically (GMP, MPFR, LibPoly). A record like
  `derived/tla-kit-licence-check-2026.11.15.md` says what redistribution needs, and whether tla-kit keeps copies
  of the archives and of the libraries' source (ADR-0005 item 2 does this for the prover). **Written 2026.11.17**
  (`derived/tla-kit-licence-check-cvc5-ethos-2026.11.17.md`), for the custodian to decide on. It recommends
  upstream's builds on D7's three conditions: the notices, a kept release with the copyleft parts' source, and
  two facts settled from the bytes, which glibc and `ncurses` patch releases are linked in. It also recommends
  keeping the two zips, which needs a new record (ADR-0013 item 8). **The custodian chose option A and to keep
  the zips, 2026.11.17.** Condition 3 is met the same day (`derived/tla-kit-static-libraries-2026.11.17.md`): both
  binaries contain glibc `2.35-0ubuntu3.14`, and `cvc5` the `libtinfo.a` that `ncurses` `6.3-2ubuntu0.2` and `0.3`
  share, which owes no source. ADR-0017 keeps the zips with the copyleft parts' source in one release. At the
  custodian's choice, `spec/PinLifecycle.tla` models them as a fourth pin, `smt`, and ADR-0017 was accepted on
  2026.11.17 once its 51 rows were as expected.
- **Keep them.** `tools/keep-cvc5.sh` assembles the release `cvc5-1.4.0`, and the custodian creates it with
  `--create`, before the pull request that pins them. It holds the two zips, cvc5's and ethos's source, the
  copyleft parts' source at the releases the bytes show, and `licenses/`, which gains the notices the zips leave out
  (`licenses/THIRD-PARTY.md`, "cvc5 and ethos"). Every asset is checked by sha256, and the CPC signature in cvc5's
  source by the tree digest TOPAK's results print, `633f74115700ad32`. **Script written 2026.11.17**: it assembles
  17 assets, 78 MB, with every digest as recorded. The GNU and Ubuntu signatures are kept and were not checked: no
  `gpg` where it ran.
- **Pin and install them**, in one pull request:
  - the `Dockerfile` installs them by digest;
  - `PINS.json` gains them as checkers, and ADR-0013 item 1's table gains them by a History row;
  - `licenses/` gains their notices;
  - the self-test gains ADR-0012 item 8's check.

  The image sets `CVC5` and `ETHOS`, which TOPAK's `proof-cert.sh` already reads (ADR-0004, by a History row).
  **Kept 2026.11.17:** the custodian created `cvc5-1.4.0` from `main` at `6f73402`. Its `SHA256SUMS` verifies,
  and its `licenses.tar.gz` holds `main`'s notices. **In pull request #27:** the `Dockerfile` installs the three
  from the kept copies, CI fetches them as it does the prover's tarball, and `PINS.json` gains them, with
  `tools/pins.py` checking that they agree and that a new pin counts as a move. The weekly check compares them
  and their kept copies with upstream, and the evidence workflow runs TOPAK's certified step for them. **Merged
  2026.11.18** as `ada119b`.
- **Run TOPAK's certified step in the candidate image**, at a named TOPAK commit, as the spike ran `defects-run.sh`.
  **Run locally 2026.11.17**, in a candidate built from the branch, at TOPAK `0dfdfcd`:
  - `proof-cert.sh Alone_proof` certified all 263 obligations, with the route counts of TOPAK's own record under
    `7824dab`;
  - `defects-run.sh`'s certified section printed counts for all twelve modules. Nine differ from TOPAK's §8 under
    `ff40755`, as the spike's run did, which is TOPAK's to explain (its ADR-0077 §5).

  The self-test's `smt` check passed, and fails with an `ethos` that accepts everything or refuses everything.

**Done when**, in the published image:
- the self-test's check of `cvc5` and `ethos` passes;
- TOPAK's `spec/proof-cert.sh` certifies one of its proof modules with the image's tools;
- `defects-run.sh`'s certified step prints counts, not empty ones.

Where the counts differ from TOPAK's records, which were made under `7824dab`, the record lists the differences.
Explaining them is TOPAK's (its ADR-0077 §5).

**Done 2026.11.18** for cvc5 and ethos, in `v0.4.0` (`derived/tla-kit-phase6-checks-2026.11.18.md`):
1. **The self-test:** its `smt` check passed in the release workflow, before publishing and on the digest pulled
   back, and again in `v0.4.0` pulled by digest.
2. **The certified step:** at TOPAK `0dfdfcd`, `proof-cert.sh Alone_proof` certified all 263 obligations, with the
   counts by route of TOPAK's record under `7824dab`, and byte for byte the candidate's output.
3. **The defect run:** `defects-run.sh`'s certified section printed counts for all twelve modules. Nine differ
   from §8, as in the candidate. Under `tlapm`, 13 lines differ. Under TLC, every statement is
   violated, as §8 says. The record lists every difference, for TOPAK to explain.

Along the way:
- **Released:** `v0.4.0`, a MINOR (ADR-0014 item 2) that adds the three checker pins and moves no existing one,
  was published on 2026.11.18 from `ada119b` as `sha256:6c27b7a0…8f2f`, the digest CI's two runners reproduced,
  with both attestations verified. Its release links the kept `cvc5-1.4.0`.
- **A certified run's evidence digest depends on the machine.** On GitHub's runner `tlapm` reused two duplicate
  obligations that it proved twice here, so CI's digest differs from a local one. The counts by route agree, and
  are what to compare.
- **Trivy does not scan the static binaries:** they carry no package metadata, so the scan covers the Ubuntu
  packages only.
- **Owed:** the weekly check's first comparison of the kept zips in Actions (Monday 2026.11.23), and the TOPAK pull
  request that moves the plugin's `.mcp.json` to `v0.4.0`.

Then, each on its own:

- The TLA+ community modules. ADR-0012 does not place them yet.
- Apalache: type checking and symbolic checking. The skill gives no guidance for it, so exploratory.
- TLATeX, which needs a LaTeX installation.
- A Linux arm64 `tlapm` built from source, for Apple Silicon without emulation. A second platform is a second
  binary and a second digest to pin.

### Outside the phases: the lemma graph (ADR-0024, Proposed)

Added 2026.11.22, at the custodian's request. A proof module's facts and the citations between them, read from
SANY's XML export; a table of one-line readings, each pinned to the text of the proof it is a reading of; and a
check of a drawn graph's arrows against the citations. `server/lemma_graph.py`, the server's `lemma_graph` tool,
`tla-kit lemma-graph` and `server/test_lemma_graph.py` are built ahead of acceptance, as working output, and are in
no release. It needs nothing from [`GRAPH-AND-DIAGRAMS.md`](GRAPH-AND-DIAGRAMS.md)'s two phases, and it is what a
diagram of a proof module would be drawn from.
[`LEMMA-GRAPH-BROWSER.md`](LEMMA-GRAPH-BROWSER.md) is a design note, not built, for drawing it as a browsable page
after Lean's Blueprint.

**Check that can fail:** `server/test_lemma_graph.py`, natively for the tables and in the image for the reader;
thirteen faults planted in the script, one at a time, each failed it on 2026.11.22. **Not run:** the image was not
built in the session that wrote it, so the tool and the command inside the image are untested until CI runs.

## Risks

- **The prover tag moves.** Three builds in six weeks across the three projects. The answer is the copy of the
  tarball kept in a release `tlapm-<commit>` since Phase 1c, which D7 allows on its conditions. CI and the release
  build from it, so a moved tag no longer fails a rebuild. The weekly check reports the move.
- **A newer prover changes what proves.** It did, for the defect modules. Every prover move needs the full
  proof run and the defect run before a pin moves.
- **Rebuilds rely on upstreams that no record keeps.** Only the prover's tarball has a kept copy. The base
  image comes from Docker Hub, which refused the spike's pull (HTTP 429), the `apt` packages from Ubuntu's
  snapshot archive, and the jar from GitHub's releases. ADR-0015's `Durable` makes this a stated assumption
  rather than an unstated one. On 2026.11.16 the snapshot archive answered 500, 502 and
  503 for long enough that CI on one pull request failed twice at `apt-get`, with nothing wrong in the change.
- **The gate on ADR-0005, 0013 and 0014 was working output.** Phase 1b checked the model in an unpublished
  image. Phase 1c regenerated the results in the published `v0.1.0` image and they reproduced byte for byte, so
  the acceptance now rests on a run that can be cited (2026.11.16).
- **Emulation on Apple Silicon** was measured once, in Phase 1a: TOPAK's full proof run under emulation took
  6 min 43 s on a 12-CPU Mac, against 539 s natively on a 4-CPU x86_64 machine at the spike. That is one machine
  and not a ratio, but it is not the slowdown feared. The arm64 build (Phase 6) is for parity, not speed.
- **Two copies of the method.** Vendored scripts can drift from the skill. D2's digest check is the guard.
- **Process for one custodian.** ADR-0013 to ADR-0016 add an inventory, a weekly issue, a scan, a list of
  projects with a log, attestations and two TLA+ modules. If that is more than one person can keep, the records
  change by new records. The practice does not drift away from them unrecorded.
- **Scope.** The MCP layer is the smaller gain; CI-checked proofs (Phases 1 and 2) come first and stand
  without it.
