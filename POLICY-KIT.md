# tla-kit — A policy kit after the same pattern: Cedar and Rego, pinned, with a server and a skill

**2026.11.21** · a design note, not a record, kept beside `PLAN.md` as `GRAPH-AND-DIAGRAMS.md` is · basis: tla-kit
`main` at `822c4c7` (README, `PLAN.md`, `PINS.json`, ADR-0001, 0002, 0006 to 0008, 0012 to 0017, `CONSUMERS.md`,
`GRAPH-AND-DIAGRAMS.md`) and branch `adr-tla-cicd` (`COUPLING.md`, ADR-0018 to ADR-0020, read for their titles and
the claims table only); TOPAK at `ffd02f1` (`floor/`, `floor/proposed/`, `policies/`,
`mechanism/scripts/build-bundle.sh`, `mechanism/bundles/`, `mechanism/GAPS-AND-ASSUMPTIONS.md`,
`.github/workflows/results.yml`, `tools/TLA-KIT-PIN`, ADR-0070's Annex finding on the OPA image); `opa` at `40207f8`;
`opa-mcp-http` at `f7e9e93` · prepared by the assistant at the custodian's request

Nothing here is built and nothing here is accepted. It proposes a sibling of tla-kit, five phases and the records
they need. Where it says what exists, it cites the file. Three things were tried while writing it, and §6 records
them. The name `policy-kit` is a working name; the name is the custodian's to choose (K8).

---

## 0. In one paragraph

tla-kit made one thing true for TLA+: a result names exactly what checked it, on a laptop and in CI alike, and an
agent reaches the same tools through a server that cannot make evidence of its own. TOPAK's policy tier has the
method for that and not the tools. Its Cedar floor is gated by a solver whose every `unsat` is checked by a second
program, and its Rego bundle is named by a digest of its source; but the floor's CI job downloads and builds its
tools on each run, and the bundle is compiled by whichever OPA the tag `latest` served that day. The `opa`
repository has Rego and build scripts with the same unpinned tools. `opa-mcp-http` is a server, but for a different
job: it changes a running OPA over its REST interface. This note proposes **a second image, built from tla-kit's by
digest, that adds a pinned `cedar` and a pinned `opa`; a server over them in tla-kit's form; and a skill drawn from
TOPAK's floor and bundle method.** The solver and the proof checker the Cedar gates need are already in tla-kit's
base, at the versions TOPAK's gate runs name, so the two kits would cite one checker.

---

## 1. What exists, and what is tied to its repository

| Piece | Where | General | Tied to its repository |
|---|---|---|---|
| The floor's gates | TOPAK `floor/run-gates.py` (309 lines) | Five gate kinds over a schema and a policy set: totality, non-vacuity, discrimination, every entry matters, routing; negative controls; the tree digest of the evidence | The table of action signatures (`SIGS`), the three routing candidates, the paths, the entries' names |
| The solver wrapper | TOPAK `floor/cvc5-checked` (384 lines) | All of it: it keeps each query, runs cvc5 with proofs, binds the proof to the query's own text, and forwards `unsat` only when ethos accepts | Its variables are named `TOPAK_CVC5`, `TOPAK_ETHOS`, `TOPAK_CPC` |
| The behavioural cases | TOPAK `floor/gen-tests.py` (210 lines) | The rule: every permit has a case that allows and one that denies, and every forbid is the reason for some deny | Every entity and case |
| The staged floor | TOPAK `floor/proposed/build.py` (524 lines) | A stage is the one before it plus named edits, each asserted to apply exactly once | Every edit |
| The floor in Lean | TOPAK `floor/lean/` | The idea of a second derivation under Cedar's verified model | The generator and every theorem; needs a Lean toolchain |
| The bundle's identity | TOPAK `mechanism/scripts/build-bundle.sh` (28 lines) | A revision that is a digest of the sorted sources; a signature beside the tarball | The entrypoint, and the signing through the `topak` binary |
| The bundle tier's Rego | TOPAK `policies/` (4 modules, 3 test files, 38 cases) | "The bundle can only refuse" as a way to write Rego | The modules |
| The Paxos Rego | `opa` `policies/` (5 modules, 3 test files, 108 cases), `data/` | A second project's policies, for a kit to be tried on | The modules; no Cedar |
| Bundle and Wasm scripts | `opa` `build_bundle.sh`, `build_wasm.sh`, `validate_policies.sh`, `Makefile` | What a project wants from a build: check, test, bundle, Wasm | `openpolicyagent/opa:latest` throughout |
| A server over OPA | `opa-mcp-http` `src/` (TypeScript, 14 tools, 170 tests) | The shapes of three tools: evaluate at a path, evaluate a query, partially evaluate with unknowns | Everything else: see §4 |
| The solver, the checker, the rules | tla-kit's base: `cvc5` 1.4.0, `ethos` at `8dc85c4`, the CPC signature | All of it | Nothing. TOPAK's gate runs name these versions |
| A policy skill | nowhere | | No repository of the four has one. TOPAK's skills cover TLA+, Lean, diagrams and audits; `opa` and `opa-mcp-http` have no `.claude/` |

`opa`'s own `.mcp.json` names two Kafka servers at a path on one machine. It is not a server for OPA.

---

## 2. The kit

### 2.1 A sibling, built from tla-kit's image

- **A second repository and a second image**, `FROM ghcr.io/scottcochran/tla-kit@sha256:…`. It adds `cedar`, with
  symbolic analysis, and `opa`, and nothing else a result depends on.
- **Why not a variant of tla-kit.** ADR-0012's variants are for large optional tools of the TLA+ family, and
  `PLAN.md` says nothing in the image is specific to a project. Cedar and OPA are a second family, with their own
  skill, their own pins and their own releases. K1 below.
- **What it inherits.** `cvc5`, `ethos` and the CPC signature, by the base's digest, so a Cedar gate result and a
  certified TLAPS run rest on the same bytes. Python, for the scripts. TLC, so the kit's own process can be
  specified and checked in its own image (§2.5).
- **What it costs.** A release of tla-kit that moves a checker pin means a release here. The kit names its base in
  a pin file, joins `CONSUMERS.md`, and its evidence for a base move is its own self-test and its consumers' gate
  runs (ADR-0013 item 3).

### 2.2 The two new pins

- **`opa`.** Upstream serves a static Linux x86_64 binary with its sha256 for every release; three were fetched
  and each matched its published digest (§6.1). It is pinned as a checker and as a **compiler**: §6.1 shows the
  release decides the bytes of the compiled module. Whether a copy is kept in a release here, as ADR-0005 and
  ADR-0017 do, is K4.
- **`cedar`.** TOPAK's CI installs it with `cargo install cedar-policy-cli@4.13.0 --features analyze --locked`.
  The assistant knows of no upstream binary with that feature, and did not look further. So the kit builds it once,
  from the locked source, keeps the binary in a release with its licence texts, and pins both the source and the
  binary. **Whether two builds of it give one digest has not been tried**; if they do not, the kept copy is the
  only definition of the pin, as it is for `tlapm`.
- **Cedar's version is also TOPAK's linked engine's.** `mechanism/Cargo.toml` has `cedar-policy = "4.13"`, and
  `floor/lean` models tag `v4.13.0`. A kit that moves `cedar` moves it knowingly, by ADR-0013's one rule.

### 2.3 The skill

A fourth kind of skill, for writing and checking Cedar and Rego, in the form of `writing-tla-specs-and-proofs`.
It is the long part of this work.

- **The method, written down once.** A floor that can permit and a bundle that can only refuse; the five gates and
  what each one cannot see; negative controls, including a solver that lies; the rule for behavioural cases; a
  bundle named by a digest; what `holds✓` and `holds°` each rest on. TOPAK's `floor/README.md` states most of it,
  as a description of one floor.
- **The scripts, with TOPAK taken out.** A gate runner that reads the action signatures from the schema and the
  routing candidates from a project's file. `cvc5-checked` nearly as it is, with its variables renamed or read
  both ways. A case checker for the allow, deny and reason rule. A bundle builder that records the compiler's
  digest and the module's. A sync check of every results file against the tree and the pins.
- **A self-test fixture**: a small schema and floor, a small bundle, a row list of gates, and a flip test, in which
  each mutation of the floor must be caught by the gate that should catch it.
- **Where it lives** is K2. ADR-0018 (Proposed) makes tla-kit the home of its skills; by the same reasoning this
  skill lives in the policy kit from the start, and TOPAK takes it from a release.

### 2.4 The server

`policy-kit mcp`: Python's standard library over stdio, in the image, confined to the mounted project, as
ADR-0008 has it. It has no way of its own to write a results file or a bundle (ADR-0006).

| Tool | Does | Writes |
|---|---|---|
| `info` | What the image holds, with the digests a results file would cite, the base's among them | no |
| `cedar_validate` | A policy set against a schema: errors and warnings with their locations | no |
| `cedar_authorize` | One request with its entities: the decision and the policies that determined it | no |
| `cedar_tests` | A case file, as `cedar run-tests`: each failing case with what was expected | no |
| `cedar_analyze` | One symbolic query (never-errors, always-allows, always-denies, equivalent, implies) through the checked wrapper: `holds✓`, `holds°`, a counterexample, or `unknown` | no; labelled working output |
| `rego_check` | `opa check --strict`: errors with their locations | no |
| `rego_eval` | A query at an input, against the project's files and not a server | no |
| `rego_partial` | Partial evaluation with named unknowns: what is left to decide | no |
| `rego_test` | The tests, with coverage, naming the rules no test reaches | no |
| `bundle_inspect` | A bundle's manifest and revision, and each file's digest, the compiled module's among them | no |
| `admit` | The composition on one request: the floor's decision, then the bundle's, and which tier refused | no |
| `gates_run` | The skill's gate generator on a project's gate list, as from the command line | yes, the generator's |
| `bundle_build` | The skill's builder: the bundle, with the compiler's digest and the module's beside it | yes, the builder's |
| `policy_sync` | The skill's sync check: every results file and bundle against the tree and the pins | no |

- **`admit` composes two inputs the project supplies.** How one request becomes a Cedar request and a Rego input is
  the project's lift (TOPAK's is ADR-0030 §4, in `lift.rs`). The tool does not derive one from the other.
