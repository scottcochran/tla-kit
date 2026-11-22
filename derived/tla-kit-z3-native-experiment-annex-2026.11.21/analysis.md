## Modules: obligations proved and wall seconds per leg

| module | committed | A0-pristine obl | A0-pristine s | A-z3-4.8.9-amd64-emulated obl | A-z3-4.8.9-amd64-emulated s | B-z3-5.4.1-amd64-emulated obl | B-z3-5.4.1-amd64-emulated s | C-z3-5.4.1-arm64-native obl | C-z3-5.4.1-arm64-native s |
|---|---|---|---|---|---|---|---|---|---|
| Alone | 263 | 263 | 5.7 | 263 | 7.0 | 263 | 6.6 | 263 | 6.3 |
| Anchor | 40 | 40 | 0.7 | 40 | 1.2 | 40 | 1.3 | 40 | 1.0 |
| BreakGlass | 37 | 37 | 0.7 | 37 | 1.1 | 37 | 1.3 | 37 | 1.0 |
| BreakGlass_A1 | 45 | 45 | 0.7 | 45 | 1.2 | 45 | 1.4 | 45 | 0.9 |
| Confinement | 502 | 502 | 16.0 | 502 | 17.5 | 502 | 18.3 | 502 | 16.6 |
| Confinement_A1 | 503 | 503 | 16.1 | 503 | 17.0 | 503 | 17.7 | 503 | 16.9 |
| Correlator | 455 | 455 | 18.1 | 455 | 18.4 | 455 | 16.1 | 455 | 13.9 |
| Coupling | 320 | 320 | 6.7 | 320 | 7.1 | 320 | 3.3 | 320 | 2.4 |
| Coupling_live | 31 | 31 | 0.8 | 31 | 1.2 | 31 | 1.2 | 31 | 0.9 |
| Emergency | 373 | 373 | 5.5 | 373 | 6.5 | 373 | 6.8 | 373 | 5.4 |
| Emergency_live | 160 | 160 | 2.3 | 160 | 2.9 | 160 | 3.1 | 160 | 2.8 |
| Federation | 892 | 892 | 7.9 | 892 | 11.2 | 892 | 12.8 | 892 | 8.4 |
| FloorComposition | 171 | 171 | 1.8 | 171 | 2.7 | 171 | 3.3 | 171 | 2.2 |
| FloorRouting | 36 | 36 | 0.6 | 36 | 1.0 | 36 | 1.1 | 36 | 0.9 |
| Intent | 677 | 677 | 7.4 | 677 | 9.3 | 677 | 10.5 | 677 | 8.4 |
| Labels | 651 | 651 | 7.8 | 651 | 9.1 | 651 | 9.9 | 651 | 8.4 |
| Lease_A1 | 200 | 200 | 17.8 | 200 | 18.5 | 200 | 19.0 | 200 | 18.1 |
| Membership | 495 | 495 | 9.3 | 495 | 10.2 | 495 | 10.6 | 495 | 10.6 |
| Mesh | 1470 | 1470 | 106.7 | 1470 | 113.1 | 1470 | 113.1 | 1470 | 105.6 |
| NonComposition | 58 | 58 | 0.8 | 58 | 1.5 | 58 | 1.4 | 58 | 1.0 |
| NonComposition_A1 | 96 | 96 | 1.1 | 96 | 1.8 | 96 | 2.0 | 96 | 1.5 |
| Observers | 65 | 65 | 0.8 | 65 | 1.3 | 65 | 1.4 | 65 | 1.0 |
| Operators | 354 | 354 | 11.2 | 354 | 14.1 | 354 | 9.6 | 354 | 8.6 |
| Outstanding | 1871 | 1871 | 34.7 | 1871 | 38.1 | 1871 | 35.8 | 1871 | 35.3 |
| Peer | 254 | 254 | 3.3 | 254 | 4.2 | 254 | 4.6 | 254 | 3.7 |
| PlaneClock | 535 | 535 | 12.5 | 535 | 13.4 | 535 | 12.7 | 535 | 12.4 |
| Release | 613 | 613 | 7.6 | 613 | 9.7 | 613 | 10.1 | 613 | 8.3 |
| RulesFloorNV_rev5 | 262 | 262 | 20.4 | 262 | 20.6 | 262 | 20.7 | 262 | 20.4 |
| RunConfinement | 116 | 116 | 1.1 | 116 | 1.9 | 116 | 2.1 | 116 | 1.4 |
| RunCoupling | 469 | 469 | 7.3 | 469 | 7.8 | 469 | 4.4 | 469 | 3.3 |
| RunSeats | 147 | 147 | 1.4 | 147 | 2.3 | 147 | 2.6 | 147 | 1.9 |
| Seats | 110 | 110 | 5.8 | 110 | 6.0 | 110 | 6.0 | 110 | 5.8 |
| ToolList | 215 | 215 | 1.6 | 215 | 2.8 | 215 | 3.2 | 215 | 2.1 |
| Workflow | 1136 | 1136 | 57.5 | 1136 | 59.3 | 1136 | 60.3 | 1136 | 58.0 |
| Workflow_A1 | 1169 | 1169 | 60.2 | 1169 | 67.8 | 1169 | 63.5 | 1169 | 60.4 |
| **total** | |  | **460** |  | **509** |  | **498** |  | **456** |

