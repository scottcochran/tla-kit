# tla-kit: a native arm64 Z3 under the emulated `tlapm`, compared with the packaged Z3, 2026.11.21

> **Provenance note.** Written 2026.11.21 by the assistant, at the custodian's direction to run an experiment: prove
> TOPAK's proof modules with the Z3 that tla-kit packages (4.8.9, x86_64, under emulation on Apple Silicon) and with
> a Z3 that runs in a Docker container on the same Mac without emulation, upstream's `z3-5.4.1` Linux arm64 build.
> It was written on `main` after `a53425b`, in the working tree, and is not committed. Every run was made in the
> local image `tla-kit:9a52faf` (`ad31db45d0aa`, `tlapm` 9a52faf, binary `faa92f26…2cc0`), on TOPAK at `b556e52`,
> its `spec/` mounted read-only. The raw output, the harness and the obligations whose verdicts differ are in the
> annex beside it, [`tla-kit-z3-native-experiment-annex-2026.11.21/`](tla-kit-z3-native-experiment-annex-2026.11.21/).
> It decides nothing.

## 1. The question

tla-kit's image is `linux/amd64`, and on Apple Silicon it runs under emulation (README, Limits). `tlapm` runs Z3 as
a backend some thousands of times over TOPAK's proofs. If Z3 ran natively, how much of the run would come back, and
would the proofs give the same result under a Z3 five major versions newer?

## 2. The machine

| | |
|---|---|
| Host | Apple M4 Pro, macOS 26.6.2 |
| Docker | Docker Desktop 4.53.0, engine 29.0.1, 12 CPUs and 8 GB for the VM |
| Emulation | Rosetta: an amd64 container maps `rosetta/rosetta` into every process, and `/proc/cpuinfo` reads `VirtualApple @ 2.50GHz` |

## 3. How Z3 was swapped

`tlapm` does not take a Z3 path. `tlapm --config` shows that it runs
`PATH='/opt/tlaps/lib/tlapm/backends/bin:…'; z3 -smt2 -v:0 AUTO_CONFIG=false smt.MBQI=true "$file"`, with that
directory first on the path. `--solver` and `TLAPM_SMT_SOLVER` change only the `smt` method's command, not the `z3`
method's, so neither was used. Instead a Python script (`harness/z3wrap.py`) was bind-mounted over
`/opt/tlaps/lib/tlapm/backends/bin/z3`. It sends Z3's arguments and the SMT-LIB file over TCP to a Z3 server in a
sidecar container (`harness/z3server.py`, `harness/Dockerfile.sidecar`: Ubuntu 24.04 with the Z3 binary), which
runs the real Z3 with the same arguments on a copy of the file and answers with its exit code and output. If `tlapm`
kills the call at its time budget, the socket closes and the server kills its Z3. The sidecar logs every call with
its time, exit code, first line of output and the file's sha256, which is how the legs are joined obligation by
obligation. TOPAK's proofs never name `Z3` as a method (209 uses of `PTL`, 10 of `Isa`, none of `Z3` or `SMT`), so
the mount covers every SMT call.

Three sidecars were built from one Dockerfile, so that the only difference between legs is the Z3 binary and the
platform it runs on:

| Leg | Z3 | Platform of the sidecar | Binary sha256 |
|---|---|---|---|
| A | 4.8.9, the image's own, copied out of `/opt/tlaps/lib/tlapm/backends/bin/z3` | `linux/amd64`, emulated | `4321b0c0…1436` (PINS.json) |
| B | 5.4.1, `z3-5.4.1-x64-glibc-2.39.zip` (zip `b548bac4…9d85`) | `linux/amd64`, emulated | `2bb3e9e7…a59e` |
| C | 5.4.1, `z3-5.4.1-arm64-glibc-2.38.zip` (zip `9e8f781f…050f`) | `linux/arm64`, native | `bb00f9bc…24ca` |
| A0 | 4.8.9 in the image, no wrapper and no sidecar | emulated, as tla-kit runs today | |

The zips are release `z3-5.4.1` of `Z3Prover/z3` (published 2026-11-11, commit `145c0c5`); their digests match the
ones GitHub's API gives for the assets. Each leg ran `harness/run-leg.sh` inside the tla-kit container: for each of
the 35 `<M>_proof.tla`, `tlapm --cleanfp --strict --cache-dir <tmp> <M>_proof.tla`, as TOPAK's `proof-results.sh`
and the spike's `prove-all.sh` do, with the obligation count compared with the newest committed results file. The
legs ran one after another, A, C, B, then A0, between 02:40 and 03:14 UTC on 2026-11-22.

## 4. Findings

**F-1. Every leg proved every module, with the committed counts.** 35 of 35 modules `SAME` in all four legs,
14,791 obligations each. Z3 5.4.1, native or emulated, changes no proof's outcome under this `tlapm`.

**F-2. Native Z3 is about twenty times faster per call, and the run is about one tenth shorter.** Over the 4,692
obligations that every leg's Z3 proved (`unsat`), the per-call time was:

| Leg | Sum s | Median s | p90 s | Max s |
|---|---|---|---|---|
| A, 4.8.9 emulated | 455.3 | 0.098 | 0.124 | 3.14 |
| B, 5.4.1 emulated | 665.4 | 0.141 | 0.181 | 1.09 |
| C, 5.4.1 native | 30.5 | 0.005 | 0.008 | 0.66 |

