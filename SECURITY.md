# Security Policy

## Reporting a vulnerability

Please do not open a public issue for security problems.

Report them privately through GitHub's private vulnerability reporting:
go to the repository's **Security** tab and choose **Report a vulnerability**.

You should get a response within a few days. Once the problem is confirmed,
a fix will be prepared and the report disclosed after it is released.

## What is in scope

This repository's own code: the `Dockerfile`, the wrappers, `tla-kit-info` and `tla-kit-selftest` in `bin/`, the
scripts and workflows, and the MCP server once it exists.

The image also carries tools that are not part of this repository: the TLA+ tools, TLAPS, and the backends TLAPS
bundles (Isabelle, Poly/ML, GMP, Z3, Zenon, LS4). Report a problem in one of them to its upstream project. Tell us as
well, so that the pin can be moved once upstream has a fix. The backends are not patched here. They move only with
the prover.

## Supported versions

Only the latest release is supported, now [`v0.4.0`](https://github.com/scottcochran/tla-kit/releases/tag/v0.4.0).
Older releases stay available, and their digests keep resolving, but they get no fixes
([ADR-0014](decisions/ADR-0014.md), items 5 and 7).
