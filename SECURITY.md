# Security Policy

## Reporting a vulnerability

Please do not open a public issue for security problems.

Report them privately through GitHub's private vulnerability reporting:
go to the repository's **Security** tab and choose **Report a vulnerability**.

You should get a response within a few days. Once the problem is confirmed,
a fix will be prepared and the report disclosed after it is released.

## What is in scope

This repository's own code: the `Dockerfile`, the wrappers and `tla-kit-info` in `bin/`, the scripts, and the
MCP server once it exists.

The image also carries tools that are not part of this repository: the TLA+ tools, TLAPS, and the backends TLAPS
bundles (Isabelle, Poly/ML, Z3, Zenon, LS4). Report a problem in one of them to its upstream project. Tell us as
well, so that the pin can be moved once upstream has a fix. The backends are not patched here. They move only with
the prover.

## Supported versions

Nothing has been released yet. Until the first release, only the latest commit on `main` is supported. After it,
only the latest release will be, and older releases stay available without fixes (proposed in
[ADR-0014](decisions/ADR-0014.md), item 7).
