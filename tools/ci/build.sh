#!/bin/bash
# Build the image the way CI and the release workflow do, fixed in time to the checked-out commit (ADR-0014 item 8).
#   tools/ci/build.sh [docker buildx build options ...]     for example --load -t tla-kit:ci, or an --output
#
# SOURCE_DATE_EPOCH is the commit's time. TLA_KIT_REVISION and TLA_KIT_CREATED are the commit and its time, for the
# OCI labels. BuildKit's own provenance and SBOM attestations are off: they would put the build's clock into what
# is pushed. The release workflow attests through GitHub instead (ADR-0014 item 4). If tools/ci/fetch-kept.sh has
# put the kept prover tarball in build/tlapm-tarball/, it is passed as the build context `tlapm-tarball`, which
# takes the place of the Dockerfile's download of the same file; the Dockerfile checks its sha256 either way. So
# are cvc5's and ethos's kept copies in build/kept-cvc5/, as the build context `kept-cvc5`.
# Pass --output type=...,rewrite-timestamp=true for files' times to be clamped to the commit's too.
set -euo pipefail
cd "$(dirname "$0")/../.."
sde=$(git log -1 --format=%ct)
created=$(date -u -d "@$sde" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -r "$sde" +%Y-%m-%dT%H:%M:%SZ)
ctx=()
[ -f build/tlapm-tarball/tlapm.tar.gz ] && ctx=(--build-context tlapm-tarball=build/tlapm-tarball)
[ -f build/kept-cvc5/cvc5.zip ] && ctx+=(--build-context kept-cvc5=build/kept-cvc5)
export SOURCE_DATE_EPOCH=$sde
set -x
docker buildx build --provenance=false --sbom=false ${ctx[@]+"${ctx[@]}"} \
  --build-arg SOURCE_DATE_EPOCH="$sde" \
  --build-arg TLA_KIT_REVISION="$(git rev-parse HEAD)" \
  --build-arg TLA_KIT_CREATED="$created" \
  "$@" .