- **No tool signs.** A signature is a custody act (TOPAK ADR-0044), and a key does not belong in the image.
- **No tool talks to a running OPA.** §4.

### 2.5 Specify before building

tla-kit specifies a process before it builds it (ADR-0015, ADR-0016). The process here is a bundle's identity:
sources give a revision, a compiler gives a module, a key signs, a loader accepts. The property worth stating is
the one §6.1 shows to be false today: **one revision never names two modules.** A small module with a row for the
process as it is, expected to violate that, and a row for each candidate fix, checked with TLC in the kit's own
image. The fix itself is K3.

### 2.6 How it joins tla-kit's chain

- **Claims.** A gate result is a row a claims table can cite (ADR-0019, Proposed). `holds✓` is *certified*: a
  second program accepted a proof. `holds°` is weaker and has no word yet; a passing case file is *checked*. The
  kit's results files carry the header the claims check reads, so one check covers both kits.
- **The graph.** `GRAPH-AND-DIAGRAMS.md` leaves every edge below the model to the project. A floor's gate results
  and a bundle's digest are such edges, and TOPAK's builder already reads `floor/`. Nothing in the graph's format
  needs to change for this kit.
- **One plugin configuration.** A project's `.mcp.json` names both servers by digest and mounts the same root. An
  agent then has the model's tools and the policy's in one session.

