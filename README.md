# tla-kit

One container image of the TLA+ tool family, so that the checker and the prover are the same build on a
laptop and in CI, and (planned) an MCP server over those tools to pair with the
[`writing-tla-specs-and-proofs`](https://github.com/scottcochran/TOPAK/tree/main/skills/writing-tla-specs-and-proofs)
skill.

**Status: spike.** The image builds and runs TOPAK's model checking and proofs. There is no MCP server yet, and
the image is not published.

## What is in the image

| Tool | Build | Held to |
|---|---|---|
| TLC, SANY, PlusCal translator | `tla2tools.jar` v1.7.4 (TLC2 2.19, rev 5a47802) | sha256 `936a2620…0e88`, the digest TOPAK's `tools/TLA-PIN` names |
| TLAPS proof manager | `tlapm` at commit `ff40755`, from the rolling `1.6.0-pre` tag as served on 2026.11.15 | tarball sha256 `99db29f1…6bcc`; binary sha256 `6182df63…5bb2` |
| TLAPS backends | Z3 4.8.9, Zenon 0.8.4 [a268], Isabelle2025 (Isabelle/TLA+ heap), LS4 | inside the tarball above |
| Runtime | Ubuntu 24.04, Temurin JRE 25, Python 3.12, perl (`shasum`), git | base image tag, not a digest yet |

`tla-kit-info` (the image's default command) prints each tool with the digest a results file would cite.
`tlc`, `sany` and `pcal` are wrappers on the jar; `tlapm` and `tlapm_lsp` are on `PATH`.

The image sets `TLA_JAR` and `TLAPM`, the two variables the skill's scripts and TOPAK's run scripts already
read, so a mounted project uses the image's tools without changes.

## Build and run

```sh
docker build -t tla-kit:spike .
docker run --rm tla-kit:spike                                  # what is inside
docker run --rm -v "$PWD:/work" tla-kit:spike tlc -config M.cfg M.tla
docker run --rm -v "$PWD:/work" tla-kit:spike tlapm --cleanfp --strict M_proof.tla
```

Both downloads are checked against a sha256 in the `Dockerfile`. Upstream rebuilds the `1.6.0-pre` TLAPS tag
under the same name, so the build will fail when the tarball changes. That is intended: a new prover build is
a decision, and the place to record it is `TLAPM_SHA256`. Once an image is published, its digest is what a
project should cite, because upstream stops serving the tarball it was built from.

`BASE_IMAGE` is a build argument, for a registry mirror or a base with a private CA:
`--build-arg BASE_IMAGE=public.ecr.aws/docker/library/eclipse-temurin:25-jre-noble`.

## Limits

- **Linux x86_64 only.** Upstream publishes no Linux arm64 build of `tlapm`. On Apple Silicon the image runs
  under emulation; how slow that makes the proofs is not measured.
- **Base must be Ubuntu 24.04 or newer.** The `tlapm` binary needs glibc 2.38; Debian 12 and Ubuntu 22.04 are
  too old.
- **Not reproducible bit for bit.** `apt-get` installs whatever the archive serves on the day, and the base
  image is referenced by tag.
- **No certified proof runs yet.** cvc5 and ethos, which TOPAK's `spec/proof-cert.sh` needs, are not in the
  image.

## Spike results, 2026.11.15

Run in the image on a 4-CPU x86_64 Linux machine, against TOPAK at commit `0ad9f88`, mounted read-only and
copied inside the container. Nothing was written to TOPAK and no results file was produced.

| Check | Command | Outcome |
|---|---|---|
| The skill's setup check | `setup_check.py --proofs`, in an empty project, `TLAPM_UNPINNED=1` | Ready for model checking and proofs: all 11 fixture rows as expected; the fixture's 19 obligations proved; its flipped hypothesis fails as required |
| TOPAK's jar pin | `tools/check-pins.sh` | In step with `tools/TLA-PIN` |
| TOPAK's proofs | `spike/prove-all.sh /work/spec` | 34 of 34 proof modules proved; 13,622 obligations; every module's count equals its committed results file; 539 s in all, `Mesh` the slowest at 152 s |
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

- The MCP server: the skill's scripts as tools (`tlc_run`, `tlc_rows`, `proof_results`, `flip_test`,
  `proof_sync`), exploration tools (parse, symbols, evaluate, coverage, state graph), and proof tools on
  `tlapm` (check a module, check one step, list failed obligations).
- cvc5 and ethos for certified runs; Apalache; the TLA+ community modules.
- A published image, a CI workflow that builds it, and a base image pinned by digest.
- A Linux arm64 build of `tlapm` from source.
