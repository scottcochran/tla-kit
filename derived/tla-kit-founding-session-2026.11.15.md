# How tla-kit began: one session, from a question about TLA+ MCP servers to a spike image and a plan

> What functionality do existing TLA+ MCP servers provide that could benefit TOPAC development?
>
> Could a dockerized TLA MCP server be used in github actions?
>
> The idea is to have the same local & in CI, to have an external TLA MCP to pair with the
> writing-tla-specs-and-proofs skill, and include as many tla+ family tools as possible including tlaps.
>
> Good names for the git repo for this ?
>
> add the tla-kit repo to this session, add a README.md, and do the spike build.
>
> Ideas from this repo?: https://github.com/marco6/tlapm-mcp
>
> Write a development plan to the tla-kit repo
>
> Write this session out to tla-kit as a TOPAK style derived document.

(The custodian's eight prompts of 2026.11.15, as typed. "TOPAC" in the first was read as TOPAK. Between the
fifth and the sixth the custodian also answered one question the assistant put: where to push; the answer was
`main`.)

**2026.11.15** · derived · a session record, not a decision · prepared by the assistant at the custodian's request ·
tla-kit at `5a35f4d`, read against TOPAK at `0ad9f88` and gov-tla at `39bd8c1` · follows the form of TOPAK's
`derived/`: dated, frozen, never revised

**Nothing here decides anything.** It says what was asked, what was read, what was built and run, what came out,
what the assistant got wrong on the way, and what is left to the custodian. `README.md` holds the state of the
repository and `PLAN.md` the plan; where either moves on, this document stays as it is.

**Nothing was written to TOPAK or gov-tla.** Both were mounted read-only into containers and copied inside them.

**How things were read.** The three repositories were read directly. Every web page was read by a fetch agent
whose report is a model's summary; the assistant read the reports, not the pages. What rests on such a report is
marked *(by report)*. What was neither read nor run is marked *(not verified)*.

The raw output of every run in §4 is in `tla-kit-founding-session-annex-2026.11.15/`.

---

## 1. What this is

In one session the custodian asked what existing TLA+ MCP servers could do for TOPAK, whether one could run in
GitHub Actions in a container, and then stated the idea this repository is for: one toolchain, the same locally
and in CI, with an MCP server beside the `writing-tla-specs-and-proofs` skill and as much of the TLA+ family in it
as possible, TLAPS included. The repository was named, created by the custodian, and attached to the session. A
spike image was built and run against TOPAK. A plan was written.

§2 gives the session in order. §3 is what the survey of servers found. §4 is the spike. §5 lists the findings.
§6 lists what the assistant said that turned out wrong. §7 says who chose what. §8 says where this stops, and §9
what the custodian may decide.

---

## 2. The session in order

| # | Asked | Done | Left behind |
|---|---|---|---|
| 1 | What existing TLA+ MCP servers offer TOPAK | Three web searches, two fetch agents over the servers' repositories; TOPAK's `spec/` scripts, `tools/` pins, workflows and the skill read | A survey (§3): useful for the interactive TLC loop; nothing for TLAPS; nothing that could produce evidence |
| 2 | Whether a containerized server could run in GitHub Actions | TOPAK's three workflows read; the Claude Code action's configuration and the servers' packaging read *(by report)* | Yes, but only where a workflow runs an agent; none of the servers ships an image |
| 3 | The idea: same locally and in CI, external, paired with the skill, TLAPS included | The skill's packaging and scripts, `tools/install-tlaps.sh`, `tools/tlapm`, `spec/proof-cert.sh` read | A design: one image with two ways in; two problems named (the prover pin, Apple Silicon) |
| 4 | Names for the repository | None | Five candidates; the custodian took `tla-kit` |
| 5 | Attach the repository, add a README, do the spike build | The empty repository cloned; a `Dockerfile`, four wrappers and `spike/prove-all.sh` written; the image built; five checks run (§4) | Commit `770daf2` |
| 6 | Ideas from marco6/tlapm-mcp | Its README and main source read *(by report)* | A correction (§6, C-1) and a list of what to take and what to change |
| 7 | A development plan | Tool flags checked in the image; TOPAK's defect reproductions run in the image; gov-tla's prover pin read | `PLAN.md`; the defect result (F-7); commit `5a35f4d` |
| 8 | This document | TOPAK's `derived/README.md` and three of its documents read for form; the run outputs saved as an annex | This file, its annex, and `derived/README.md` |