---

## 3. What each repository would do

- **TOPAK.** A pin file, `tools/POLICY-KIT-PIN`, in the form of `tools/TLA-KIT-PIN`, by a TOPAK record. The `floor`
  job of `results.yml` runs in the image and loses its three install steps. `build-bundle.sh` calls the image's
  `opa` in place of `docker run … openpolicyagent/opa`, which closes the open finding that ADR-0070 and the format
  inventory record. Its floor and bundle stay where they are. Its `floor/lean` is unchanged and outside the kit.
- **`opa`.** The second project. Its policies give the Rego half of the skill something that is not TOPAK's, and
  its scripts are replaced by the kit's. It has no Cedar, so it tries half the kit. Its tracked build products and
  rendered videos are its own to tidy.
- **`opa-mcp-http`.** Not part of the kit. §4.
- **tla-kit.** One row in `CONSUMERS.md` for the policy kit, and this note. Nothing in the image changes.

---

## 4. `opa-mcp-http`: what it is for, and what is taken from it

It is a working server of fourteen tools, each one call to a running OPA's REST interface. Five of them change that
OPA: they upload or delete a policy, or put, patch or delete data.

| tla-kit's rule | `opa-mcp-http` |
|---|---|
| Every tool held to a digest (ADR-0002) | `node:20-alpine` by tag; dependencies by range; the lockfile is ignored by git; the OPA is whatever answers at `OPA_URL` |
| Confined to the mounted project, over stdio (ADR-0008) | A listener on a port, any origin allowed, no authentication |
| No evidence of the server's own (ADR-0006) | Five tools change the engine whose decisions are the evidence |
| The server calls the skill's scripts (ADR-0007) | No skill; and `check`, `test` and `build` are not in the REST interface at all |

