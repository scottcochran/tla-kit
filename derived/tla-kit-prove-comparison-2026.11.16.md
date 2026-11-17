# tla-kit: `tlapm` per request against `tlapm_lsp`, for the `prove` tool, 2026.11.16

> **Provenance note.** Written 2026.11.16 by the assistant, at the custodian's direction to start Phase 4 of
> `PLAN.md`, on branch `phase4-compare` after `1d57852`. It is ADR-0009 item 5's comparison: drive `tlapm` per
> request, or drive `tlapm_lsp`, whichever is simpler and passes the same tests. ADR-0016 waits on it. Every run
> was made in the published image `v0.2.0`, `ghcr.io/scottcochran/tla-kit@sha256:5554015f…1e5d`, which holds `tlapm`
> and `tlapm_lsp` at `ff40755`, on the skill's fixture `Counter_proof.tla` and on a copy with one step broken. The
> source of `tlapm_lsp` was read at `ff40755` through the GitHub API (`lsp/README.md`, `lsp/lib/prover/prover.ml`,
> `lsp/lib/server/handlers.ml`). The raw output is in the annex beside it,
> [`tla-kit-prove-comparison-annex-2026.11.16/`](tla-kit-prove-comparison-annex-2026.11.16/). It recommends, and
> section 7 records the custodian's choice.

## 1. The question

ADR-0009 item 3 asks the `prove` tool for each unresolved obligation with its text, the backends tried and the
reason; a theorem named and resolved to lines by the server; the image's pinned `tlapm`; a cache the server owns,
never beside the module; and the whole process group killed on cancel or timeout. Item 5 asks whether to get there
by running `tlapm` for each request, or through `tlapm_lsp`, which already resolves a cursor to its obligations.

## 2. What was run

The broken step is `NextBounded` (lines 12 to 15) with its `BY` cut to `BY DEF Bounded`
(`broken-step.diff`).

| Run | Command | Outcome | Annex |
|---|---|---|---|
| The module, as it is | `tlapm --toolbox 0 0 --cache-dir /tmp/c --threads 2 Counter_proof.tla` | Exit 0 in about 1 s. 19 obligations proved: 9 by a backend, 10 trivial. | `toolbox-proved-module.txt` |
| The broken module | the same | **Exit 0** in about 6 s. `[ERROR]: 1/18 obligations failed.` | `toolbox-broken-module.txt` |
| The broken step's lines | `tlapm --toolbox 12 15 ...` | Exit 0. `[ERROR]: 1/1 obligation failed.` | `toolbox-broken-range-12-15.txt` |
| The same, protocol version 2 | `tlapm --toolbox 12 15 --toolbox-vsn 2 ...` | The same, with one more record listing the provers | `toolbox-broken-range-12-15-vsn2.txt` |
| `tlapm_lsp` | An LSP client (`lsp_probe.py`): `initialize`, `didOpen` with the broken module, then `workspace/executeCommand` `tlaplus.tlaps.check-step.lsp` with the cursor on line 15 | The request answered `null` at once. The failure arrived 6 s later as a diagnostic and as proof-step markers, with progress notifications. | `lsp-messages.json` |
| Names to lines | SANY's XML exporter on the proof module, with `-I /opt/tlaps/lib/tlapm/stdlib` | The line span of every named theorem and every step | `theorem-spans.txt` |
| Ranges inside a proof | `tlapm --toolbox 20 21`, `21 21`, `17 25` on the module as it is | 6, 6 and 18 obligation records: the step `<1>1`, the same, and the whole of `BoundedAlways` | (counts only) |

## 3. What each route gives

**`tlapm` per request, Toolbox protocol.** Each obligation is a `@!!BEGIN` … `@!!END` block. On a failure it holds
the location, `status:failed`, the `prover` (SMT, Zenon, Isabelle), its `meth` (time limit and time used), the
`reason` (`timeout` for SMT, `false` for Zenon and Isabelle) and, under `obl`, the obligation's text. Proved and
trivial obligations carry no text. The run ends with an `[ERROR]` or `[INFO]` summary line.

**`tlapm_lsp`.** It is an adapter over the same route. For each check it starts
`tlapm --toolbox FROM TO --toolbox-vsn 2 --printallobs --prefer-stdlib --stdin MODULE`, in the module's directory,
reads the Toolbox protocol, and reports the result to an editor:
- a diagnostic whose message is `Obligation: failed` and the obligation's text;
- proof-step markers, `pending` or `failed`, each over a step's range, with hover text;
- progress, `0 of 1` to `1 of 1 obligations checked`.

