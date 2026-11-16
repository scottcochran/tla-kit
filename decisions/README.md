# Decisions

Architecture decision records, one file each, after the form of TOPAK's `decisions/`. They were drafted on
2026.11.15 from [PLAN.md](../PLAN.md) and [the founding session
record](../derived/tla-kit-founding-session-2026.11.15.md), all as Proposed. **ADR-0001 to ADR-0008,
ADR-0010, ADR-0011 and ADR-0013 to ADR-0015 were accepted by the custodian on 2026.11.15 and 2026.11.16, and the
rest are Proposed.** The custodian chose the idea, the name and the spike. Every other choice was the
assistant's, or is a recommendation the plan lists as owed. Nothing here is accepted until the custodian accepts it.

Once a record is accepted it is not edited. A change is a History row, or a new record that supersedes it.

Each record has a **Chosen by** line (the custodian, the assistant, or owed) and a **State** line (built in the
spike, or planned for a phase of `PLAN.md`). An accepted record's State line is as it was at acceptance; its later
state is in its History rows, and the State column below follows them.

| Record | Title | Chosen by | State | Status |
|---|---|---|---|---|
| [ADR-0001](ADR-0001.md) | One image of the TLA+ tool family, cited by digest, with two ways in | Custodian (the idea); assistant (the form) | Built in part | Accepted · 2026.11.15 |
| [ADR-0002](ADR-0002.md) | Every tool is held to a digest, and every result names the image's digest | Assistant | Built in part | Accepted · 2026.11.15 |
| [ADR-0003](ADR-0003.md) | The base is Ubuntu 24.04 with Temurin JRE 25, on Linux x86_64 only | Assistant (forced by glibc) | Built | Accepted · 2026.11.15 |
| [ADR-0004](ADR-0004.md) | The image speaks through the variables the projects already read | Assistant | Built | Accepted · 2026.11.15 |
| [ADR-0005](ADR-0005.md) | One prover build per image, from a copy of its tarball kept here | Assistant | Built; the weekly comparison has not run yet | Accepted · 2026.11.15 |
| [ADR-0006](ADR-0006.md) | The MCP server has no way of its own to write a results file | Assistant | Planned, Phases 3 and 4 | Accepted · 2026.11.16 |
| [ADR-0007](ADR-0007.md) | The skill is the source of the method; its scripts are vendored here at a named commit | Custodian (D2) | Built in part: vendored; the server is Phase 3 | Accepted · 2026.11.15 |
| [ADR-0008](ADR-0008.md) | The MCP server is Python over stdio, inside the image, confined to the mounted project | Assistant; custodian (the standard library) | Planned, Phases 3 and 5 | Accepted · 2026.11.16 |
| [ADR-0009](ADR-0009.md) | The proof tools follow marco6/tlapm-mcp's design, with named changes, and do not depend on it | Owed (D6) | Planned, Phase 4 | Proposed |
| [ADR-0010](ADR-0010.md) | The image is published at `ghcr.io/scottcochran/tla-kit`, public, from a tag | Custodian (D3) | Built: `v0.1.0` published | Accepted · 2026.11.16 |
| [ADR-0011](ADR-0011.md) | Code is licensed Apache-2.0 and documentation CC BY 4.0, as in TOPAK | Custodian (D4) | Built | Accepted · 2026.11.15 |
| [ADR-0012](ADR-0012.md) | One base image; large optional tools as variants by tag, each added with a check that uses it | Owed (D5) | Planned, Phase 6 | Proposed |
| [ADR-0013](ADR-0013.md) | Every pin moves by one rule: one pull request, evidence that fits what the pin can change | Assistant | Built; the weekly check has not run yet | Accepted · 2026.11.15 |
| [ADR-0014](ADR-0014.md) | Every pull request is built and tested; a release is an immutable tag, attested, and never deleted | Assistant | Built in part: Phase 1 done; the projects' pins are Phase 2 | Accepted · 2026.11.15 |
| [ADR-0015](ADR-0015.md) | The pin and release process is specified in TLA+, and checked by TLC before the records it covers are accepted | Custodian (that it is written); assistant (its scope) | Built | Accepted · 2026.11.15 |
| [ADR-0016](ADR-0016.md) | The `prove` tool's requests, processes and cache are specified in TLA+ before the tool is built | Custodian (that it is written); assistant (its scope) | Planned, Phase 4 | Proposed |

**Not recorded here.** `PLAN.md`'s D1, whether TOPAK moves `tools/TLAPS-PIN` to the image's Linux prover, is
TOPAK's decision and is made there. So is the same question for gov-tla. ADR-0005 says what tla-kit provides
either way.
