# tla-kit: Phase 6's "Done when", cvc5 and ethos in the published image, 2026.11.18

> **Provenance note.** Written 2026.11.18 by the assistant, at the custodian's direction to write the Phase 6 Done
> record, on branch `phase6-done` after `ada119b`. It records the check of `PLAN.md` Phase 6's "Done when" for
> `cvc5` and `ethos` (ADR-0012 item 8, ADR-0017) in the published image:
> - the self-test's check of the two passes;
> - TOPAK's `spec/proof-cert.sh` certifies one of its proof modules with the image's tools;
> - `defects-run.sh`'s certified step prints counts, not empty ones.
>
> The image is `v0.4.0`, `ghcr.io/scottcochran/tla-kit@sha256:6c27b7a0…8f2f`, published that day from `ada119b`
> (pull request #27), its tag made at the custodian's instruction. TOPAK is at `0dfdfcd`, its `main`. The annex
> beside it, [`tla-kit-phase6-checks-annex-2026.11.18/`](tla-kit-phase6-checks-annex-2026.11.18/), holds the
> commands and every output. It decides nothing.

## 1. What was checked

- **The image:** `v0.4.0`, pulled by digest. Its `cvc5` 1.4.0, `ethos` 0.2.4 and CPC signature come from the copies
  kept in release `cvc5-1.4.0`. `tla-kit-info` prints them with their digests (`info.txt`).
- **The self-test:** `tla-kit-selftest`, whose `smt` check asks `cvc5` for a proof that `x > 2 ∧ x < 1` is
  unsatisfiable, in the CPC format. `ethos` has to accept it, and refuse a copy with one rule changed.
- **The certified step:** TOPAK's `spec/proof-cert.sh Alone_proof`, then `spec/defects/defects-run.sh`, as the
  evidence workflow runs them: TOPAK mounted read-only and `TLAPM_UNPINNED=1`. The image's prover is `ff40755`,
  and TOPAK's pin is still `7824dab` (TOPAK's ADR-0077). `CVC5` and `ETHOS` are the image's, as its variables
  set them.

## 2. The runs

| Check | Where | Outcome |
|---|---|---|
| Self-test, before publishing | Release run 44252970208, on the image built from the tag | passed, `smt` among its checks |
| Self-test, on the digest pulled back | The same run | passed |
| Self-test | Here, `v0.4.0` by digest, under emulation | passed (`selftest.txt`) |
| `proof-cert.sh Alone_proof` | Here, `v0.4.0` by digest, 18 s | all 263 obligations proved (`Alone-proof-cert.txt`) |
| `defects-run.sh` | Here, `v0.4.0` by digest, 2½ min | counts for all twelve prover modules; differs from TOPAK's §8 where the candidate did (`defects.txt`) |
| `proof-cert.sh Alone_proof` | CI on `main` at `ada119b` (run 44247785902), in the candidate built there | all 263 proved (`ci-cert-main.txt`) |

Before any of these, the release workflow checked the published digest:
- **It is the one CI's two runners built** from `ada119b`, `sha256:6c27b7a0…8f2f`.
- **Both attestations verify** with `gh attestation verify`: the provenance, and the SBOM, which was checked with
  `--predicate-type https://spdx.dev/Document/v2.3`.

## 3. Findings

**F-1. The self-test's check of `cvc5` and `ethos` passes in the published image.** It passed three times: in the
release run, before publishing and on the digest pulled back, and here. `ethos` accepted the proof `cvc5` gave and
refused the changed copy. The `pins` check found `cvc5` and `ethos` as built, and its 101 installed files as
`PINS.json` lists them, the signature's 51 among them. The `env` check found `CVC5` and `ETHOS` set, and both on
`PATH`.

**F-2. `proof-cert.sh` certifies `Alone_proof` with the image's tools.** All 263 obligations proved, by route:

| Route | Obligations |
|---|---|
| Trivial, closed by `tlapm` with no backend | 173 |
| SMT, with a proof `ethos` accepted | 78 |
| Isabelle | 6 |
| LS4, which no checker confirms | 6 |

257 rest on `tlapm`'s own normalization or on a checked proof. The header names `cvc5` `d4c534360e602f07`, `ethos`
`97e95d36dcb596e6` and the signature's tree `633f74115700ad32`, as the image's pins give them.
- **Against TOPAK's record:** the counts by route are those of TOPAK's `spec/Alone-proof-cert-results-2026.11.10.txt`,
  made under `7824dab`.
