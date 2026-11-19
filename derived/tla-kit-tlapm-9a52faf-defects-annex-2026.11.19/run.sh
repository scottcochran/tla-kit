#!/bin/bash
# The run of derived/tla-kit-tlapm-9a52faf-defects-2026.11.19.md: TOPAK's defect run in the image of pull request #34
# (tlapm 9a52faf), built here from tla-kit c92220b, which has pull request #36's Ubuntu 26.04 base merged in.
#   run.sh <TOPAK checkout at 6a26310> <output directory>        from the root of tla-kit at c92220b
# The image was not published. It is built as CI builds it, from the kept copies. The defect run is the evidence
# workflow's (.github/workflows/evidence.yml, topak-defects). On a Mac, --platform linux/amd64 runs it under emulation.
set -euo pipefail
topak=$1; out=$2
tools/ci/fetch-kept.sh
tools/ci/build.sh --load -t tla-kit:9a52faf
run() { docker run --rm --platform linux/amd64 "$@"; }
run tla-kit:9a52faf tla-kit-info > "$out/info.txt" 2>&1
set +e
run --user "$(id -u):$(id -g)" -v "$topak:/src:ro" -e TLAPM_UNPINNED=1 tla-kit:9a52faf \
  sh -c 'cp -r /src /tmp/topak && cd /tmp/topak && spec/defects/defects-run.sh' > "$out/defects.txt" 2>&1
echo "exit $?" >> "$out/defects.txt"
