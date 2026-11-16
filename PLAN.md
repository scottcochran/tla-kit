# Development plan

Written 2026.11.15, after the spike the README records, and updated the same day for ADR-0013 to ADR-0016. It is a
plan, not a record: nothing below is built unless the README says so.

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
| D5 | One image, or a small one with variants for the large optional tools? | One base image; variants by tag for Apalache and TLATeX. | Phase 6 |
| D6 | Take `marco6/tlapm-mcp` as a design to follow, a dependency, or neither? (session record, §9 item 6) | A design to follow, with named changes, and no dependency on it. | Phase 4 |
| D7 | May tla-kit redistribute what the TLAPS tarball bundles (Isabelle, Poly/ML, GMP, `libsha1`, Z3, Zenon, LS4)? | Settled 2026.11.15, as `derived/tla-kit-licence-check-2026.11.15.md` recommends: yes, on three conditions. (1) Every redistribution carries the notices: the image does, in `licenses/`. (2) The release offers the source of Poly/ML, GMP and `libsha1` beside the kept tarball. (3) The bundled GMP release and `libsha1`'s licence are settled before the first public release. | Nothing now. Conditions 2 and 3 are Phase 1c work, before anything is published |

### Records to accept, and when

This is the order in which the phases need the records. The Phase 1a and 1b rows were accepted on 2026.11.15,
and so were ADR-0005, 0013 and 0014. ADR-0010 was accepted on 2026.11.16. Every other record is
Proposed.

| Before | Accept | Why then |
|---|---|---|
| Phase 1a | ADR-0001, 0002, 0003, 0004, 0011; ADR-0007 (D2) | The first five are mostly built. ADR-0007 is pulled forward from Phase 3 (D2). All six accepted 2026.11.15. |
| Phase 1b | ADR-0015 | Its scope, so that `spec/PinLifecycle.tla` can be written. Accepted 2026.11.15. |
| Phase 1c | ADR-0005, 0013, 0014; ADR-0010 (D3) | ADR-0015 item 7: the first three are accepted only when every row of Phase 1b has its expected outcome, and they will probably change before then. ADR-0005, 0013 and 0014 accepted 2026.11.15, and ADR-0010 2026.11.16. ADR-0010 item 5 now says "always", as ADR-0014 item 5 does, where it first said "while any project's pin names them". |
| Phase 3 | ADR-0006, 0008 | |
| Phase 4 | ADR-0009 (D6); then ADR-0016 | ADR-0016 waits on ADR-0009 item 5's comparison of `tlapm` with `tlapm_lsp`. |
| Phase 6 | ADR-0012 (D5) | |

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
Phase 1a. Paths are confined to the mounted project. The image gains the MCP SDK, pinned by hash.

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

### Phase 4: the MCP server, proofs

In this order: the comparison, the tests of `tlapm`, the module, then the tools.

- Compare driving `tlapm` per request with driving `tlapm_lsp`, which already resolves a cursor position to its
  obligations (ADR-0009 item 5). The choice decides which processes exist.
- Test three assumptions about `tlapm` in the image: whether two processes can share a cache directory, whether
  every backend stays in `tlapm`'s process group, and what a kill leaves in the cache (ADR-0016 item 6).
- Write `spec/ProveRequests.tla` for the chosen option, before the tool's code: a row for a naive design, one for
  the chosen design, and one with a backend that leaves the process group (ADR-0016).
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

### Phase 5: pairing with the skill

- The skill's plugin declares the server, by image digest. The skill says which tool answers which step of
  its workflow, and what to do when Docker is absent.
- An example workflow for an agent job in GitHub Actions (`--mcp-config`, each tool in `--allowedTools`).

**Done when** one configuration serves a local session and an Actions job against the same project.

### Phase 6: more of the family

Each is optional, pinned like the rest, and added only with a check that uses it.

- cvc5 and ethos, so that TOPAK's certified runs (`spec/proof-cert.sh`) and the rest of `defects-run.sh` work.
- The TLA+ community modules.
- Apalache: type checking and symbolic checking. The skill gives no guidance for it, so exploratory.
- TLATeX, which needs a LaTeX installation.
- A Linux arm64 `tlapm` built from source, for Apple Silicon without emulation. A second platform is a second
  binary and a second digest to pin.

## Risks

- **The prover tag moves.** Three builds in six weeks across the three projects. Phase 1c's copy of the tarball
  is the answer. D7 allows it, on its conditions. Until then a rebuild can fail on the checksum by design.
- **A newer prover changes what proves.** It did, for the defect modules. Every prover move needs the full
  proof run and the defect run before a pin moves.
- **Rebuilds rely on upstreams that no record keeps.** Only the prover's tarball will have a kept copy. The base
  image comes from Docker Hub, which refused the spike's pull (HTTP 429), the `apt` packages from Ubuntu's
  snapshot archive, and the jar from GitHub's releases. ADR-0015's `Durable` makes this a stated assumption
  rather than an unstated one.
- **The gate on ADR-0005, 0013 and 0014 is working output.** Phase 1b checks the model in an unpublished image.
  Until 1c regenerates the results in a published one, the acceptance rests on a run that cannot be cited.
- **Emulation on Apple Silicon** was measured once, in Phase 1a: TOPAK's full proof run under emulation took
  6 min 43 s on a 12-CPU Mac, against 539 s natively on a 4-CPU x86_64 machine at the spike. That is one machine
  and not a ratio, but it is not the slowdown feared. The arm64 build (Phase 6) is for parity, not speed.
- **Two copies of the method.** Vendored scripts can drift from the skill. D2's digest check is the guard.
- **Process for one custodian.** ADR-0013 to ADR-0016 add an inventory, a weekly issue, a scan, a list of
  projects with a log, attestations and two TLA+ modules. If that is more than one person can keep, the records
  change by new records. The practice does not drift away from them unrecorded.
- **Scope.** The MCP layer is the smaller gain; CI-checked proofs (Phases 1 and 2) come first and stand
  without it.