- **Against the candidate:** the output is byte for byte the run made on 2026.11.17 in the image built from pull
  request #27.

**F-3. `defects-run.sh`'s certified step prints counts for all twelve prover modules.** Section 2, the certified
run, gives each module's obligations by route and whether it is certified:
- **3 lines as §8 says:**
  - `HiddenDef` and `HiddenBox` are not certified, as §10's rule requires.
  - `CapturePTL` is certified.
- **9 lines differ:** the modules §8 records as certified are not certified, because an obligation fails at
  Isabelle.

The other two sections:
- **Section 1, under `tlapm`:** 13 lines differ, and 18 are as §8 says.
- **Section 3, under TLC:** all 8 statements are violated, as §8 says.

The differing lines are those of the candidate run. They are differences under `ff40755` from TOPAK's §8, which
was made under `7824dab`, and explaining them is TOPAK's (its ADR-0077 §5).

The only difference from the candidate run is two state counts in section 3, `BadEventually` and `BadLeadsTo`. Both
are violated in either run (`defects-vs-candidate.diff`). The point at which TLC's liveness search stops varies with
the machine, as it did for `spec/PinLifecycle.tla` (`spec/README.md`). The run compares the verdict only.

**F-4. The evidence digest of a certified run is not the same on every machine; the counts by route are.**
`proof-cert.sh` prints the number of SMT calls it forwarded on an accepted proof, how many obligations it reused
from one already proved, and a digest over the queries and proofs it checked:

| Run | Calls forwarded | Reused | Evidence digest |
|---|---|---|---|
| Here, twice: the candidate and `v0.4.0` | 78 | 0 | `a97da25713d23e55` |
| CI, twice: pull request #27 and `main` at `ada119b` | 76 | 2 | `08388b0b2aeecb7b` |
| TOPAK's record, under `7824dab` | 78 | 0 | `546b08d7d1ad31af` |

On GitHub's runner, `tlapm` proved two duplicate obligations once and reused the result. Here, with Docker given 12
CPUs, it proved them separately, so the digest covers two more checked proofs. Each place gave its own value twice.
Why the scheduling differs was not looked into. TOPAK's digest differs from both because another prover writes other
queries. A reader comparing certified runs across machines should compare the counts by route, not the digest.

**F-5. The release is a MINOR that adds tools and moves no existing pin.** `tools/pins.py moved v0.3.0` lists the
three new pins only, so TLC, the prover and the runtime are `v0.3.0`'s bytes and no existing verdict changes
(ADR-0014 item 2). Two other checks ran on the release:
- **Scan:** no HIGH or CRITICAL vulnerability in the Ubuntu packages. Trivy reads package metadata, and the static
  `cvc5` and `ethos` carry none, so neither they nor the libraries linked into them were scanned.
- **Release page:** it links both kept releases, `tlapm-ff40755` and `cvc5-1.4.0`.

## 4. Not done

- **One module.** `proof-cert.sh` was run on `Alone_proof` only, as the "Done when" asks. TOPAK's other certified
  results files, and the move of TOPAK's prover pin its ADR-0077 Q2 waits on, are TOPAK's.
- **The weekly comparison of the kept zips** ran locally for pull request #27. It has not run in Actions: the
  schedule's next run is Monday 2026.11.23. It already offers `cvc5` 1.4.2.
- **The GNU and Ubuntu signatures** kept in `cvc5-1.4.0` were not checked, for lack of `gpg` where the release was
  assembled.
- **The plugin** still declares `v0.3.0`. A TOPAK pull request moves its `.mcp.json` to `v0.4.0`'s digest.
- **The rest of Phase 6:** the community modules, Apalache, TLATeX and an arm64 `tlapm`, each on its own.

## 5. The annex

| File | What it is |
|---|---|
| `run.sh` | The commands, in `v0.4.0` by digest |
| `selftest.txt`, `info.txt` | `tla-kit-selftest` and `tla-kit-info` in `v0.4.0` (F-1) |
| `Alone-proof-cert.txt` | `proof-cert.sh Alone_proof` in `v0.4.0` (F-2) |
| `ci-cert-main.txt` | The same in CI on `main` at `ada119b`, from the job's log (F-4) |
| `defects.txt` | `defects-run.sh` in `v0.4.0` (F-3) |
| `defects-candidate.txt`, `defects-vs-candidate.diff` | The same in the candidate built from pull request #27, on 2026.11.17, and the difference (F-3) |
