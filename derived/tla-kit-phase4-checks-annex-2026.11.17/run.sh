#!/bin/sh
# The agent's run, as made on 2026.11.17 with Claude Code 2.1.312. <run> is a fresh directory holding project/spec/
# (the fixture's Counter.tla and Counter-rows.txt, and Counter_proof.tla with NextBounded broken), mcp.json and
# prompt.txt. The working directory is the project, so Read and Edit reach nothing else.
cd <run>/project && claude -p "$(cat <run>/prompt.txt)" \
  --model claude-opus-5-5 --restricted --tools "Read,Edit" \
  --mcp-config <run>/mcp.json --strict-mcp-config \
  --allowedTools "mcp__tla-kit" "Read" "Edit" --permission-mode dontAsk \
  --no-session-persistence --output-format stream-json --verbose > <run>/transcript.jsonl
