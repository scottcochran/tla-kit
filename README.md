# tla-kit

One container image of the TLA+ tool family, so that the checker and the prover are the same build on a
laptop and in CI, and (planned) an MCP server over those tools to pair with the
[`writing-tla-specs-and-proofs`](https://github.com/scottcochran/TOPAK/tree/main/skills/writing-tla-specs-and-proofs)
skill.

**Status: Phase 1a of [PLAN.md](PLAN.md).** The image builds with a plain `docker build .`, from a base pinned by
digest and packages pinned by date. It runs as a non-root user, carries the skill's scripts and a self-test, and
says what it holds. Phase 1b's model of the pin and release process, [`spec/PinLifecycle.tla`](spec/), is written and checked: all
49 rows as expected, as working output. There is no MCP server yet, no CI, and the image is not published.

## What is in the image

| Tool | Build | Held to |
|---|---|---|
| TLC, SANY, PlusCal translator | `tla2tools.jar` v1.7.4 (TLC2 2.19, rev 5a47802) | sha256 `936a2620…0e88`, the digest TOPAK's `tools/TLA-PIN` names |
| TLAPS proof manager | `tlapm` at commit `ff40755`, from the rolling `1.6.0-pre` tag as served on 2026.11.15 | tarball sha256 `99db29f1…6bcc`; binary sha256 `6182df63…5bb2`, checked at build |
| TLAPS backends | Z3 4.8.9, Zenon 0.8.4 [a268], Isabelle2025 (Isabelle/TLA+ heap) on Poly/ML 5.9.1, LS4 1.0, and a second TLA+ tools jar (`d8fb231`) that `tlapm` uses | inside the tarball above |
| The skill's scripts | `writing-tla-specs-and-proofs` `scripts/` and `assets/selftest/`, vendored at TOPAK `0ad9f88` | each file's sha256 in [`vendor/writing-tla-specs-and-proofs/VENDOR-PIN`](vendor/writing-tla-specs-and-proofs/VENDOR-PIN) |
| Runtime | Ubuntu 24.04.5, Temurin JRE 25.0.5+8, Python 3.12.3, perl 5.38.2 (`shasum`), git 2.43.0 | base `eclipse-temurin:25-jre-noble` by digest, `sha256:5b5a79b8…e2f5` (amd64, resolved 2026.11.15); packages from Ubuntu's snapshot of 2026-11-15T00:00:00Z |

`tla-kit-info`, the default command, prints each tool with the digest a results file would cite, the skill's
commit, the package versions and the build arguments; `tla-kit-info --json` prints the same as JSON.
`tla-kit-selftest` checks the image against itself in about half a minute: the digests, `TLA_JAR` and `TLAPM`,
the licence texts, the `sany`, `pcal` and `tlc` wrappers, and the skill's setup check with proofs (the fixture's
row list, its proof and its flip test). `tlapm` and `tlapm_lsp` are on `PATH`, and the skill's scripts are at
`/opt/tla-kit/skill` (`$TLA_KIT_SKILL`).

The image sets `TLA_JAR` and `TLAPM`, the two variables the skill's scripts and the projects' run scripts
already read, so a mounted project uses the image's tools without changes.

The third-party software in the image, with each part's licence, the path of its licence text and its source, is
listed in [`licenses/THIRD-PARTY.md`](licenses/THIRD-PARTY.md), which the image carries at `/opt/tla-kit/licenses/`.

## Build and run

```sh
docker build -t tla-kit:dev .
docker run --rm tla-kit:dev                                      # what is inside
docker run --rm tla-kit:dev tla-kit-selftest                     # does it work
docker run --rm -v "$PWD:/work" tla-kit:dev tlc -config M.cfg M.tla
docker run --rm -v "$PWD:/work" tla-kit:dev tlapm --cleanfp --strict M_proof.tla
```