## Z3 calls per leg (from the sidecar's log; -version calls excluded)

| leg | calls | unsat | killed at budget | unknown | sat | other | z3 CPU-ish s (sum) | median s | p90 s | max s |
|---|---|---|---|---|---|---|---|---|---|---|
| A-z3-4.8.9-amd64-emulated | 4712 | 4699 | 13 | 0 | 0 | 0 | 520.3 | 0.098 | 0.125 | 4.96 |
| B-z3-5.4.1-amd64-emulated | 4716 | 4707 | 9 | 0 | 0 | 0 | 714.1 | 0.141 | 0.182 | 4.98 |
| C-z3-5.4.1-arm64-native | 4718 | 4709 | 9 | 0 | 0 | 0 | 76.4 | 0.005 | 0.008 | 4.95 |

## Obligations by SMT-LIB content hash

4727 distinct files in all; 4706 seen in every leg.
- A-z3-4.8.9-amd64-emulated: 4712 distinct, 6 not in every other leg
- B-z3-5.4.1-amd64-emulated: 4716 distinct, 10 not in every other leg
- C-z3-5.4.1-arm64-native: 4718 distinct, 12 not in every other leg

### Verdict differences on common obligations

6 obligations whose verdicts differ between legs.

| hash | A-z3-4.8.9-amd64-emulated | B-z3-5.4.1-amd64-emulated | C-z3-5.4.1-arm64-native | ids |
|---|---|---|---|---|
| 21d754137f73f188 | killed 4.90s | unsat 0.18s | unsat 0.01s | A-z3-4.8.9-amd64-emulated:003767; B-z3-5.4.1-amd64-emulated:003771; C-z3-5.4.1-arm64-native:003773 |
| 372479a2ff588c59 | killed 4.89s | unsat 0.16s | unsat 0.01s | A-z3-4.8.9-amd64-emulated:002502; B-z3-5.4.1-amd64-emulated:002501; C-z3-5.4.1-arm64-native:002501 |
| 4216aa23e85ecac9 | unsat 0.68s | killed 4.95s | killed 4.89s | A-z3-4.8.9-amd64-emulated:003377; B-z3-5.4.1-amd64-emulated:003381; C-z3-5.4.1-arm64-native:003383 |
| 668bf0844ef1c7df | killed 4.90s | unsat 0.80s | unsat 0.39s | A-z3-4.8.9-amd64-emulated:003373; B-z3-5.4.1-amd64-emulated:003377; C-z3-5.4.1-arm64-native:003379 |
| 8b77f924d5b385ed | killed 4.92s | unsat 0.19s | unsat 0.01s | A-z3-4.8.9-amd64-emulated:000660; B-z3-5.4.1-amd64-emulated:000660; C-z3-5.4.1-arm64-native:000660 |
| bcdc189163d39253 | killed 4.96s | unsat 2.00s | unsat 1.24s | A-z3-4.8.9-amd64-emulated:000607; B-z3-5.4.1-amd64-emulated:000607; C-z3-5.4.1-arm64-native:000607 |

### Time on common obligations proved (unsat) by every leg

4692 obligations unsat in every leg.

| leg | sum s | median s | p90 s | max s |
|---|---|---|---|---|
| A-z3-4.8.9-amd64-emulated | 455.3 | 0.098 | 0.124 | 3.14 |
| B-z3-5.4.1-amd64-emulated | 665.4 | 0.141 | 0.181 | 1.09 |
| C-z3-5.4.1-arm64-native | 30.5 | 0.005 | 0.008 | 0.66 |

B-z3-5.4.1-amd64-emulated / A-z3-4.8.9-amd64-emulated per-obligation time ratio: median 1.48, geometric-mean-ish (median of log) ; faster in 73 of 4692

C-z3-5.4.1-arm64-native / A-z3-4.8.9-amd64-emulated per-obligation time ratio: median 0.05, geometric-mean-ish (median of log) ; faster in 4683 of 4692
