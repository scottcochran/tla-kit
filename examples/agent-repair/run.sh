#!/bin/sh
# Run the agent on the project: Claude Code with the writing-tla-specs-and-proofs plugin, whose .mcp.json starts
# the tla-kit server, and nothing else to work with but Read and Edit. The same command runs locally and in the
# Actions job (.github/workflows/agent.yml).
#   examples/agent-repair/run.sh PROJECT PLUGIN_DIR TRANSCRIPT
#
# PLUGIN_DIR is the plugin's root in a TOPAK checkout, skills/writing-tla-specs-and-proofs. The model is
# AGENT_MODEL, claude-opus-5-5 unless set. Claude Code needs its credentials, as ANTHROPIC_API_KEY in Actions.
#
# --restricted removes the tools that run commands, ignores settings files and keeps Read and Edit inside the
# project. --tools leaves Read and Edit of the built-in tools. --allowedTools names each of the server's tools,
# and --permission-mode dontAsk refuses anything else, an account's own connectors included.
set -eu
project=${1:?usage: run.sh PROJECT PLUGIN_DIR TRANSCRIPT}
plugin=$(cd "${2:?usage: run.sh PROJECT PLUGIN_DIR TRANSCRIPT}" && pwd)
out=${3:?usage: run.sh PROJECT PLUGIN_DIR TRANSCRIPT}
case $out in /*) ;; *) out="$PWD/$out" ;; esac
here=$(cd "$(dirname "$0")" && pwd)
prefix=mcp__plugin_writing-tla-specs-and-proofs_tla-kit__
allowed=Read,Edit
for t in info parse symbols evaluate tlc_run simulate coverage state_graph tlc_rows \
         prove proof_check proof_results flip_test proof_sync; do
  allowed="$allowed,$prefix$t"
done
cd "$project"
claude -p "$(cat "$here/prompt.txt")" \
  --model "${AGENT_MODEL:-claude-opus-5-5}" --restricted --tools "Read,Edit" \
  --plugin-dir "$plugin" --allowedTools "$allowed" --permission-mode dontAsk \
  --no-session-persistence --output-format stream-json --verbose < /dev/null > "$out"