The image runs as `tla` (uid 1000). On Linux, a project owned by another uid (a GitHub runner's is 1001) needs
`--user "$(id -u):$(id -g)"`; `HOME` is world-writable, so the prover works under any uid. Docker Desktop on macOS
maps ownership itself, and files written to a mounted project are the host user's.

The platform is fixed to `linux/amd64` in the `Dockerfile`, so a plain build on Apple Silicon makes the x86_64
image and runs it under emulation. Docker then prints a warning about the platform at build and at run. Passing
`--platform linux/amd64` to `docker run` can make Docker on macOS look for the image in the registry instead of
using the local one.

Every input is held to a digest or a date: the base by digest, the `apt` sources pointed at Ubuntu's snapshot for
`APT_SNAPSHOT` and at nothing else, both downloads by sha256, and the `tlapm` binary by sha256 after extraction.
Upstream rebuilds the `1.6.0-pre` TLAPS tag under the same name, so the build will fail when the tarball changes.
That is intended: a new prover build is a decision, and the place to record it is `TLAPM_SHA256`. Once an image is
published, its digest is what a project should cite, because upstream stops serving the tarball it was built from.

`BASE_IMAGE` is a build argument, for a registry mirror or a base with a private CA:
`--build-arg BASE_IMAGE=public.ecr.aws/docker/library/eclipse-temurin:25-jre-noble@sha256:5b5a79b8…`. A digest
built with other arguments is for working, not for citing (ADR-0002 item 7).

`vendor/check.py` checks the vendored scripts against their pin, and with `--upstream <TOPAK checkout>` against
the commit itself.

## Limits

- **Linux x86_64 only.** Upstream publishes no Linux arm64 build of `tlapm`. On Apple Silicon the image runs
  under emulation. On one 12-CPU Mac that was not slow: TOPAK's full proof run took under 7 minutes (the Phase 1a
  checks below).
- **Base must be Ubuntu 24.04 or newer.** The `tlapm` binary needs glibc 2.38; Debian 12 and Ubuntu 22.04 are
  too old.
- **Not yet reproducible bit for bit.** The base and the packages are pinned, but file times in the layers come
  from the build. `SOURCE_DATE_EPOCH` and a two-build comparison are Phase 1c (ADR-0014 item 8).
- **Not published yet.** `PLAN.md` D7, settled 2026.11.15, allows the image and the TLAPS tarball's contents to
  be redistributed on three conditions
  ([`derived/tla-kit-licence-check-2026.11.15.md`](derived/tla-kit-licence-check-2026.11.15.md) §5). The image
  meets the first, carrying the notices. The other two come with the release process in Phase 1c: the copyleft
  parts' source beside the kept tarball, and the GMP release and `libsha1`'s licence settled.
- **No certified proof runs yet.** cvc5 and ethos, which TOPAK's `spec/proof-cert.sh` needs, are not in the
  image.

## Phase 1a checks, 2026.11.15

Run on an Apple Silicon Mac (arm64), Docker Desktop 29.0.1, the image built for linux/amd64 and run under
emulation.

| Check | Outcome |
|---|---|
| `docker build .` with no arguments | Builds, in 2 min 22 s from a warm cache. Docker warns that the `FROM` platform is a constant, which is intended. 805 MB. |
| `apt` from the snapshot only | All 53 index and package downloads from `snapshot.ubuntu.com/ubuntu/20261115T000000Z`, none from the live archive. `apt-get update --snapshot` had also fetched the live indices, so the sources are rewritten instead. |
| `tla-kit-selftest` | All seven checks ok in 28 s. The skill's setup check takes 23 s of it: all 11 fixture rows as expected, the fixture's 19 obligations proved, and its flipped hypothesis failing as required. The prover is held to its pin, with no `TLAPM_UNPINNED` override. |
| The self-test can fail | It fails with `TLAPM=/bin/true` (pins, env, setup), with a vendored script changed (pins), and with a licence text removed (notices). |
| Writing to a mounted project | A macOS bind mount: the results file is the host user's. A volume owned by uid 1001: the default uid 1000 is refused, as Linux permissions require; with `--user 1001:1001` the TLC results and a proof results file are written, owned by 1001. |
| TOPAK's proofs under emulation | `spike/prove-all.sh` over TOPAK's `spec/` at `0ad9f88` (taken with `git archive`, mounted read-only): 34 of 34 proof modules proved, 13,622 obligations, every count equal to its committed results file. 6 min 43 s on 12 CPUs, `Mesh` the slowest at 103 s. The spike's native run took 539 s on 4 CPUs (`Mesh` 152 s); the machines differ, so this is not a ratio for emulation. |
| `vendor/check.py --upstream` | 11 files match `VENDOR-PIN` and TOPAK at `0ad9f88`. It fails on a changed file and on an extra one. |