C was faster than A on 4,683 of the 4,692, median ratio 0.05. Yet `tlapm`'s wall time over the 35 modules was 509 s
in A and 456 s in C: Z3 is about a tenth of the run under emulation (A's Z3 time, summed over 12 threads, is 52 s of
its 509), and about 2% of it when native. The rest is `tlapm` itself, Zenon, Isabelle and LS4, all still emulated.
`Mesh`, the slowest module at 106 to 113 s, spends under 5% of its time in Z3 in any leg.

**F-3. Against tla-kit as it is, the native Z3 gains almost nothing.** A0, the untouched image, took 460 s, 4 s
more than C. The wrapper costs about 50 s over a run (A's 509 against A0's 460): a Python start under emulation for
each of some 4,700 calls, spread over 12 threads. In this harness the native Z3 recovers that cost and no more.
A Z3 swap without the wrapper (a native binary that `tlapm` could exec directly) would gain at most the ~50 s of
F-2, a tenth of the run.

**F-4. Z3 5.4.1 under emulation is slower per call than 4.8.9, with no effect on the run.** Median 0.141 s against
0.098 s, slower on 4,619 of 4,692 obligations. The binary is larger (42 MB against 27 MB), and most calls are too
short for the solver to matter: under Rosetta each call pays to translate the code it touches. B's run was 498 s,
A's 509 s; the difference is within what F-5 explains.

**F-5. Six obligations change Z3 verdict between versions. All are proved anyway, by another backend.** Z3 4.8.9
reached `tlapm`'s 5 s budget on 13 calls, 5.4.1 on 9 (in both B and C, the same 9). Eight obligations time out
under every Z3: six in `RulesFloorNV_rev5_proof.tla` (lines 115, 120, 122, 124, 126, 160), `Lease_A1_proof.tla`
line 301 and `Seats_proof.tla` line 73. The six that differ:

| Obligation | Z3 4.8.9 (A) | Z3 5.4.1 emulated (B) | Z3 5.4.1 native (C) |
|---|---|---|---|
| `Correlator_proof.tla` line 518 (#449) | killed at 4.96 s | unsat 2.00 s | unsat 1.24 s |
| `Coupling_proof.tla` line 144 (#170) | killed at 4.92 s | unsat 0.19 s | unsat 0.01 s |
| `Operators_proof.tla` line 134 (#81) | killed at 4.89 s | unsat 0.16 s | unsat 0.01 s |
| `Release_proof.tla` line 102 (#15) | killed at 4.90 s | unsat 0.80 s | unsat 0.39 s |
| `RunCoupling_proof.tla` line 222 (#276) | killed at 4.90 s | unsat 0.18 s | unsat 0.01 s |
| `Release_proof.tla` line 112 (#28) | **unsat 0.68 s** | **killed at 4.95 s** | **killed at 4.89 s** |

Where Z3 gave up, `tlapm` went on to Zenon or Isabelle and proved the step, so every module's count held (F-1). The
five that 5.4.1 proves explain why `Coupling`, `RunCoupling` and `Operators` are the modules whose wall time fell
most in B and C (7.1 → 3.3 → 2.4 s, 7.8 → 4.4 → 3.3 s, 14.1 → 9.6 → 8.6 s). The one that 5.4.1 loses is a
regression for that obligation only. Each file and each leg's output is in `differing/`, named by the file's hash.

**F-6. The two Z3 5.4.1 builds agree.** B and C, the same version on two architectures, gave the same verdict on
every one of the 4,706 obligations seen in every leg, including the same 9 timeouts. The arm64 build is not a
different solver.

**F-7. The obligations themselves are stable across runs.** 4,706 of 4,727 distinct SMT-LIB files were seen in
every leg; the 21 others are files only one or two legs produced (6, 10 and 12 per leg), which is `tlapm` taking a
different route after an earlier backend's outcome differed, not Z3 receiving different input for the same step.

## 5. Limits

- The test is of one `tlapm` (9a52faf) over one corpus (TOPAK at `b556e52`). The 5 s SMT budget is `tlapm`'s
  default; a longer one would move the timeouts of F-5.
- 4.8.9 was not run natively: upstream publishes no Linux arm64 build of it, so version and architecture are
  separated only through 5.4.1 (B against C), not through 4.8.9.
- Each leg ran once. Wall times vary by a few percent between runs on this machine, so differences under 5%
  between legs are not findings.
- The per-call times are measured in the sidecar around Z3's process; the wrapper adds about 10 ms on the
  client side to each, which F-3 accounts for and the per-call tables do not include.
- Nothing here was run on Linux x86_64, where none of it is emulated.

## 6. What this says for tla-kit

Z3 is not where the emulated run's time goes. Making Z3 native, by a sidecar or by an arm64 binary in the image,
would return at most a tenth of a proof run on Apple Silicon. The time is in `tlapm` and its other backends, which
is the case for `PLAN.md`'s "A Linux arm64 build of `tlapm` from source", not for a Z3 swap. Moving to Z3 5.4.1 is
a separate question: it changes no outcome here, speeds the solver natively but slows it under emulation, and moves
six obligations between backends, one of them to Z3's loss.
