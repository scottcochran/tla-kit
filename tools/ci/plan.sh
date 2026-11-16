#!/bin/bash
# What does a CI run compare against, and what does the change touch?
#   tools/ci/plan.sh EVENT [PR_BASE_SHA] [PUSH_BEFORE_SHA]
# Prints key=value lines, for $GITHUB_OUTPUT:
#   base=<sha>     pull_request: the pull request's base; push: the commit before the push; otherwise, or when that
#                  commit is unknown, HEAD's parent
#   moved=<list>   the pins PINS.json moves against base, as `<kind> <tool>` separated by `;` (tools/pins.py moved)
#   checker=       true when a checker pin moves (ADR-0013 item 1)
#   rows=          true when the PinLifecycle rows are regenerated: the change touches spec/ or decisions/, or moves
#                  a checker pin (ADR-0014 item 1, ADR-0015 item 8), or changes the vendored scripts that generate
#                  them or this plan; always on workflow_dispatch
#   server=        true when the MCP server's tools are compared with their commands on TOPAK (ADR-0008 item 5):
#                  the change touches server/, the vendored scripts, bin/, the Dockerfile or this plan, or moves
#                  a checker pin; always on workflow_dispatch
# Runs the same by hand: tools/ci/plan.sh pull_request "$(git merge-base origin/main HEAD)".
set -u
cd "$(dirname "$0")/../.."
event=${1:?usage: tools/ci/plan.sh EVENT [PR_BASE_SHA] [PUSH_BEFORE_SHA]}
pr_base=${2:-}; before=${3:-}
known() { [ -n "$1" ] && ! [[ "$1" =~ ^0+$ ]] && git cat-file -e "$1^{commit}" 2>/dev/null; }
if [ "$event" = pull_request ] && known "$pr_base"; then base=$pr_base
elif [ "$event" = push ] && known "$before"; then base=$before
else base=$(git rev-parse HEAD~1 2>/dev/null || git rev-parse HEAD); fi
moved=$(python3 tools/pins.py moved "$base" | paste -sd ';' -)
checker=false; grep -qE '(^|;)checker ' <<< "$moved" && checker=true
changed=$(git diff --name-only "$base" HEAD)
rows=false
if [ "$event" = workflow_dispatch ] || [ "$checker" = true ] \
   || grep -qE '^(spec|decisions|vendor)/|^tools/ci/(plan|pinlifecycle)\.sh$' <<< "$changed"; then rows=true; fi
server=false
if [ "$event" = workflow_dispatch ] || [ "$checker" = true ] \
   || grep -qE '^(server|vendor|bin)/|^Dockerfile$|^tools/ci/plan\.sh$' <<< "$changed"; then server=true; fi
echo "base=$base"
echo "moved=$moved"
echo "checker=$checker"
echo "rows=$rows"
echo "server=$server"