## Spike results, 2026.11.15

Run in the image on a 4-CPU x86_64 Linux machine, against TOPAK at commit `0ad9f88`, mounted read-only and
copied inside the container. Nothing was written to TOPAK and no results file was produced.

| Check | Command | Outcome |
|---|---|---|
| The skill's setup check | `setup_check.py --proofs`, in an empty project, `TLAPM_UNPINNED=1` | Ready for model checking and proofs: all 11 fixture rows as expected; the fixture's 19 obligations proved; its flipped hypothesis fails as required |
| TOPAK's jar pin | `tools/check-pins.sh` | In step with `tools/TLA-PIN` |
| TOPAK's proofs | `spike/prove-all.sh /work/spec` | 34 of 34 proof modules proved; 13,622 obligations; every module's count equals its committed results file; 539 s in all, `Mesh` the slowest at 152 s |
| TOPAK's prover-defect reproductions | `spec/defects/defects-run.sh`, `TLAPM_UNPINNED=1` | Differs from the committed record: 13 lemmas the record expects to prove (12 by SMT, 1 by LS4) fail under this prover build; TLC still finds all 8 statements false; the certified step cannot run without cvc5 and ethos |
| TOPAK's TLC results | `tools/check-results.sh` on the `pr` tier | All 14 modules regenerated and compared with their committed results files: 490 rows, 0 differences; 3,390 s run one after another (CI runs them as a matrix), `Release` the slowest at 913 s |

The committed proof results were made by `tlapm` 7824dab on arm64-darwin. This run used ff40755 on Linux
x86_64, with the same backend versions (Z3 4.8.9, Zenon 0.8.4 [a268], Isabelle2025). Equal obligation counts
are not equal results files: a file generated in this image would carry a different `Prover:` line, and
TOPAK's `tools/TLAPS-PIN` still names the darwin binary.

The spike image was built on a derived base that adds a private proxy certificate, from a registry mirror, so
its digest is not one to cite.

Not tried: certified proof runs (`spec/proof-cert.sh`), the image under emulation on Apple Silicon, the `Mesh`
TLC results (tier `manual`, about 70 minutes), and any GitHub Actions run.

## Not built yet

[PLAN.md](PLAN.md) is the development plan, and [derived/](derived/) holds dated, frozen records: the session
that produced the spike, with the raw output of its runs, and the licence check of the bundled tools. [decisions/](decisions/) holds the architecture
decision records drafted from both: ADR-0001 to ADR-0004, ADR-0007, ADR-0011 and ADR-0015 accepted, the rest Proposed. In short:

- The MCP server: the skill's scripts as tools (`tlc_run`, `tlc_rows`, `proof_results`, `flip_test`,
  `proof_sync`), exploration tools (parse, symbols, evaluate, coverage, state graph), and proof tools on
  `tlapm` (check a module, check one step, list failed obligations).
- cvc5 and ethos for certified runs; Apalache; the TLA+ community modules.
- A published image, the CI workflow that builds it, its inventory (`PINS.json`) and the release process
  (Phase 1c).
- A Linux arm64 build of `tlapm` from source.

## License

Code and tooling are Apache-2.0 ([LICENSE](LICENSE)); documentation is CC BY 4.0
([LICENSE-DOCS](LICENSE-DOCS)). See [NOTICE](NOTICE) for how the split applies. The tools inside the image keep
their own licences. [`licenses/THIRD-PARTY.md`](licenses/THIRD-PARTY.md) lists them.