- **It conflicts with TOPAK's bundle model.** A bundle is trusted by a signature over its revision (I34). A policy
  uploaded through the REST interface changes what a sidecar decides and moves neither. Aimed at the mechanism's
  sidecar, the write tools go around the control.
- **Taken from it: three tool shapes**, as `rego_eval` and `rego_partial` above, run against files with the pinned
  binary. No code: it is TypeScript on Node, and the kit's server is the standard library's Python.
- **What it could stay as:** a reader of a running sidecar for the development stack. Its status tool reports
  which revision a sidecar serves, and TOPAK's fallback rule turns on exactly that (I2). That use needs the five
  write tools removed. K7.
- **Found while reading it** (§6.3): its `Dockerfile` runs `npm ci` with no lockfile in the tree; its HTTP route
  calls a private map of the SDK's server; its `package.json` says MIT and its `LICENSE` is Apache-2.0.

---

## 5. Phases offered

The kit's own, numbered apart from `PLAN.md`'s. Each ends with a check that can fail.

### Phase P1: an image that can be cited

1. The `Dockerfile`, from tla-kit's digest, with `opa` and `cedar` pinned as §2.2 says, and `PINS.json`.
2. A self-test: the base's own, then `cedar` validates and analyses a fixture through the checked wrapper, and
   `opa` checks, tests and builds one.
3. CI, the release workflow and the attestations, in tla-kit's form.

**Done when:**
- TOPAK's genesis gate run and its four stage runs, made in the published image, give the verdicts of the
  committed results files, and the evidence tree's digest for the proof-carrying run;
- TOPAK's 38 Rego cases and `opa`'s 108 pass in it;
- `cedar` built twice gives one digest, or the reason it does not is written down.

### Phase P2: the skill

1. The method, as a `SKILL.md` with references, drawn from `floor/README.md`, `floor/proposed/README.md` and the
   bundle's rules in `GAPS-AND-ASSUMPTIONS.md`.
2. The scripts of §2.3, and the fixture with its flip test.
3. The bundle-identity module of §2.5, and the record K3 leads to.

**Done when:**
- TOPAK's floor runs under the skill's gate runner with a TOPAK file of signatures and candidates, and every
  verdict row matches `floor/run-gates.py`'s;
- a floor that is not TOPAK's goes from an empty directory to a passing gate run with the skill and the image
  alone;
- each of the fixture's mutations is caught by its gate.

### Phase P3: the server

The fourteen tools of §2.4, with an MCP client test in CI that drives each against the fixture.

**Done when** each tool gives the verdict of the script or binary it wraps on TOPAK's floor and bundle, and an
agent with only the server's tools, `Read` and `Edit` repairs a floor with one entry deliberately broken, as
tla-kit's Phase 4 did for a proof.

