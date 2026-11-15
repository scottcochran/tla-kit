# Development plan

Written 2026.11.15, after the spike the README records. It is a plan, not a record: nothing below is built
unless the README says so.

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

Drafted as records in [decisions/](decisions/): D2 is ADR-0007, D3 ADR-0010, D4 ADR-0011 and D5 ADR-0012. D1 is
TOPAK's and has no record here.

| | Decision | Recommendation | Blocks |
|---|---|---|---|
| D1 | Does TOPAK move `tools/TLAPS-PIN` to the image's Linux prover? TOPAK's decision, made there. | Yes: it is the only route to proofs rerun in CI, and the newer build rejects the two unsound cases. It means regenerating 34 proof results files, and the records that cite the two cases need a look. | Phase 2 as evidence |
| D2 | Where do the skill's scripts live for the server to call? | Vendor them here at a named TOPAK commit, checked by digest in CI. The skill stays usable without Docker. | Phase 3 |
| D3 | Registry and visibility for the image. | `ghcr.io/scottcochran/tla-kit`, public. | Phase 1 |
| D4 | Licence for this repository. There is none yet. | Apache-2.0, as TOPAK's code. | Publishing |
| D5 | One image, or a small one with variants for the large optional tools? | One base image; variants by tag for Apalache and TLATeX. | Phase 6 |

## Phases

Each phase ends with a check that can fail. Later phases do not start on an earlier one's assumption.

### Phase 1: an image that can be cited

- Build with plain `docker build .` on a stock machine and in GitHub Actions. The spike built on a derived
  base through a mirror, so the default path is untested.
- Pin the base image by digest. Look at Ubuntu's snapshot archive to fix the `apt` packages by date.
- Keep the pinned TLAPS tarball as a release asset here, after checking the licences of what it bundles, so
  the image can be rebuilt when upstream has moved the tag. Build from the copy; compare with upstream as a
  separate, reporting check (the analogue of TOPAK's `sources.yml`).
- Run as a non-root user, so files written to a mounted project are not owned by root.
- A self-test in the image: a fixture module and proof, a row list, a flip test. `tla-kit-info` as JSON.
- A workflow that builds, runs the self-test, publishes on a tag, and records the digest in the release.
- Repeat the spike's TOPAK checks from the published image.

**Done when** a published digest reproduces the README's spike table.

### Phase 2: the image in the projects' CI

Changes in TOPAK and gov-tla, each made in its own repository and asked for there.

- TOPAK: run the `tlc` job in the image; add a `proofs` job that reruns every proof module; fix the pin key
  the skill's scripts read (`binary_sha256`, where `tools/TLAPS-PIN` has `binary_sha256_16`).
- gov-tla: the same two jobs. Its pinned prover (c8ddc44) is no longer served, so it faces D1 as well.
- Before D1 the proofs job reports counts only. After it, the results files are regenerated in the image.

**Done when** a pull request in TOPAK shows its proofs rerun in CI.

### Phase 3: the MCP server, model checking

A Python server over stdio, started as `tla-kit mcp`, so it can import the skill's `tla_common.py`. Paths are
confined to the mounted project. The image gains the MCP SDK, pinned by hash.

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

- `proof_check`: parse and count obligations without backends (`tlapm --summary`).
- `prove`: one step, a line range, or a theorem by name, resolved to lines by the server. It reads `tlapm`'s
  Toolbox protocol, not log text, and returns only the unresolved obligations, each with its text, the backends
  tried and the reason. Success needs exit 0, no error line and a non-zero obligation count.
- Warnings on success when a later backend closed what an earlier one failed, naming the `BY` tactic.
- A cache directory the server owns, never beside the module; the whole process group killed on cancel or
  timeout; threads, timeout stretch and Isabelle checking of Zenon's proofs as options.
- `proof_results`, `flip_test` and `proof_sync`: the skill's scripts, as tools.
- Compare with driving `tlapm_lsp`, which already resolves a cursor position to its obligations.

**Done when** an agent using only these tools repairs a deliberately broken step in the fixture, and
`proof_results` through the server writes the file the script writes.

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

- **The prover tag moves.** Three builds in six weeks across the three projects. Phase 1's copy of the tarball
  is the answer; until then a rebuild can fail on the checksum by design.
- **A newer prover changes what proves.** It did, for the defect modules. Every prover move needs the full
  proof run and the defect run before a pin moves.
- **Emulation on Apple Silicon** is unmeasured. If it is slow, local proof work stays on the native binary
  until the arm64 build exists, and "the same locally and in CI" holds for CI and Linux only.
- **Two copies of the method.** Vendored scripts can drift from the skill. D2's digest check is the guard.
- **Scope.** The MCP layer is the smaller gain; CI-checked proofs (Phases 1 and 2) come first and stand
  without it.
