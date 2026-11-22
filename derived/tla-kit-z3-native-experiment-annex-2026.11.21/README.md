# Annex to `tla-kit-z3-native-experiment-2026.11.21.md`

- `harness/`: `z3wrap.py` (mounted over the image's `z3`), `z3server.py` and `Dockerfile.sidecar` (the sidecar),
  `run-leg.sh` (inside the container), `drive.sh` and `all-legs.sh` (host), `analyze.py` (the comparison).
- `A-…`, `B-…`, `C-…`, `A0-pristine/`: each leg's `run.txt`, `leg.txt`, `summary.tsv` (module, committed count,
  this run, seconds, verdict), `z3calls.tsv` (the wrapper's log: time, client seconds, server seconds, exit code,
  first line, bytes, sha256 prefix, server id) and `z3server-calls.tsv` (the server's log: id, seconds, exit code,
  first line, bytes, sha256 prefix; killed calls appear here and not in the wrapper's log).
- `analysis.md`: `analyze.py`'s output over the four legs.
- `differing/`: the six obligations whose Z3 verdicts differ, as `<sha256 prefix>.smt2` with each leg's output
  `<sha256 prefix>.<leg>.out` (first line: exit code and seconds; `-9` is killed at `tlapm`'s budget).
- `all-legs.txt`: the runner's log with start and end times.