### Phase P4: the projects

TOPAK's pin and its `floor` job; `opa`'s scripts. Each by its own repository's decision.

**Done when** a pull request in TOPAK shows the floor's gates rerun in the image, and its bundle is built by a
compiler the results name.

### Phase P5: the chain

Gate results in a claims table, and the plugin that declares both servers. Needs tla-kit's Phase 7.

**Done when** one claims check reports a TLA+ property and a floor gate in sync, from two images, in one run.

---

## 6. What was tried

On 2026.11.21, in a scratch directory, with nothing changed in any repository.

### 6.1 One revision, more than one module

TOPAK's `policies/` was compiled as `build-bundle.sh` does (`opa build -t wasm -e topak/bundle/allow`, the same
revision, tests ignored), with upstream's static Linux x86_64 binary of eighteen releases. The revision computed from
the tree is `3e98ed17…5d62`, the name of the tracked bundle.

| OPA | `policy.wasm`, sha256 | Bytes |
|---|---|---|
| 1.0.0, 1.4.2, 1.8.0 to 1.11.0 | `c0fed3c6…c2b6` | 147,932 |
| 1.12.0, 1.12.3 | `830a742e…04aa` | 148,588 |
| 1.13.0 | `73d95d7e…` | 148,593 |
| 1.14.0 to 1.22.0 | `92a1484c…` | 142,852 |
| The tracked bundle, `mechanism/bundles/3e98ed17….tar.gz` | `c45a9f4c…c76f` | 147,868 |

- **Four modules from eighteen releases, all under one revision.** Within a release the build is stable: three
  releases were built twice and gave the same tarball, byte for byte.
- **None of the eighteen gives the tracked module.** The tracked bundle was made on 2026.10.05 from the Docker image
  `openpolicyagent/opa` with no tag. Which release that was, and whether the image's binary compiles as the static
  one does, was not found. Docker was not used here.
- **All 38 Rego cases pass under the fourteen releases they were run with**, at least one for each module, and so do `opa`'s 108 under the three it was tried with.
  So the modules differ in bytes; no difference in a decision was found, and none was looked for beyond the tests.
- Each of the first three binaries fetched matched the sha256 upstream publishes beside it.

This is a finding for TOPAK, and the open one its inventory and ADR-0070 already record, now with numbers: the
lease's `bundle` field, the sidecar's reported revision and the fallback's file name all name the sources, and the
thing that decides is the module.

### 6.2 `opa`'s policies

All 108 cases pass under OPA 1.0.0, 1.4.2 and 1.9.0.

### 6.3 `opa-mcp-http`

Installed with `npm install`, since there is no lockfile; `tsc` compiles; 170 tests in 8 suites pass. The tests
replace `fetch`, so no test reaches an OPA. The Docker build was not run. The server was not tried with an MCP
client.

### 6.4 Not tried

The `cedar` build and whether it reproduces; TOPAK's gates in tla-kit's image (its Python is 3.14, and TOPAK's CI
runs the gates on 3.12); any image at all.

---

## 7. Records this needs

In the policy kit, after the form of tla-kit's `decisions/`. Most are tla-kit's records restated for a second
family, and can say so in a line.

| Record | Title, short | Notes |
|---|---|---|
| ADR-0001 | One image of the policy tools, built from tla-kit's by digest, cited by digest, with two ways in | Takes tla-kit's ADR-0001, 0002, 0004, 0013 and 0014 as its form |
| ADR-0002 | `opa` is pinned as a compiler: a bundle names the compiler's digest and the module's | From §6.1. Says what a kept copy is, if K4 is yes |
| ADR-0003 | `cedar` is built once from locked source and kept, with symbolic analysis | Says what happens if the build does not reproduce |
| ADR-0004 | The skill is the source of the method, and the server calls its scripts | tla-kit's ADR-0006 to 0008, restated |
| ADR-0005 | The bundle's identity is specified in TLA+ before the builder is written | The module of §2.5 |