---

## 3. The servers that exist

All *(by report)*. Star counts and activity are as the pages showed them on 2026.11.15.

| Server | What it is | Tools | TLAPS | Ships an image |
|---|---|---|---|---|
| The one built into `tlaplus/vscode-tlaplus` | An HTTP server on localhost inside VS Code or Cursor, merged 2025.05.22 (PR 379) | SANY parse, symbols, module list; TLC check, smoke, explore, trace replay; optional file and knowledge-base tools | no | no; it needs the editor running |
| `richashworth/tlaplus-mcp` | TypeScript, run with `npx`; 2 stars, listed as inactive | Nine: parse, check, simulate, evaluate a constant expression, coverage, state graph, trace spec, PlusCal, TLATeX | no | no |
| `photoszzt/tlaplus-ai-tools` | A Claude Code and Codex plugin; 0 stars | The official server's SANY and TLC tools, twelve skills, animation | no | no |
| `fabracht/tla-rs` | Its own model checker in Rust, not TLC; 82 stars | Eight, among them validate, check, replay a scenario | no | no |
| `sonoisa/tlaplus-mcp` | TypeScript; 0 stars | Three: parse, PlusCal, check | no | no |
| `r33drichards/mcp-tlaplus` | Java; 1 star; no README | Not listed anywhere read | not stated | no |
| `marco6/tlapm-mcp` | Go, MIT; 1 star, 22 commits, no release | Two: `check` (parse and count obligations, no backends) and `prove` (one line or a line range) | **yes** | no |

