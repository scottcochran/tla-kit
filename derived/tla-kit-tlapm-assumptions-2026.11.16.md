# tla-kit: three assumptions about `tlapm`, tested in the image, 2026.11.16

> **Provenance note.** Written 2026.11.16 by the assistant, at the custodian's direction to run Phase 4's second
> step, on branch `phase4-assumptions` after `167ea7a`. It is ADR-0016 item 6: each assumption about `tlapm` is
> tested in the image before the row of `spec/ProveRequests.tla` that relies on it is fixed. Every run was made in
> `v0.2.0`, `ghcr.io/scottcochran/tla-kit@sha256:5554015f…1e5d` (`tlapm` `ff40755`), by one script,
> `assumptions.py`, on the fixture's proof module with `NextBounded` broken, under two module names. The annex beside
> it, [`tla-kit-tlapm-assumptions-annex-2026.11.16/`](tla-kit-tlapm-assumptions-annex-2026.11.16/), holds the script
> and its output. It decides nothing.

## 1. How it was run

Each run proves the broken step (`--toolbox 12 15`) with `--stretch 3`, so that SMT's 5 s time limit becomes 15 s and
the run lasts long enough to watch and to kill. `tlapm` is started in a session of its own, as the server would start
it, with `--cache-dir` under `/tmp`. Processes are read from `/proc`: each descendant of `tlapm`, its process group,
its session and its state, sampled every 0.05 s.

The script ran twice:
- **without an init** (`run-without-init.json`): the script is PID 1 in the container, as the server is when a client
  starts `docker run … tla-kit mcp`;
- **with `docker run --init`** (`run-with-init.json`): an init at PID 1 reaps orphans.

A first run that did not record states (`first-run-without-states.json`) reported dead processes as alive. Section 3
says why. Nothing was written into the project in any run.

## 2. The three assumptions

| Assumption (ADR-0016 item 6) | Without an init | With `--init` |
|---|---|---|
| **Every backend stays in `tlapm`'s process group** | Yes: `sh`, `z3`, `zenon`, Isabelle's `poly`, and `cat`, `ps`, `rm`, all in `tlapm`'s group and session | Yes: the same, with `ls` and `tail` |
| **Nothing outlives `tlapm`'s own end** | No live process; one zombie `z3`, dead but not reaped | Nothing at all |
| **A kill of the whole group (`SIGKILL`) stops every backend** | Yes: no live process after it | Yes |
| **A kill of `tlapm` alone stops its backends** | **No**: `sh` and `z3` kept running (state `R`) | **No**: the same |
| **A killed run leaves a usable cache** | The cache's `.thy` and `fingerprints` were empty, and an SMT temp file was left. The next run on that cache ended with the same statuses as a clean run. | The same |
| **Two processes can share one cache directory, on one module** | Both runs ended with the right statuses. A third run on that cache read 3 results from it. | The same |
| **Two processes can share one cache directory, on two modules** | Each module has its own subdirectory, `<Module>.tlaps/`, so they wrote no file in common. Both were right, and so was a third run on each. | The same |

## 3. Findings

1. **The process group is the unit to kill.** Every process `tlapm` started stayed in its group, and a `SIGKILL` to
   the group left nothing running. A `SIGKILL` to `tlapm` alone left `z3` running after its request was over. That
   is how `marco6/tlapm-mcp` `v0.0.1` stops `tlapm` on a timeout, by Go's `exec.CommandContext`. (`tlapm_lsp` sends
   `SIGINT` to `tlapm` alone, which was not tried.) ADR-0016's naive row, "the kill sent to `tlapm` alone", is a
   real failure, not a theoretical one.
2. **A server at PID 1 has to reap.** When `tlapm` is killed or exits, its children are re-parented to PID 1. If the
   server is PID 1, as it is under `docker run -i --rm … tla-kit mcp`, and does not reap them, they stay as zombies.
   They use no CPU, but they hold process table entries, and a probe of `/proc` takes them for live processes. Either
   the client command gains `--init` (ADR-0008 item 2), or the server reaps every child, not only `tlapm`.
3. **A kill costs the cache, not correctness.** A killed run left the module's `.thy` and `fingerprints` empty and
   an SMT temp file behind. The next run proved the step again and got the clean run's result. So a kill loses what
   the cache held for that module, and leaves a little garbage, but did not make a later answer wrong.
4. **Sharing a cache across modules is sharing nothing.** The cache is one subdirectory per module proved. Two
   modules that extend a shared module still have separate subdirectories.
5. **Two runs of one module on one cache gave no visible conflict, which proves little.** Both wrote the same
   results, and the cache that was left worked. Nothing seen shows that `tlapm` locks the cache. Two runs that
   cover different steps of one module, or different results, could overwrite each other's fingerprints, and that
   was not tried. The safe reading is ADR-0016's invariant as written: one writer per cache directory, which for
   `tlapm` means one run per module at a time.

## 4. What it means for `spec/ProveRequests.tla`

- **Processes:** a backend is in `tlapm`'s group. The row "a backend that leaves the process group" stays as ADR-0016
  item 5 asks, as a stated choice, but nothing seen here does so.
- **Kill:** the chosen design kills the group, and the naive design's kill of `tlapm` alone leaves a backend alive.
  Both are now observed, not assumed.
- **Cache:** one run at a time per module directory. A kill empties that module's cache, and the next run is still
  right.
- **Answer:** `tlapm` ending, by itself or by a kill, leaves nothing running once its children are reaped.

## 5. Not done

- Runs on different steps of one module, on one cache, at the same time.
- `SIGINT` and `SIGTERM`, which `tlapm` may handle by stopping its backends itself. Only `SIGKILL` was sent.
- More than two runs at once, and TOPAK's proof modules, whose runs are longer.
