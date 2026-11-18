#!/bin/bash
# The runs of derived/tla-kit-phase6-checks-2026.11.18.md, in the published v0.4.0, pulled by digest.
#   run.sh <TOPAK checkout at 0dfdfcd> <output directory>
# The two TOPAK commands are the evidence workflow's (.github/workflows/evidence.yml, topak-cert and topak-defects).
# On a Mac, --platform linux/amd64 runs the image under emulation.
set -euo pipefail
topak=$1; out=$2
img=ghcr.io/scottcochran/tla-kit@sha256:6c27b7a007d723b55c126eedd4a6f295ecefdfb98a1c27c34580eaab862b8f2f
run() { docker run --rm --platform linux/amd64 "$@"; }
docker pull --platform linux/amd64 "$img"
run "$img" tla-kit-selftest > "$out/selftest.txt" 2>&1; echo "exit $?" >> "$out/selftest.txt"
run "$img" tla-kit-info > "$out/info.txt" 2>&1
run --user "$(id -u):$(id -g)" -v "$topak:/work:ro" -w /work/spec -e TLAPM_UNPINNED=1 "$img" \
  ./proof-cert.sh Alone_proof > "$out/Alone-proof-cert.txt" 2>&1
set +e
run --user "$(id -u):$(id -g)" -v "$topak:/src:ro" -e TLAPM_UNPINNED=1 "$img" \
  sh -c 'cp -r /src /tmp/topak && cd /tmp/topak && spec/defects/defects-run.sh' > "$out/defects.txt" 2>&1
echo "exit $?" >> "$out/defects.txt"
