#!/bin/bash
# Write a version release's notes: what a reader needs to check a citation (ADR-0014 item 3).
#   tools/ci/release-notes.sh TAG DIGEST INFO_JSON [SCAN_FILE] > notes.md
#
# The kind of move, its evidence, and the line saying what a project must regenerate are the custodian's: they are
# the annotated tag's message, which the release workflow refuses to publish without. The rest is generated here.
set -euo pipefail
cd "$(dirname "$0")/../.."
tag=${1:?usage: release-notes.sh TAG DIGEST INFO_JSON [SCAN_FILE]}; digest=${2:?}; info=${3:?}; scan=${4:-}
image=ghcr.io/scottcochran/tla-kit
kept=$(python3 -c 'import json; p=next(p for p in json.load(open("PINS.json"))["pins"] if p["tool"]=="tlapm"); print(p["kept_release"])')
echo "$(git tag -l --format='%(contents)' "$tag")"
cat <<EOF

## Cite this image by its digest

\`\`\`
$image@$digest
\`\`\`

The tag \`$tag\` names the same image, for reading; a results file and a project's CI name the digest (ADR-0010
item 4). Check that it was built here, from this tag, by this workflow:

\`\`\`
gh attestation verify oci://$image@$digest --repo scottcochran/tla-kit
\`\`\`

## What it holds

The inventory, \`PINS.json\`, as committed at the tag, and \`tla-kit-info --json\` from the image, are attached. The
prover tarball, with the licence notices and the source of its copyleft parts, is kept in the release
[\`$kept\`](../../releases/tag/$kept) (ADR-0005 item 2).

\`\`\`
$(python3 -c '
import json, sys
f = json.load(open(sys.argv[1]))
print("checker  ", f["checker"]["path"], "sha256", f["checker"]["sha256"])
print("tlc      ", f["checker"]["tlc"])
print("prover   ", f["prover"]["path"], "sha256", f["prover"]["sha256"])
print("tlapm    ", f["prover"]["version"])
for b in f["backends"]: print("backend  ", b["name"], b["version"])
print("java     ", f["java"])
print("skill    ", f["skill"]["source"], "at", f["skill"]["commit"])
print("image    ", f["image"]["source"], "at", f["image"]["revision"], "committed", f["image"]["created"])
' "$info")
\`\`\`

The SBOM is attached, and attested with the digest. The vulnerability scan at release time, for packages rated
HIGH or CRITICAL:

\`\`\`
$( [ -n "$scan" ] && [ -f "$scan" ] && tail -c 6000 "$scan" || echo "not run" )
\`\`\`

Only the latest release is supported. This release stays available, and is never deleted (ADR-0014 items 5 and 7).
EOF
