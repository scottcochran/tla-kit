#!/bin/bash
# Regenerate spec/PinLifecycle.tla's rows in an image and compare them with the newest committed results file
# (ADR-0015 item 8).
#   tools/ci/pinlifecycle.sh IMAGE [JOBS]
#
# The rows are run under the newest results file's date, with the skill's generator. It never overwrites a results
# file: when every row is as expected and the output is the same, it says it reproduced the file byte for byte,
# and that is a pass. Anything else fails: a row not as expected writes nothing, and output that differs is
# written beside the file with a letter suffix, which is then left in spec/ for a look.
set -euo pipefail
cd "$(dirname "$0")/../.."
image=${1:?usage: tools/ci/pinlifecycle.sh IMAGE [JOBS]}
jobs=${2:-$(nproc 2>/dev/null || sysctl -n hw.ncpu)}
latest=$(ls spec/PinLifecycle-results-*.txt | sort | tail -1)
date=$(basename "$latest" | sed -E 's/^PinLifecycle-results-([0-9]{4}\.[0-9]{2}\.[0-9]{2})[a-z]?\.txt$/\1/')
echo "pinlifecycle: regenerating under $date, to compare with $latest"
set +e
out=$(docker run --rm --user "$(id -u):$(id -g)" -v "$PWD:/work" -e TLA_PROJECT=tla-kit "$image" \
  sh -c "python3 \$TLA_KIT_SKILL/scripts/tlc_rows.py spec/PinLifecycle-rows.txt -j $jobs --date $date" 2>&1)
code=$?
set -e
echo "$out" | tail -60
if [ "$code" -ne 0 ]; then echo "pinlifecycle: the generator exited $code"; exit 1; fi
if grep -qF "reproduced $(basename "$latest") byte for byte" <<< "$out" \
   || grep -qF "reproduced $latest byte for byte" <<< "$out"; then
  echo "pinlifecycle: every row as expected, and $latest reproduced byte for byte"
else
  echo "pinlifecycle: the rows did not reproduce $latest"
  git status --short spec/
  exit 1
fi