What the first six would add to TOPAK's working loop, none of which its scripts or the skill use today: action
coverage, constant-expression evaluation, a parse-only check, a module's symbols as JSON, the state graph as
JSON, and counterexamples as structured states. (Coverage, state dumps and trace specs were checked by search
of `spec/`, `tools/` and the skill; the rest by reading the skill's list of scripts.)

What limits them: `richashworth/tlaplus-mcp` downloads its own `tla2tools.jar` unless `TLC_JAR_PATH` is set, so
by default it runs outside a project's pin; `tla-rs` is a different checker with its own subset of the language
and was not run on any TOPAK module; the official server cannot run headless.

`marco6/tlapm-mcp` drives the `tlapm` command line: `--summary -N` for `check`; `--timing` with `--line N` or
`--toolbox FROM TO` for `prove`, and `--nofp` when the caller turns the cache off. It parses the Toolbox
protocol's blocks and returns only unresolved obligations, with line, status and reason. It does not return an
obligation's text, takes `tlapm` from `PATH` with no pin, lets `.tlacache` land beside the module, and accepts
any absolute path. Its tests were not read and it was not run.

---

## 4. The spike

**Built.** `Dockerfile`: Ubuntu 24.04 with Temurin JRE 25, Python 3.12, perl and git; `tla2tools.jar` v1.7.4 and
the `tlapm` tarball of the `1.6.0-pre` tag, each held to a sha256. `bin/`: `tlc`, `sany`, `pcal`, `tla-kit-info`.
`spike/prove-all.sh`: re-proves every `<M>_proof.tla` of a mounted directory in a temporary copy and compares
each obligation count with the newest committed `<M>-proof-results-*.txt`.

**How it was built here.** The session's machine reaches the network through a proxy that containers do not
trust, Docker Hub refused the pull (HTTP 429), and plain HTTP to the Ubuntu archive is refused. So the image was
built on a local base derived from `public.ecr.aws/docker/library/eclipse-temurin:25-jre-noble` with the proxy's
certificate added and the `apt` sources switched to HTTPS, passed as `BASE_IMAGE`. The `Dockerfile` is the one
committed. The image is 806 MB; its local id was `sha256:e3699009…8834`, which nothing should cite.

**What is in it**, as `tla-kit-info` prints it (annex, `tla-kit-info.txt`): the jar at sha256 `936a2620…0e88`
(TLC2 2.19, rev 5a47802), which is TOPAK's `tools/TLA-PIN`; `tlapm` ff40755 at sha256 `6182df63…5bb2`; Z3 4.8.9,
Zenon 0.8.4 [a268], Isabelle2025.

**Run**, on 4 CPUs, x86_64, TOPAK at `0ad9f88`:

| # | Check | Outcome | Annex file |
|---|---|---|---|
| 1 | The skill's `setup_check.py --proofs`, in an empty project, `TLAPM_UNPINNED=1` | Ready for model checking and proofs: 11 fixture rows as expected; 19 obligations proved; the flipped hypothesis fails as required | `setup-check.txt` |
| 2 | TOPAK's `tools/check-pins.sh` | In step with `tools/TLA-PIN` | `check-results-1-of-2.txt` |
| 3 | `spike/prove-all.sh` on TOPAK's `spec/` | 34 of 34 proof modules; 13,622 obligations; every count equal to its committed file; 539 s; `Mesh` 152 s, `Workflow` 82 s | `prove-all.txt` |
| 4 | TOPAK's `tools/check-results.sh` on the 14 `pr`-tier modules | 490 rows, 0 differences; 3,390 s one after another; `Release` 913 s, `BreakGlass_A1` 716 s | both `check-results` files |
| 5 | TOPAK's `spec/defects/defects-run.sh`, `TLAPM_UNPINNED=1` | Differs from the committed record (F-7) | `defects-run.txt` |

Checks 3 and 4 overlapped for about nine minutes, so their times are upper bounds for this machine. Check 4 ran
in two parts: the first was stopped by the session's 50-minute limit on a background command after ten modules,
and the remaining four were run again (§6, C-4).

---

## 5. The findings

| # | Finding | Evidence | How firm |
|---|---|---|---|
| F-1 | **No existing server ships a container image, and one wraps TLAPS.** | §3 | By report; GitHub search is not exhaustive |
| F-2 | **TOPAK's CI does not rerun its proofs.** `results.yml` says the pinned prover is arm64-darwin and not what upstream serves, so a runner cannot; `checks.yml` runs `spec/proof-sync.sh`, which compares digests and needs no prover. | `.github/workflows/results.yml` lines 9 to 10 | Read |
| F-3 | **The Linux `tlapm` now served proves all of TOPAK's proof modules with the committed counts.** | §4, check 3 | Run once |
| F-4 | **TOPAK's `pr`-tier TLC results regenerate in the image without a difference.** | §4, check 4 | Run once |
| F-5 | **The three projects are on three prover builds, and upstream serves one.** TOPAK pins 7824dab (arm64-darwin, pinned 2026.10.03) and records having seen bfa9468 the same day; gov-tla pins c8ddc44 (x86_64-linux, tarball sha256 `fa6d537f…`, pinned 2026.11.09); the tag served ff40755 on 2026.11.15 (tarball sha256 `99db29f1…`). | `tools/TLAPS-PIN` in both; the download | Read and downloaded |
| F-6 | **The TLAPS download is 52 MB, not the size TOPAK's script states.** `tools/install-tlaps.sh` says about 1.1 GB compressed and 1.9 GB on disk. The current tarball holds `tlapm`, `tlapm_lsp`, Z3, Zenon, LS4 and an Isabelle of two heaps and Poly/ML. | The download, listed | Measured |
| F-7 | **Under ff40755, TOPAK's defect reproductions do not reproduce.** Of the lemmas the record expects to prove, 13 fail (12 it expects SMT to prove, 1 LS4), the false statements among them; 5 others it expects SMT to prove still prove; TLC still finds all 8 statements false; the certified step printed no counts, having no cvc5 or ethos. | §4, check 5; committed `defects-results-2026.10.22.txt` | Run once. That upstream closed the two cases is an inference; tlaplus/tlapm issues 309 and 310 were not read |
| F-8 | **The current `tlapm` needs glibc 2.38.** Debian 12 (2.36) and Ubuntu 22.04 (2.35) are too old. | `objdump -T` on `bin/tlapm`, `zenon`, `ls4` | Measured |
| F-9 | **The skill's scripts and TOPAK's pin file disagree on a key.** `tla_common.py` reads `binary_sha256`; TOPAK's `tools/TLAPS-PIN` has `binary_sha256_16`. gov-tla's has `binary_sha256`. Read literally, the skill's proof scripts treat TOPAK's prover as unpinned. | The three files | Read, not run in TOPAK |
| F-10 | **The image's variables are ones the projects already read.** `TLA_JAR` and `TLAPM` are read by the skill's scripts, by TOPAK's run scripts and by `tools/tlapm`. | The scripts; checks 3 to 5 ran unchanged | Read and run |
| F-11 | **The Claude Code action takes MCP servers through `claude_args`** (`--mcp-config`), with every tool named in `--allowedTools`. Its documents show `npx` and `uv` servers and no `docker run` one. | The action's `docs/configuration.md` and `docs/usage.md` | By report; not tried |

---

## 6. What the assistant got wrong, and when it was put right

| # | What was said | What is so | Put right |
|---|---|---|---|
| C-1 | After the first three prompts: no MCP server wraps TLAPS. Searches for it had returned only TOPAK itself. | `marco6/tlapm-mcp` does. | At the sixth prompt, when the custodian supplied it |
| C-2 | At the third prompt: the image would carry a prover of about 1.9 GB. The figure came from TOPAK's `install-tlaps.sh`. | The current tarball is 52 MB and the whole image 806 MB (F-6). | At the fifth, by downloading it |
| C-3 | At the second prompt: the proof side "stays out of reach" in CI because the pin is a darwin binary. | True of the pinned binary only; the Linux build proves everything (F-3). | At the fifth |
| C-4 | The first run of check 4 was given a 50-minute limit and was stopped at ten modules. | The four left took 935 s more. | Rerun in the same turn; both outputs are in the annex |
| C-5 | The first build's `tla-kit-info` printed an empty `tlc` line: TLC prints its banner without `-h`, not with it. | Fixed before any result was recorded. | Same turn |
| C-6 | The Docker daemon, started by hand in the session, stopped twice between commands. | Restarted each time; no run was in progress either time. | Same turn |

---

## 7. Who chose what

**The custodian:** the idea, in the third prompt; the name `tla-kit`; that the spike be built; `main` as the
branch; that there be a plan and this document.

**The assistant, each open to change:** Ubuntu 24.04 (forced by F-8) with Temurin 25, which is what TOPAK's
`results.yml` sets up; both downloads checked by `ADD --checksum`, so that a moved upstream tag fails the build;
`BASE_IMAGE` as a build argument; the jar and the prover exposed through `TLA_JAR` and `TLAPM`; a spike script
that writes nothing and compares counts only; raw outputs kept as an annex; everything in `PLAN.md`, including
the order of its phases and the five recommendations it marks as such.

**Recommended and not taken up:** `tla-workbench` as the name.

---

## 8. Where this stops

- **The committed `Dockerfile` has not been built as it stands.** Every build here passed `BASE_IMAGE`. Plain
  `docker build .`, GitHub Actions and Apple Silicon are untried.
- **Each check ran once**, on one machine, with the CPU shared between two of them.
- **Equal obligation counts are not equal results files.** A file made in this image would carry another
  `Prover:` line. No results file was made.
- **No MCP server exists here.** §3 describes other people's; `PLAN.md` describes one to build.
- **Recalled, not checked:** that a Claude Code plugin can declare an MCP server; how `tlapm_lsp` is started;
  that upstream publishes no Linux arm64 `tlapm` (TOPAK's script says so; the release's asset list would not
  load for the fetch agent); that GitHub's Ubuntu runners have Docker.
- **Not read:** `marco6/tlapm-mcp`'s tests; the sources of `r33drichards/mcp-tlaplus` and `sonoisa/tlaplus-mcp`;
  the upstream `tlapm` issues; TOPAK's records, except as its scripts and workflows cite them.
- **A survey by search finds what search returns.** C-1 is the instance.

---

## 9. What the custodian may decide

1. **Whether TOPAK moves its prover pin to a Linux build** (`PLAN.md` D1). F-3 says it can; F-7 says the move
   changes what the defect record reports, so the records that cite the two cases would need reading first.
2. **Whether gov-tla does the same.** Its pinned tarball is no longer what upstream serves (F-5).
3. **Whether tla-kit keeps a copy of the tarball it pins**, since upstream keeps none (F-5).
4. **The other four decisions `PLAN.md` lists:** where the skill's scripts live for the server, the registry,
   a licence for this repository, and one image or variants.
5. **Three small corrections in TOPAK**, each a lead and none made: the size in `tools/install-tlaps.sh` (F-6);
   the pin key (F-9); and whether `defects-run.sh` should say plainly when its certified step cannot run, where
   today it prints empty counts.
6. **Whether to take `marco6/tlapm-mcp` as a design to follow, a dependency, or neither.** `PLAN.md` assumes the
   first.
