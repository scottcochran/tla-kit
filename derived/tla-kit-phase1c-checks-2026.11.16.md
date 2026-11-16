# tla-kit: Phase 1c's checks of the first release, 2026.11.16

> **Provenance note.** Written 2026.11.16 by the assistant, at the custodian's direction to record Phase 1c's
> end, on branch `phase1c-done` after `bfeecc8`. It records the checks of `PLAN.md` Phase 1c's "Done when", run on
> the image the release workflow published for tag `v0.1.0`. The raw output of each check is in the annex beside
> it, [`tla-kit-phase1c-checks-annex-2026.11.16/`](tla-kit-phase1c-checks-annex-2026.11.16/). It decides nothing.

## 1. The image

```
ghcr.io/scottcochran/tla-kit@sha256:454328cd7464efcf8a27a063c51c10086e09571c462c73d085b4a249e44950c6
```

- **Built from tag `v0.1.0`** by `.github/workflows/release.yml`, run 43834109296, at commit `bfeecc8`
  (committed 2026-11-16T07:29:10Z). The release is https://github.com/scottcochran/tla-kit/releases/tag/v0.1.0.
- **The digest CI tested.** It is the digest that CI's `reproduce` job got on `main` at the same commit (run
  43824194995), where two runners each built the commit from nothing. The release build, a third build on a
  third runner, gave the same digest.
- **Self-tested twice in the workflow,** as built and again after being pulled back from the registry by digest.
- **Pulled without credentials:** GHCR answers an anonymous request for its manifest with HTTP 200.
- **Holds:**
  - the checker jar, v1.7.4 (`936a2620…0e88`);
  - `tlapm` ff40755, binary `6182df63…5bb2`, from the kept release `tlapm-ff40755`;
  - the skill's scripts, at TOPAK `5ade81e` (`info.txt`).

## 2. The checks

| Check | Outcome | Annex |
|---|---|---|
| `gh attestation verify --repo scottcochran/tla-kit` | Passes for the build provenance (SLSA v1) and the SBOM (SPDX 2.3), both signed for `release.yml` at `refs/tags/v0.1.0` and commit `bfeecc8` | `attestation.txt` |
| `PinLifecycle` rows (ADR-0015 item 1) | All 50 rows as expected. `spec/PinLifecycle-results-2026.11.16.txt` reproduced byte for byte. | `pinlifecycle.txt` |
| The vulnerability scan at release (Trivy, HIGH and CRITICAL) | 0 in the Ubuntu packages. Trivy reported no other target, so the Java runtime and the jars were not covered. | the release's `scan.txt` |

The spike's checks were repeated from the published image, against TOPAK at `0ad9f88`, the commit the spike used.
TOPAK was taken with `git archive`, mounted read-only and copied inside each container, so nothing was written to
it. They ran on an Apple Silicon Mac with 12 CPUs, under emulation. The spike ran on 4 native CPUs.

| Spike check | This run | The spike |
|---|---|---|
| The skill's setup check, `--proofs`, `TLAPM_UNPINNED=1` | Ready for model checking and proofs: 11 fixture rows as expected, the fixture's 19 obligations proved, the flipped hypothesis failing as required | The same |
| TOPAK's jar pin, `tools/check-pins.sh` | In step with `tools/TLA-PIN` | The same |
| TOPAK's proofs, `spike/prove-all.sh` | 34 of 34 proof modules proved, 13,622 obligations, every count equal to its committed results file. 417 s, `Mesh` the slowest at 108 s. | The same counts. 539 s, `Mesh` 152 s. |
| TOPAK's defect run, `spec/defects/defects-run.sh`, `TLAPM_UNPINNED=1` | Differs from TOPAK's defect record, as the spike's run did, and at the same lines | The same, but for two state counts (below) |
| TOPAK's TLC results, `tools/check-results.sh`, every `pr`-tier module | 14 modules, 490 rows compared, 0 differences. 3,621 s of module time, run three at a time, `Release` the slowest at 993 s. | 490 rows, 0 differences. 3,390 s run one after another, `Release` 913 s. |

The defect run's output is the spike's line for line, but for two state counts in its TLC section:
- `BadEventually`: 20,763 distinct states, where the spike had 18,978;
- `BadLeadsTo`: 8,125, where the spike had 6,195.

Both are violated temporal properties, whose count depends on when TLC's clock-driven check runs. That is the
same count the skill's generator stopped printing at TOPAK `5ade81e`. The verdicts are the same.

## 3. What follows

All three conditions of `PLAN.md` Phase 1c's "Done when" hold for this digest:
1. **The spike table:** it reproduces the README's spike table.
2. **The attestations:** `gh attestation verify` passes.
3. **The `PinLifecycle` results:** regenerated in it, they match the committed file.

That last check makes `spec/PinLifecycle-results-2026.11.16.txt` evidence in a published, attested image, where
before it was working output (ADR-0015 item 1).
