# tla-kit

TLA+ is a language for describing how a system is meant to behave, and its tools check the description. TLC tries
every state of a small model, and shows the steps that lead to any state that breaks a property. TLAPS checks a
written proof that the property holds at every size. tla-kit is those tools in one container image, with an MCP
server over them, so that an agent such as Claude Code can check a specification, read a counterexample and repair
a proof by calling tools. The machine needs Docker and nothing else: no Java, no prover, no solvers.

The image is the same build on a laptop and in CI, and every tool in it is held to a digest, so a result can name
exactly what checked it. The server pairs with the
[`writing-tla-specs-and-proofs`](https://github.com/scottcochran/TOPAK/tree/main/skills/writing-tla-specs-and-proofs)
skill, which gives the agent the method.

## Use it with Claude Code

The image is `linux/amd64` and a little under 1 GB. On Apple Silicon it runs under emulation ([Limits](#limits)).
Pull it first, so that a session's first start does not wait for the download:

```sh
image=ghcr.io/scottcochran/tla-kit@sha256:5ee10d3e9b761f91020be2c6b11a16a459966a9a4cf5a105c964ae31a49ab59f
docker pull "$image"
```

**The server alone.** In the root of the project that holds the specifications:

```sh
claude mcp add tla-kit -- docker run -i --rm --user "$(id -u):$(id -g)" -v "$PWD:/work" "$image" tla-kit mcp
```

A session started there has the [fourteen tools](#the-mcp-server-phases-3-and-4) as `mcp__tla-kit__<tool>`. The
server sees that directory, mounted as the project, and refuses a path outside it. `claude mcp get tla-kit` says
whether it connected, and `claude mcp remove tla-kit -s local` takes it out again.

**The server with the skill.** The plugin is in TOPAK's repository and no marketplace lists it yet, so a session
loads it from a checkout:

```sh
git clone https://github.com/scottcochran/TOPAK
claude --plugin-dir TOPAK/skills/writing-tla-specs-and-proofs
```

This needs no `claude mcp add`: the plugin's `.mcp.json` names the image by digest and mounts the repository's
root. It needs a POSIX shell beside Docker, and the tools are then
`mcp__plugin_writing-tla-specs-and-proofs_tla-kit__<tool>` ([Phase 5](#an-agent-with-the-skills-plugin-phase-5)).

**Another MCP client** takes the entry under [Use it with another MCP client](#use-it-with-another-mcp-client).

### Try it: a broken proof to repair

`examples/agent-repair/make-project.sh` makes a small project: the specification of a counter and its proof, with
one step of the proof broken. With `image` set as above:

```sh
git clone https://github.com/scottcochran/tla-kit
tla-kit/examples/agent-repair/make-project.sh /tmp/counter
cd /tmp/counter
claude mcp add tla-kit -- docker run -i --rm --user "$(id -u):$(id -g)" -v "$PWD:/work" "$image" tla-kit mcp
claude
```

Then ask:

> spec/Counter_proof.tla no longer checks: one step of it was deliberately broken. Find the failing step with the
> tla-kit tools and repair it, changing only proofs.

`prove` on the module reports that 1 of its 18 obligations failed, at line 15, with the obligation's text and why
each backend failed. The agent reads the two modules, changes that one line, and `prove` then reports all 19
obligations of the repaired module proved. One such session, on Linux x86_64, took 23 seconds. The record of the
first, with its transcript, is
[`derived/tla-kit-phase4-checks-2026.11.17.md`](derived/tla-kit-phase4-checks-2026.11.17.md).

## Use it with another MCP client

A client configured by an `mcpServers` block, as Claude Desktop and Cursor are, takes this entry. Such a file has
no `$PWD`, so the project is named by its absolute path, and the server serves that one project:

```json
{
  "mcpServers": {
    "tla-kit": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm", "-v", "/absolute/path/to/project:/work",
        "ghcr.io/scottcochran/tla-kit@sha256:5ee10d3e9b761f91020be2c6b11a16a459966a9a4cf5a105c964ae31a49ab59f",
        "tla-kit", "mcp"
      ]
    }
  }
}
```

The entry has no `--user`, so the server runs as the image's uid, 1000. Docker Desktop on macOS maps ownership
itself. On Linux, in a project owned by another uid, the tools that read still answer, `prove` among them, and the
two that write a results file, `tlc_rows` and `proof_results`, are refused by the file system. For those, add
`"--user", "UID:GID"` after `"--rm"`, with the numbers `id -u` and `id -g` print.

The server started from this entry's command and arguments answers as it does from the commands above. The entry
has not been tried in those two clients.

## Status

**Phases 1, 3, 4 and 5 of [PLAN.md](PLAN.md) are done, and so is Phase 6's cvc5 and ethos.** The latest
release, [`v0.5.0`](https://github.com/scottcochran/tla-kit/releases/tag/v0.5.0), is published and attested:

```
ghcr.io/scottcochran/tla-kit@sha256:5ee10d3e9b761f91020be2c6b11a16a459966a9a4cf5a105c964ae31a49ab59f
```

It moves the vendored scripts to TOPAK `6a26310`, whose results-file writers say in one line why a file could not
be written, in place of a traceback. It changes nothing else in
[`v0.4.0`](https://github.com/scottcochran/tla-kit/releases/tag/v0.4.0) (`sha256:6c27b7a0…8f2f`), which added
`cvc5` and `ethos`, for certified proofs, to
[`v0.3.0`](https://github.com/scottcochran/tla-kit/releases/tag/v0.3.0) (`sha256:948e6d1f…257f`). That release
added the server's proof tools to [`v0.2.0`](https://github.com/scottcochran/tla-kit/releases/tag/v0.2.0)
(`sha256:5554015f…1e5d`), which added the server to the first release,
[`v0.1.0`](https://github.com/scottcochran/tla-kit/releases/tag/v0.1.0) (`sha256:454328cd…50c6`). None moved a
checker or runtime pin: TLC, the prover and the runtime are the same bytes in all five.

- **How it is built:** from a base pinned by digest, packages pinned by date, and the prover's tarball and
  `cvc5`'s and `ethos`'s builds, kept in this repository's releases. Every build of one commit gives one digest.
- **What it carries:** it runs as a non-root user, and carries the skill's scripts, a self-test and its inventory,
  [`PINS.json`](PINS.json). It says what it holds.
- **What CI does:** it builds and tests every pull request. A weekly check watches upstream, and a release
  workflow publishes from a tag.
- **The model:** Phase 1b's model of the pin and release process, [`spec/PinLifecycle.tla`](spec/), reproduces
  in the published image.
- **The MCP server:** `tla-kit mcp`, with Phase 3's model-checking tools and Phase 4's proof tools, is in `v0.3.0`
  and later releases (below). An agent with only its tools, and `Read` and `Edit`, repaired a broken proof step
  against the published image ([the record](derived/tla-kit-phase4-checks-2026.11.17.md)).
- **The skill:** the `writing-tla-specs-and-proofs` plugin declares the server by digest, so a session with the
  plugin has its tools; one configuration serves a local session and an Actions job (below).
- **Certified proofs:** `cvc5`, `ethos` and the CPC signature, so that a project's certified run checks every SMT
  proof. TOPAK's `proof-cert.sh` certified a proof module in the published image (below).
- **What's next:** Phase 2, the projects' CI in the image, and the rest of Phase 6.

## What is in the image

<!-- pins:begin (generated by tools/pins.py readme from PINS.json; do not edit) -->
| Pin | Kind | What it is | Held to | Served from |
|---|---|---|---|---|
| `tla2tools.jar` v1.7.4 | checker | TLC, SANY and the PlusCal translator (TLC2 2.19, rev 5a47802) | sha256 `936a2620…0e88` | upstream `tlaplus/tlaplus` `v1.7.4` |
| `tlapm` 1.6.0-pre at 9a52faf | checker | The TLAPS proof manager, from the rolling `1.6.0-pre` tag as served on 2026.11.19, with its backends: Z3 4.8.9, Zenon 0.8.4 [a268], Isabelle2025 (Isabelle/TLA+ heap) on Poly/ML 5.9.1, LS4 1.0, and a second TLA+ tools jar (`bc1b506`) that `tlapm` uses | tarball sha256 `d9c06a04…c1f0`, binary sha256 `faa92f26…2cc0`, and every one of its 47 files by sha256 | the kept copy, release `tlapm-9a52faf` here; upstream `tlaplus/tlapm` `1.6.0-pre` |
| `cvc5` 1.4.0 | checker | The SMT solver whose proofs a certified run checks: upstream's static Linux x86_64 build without GPL libraries (`b432cd7`), with GMP 6.3.0, MPFR 4.2.2, LibPoly 0.2.1 and glibc 2.35-0ubuntu3.14 linked in | zip sha256 `61d13483…ec6d`, binary sha256 `d4c53436…2e5b` | the kept copy, release `cvc5-1.4.0` here; upstream `cvc5/cvc5` |
| `ethos` 0.2.4 at 8dc85c4 | checker | The proof checker that accepts or refuses cvc5's CPC proofs: upstream's static Linux x86_64 build of the commit cvc5 1.4.0 names, with GMP 6.2.1 and glibc 2.35-0ubuntu3.14 linked in | zip sha256 `1582fd32…d8bc`, binary sha256 `97e95d36…6538` | the kept copy, release `cvc5-1.4.0` here; upstream `cvc5/ethos` |
| CPC signature cvc5 1.4.0 | checker | The rules ethos checks a cvc5 proof against: `proofs/eo/cpc/` of cvc5's source at tag `cvc5-1.4.0`, 51 files, tree `633f74115700ad32` as TOPAK's proof-cert.sh computes it | cvc5's source archive sha256 `06c65b30…9113`, the tree `633f74115700ad32`, and each of its 51 files by sha256 | the kept copy, release `cvc5-1.4.0` here; upstream `cvc5/cvc5` |
| Temurin JRE | checker | The Java runtime TLC runs on: Temurin 25.0.5+8 | the base's tag and digest | the base |
| base | runtime | Ubuntu 26.04.1 with Temurin JRE 25 (amd64) | digest `fa681c58…c1d7` (linux/amd64, resolved from `eclipse-temurin:25-jre-resolute` on 2026.11.19) | Docker Hub |
| `apt` | runtime | Python 3.14.4, perl 5.40.1 (`shasum`), git 2.53.0, from Ubuntu's snapshot of 2026-11-19T00:00:00Z | snapshot `20261119T000000Z`; `git` 1:2.53.0-1ubuntu1.1, `perl` 5.40.1-7ubuntu0.4, `python3` 3.14.3-0ubuntu2 | Ubuntu's snapshot archive |
| writing-tla-specs-and-proofs scripts TOPAK 6a26310 | method | The skill's `scripts/` and `assets/selftest/` | each file's sha256 in [`vendor/writing-tla-specs-and-proofs/VENDOR-PIN`](vendor/writing-tla-specs-and-proofs/VENDOR-PIN) | vendored in this repository |
<!-- pins:end -->

The table is generated from [`PINS.json`](PINS.json), the inventory of every pin with its values, sources and
served state (ADR-0013 item 7). CI fails if the two differ, or if the `Dockerfile`'s defaults differ from it.

`tla-kit-info`, the default command, prints each tool with the digest a results file would cite, the skill's
commit, the package versions and the build arguments; `tla-kit-info --json` prints the same as JSON.
`tla-kit-selftest` checks the image against itself in about half a minute: the digests, `TLA_JAR` and `TLAPM`,
the licence texts, the `sany`, `pcal` and `tlc` wrappers, the skill's setup check with proofs (the fixture's
row list, its proof and its flip test), the server, and `ethos`'s check of a `cvc5` proof. `tlapm`, `tlapm_lsp`,
`cvc5` and `ethos` are on `PATH`, and the skill's scripts are at `/opt/tla-kit/skill` (`$TLA_KIT_SKILL`).

The image sets `TLA_JAR` and `TLAPM`, the two variables the skill's scripts and the projects' run scripts
already read, and `CVC5` and `ETHOS`, which a project's certified run reads, so a mounted project uses the image's
tools without changes. The CPC signature is at `/opt/cvc5/cpc`.

The third-party software in the image, with each part's licence, the path of its licence text and its source, is
listed in [`licenses/THIRD-PARTY.md`](licenses/THIRD-PARTY.md), which the image carries at `/opt/tla-kit/licenses/`.

## Build and run

A project cites the published image by its digest. The tag names the same image, for reading:

```sh
docker pull ghcr.io/scottcochran/tla-kit@sha256:5ee10d3e9b761f91020be2c6b11a16a459966a9a4cf5a105c964ae31a49ab59f
gh attestation verify oci://ghcr.io/scottcochran/tla-kit@sha256:5ee10d3e9b761f91020be2c6b11a16a459966a9a4cf5a105c964ae31a49ab59f --repo scottcochran/tla-kit
```

To build it here:

```sh
docker build -t tla-kit:dev .
docker run --rm tla-kit:dev                                      # what is inside
docker run --rm tla-kit:dev tla-kit-selftest                     # does it work
docker run --rm -v "$PWD:/work" tla-kit:dev tlc -config M.cfg M.tla
docker run --rm -v "$PWD:/work" tla-kit:dev tlapm --cleanfp --strict M_proof.tla
```

The image runs as `tla` (uid 1000). On Linux, a project owned by another uid (a GitHub runner's is 1001) needs
`--user "$(id -u):$(id -g)"`; `HOME` is world-writable, so the prover works under any uid. Docker Desktop on macOS
maps ownership itself, and files written to a mounted project are the host user's.

The platform is fixed to `linux/amd64` in the `Dockerfile`, so a plain build on Apple Silicon makes the x86_64
image and runs it under emulation. Docker then prints a warning about the platform at build and at run. Passing
`--platform linux/amd64` to `docker run` can make Docker on macOS look for the image in the registry instead of
using the local one.

Every input is held to a digest or a date: the base by digest, the `apt` sources pointed at Ubuntu's snapshot for
`APT_SNAPSHOT` and at nothing else, both downloads by sha256, and the `tlapm` binary and every file of its tarball
by sha256. Upstream rebuilds the `1.6.0-pre` TLAPS tag under the same name, so the tarball is taken from the copy
kept in this repository's release `tlapm-9a52faf`, beside its licence notices and the source of its copyleft parts
(ADR-0005 item 2). A new prover build is a decision: a release of its own first, then a pull request that moves
`TLAPM_SHA256` and `PINS.json` together. `cvc5`'s and `ethos`'s zips, and cvc5's source with the CPC signature, are
taken the same way from the release `cvc5-1.4.0`, beside the source of the libraries linked into them, and the
three move together (ADR-0017).

To build it as CI and the release workflow do, fixed in time to the commit (ADR-0014 item 8):

```sh
tools/ci/fetch-kept.sh                     # the kept tarball and zips into build/, each sha256 checked
tools/ci/build.sh --load -t tla-kit:dev    # SOURCE_DATE_EPOCH and the OCI labels from the checked-out commit
```

With `--output type=oci,dest=…,rewrite-timestamp=true` in place of `--load`, the digest is the one the release
publishes for that commit.

`BASE_IMAGE` is a build argument, for a registry mirror or a base with a private CA:
`--build-arg BASE_IMAGE=public.ecr.aws/docker/library/eclipse-temurin:25-jre-resolute@sha256:fa681c58…`. A digest
built with other arguments is for working, not for citing (ADR-0002 item 7).

`vendor/check.py` checks the vendored scripts against their pin, and with `--upstream <TOPAK checkout>` against
the commit itself.

## The MCP server (Phases 3 and 4)

`tla-kit mcp` is an MCP server over stdio for the model-checking and proof tools, written with Python's standard
library only (ADR-0008). A client starts it in the image with the project mounted:

```sh
docker run -i --rm --user "$(id -u):$(id -g)" -v "$PWD:/work" \
  ghcr.io/scottcochran/tla-kit@sha256:5ee10d3e9b761f91020be2c6b11a16a459966a9a4cf5a105c964ae31a49ab59f tla-kit mcp
```

To try the tools by hand, the [MCP Inspector](https://github.com/modelcontextprotocol/inspector) starts the same
command and opens a web page that lists them and calls each one. It needs Node `^22.23.4`, `^24.22.1` or
`>=26.12.1`. Everything after `--` goes to `docker`, so the flags of `docker run` stay its own:

```sh
npx @modelcontextprotocol/inspector@2.13.0 docker -- run -i --rm --user "$(id -u):$(id -g)" -v "$PWD:/work" \
  ghcr.io/scottcochran/tla-kit@sha256:5ee10d3e9b761f91020be2c6b11a16a459966a9a4cf5a105c964ae31a49ab59f tla-kit mcp
```

The page shows the server disconnected. Its switch starts the container, and the Tools tab then lists the tools.
With `--cli --method tools/list` before `docker`, it lists the tools in the terminal instead.

| Tool | Does |
|---|---|
| `info` | What the image holds, with the digests a results file would cite (`tla-kit-info --json`) |
| `parse` | SANY on a module: its errors and warnings with their locations |
| `symbols` | A module's constants, variables, definitions (arity, parameters, level), assumptions and theorems |
| `evaluate` | A constant expression, through a scratch module; with a module, at its row list's constants |
| `tlc_run` | One row, as the skill's `tlc_run.py`: the verdict, the count, and a counterexample as structured states |
| `simulate` | A SIMULATE row: random behaviours to a depth, labelled as sampling |
| `coverage` | TLC's per-action counts, naming the actions that never fire |
| `state_graph` | The reachable graph of a small model as JSON |
| `tlc_rows` | The skill's generator on a row list, as from the command line |
| `prove` | TLAPS on a theorem or step by name, a line, a range or the whole module: success only when every obligation is proved; otherwise each unresolved obligation with its text, the backends tried and why each failed (Phase 4) |
| `proof_check` | `tlapm --summary`: the module parses and elaborates, and how many obligations it has, without a backend (Phase 4) |
| `proof_results` | The skill's proof generator, as from the command line: the dated proof results file, written only when every obligation is proved (Phase 4) |
| `flip_test` | The skill's flip test: each mutation's hypothesis flipped on a copy, and the proof must break where it should (Phase 4) |
| `proof_sync` | The skill's sync check: every results file against the tree and the pins, and with `run` each stale proof re-checked (Phase 4) |

On `main` after `v0.5.0`, and in no release yet, the server has a fifteenth tool:

| Tool | Does |
|---|---|
| `not_taken` | Why a record item does not reach a proof by a path it could have: each path of each claim as taken, not taken with its recorded reason (design, dead end, oversight, deferred, blocked, not applicable, superseded or other), or `UNEXPLAINED`. Every reason quotes its source, and the tool never supplies one (ADR-0023, Proposed; [`spec/README.md`](spec/README.md)) |

The proof tools follow the design of [marco6/tlapm-mcp](https://github.com/marco6/tlapm-mcp) (MIT), with the
changes ADR-0009 names; none of its code is used. `prove` runs `tlapm` once per request, in a process group of its
own that is killed whole on a timeout or a cancel, with a cache the server owns, one run per module at a time, and
every child reaped before it answers: the design `spec/ProveRequests.tla` checks (ADR-0016). Requests run side by
side, and a cancelled request gets no response. `server/test_prove.py` tries to break each of that module's
properties in the image.

Only `tlc_rows` and `proof_results` write into the project, and only the generators' results files. The proof
scripts hold the prover to the project's `tools/TLAPS-PIN`, as from the command line; the server sets
`TLAPM_UNPINNED=1` only when the client asks, and the output and any results file then say so. Every other tool returns working
output and keeps its scratch files outside the project (ADR-0006). A path outside the mounted project is refused.
`server/test_mcp.py` drives every tool over stdio against the skill's fixture, natively or against the image, and CI
runs it on every pull request. `server/compare_topak.py` is Phase 3's "Done when": it compares each tool with the
command it stands for on TOPAK's `Alone` and `Coupling`, every row of both, and CI runs it in the image when a change
touches the server. Phase 3 is done: on 2026.11.16, in the image CI built for pull request #11, all 84
comparisons over the nine tools were the same. The server is in `v0.2.0` and later releases. Phase 4 is done: on
2026.11.17, against `v0.3.0`, an agent repaired the fixture's broken `NextBounded` step with the server's tools, and
`Read` and `Edit`, without being told which step it was
([`derived/tla-kit-phase4-checks-2026.11.17.md`](derived/tla-kit-phase4-checks-2026.11.17.md)).

## An agent with the skill's plugin (Phase 5)

The `writing-tla-specs-and-proofs` plugin declares the server in its `.mcp.json`, by image digest, so a session
with the plugin has the fourteen tools as `mcp__plugin_writing-tla-specs-and-proofs_tla-kit__<tool>`. The server
mounts the repository's root. [`examples/agent-repair/`](examples/agent-repair/) runs an agent with only those
tools and `Read` and `Edit` on the fixture with one proof step broken, and checks its repair apart from the agent.
[`.github/workflows/agent.yml`](.github/workflows/agent.yml) runs the same scripts in Actions, and is the example
a project copies: the plugin checked out at a commit, the image pulled first, Claude Code installed by version and
integrity, `--plugin-dir`, and each tool in `--allowedTools`.

```sh
examples/agent-repair/make-project.sh /tmp/agent-project
examples/agent-repair/run.sh /tmp/agent-project <TOPAK>/skills/writing-tla-specs-and-proofs transcript.jsonl
python3 examples/agent-repair/check.py /tmp/agent-project <TOPAK>/skills/writing-tla-specs-and-proofs transcript.jsonl
```

Phase 5 is done: on 2026.11.17 the plugin at TOPAK `2db08ff` served a local session and an Actions job against the
same project, and in both the agent repaired the step and every check passed
([`derived/tla-kit-phase5-checks-2026.11.17.md`](derived/tla-kit-phase5-checks-2026.11.17.md)). A session's first
message can show the server still connecting, so a check looks at the calls it answered. A new release reaches the
plugin by a TOPAK pull request that moves the digest in its `.mcp.json`.

## Certified proofs (Phase 6)

A certified run counts an obligation proved by SMT only when `ethos` accepts the proof `cvc5` gives for it. TOPAK's
`spec/proof-cert.sh` reads `CVC5` and `ETHOS`, so it runs in the image as it is:

```sh
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD:/work" -w /work/spec \
  ghcr.io/scottcochran/tla-kit@sha256:5ee10d3e9b761f91020be2c6b11a16a459966a9a4cf5a105c964ae31a49ab59f \
  ./proof-cert.sh Alone_proof
```

Phase 6 is done for `cvc5` and `ethos`: on 2026.11.18, in `v0.4.0`, the self-test's check of the two passed,
`proof-cert.sh` certified all 263 obligations of TOPAK's `Alone_proof` with the counts by route of TOPAK's record,
and `defects-run.sh`'s certified step printed counts for all twelve modules
([`derived/tla-kit-phase6-checks-2026.11.18.md`](derived/tla-kit-phase6-checks-2026.11.18.md)). Compare certified
runs by those counts: the evidence digest a run prints differs between machines. A project whose prover pin is not
the image's sets `TLAPM_UNPINNED=1`, as tla-kit's evidence workflow does.

## Limits

- **Linux x86_64 only.** Upstream publishes no Linux arm64 build of `tlapm`. On Apple Silicon the image runs
  under emulation. On one 12-CPU Mac that was not slow: TOPAK's full proof run took under 7 minutes (the Phase 1a
  checks below).
- **Base must be Ubuntu 26.04 or newer.** The `tlapm` binary needs glibc 2.42 from `9a52faf`, and 2.38 before it;
  Ubuntu 24.04 has 2.39, and Debian 12 and Ubuntu 22.04 are older.
- **One release is supported:** the latest. Older ones stay available and get no fixes (ADR-0014 items 5 and 7).
- **The scan covers the Ubuntu packages only.** Trivy reported no target for the Java runtime or the jars, nor
  for the static `cvc5` and `ethos`.
- **The TLAPS tarball's contents are redistributed** on the three conditions of `PLAN.md` D7
  ([`derived/tla-kit-licence-check-2026.11.15.md`](derived/tla-kit-licence-check-2026.11.15.md) §5):
  - the image carries the notices;
  - the release [`tlapm-9a52faf`](https://github.com/scottcochran/tla-kit/releases/tag/tlapm-9a52faf) keeps the
    tarball beside them, with the source of Poly/ML, GMP and `libsha1`;
  - the GMP release and `libsha1`'s licence are settled
    ([`derived/tla-kit-copyleft-sources-2026.11.16.md`](derived/tla-kit-copyleft-sources-2026.11.16.md)).
- **`cvc5`'s and `ethos`'s builds are redistributed** on the same three conditions
  ([`derived/tla-kit-licence-check-cvc5-ethos-2026.11.17.md`](derived/tla-kit-licence-check-cvc5-ethos-2026.11.17.md)
  §5): the image carries the notices; the release
  [`cvc5-1.4.0`](https://github.com/scottcochran/tla-kit/releases/tag/cvc5-1.4.0) keeps the zips beside the source
  of the LGPL libraries linked into them; and those libraries' releases are settled from the bytes
  ([`derived/tla-kit-static-libraries-2026.11.17.md`](derived/tla-kit-static-libraries-2026.11.17.md)).

## Phase 1c checks, 2026.11.16

These ran on the published digest, `sha256:454328cd…50c6`. The record, with the raw output of every run, is
[`derived/tla-kit-phase1c-checks-2026.11.16.md`](derived/tla-kit-phase1c-checks-2026.11.16.md).

| Check | Outcome |
|---|---|
| The release workflow, tag `v0.1.0` | Every step passed on its first run: build, self-test, publish, self-test of the pulled digest, SBOM, scan, both attestations, the release |
| One digest from every build | CI's two runners on `main` at `bfeecc8`, and the release build, gave the same digest |
| `gh attestation verify` | Passes for the build provenance and the SBOM, both signed for `release.yml` at `refs/tags/v0.1.0` |
| `PinLifecycle` rows | All 50 as expected; `spec/PinLifecycle-results-2026.11.16.txt` reproduced byte for byte |
| The spike's checks, against TOPAK at `0ad9f88` | All as in the spike table below. Setup check ready; jar pin in step; 34 of 34 proof modules, 13,622 obligations, every count equal to its committed results file; TLC results of the `pr` tier, 490 rows, 0 differences; the defect run differing from TOPAK's record, as in the spike, and from the spike's run only in two clock-dependent state counts. |
| The vulnerability scan | 0 HIGH or CRITICAL in the Ubuntu packages |

## Phase 1a checks, 2026.11.15

Run on an Apple Silicon Mac (arm64), Docker Desktop 29.0.1, the image built for linux/amd64 and run under
emulation.

| Check | Outcome |
|---|---|
| `docker build .` with no arguments | Builds, in 2 min 22 s from a warm cache. Docker warns that the `FROM` platform is a constant, which is intended. 805 MB. |
| `apt` from the snapshot only | All 53 index and package downloads from `snapshot.ubuntu.com/ubuntu/20261115T000000Z`, none from the live archive. `apt-get update --snapshot` had also fetched the live indices, so the sources are rewritten instead. |
| `tla-kit-selftest` | All seven checks ok in 28 s. The skill's setup check takes 23 s of it: all 11 fixture rows as expected, the fixture's 19 obligations proved, and its flipped hypothesis failing as required. The prover is held to its pin, with no `TLAPM_UNPINNED` override. |
| The self-test can fail | It fails with `TLAPM=/bin/true` (pins, env, setup), with a vendored script changed (pins), and with a licence text removed (notices). |
| Writing to a mounted project | A macOS bind mount: the results file is the host user's. A volume owned by uid 1001: the default uid 1000 is refused, as Linux permissions require; with `--user 1001:1001` the TLC results and a proof results file are written, owned by 1001. |
| TOPAK's proofs under emulation | `spike/prove-all.sh` over TOPAK's `spec/` at `0ad9f88` (taken with `git archive`, mounted read-only): 34 of 34 proof modules proved, 13,622 obligations, every count equal to its committed results file. 6 min 43 s on 12 CPUs, `Mesh` the slowest at 103 s. The spike's native run took 539 s on 4 CPUs (`Mesh` 152 s); the machines differ, so this is not a ratio for emulation. |
| `vendor/check.py --upstream` | 11 files match `VENDOR-PIN` and TOPAK at `0ad9f88`. It fails on a changed file and on an extra one. |

## Spike results, 2026.11.15

Run in the image on a 4-CPU x86_64 Linux machine, against TOPAK at commit `0ad9f88`, mounted read-only and
copied inside the container. Nothing was written to TOPAK and no results file was produced.

| Check | Command | Outcome |
|---|---|---|
| The skill's setup check | `setup_check.py --proofs`, in an empty project, `TLAPM_UNPINNED=1` | Ready for model checking and proofs: all 11 fixture rows as expected; the fixture's 19 obligations proved; its flipped hypothesis fails as required |
| TOPAK's jar pin | `tools/check-pins.sh` | In step with `tools/TLA-PIN` |
| TOPAK's proofs | `spike/prove-all.sh /work/spec` | 34 of 34 proof modules proved; 13,622 obligations; every module's count equals its committed results file; 539 s in all, `Mesh` the slowest at 152 s |
| TOPAK's prover-defect reproductions | `spec/defects/defects-run.sh`, `TLAPM_UNPINNED=1` | Differs from the committed record: 13 lemmas the record expects to prove (12 by SMT, 1 by LS4) fail under this prover build; TLC still finds all 8 statements false; the certified step cannot run without cvc5 and ethos |
| TOPAK's TLC results | `tools/check-results.sh` on the `pr` tier | All 14 modules regenerated and compared with their committed results files: 490 rows, 0 differences; 3,390 s run one after another (CI runs them as a matrix), `Release` the slowest at 913 s |

The committed proof results were made by `tlapm` 7824dab on arm64-darwin. This run used ff40755 on Linux
x86_64, with the same backend versions (Z3 4.8.9, Zenon 0.8.4 [a268], Isabelle2025). Equal obligation counts
are not equal results files: a file generated in this image would carry a different `Prover:` line, and
TOPAK's `tools/TLAPS-PIN` still names the darwin binary.

The spike image was built on a derived base that adds a private proxy certificate, from a registry mirror, so
its digest is not one to cite.

Not tried in the spike: certified proof runs (`spec/proof-cert.sh`), the image under emulation on Apple Silicon,
the `Mesh` TLC results (tier `manual`, about 70 minutes), and any GitHub Actions run. Phases 1a and 1c have since
run the image under emulation and in GitHub Actions.

## Not built yet

[PLAN.md](PLAN.md) is the development plan, and [derived/](derived/) holds dated, frozen records: the session
that produced the spike, with the raw output of its runs, the licence check of the bundled tools, the settling of
their copyleft sources, the checks of the first release, those of Phases 4, 5 and 6, and the licence check of
`cvc5` and `ethos`. [decisions/](decisions/) holds the architecture decision records drafted from them, all
seventeen accepted. In short:

- The projects' CI in the image, with each project's pin (Phase 2).
- Apalache; TLATeX; the TLA+ community modules (the rest of Phase 6).
- A Linux arm64 build of `tlapm` from source.

## License

Code and tooling are Apache-2.0 ([LICENSE](LICENSE)); documentation is CC BY 4.0
([LICENSE-DOCS](LICENSE-DOCS)). See [NOTICE](NOTICE) for how the split applies. The tools inside the image keep
their own licences. [`licenses/THIRD-PARTY.md`](licenses/THIRD-PARTY.md) lists them.
