#!/bin/bash
# Download the kept prover tarball from this repository's release (ADR-0005 item 2), check it against PINS.json,
# and put it where tools/ci/build.sh passes it to the build: build/tlapm-tarball/tlapm.tar.gz.
#   GH_TOKEN=<token> tools/ci/fetch-kept.sh
#
# The release is `kept_release` in PINS.json's tlapm entry. It is made before the pull request that pins the build
# (ADR-0005 item 2), so a pull request that names a build with no kept copy fails here, with a message that says
# so. CI takes the copy this way, not by the Dockerfile's URL, so that the failure is that message.
set -euo pipefail
cd "$(dirname "$0")/../.."
read -r release asset sha < <(python3 - <<'EOF'
import json, os
p = next(p for p in json.load(open("PINS.json"))["pins"] if p["tool"] == "tlapm")
print(p["kept_release"], os.path.basename(p["kept_copy"]), p["download_sha256"])
EOF
)
mkdir -p build/tlapm-tarball
if ! gh release download "$release" --pattern "$asset" --dir build/tlapm-tarball --clobber; then
  echo "fetch-kept: release $release has no asset $asset. The kept copy is made before the pull request that pins" >&2
  echo "the build (ADR-0005 item 2): tools/keep-tlapm.sh." >&2
  exit 1
fi
mv "build/tlapm-tarball/$asset" build/tlapm-tarball/tlapm.tar.gz
echo "$sha  build/tlapm-tarball/tlapm.tar.gz" | sha256sum -c -
