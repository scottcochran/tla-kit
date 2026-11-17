# tla-kit: Phase 4's "Done when", checked on `v0.3.0`, 2026.11.17

> **Provenance note.** Written 2026.11.17 by the assistant, at the custodian's direction to write up Phase 4, on
> branch `phase4-done` after `4aee1f5`. It records the checks of `PLAN.md` Phase 4's "Done when" on the third
> release, `v0.3.0`, `ghcr.io/scottcochran/tla-kit@sha256:948e6d1f…257f`, built from `4aee1f5`. One condition needed
> a run of its own: an agent repairing a broken step with only the server's tools. It was made on 2026.11.17, with
> the model and the tools the custodian chose. The other three were checked in CI, and the module's rows again in the
> published image. The annex beside it,
> [`tla-kit-phase4-checks-annex-2026.11.17/`](tla-kit-phase4-checks-annex-2026.11.17/), holds the agent's prompt,
> configuration and transcript, the diffs, and the raw output of the checks. It decides nothing.

## 1. The four conditions

| Condition (`PLAN.md`, Phase 4) | Where it was checked | Result |
|---|---|---|
| An agent using only these tools repairs a deliberately broken step in the fixture | In `v0.3.0`, on 2026.11.17 (section 2) | Repaired in three `prove` calls. The repaired module is the fixture byte for byte, and `tlapm` run directly proves its 19 obligations |
| `proof_results` through the server writes the file the script writes | `server/test_prove.py`, in the images CI built for pull request #22 (run 44030562024, `2019240`) and for `main` at `4aee1f5` (run 44033259889) | The script, run directly, reproduced the server's file byte for byte |
| Every `ProveRequests` row has its expected outcome | `tools/ci/pinlifecycle.sh … ProveRequests`, in `v0.3.0` on 2026.11.17 (`proverequests-rows.txt`), as in `v0.2.0` for pull request #19 (run 44001355558) | 78 rows, 78 as expected, and `spec/ProveRequests-results-2026.11.16.txt` reproduced byte for byte, in 56 s on 10 workers under emulation |
| The tests of ADR-0016 item 7 pass | `server/test_prove.py`, in CI for pull requests #21 (run 44026231569, `ef75d5d`) and #22, and for `main` at `4aee1f5` | All passed: one module twice takes turns, two modules run side by side, a cancel during a run or while waiting for the cache gets no response, a cancel after the response changes nothing, a timeout kills the whole group, and no backend is left alive or unreaped |

`main` at `4aee1f5` is the commit of `v0.3.0`. CI's two runners built it to the digest the release published, so
the image the release workflow tested and published is the one CI reproduced. The release workflow itself runs the
self-test, not `test_prove.py`.

## 2. The agent's repair

### How it was run

- **The project:** a fresh directory with the skill's fixture in `spec/`: `Counter.tla`, `Counter-rows.txt`, and
  `Counter_proof.tla` with one step broken, as `server/test_prove.py` breaks it. `NextBounded`'s proof,
  `BY LimitNat DEF TypeOK, Bounded, Next, Step, vars`, became `BY DEF Bounded` (`broken-step.diff`).
- **The agent:** Claude Code 2.1.312, `claude -p`, model `claude-opus-5-5`, the custodian's choice.
- **The tools:** the server's 14 and `Read` and `Edit`, the custodian's choice. With `Edit` the agent can change the
  module, and without it no agent could repair one. The session's tool list was those 16 and nothing else.
  `--restricted` removes the tools that run commands, ignores settings files and confines the file tools to the
  project. `--strict-mcp-config` makes tla-kit the only MCP server, and `--permission-mode dontAsk` refuses any tool
  not on the list (`run.sh`).
- **The server:** started with the README's command, `docker run -i --rm --user … -v <project>:/work`, at the
  published digest (`mcp.json`).
- **The prompt** (`prompt.txt`) said that one step of `spec/Counter_proof.tla` was broken, but not which. It allowed
  changes to proofs only, not to statements or to `Counter.tla`. The agent was done when `prove` on the whole module
  reported success.

### What it did