In TOPAK: one record to pin the policy kit, with ADR-0077 as its model; and one for what a bundle's identity covers
(K3), which amends I3. In tla-kit: none, unless K1 goes the other way.

---

## 8. Decisions owed

| | Decision | Recommendation |
|---|---|---|
| K1 | A sibling repository and image, a variant of tla-kit by tag, or the tools in tla-kit's base | A sibling. The base stays the TLA+ family's; the kit gets its own skill and releases; the cost is one more pin to move |
| K2 | Where the policy skill lives: the kit, or TOPAK's `skills/` with its scripts vendored | The kit. ADR-0007's vendoring was for a skill that already existed in TOPAK; this one does not exist yet |
| K3 | What a bundle's identity covers: the sources as now, the module too, or the sources and the compiler's digest | TOPAK's to decide. The module too is the direct fix; naming the compiler is the smaller change and leaves the property to the pin |
| K4 | Does the kit keep a copy of `opa`'s binary in a release, as tla-kit does for `tlapm` and `cvc5` | Yes, if upstream's assets can be replaced; check that first. It costs one release asset |
| K5 | Is Lean in scope | No. `floor/lean` is TOPAK's second derivation and needs a toolchain no image here carries. A Lean kit would be a third sibling |
| K6 | Does the server offer `admit` | Yes, as a composition of two inputs the project supplies, and labelled so. It is the one question an agent cannot answer with either engine alone |
| K7 | What becomes of `opa-mcp-http` | Keep it apart, remove the five write tools, fix the three defects of §4, and never aim it at a sidecar whose bundle is signed |
| K8 | The name | `policy-kit` is the working name. `cedar-opa-kit` says what is in it and ages if a third engine joins |
| K9 | Does the kit wait for tla-kit's Phase 2, or its ADR-0018 to ADR-0020 | No. P1 to P3 depend on a published tla-kit digest and nothing else. P5 waits for the claims check |

---

## 9. What this does not do

- **It does not prove anything about Rego.** There is no solver behind the bundle tier. The kit offers tests,
  coverage and partial evaluation, and says which is which. The asymmetry is TOPAK's design: the floor is the part
  that can permit, and it is the part with proofs.
- **It does not check the lift.** That a request means what its Cedar form says is the project's premise, and the
  kit's `admit` prints that it takes both forms as given.
- **It does not decide what a bundle's identity is.** §6.1 is evidence for that decision; the decision is TOPAK's.
- **It does not administer a running OPA.** No tool loads, replaces or deletes a policy in a server.
- **It does not sign.** It builds what is signed and reports its digests.
- **It does not replace the floor in Lean**, or anything else that is one project's own derivation.
- **A passing gate decides nothing about fitness.** The gates say a floor is total, refuses something, admits
  something and has no dead entry. Whether it is the right floor is a reviewer's reading, as ADR-0029 §5 has it.

---

## 10. Risks

| Risk | What follows | What limits it |
|---|---|---|
| The `cedar` build does not reproduce | Its pin is a kept binary no one can rebuild to the byte | The kept copy with its source, as for `tlapm`; P1's third test finds out early |
| Extracting the gate runner changes a verdict | TOPAK's floor evidence moves for no reason of TOPAK's | P2's first test compares every verdict row with the runner TOPAK has now |
| The kit lags tla-kit's base | Two kits cite two solvers, which is the thing the sibling was meant to prevent | The base is a pin, in the weekly check, moved by ADR-0013's rule |
| Symbolic analysis in `cedar` changes between versions | A gate's meaning moves with a pin | The self-test's negative controls, and the flip test, run on every pin move |
| A `rego_test` pass is read as a proof | False assurance | The tool's header, and the grade word beside every result |
| The skill is general on paper and TOPAK's in practice | A second project cannot use it | `opa` is the second project for Rego; P2's second test needs a floor that is not TOPAK's |
| The work grows past its use | Five phases for two consumers | P1 alone closes TOPAK's open finding and removes its CI's three installs. Each later phase can stop there |