What it adds is the editor's view: it turns a cursor into a step's range, and tracks a document's versions.

## 4. Findings

1. **The text of a failed obligation is in both.** It is the Toolbox protocol's `obl` field, and `tlapm_lsp`
   passes it on.
2. **The backends tried and the reasons are only in the per-request route.** `tlapm_lsp`'s diagnostic drops
   `prover`, `meth` and `reason`: it does not say that SMT timed out at 5 s, or that Zenon and Isabelle found the
   goal false. ADR-0009 item 3 needs both.
3. **`tlapm_lsp` writes its cache into the project, and it could not be moved.** It passes no `--cache-dir`, and
   runs `tlapm` in the module's directory. `.tlacache/` appeared beside the module in both runs, and setting
   `TLAPM_CACHE_DIR` in its environment did not move it. Why was not traced: the `tlapm` it starts either did not
   receive the variable or did not use it.
   ADR-0006 item 3 and ADR-0009 item 3 forbid this. The only way around it would be to run `tlapm_lsp` on a copy of
   the project. Per request, `--cache-dir` (or `TLAPM_CACHE_DIR`) puts the cache where the server wants it.
4. **Naming a theorem needs no cursor.** SANY's XML exporter gives the span of each named theorem and step:
   `NextBounded` 12 to 15, `BoundedAlways` 17 to 25, its `<1>1` 20 to 21. `--toolbox FROM TO` over a step's span
   proves that step: 20 to 21, and 21 alone, gave the 6 records of `<1>1`. What `tlapm_lsp` adds can be done in the
   server with a tool it already runs.
5. **`tlapm` exits 0 when an obligation fails.** Success has to be read from the output: no `[ERROR]` line, no
   `failed` status, and a non-zero obligation count. ADR-0009 item 3's "success also needs exit 0" is necessary, and
   far from enough. `marco6/tlapm-mcp` `v0.0.1` already reads the output this way (ADR-0009, Context).
6. **`tlapm_lsp` runs one prover at a time, and cancels with `SIGINT` to `tlapm` alone.** Starting a check cancels
   the one before. The signal goes to `tlapm`'s process, not its process group, so backends could outlive a cancel.
   That is one of ADR-0016 item 6's assumptions to test, and the per-request route would own the process group
   itself.
7. **`tlapm_lsp` is asynchronous, and was fragile to a client.** A check answers `null`, and the result arrives as
   notifications that the server would have to wait for and collect. A `shutdown` request with `"params": null`,
   which the probe sent, made it exit with an uncaught exception (`Jsonrpc: json conversion failed: invalid
   structured value`). The probe's request was the trigger, but a server built on it would have to guard against
   that.
8. **Phase 3's `parse` and `symbols` miss the prover's library.** A proof module extends `TLAPS`, which SANY finds
   only with `-I /opt/tlaps/lib/tlapm/stdlib`. Without it the exporter wrote nothing for `Counter_proof.tla`. The
   server's `parse` and `symbols` do not pass it, so they would fail on any proof module. This is outside the
   comparison, and needs a fix of its own.

## 5. Recommendation

**Drive `tlapm` per request**, with `--toolbox FROM TO`, `--cache-dir` in a directory the server owns, and the
process started in a group of its own. Read the Toolbox protocol, version 2 as `tlapm_lsp` does, for the provers
record. Resolve a theorem's name, or a line, to a span from SANY's XML. Judge success from the output, not the exit
status. That is, ADR-0009 items 2 to 4 as written.

`tlapm_lsp` would not pass the same tests. It loses the backends and reasons that item 3 requires, it writes its
cache into the project, and its cursor resolution is the one part the per-request route lacks, which the server can
do with SANY. It would also add an asynchronous LSP session to manage inside the MCP server.

For ADR-0016, the per-request route means: one `tlapm` process group per `prove` call, a cache directory the server
owns, and the server's own choice of whether two calls may share it. Its item 6 assumptions are then about `tlapm`
alone: a shared cache, backends in the group, and what a kill leaves.

## 6. Not done

- No assumption of ADR-0016 item 6 was tested: not a shared cache, not where backends run, not a kill.
- `--printallobs`, which `tlapm_lsp` passes, was not tried. It may give the text of every obligation, not only
  failed ones, which `proof_check` could use.
- Only one broken step, of one module, was run. TOPAK's proof modules were not.

## 7. The choice

The custodian chose the per-request route on 2026.11.16, as section 5 recommends. ADR-0009's History records it,
and ADR-0016 is brought into line with it.