It ran for 28 s over 8 turns, cost $0.15, and no tool call was refused (`summary.txt`).

| Call | What came back | What the agent did next |
|---|---|---|
| `prove` on the whole module, then `Read` of it | `failed`: 18 obligations, one failed at line 15. Its text was `TypeOK /\ ~over /\ [Next]_vars => (~over)'` under `Mut # "M_NOLIMIT"`. SMT timed out at 5 s; Zenon and Isabelle failed | Read `Counter.tla`, and added `TypeOK, Next, Step, vars` to the `DEF`s, the list `TypeNext` uses |
| `prove` on the whole module | `failed`, the same step. The text now had `Next` and `Step` opened: `n < Limit /\ n' = n + 1 /\ over' = (over \/ n >= Limit)` | Said the prover needs `Limit \in Nat` to get `~(n >= Limit)` from `n < Limit`, and added `LimitNat` |
| `prove` on the whole module | `proved`: 19 obligations, 8 of them from the server's cache, in 0.5 s | Stopped, and named the step, what was wrong and what it changed |

The repaired module is the fixture byte for byte (`repair.diff`), and `Counter.tla` is unchanged. Proved directly,
outside the server, in `v0.3.0` with `tlapm --cleanfp --strict` and no cache, all 19 obligations are proved
(`tlapm-direct.txt`). Nothing was written into the project but the edit: the server kept its cache outside it.

## 3. Findings

1. **The obligation's text is what led to the repair.** The first failure showed the goal with only `Bounded`
   opened, which says the `DEF`s are missing. The second showed `Next` and `Step` opened, with `n < Limit` and
   `n >= Limit` side by side, which says a fact about `Limit` is missing. Line numbers and a verdict would have found
   the step, not what it lacked. The text, the backends and their reasons are ADR-0009 item 3's first change from
   `marco6/tlapm-mcp`.
2. **The agent never named the step.** It proved the whole module each time and took the step from the failed
   obligation's location. Proving by theorem name, by line and by range is tested by `server/test_prove.py`, not
   here.
3. **The server's cache paid off within the session.** The second and third runs read 8 results from it, and the
   third took 0.5 s against 6.1 s for the first.
4. **This is an easy repair.** One step of a 39-line fixture lost two things, the definitions and one assumption,
   and the agent restored them in two edits. Its first edit, by analogy with `TypeNext`, was not enough, and the
   tool's answer said why.

## 4. Not done

- One run, of one model. It was not repeated, and no other model was tried.
- One broken step, in the fixture. Nothing from TOPAK's proof modules, whose steps are longer and whose repairs can
  need new lemmas.
- The agent did not run `proof_results`, `flip_test` or `proof_sync`. The project had no `tools/TLAPS-PIN`, and the
  prompt did not ask for them. `server/test_prove.py` covers them.
- Phase 5: the skill does not declare the server yet, and no Actions job has run an agent against it.

## 5. The annex

| File | What it is |
|---|---|
| `prompt.txt`, `mcp.json`, `run.sh` | The agent's prompt, its MCP configuration and the command, with the local directory as `<run>` and the uid and gid as `<uid>:<gid>` |
| `broken-step.diff`, `repair.diff` | The fixture against the broken module, and the broken module against the agent's |
| `transcript.jsonl` | The session as `--output-format stream-json` gave it, redacted: the local directory is `<run>`, and from the first message the keys that list this machine's own setup (skills, plugins, slash commands, agents, capabilities, start-up timings, the scratchpad path, analytics flags, the API key source) are removed, as is one rate-limit event. The tool list, the model, the permission mode and the MCP server's status are kept. The unredacted file's sha256 was `ab8193b5e9bb60bf3c47693083b8db73f22bd78807cefcd8ae7c4f88ae6a480b` |
| `summarize.py`, `summary.txt` | The script that reads the transcript into its calls and answers, and its output |
| `tlapm-direct.txt` | `tlapm --cleanfp --strict` on the repaired module, in `v0.3.0`, outside the server |
| `proverequests-rows.txt` | `tools/ci/pinlifecycle.sh` on `spec/ProveRequests-rows.txt`, in `v0.3.0` |
