# tla-kit: Phase 5's "Done when", one configuration locally and in Actions, 2026.11.17

> **Provenance note.** Written 2026.11.17 by the assistant, at the custodian's direction to write up Phase 5, on
> branch `phase5-done` after `e80350f`. It records the check of `PLAN.md` Phase 5's "Done when": one configuration
> serves a local session and an Actions job against the same project. The configuration is the
> `writing-tla-specs-and-proofs` plugin at TOPAK `2db08ff` (TOPAK pull request #88), whose `.mcp.json` declares the
> server at `v0.3.0`, `ghcr.io/scottcochran/tla-kit@sha256:948e6d1f…257f`. The job is tla-kit's
> `examples/agent-repair/`, run locally and by `.github/workflows/agent.yml` (pull request #24, merged as `e80350f`).
> The model and the tools are the custodian's choices for Phase 4. The annex beside it,
> [`tla-kit-phase5-checks-annex-2026.11.17/`](tla-kit-phase5-checks-annex-2026.11.17/), holds each run's transcript,
> check and diff, and the probe's environment. It decides nothing.

## 1. What was checked

One configuration, used unchanged in both places:
- **The plugin** at TOPAK `2db08ff`. Its `.mcp.json` starts the server with `sh -c`, so that `docker run` gets
  `--user "$(id -u):$(id -g)"` and mounts the repository's root, from `git rev-parse --show-toplevel`.
- **The project:** `make-project.sh` makes a git repository holding the skill's fixture, with `NextBounded`'s proof
  cut to `BY DEF Bounded`, as `server/test_prove.py` and Phase 4's record break it.
- **The agent:** `run.sh` runs Claude Code 2.1.312, `claude -p`, with model `claude-opus-5-5` and `--plugin-dir`
  set to the plugin. It allows `Read`, `Edit` and each of the server's fourteen tools in `--allowedTools`, with
  `--restricted`, `--tools Read,Edit` and `--permission-mode dontAsk`. The prompt is Phase 4's: one step is broken,
  not which, and only proofs may change.
- **The check:** `check.py` looks at the outcome, not at what the agent says:
  - the session declared the plugin's server;
  - the server answered every call made to it;
  - the last `prove` of the whole module succeeded;
  - only `spec/Counter_proof.tla` changed, and only inside its proofs;
  - `tlapm --cleanfp --strict`, run directly in the image the plugin names, outside the server and with no cache,
    proves the module.

## 2. The runs

| Run | Where | Server at the session's start | The agent | The repair | `tlapm` directly | The check |
|---|---|---|---|---|---|---|
| `local` | This machine, the plugin checked out at `2db08ff` | connected, 14 tools | 8 turns, 30 s, $0.13 | `BY LimitNat DEF Bounded, TypeOK, Next, Step, vars` | 19 obligations proved | passed |
| `actions-1` | Run 44079109066, at `67909b5` | connected, 14 tools | 8 turns, 26 s, $0.11 | A structured proof: `SUFFICES`, then `CASE Next` with `~(n >= Limit)` from `LimitNat`, and `CASE UNCHANGED vars` | 31 obligations proved | failed at the time; passes now |
| `actions-2` | Run 44079703254, at `94a1e43` | pending, no tools listed | 8 turns, 27 s, $0.10 | `BY LimitNat DEF TypeOK, Bounded, Next, Step, vars` | 19 obligations proved | failed at the time; passes now |
| `actions-3` | Run 44080090637, at `09a8e92` | pending, no tools listed | 8 turns, 29 s, $0.10 | `BY LimitNat DEF Bounded, TypeOK, Next, Step, vars` | 19 obligations proved | passed |

Every run used the same plugin commit and the same image, and in every run nothing was refused. Each agent found
the step from `prove`'s answer and repaired it. `actions-2`'s repair is the fixture's own line. `local`'s and
`actions-3`'s are the same as each other, with the definitions in another order. The `actions-3` agent proved
with `nofp`, ignoring the cache's earlier results.

`actions-1` and `actions-2` failed on faults in the check, not in the repairs. Each fault was fixed by its own
commit in pull request #24, and the check as merged passes both (`check-now.txt` beside `check-at-the-time.txt`):
- **`actions-1`** (fixed in `94a1e43`): the check required each changed line to look like a proof line, indented.
  The agent wrote its steps at the margin (`<1> SUFFICES …`). The check now takes every proof out of the module
  before and after, and requires the rest to be the same. It fails a weakened statement and an added lemma, which
  were tried by hand.
- **`actions-2`** (fixed in `09a8e92`): the check required the session's first message to show the server
  connected with fourteen tools. Claude Code connects MCP servers in the background, and that message came first.
  The check now requires the server to have answered every call made to it, and checks the fourteen tools only
  when the first message lists them.

## 3. Findings

1. **A plugin declares the server, and a `docker run` command serves as one.** These are the two things ADR-0008's
   Consequences recalled and did not check. Claude Code started the server from the plugin's `.mcp.json` in every
   session, on macOS with Docker Desktop and on GitHub's `ubuntu-24.04` runner, where the uid is 1001.
2. **The project is the repository's root, not the session's directory.** In a probe whose server wrote out its
   environment, a session started in `project/sub` gave the server `PWD` and `CLAUDE_PROJECT_DIR` both as
   `project/sub` (`probe-env.txt`). So the declaration asks git for the root, and a session started in `spec/`
   (on the TOPAK branch, before #88 merged) still mounted the project.
3. **What confines the agent is `--allowedTools` and `--permission-mode dontAsk`.** `--strict-mcp-config` would
   drop the plugin's server along with the rest. Locally, the account's own connectors loaded too, and the session
   listed 38 tools against 16 in Actions. `dontAsk` refused everything not on the list, and no run tried any.
4. **The first message is not the session's state.** In two of the three runs in Actions, the plugin's server was
   still pending when the session's first message was written, and the agent's first call to it came after it
   connected. A check of an agent job has to look at the calls, not at that message.
5. **The same configuration gives different repairs.** One run in four wrote a structured proof of 31 obligations
   where the others extended a `BY` to 19. A check that compares text with a known answer would have failed a valid
   repair. The check compares what lies outside the proofs, and leaves the proofs to the prover.
6. **The tools are named for the plugin**: `mcp__plugin_writing-tla-specs-and-proofs_tla-kit__<tool>`. An
   `--allowedTools` list, or a project's settings, has to use those names.

## 4. Not done

- One model. The same plugin and job with another model, or with the skill's whole workflow rather than one repair,
  were not tried.
- Windows, and a machine without a POSIX shell: the declaration needs `sh`.
- A machine without Docker: the skill says to run the scripts on the machine, and no session was run that way.
- The time a first session takes to pull the image, about 800 MB. In Actions the job pulls it before the session.
- A project other than the fixture. TOPAK's own CI does not run an agent.

## 5. The annex

| File | What it is |
|---|---|
| `local/`, `actions-1/`, `actions-2/`, `actions-3/` | Each run's `transcript.jsonl`, `repair.diff` and check. `actions-1`'s diff is rebuilt from the transcript's two edits, applied to the project `make-project.sh` makes: the run failed before writing it. For `actions-1` and `actions-2`, `check-at-the-time.txt` is the check the run printed, and `check-now.txt` is the merged check on the same transcript and repair |
| `probe-env.txt` | `PWD`, `CLAUDE_PROJECT_DIR` and `CLAUDE_PLUGIN_ROOT` as a plugin's server saw them, in a session started in a subdirectory, with the probe's directory as `<R>` |

The transcripts are redacted as in Phase 4's annex. The local directory is `<run>`. From each first message, the
keys that list a machine's own setup are removed, along with any rate-limit event: skills, plugins, slash
commands, agents, capabilities, start-up timings, the scratchpad path, analytics flags and the API key source.
The model, the permission mode, the tools and the MCP servers' status are kept. The sha256 of each unredacted
transcript:

| Run | sha256 |
|---|---|
| `local` | `b3470ead492b1a55665eb8a8e82465043ec4200c4f0ff7fd70351dca388cf325` |
| `actions-1` | `a3e15bf3598bd77acf0ee145f69c32f2bc6a68c3ac3908c2061e32389ffdfdf7` |
| `actions-2` | `32cff12850a04d61f55cf58a9b36411263a0729fb19c280bdf82c94ac170b680` |
| `actions-3` | `b2a94c0e9cd0b4d3b5b1ab5f51200bd0f653b5727b0b1794666379218612013d` |
