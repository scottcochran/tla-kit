#!/bin/bash
# Assemble the release that keeps the pinned TLAPS tarball (ADR-0005 item 2), and with --create, make it.
#   tools/keep-tlapm.sh            download and check every asset into build/kept-tlapm/, and print the release
#   tools/keep-tlapm.sh --create   the same, then create the release with gh (the custodian's step)
#
# The release is PINS.json's `kept_release` (`tlapm-<commit>`), made before the pull request that pins the build.
# It holds, beside the tarball, what PLAN.md D7's conditions ask of every redistribution of it:
#   - licenses.tar.gz: this repository's licenses/ and NOTICE, the notices the tarball leaves out (condition 1);
#   - the source of its copyleft parts (condition 2), each at the release the tarball bundles, as settled in
#     derived/tla-kit-copyleft-sources-2026.11.16.md (condition 3):
#       Poly/ML 5.9.1 (LGPL-2.1), GMP 6.1.2 (LGPL-3.0-or-later or GPL-2.0-or-later), and libsha1, GNU coreutils
#       8.4's sha1.c as Isabelle builds it (GPL-3.0-or-later);
#   - SHA256SUMS over all of them.
# Every download is checked against the sha256 below or in PINS.json, and the script stops on any difference.
# The tag is protected once made, and the release is never deleted (ADR-0014 items 2 and 5).
set -euo pipefail
export COPYFILE_DISABLE=1  # no macOS metadata in the archives
cd "$(dirname "$0")/.."
create=false; [ "${1:-}" = --create ] && create=true

read -r release asset tarball_sha upstream < <(python3 - <<'EOF'
import json, os
p = next(p for p in json.load(open("PINS.json"))["pins"] if p["tool"] == "tlapm")
print(p["kept_release"], os.path.basename(p["kept_copy"]), p["download_sha256"], p["upstream"])
EOF
)

# name | url | sha256, as downloaded on 2026.11.16
sources=(
  "polyml-5.9.1-src.tar.gz|https://github.com/polyml/polyml/archive/refs/tags/v5.9.1.tar.gz|52f56a57a4f308f79446d479e744312195b298aa65181893bce2dfc023a3663c"
  "gmp-6.1.2.tar.xz|https://ftp.gnu.org/gnu/gmp/gmp-6.1.2.tar.xz|87b565e89a9a684fe4ebeeddb8399dce2599f9c9049854ca8c0dfbdea0e21912"
  "gmp-6.1.2.tar.xz.sig|https://ftp.gnu.org/gnu/gmp/gmp-6.1.2.tar.xz.sig|b4c5d62aeaff4158a8a1bd3284e520ac804b0e2f9865111b272c9abd6824f9b0"
)
component_url=https://isabelle.in.tum.de/components/polyml-5.9.1.tar.gz
component_sha=f633d451b76962099b5ae184fd574ff20d69205d74f2d41e1b514f249cb7e871

out=build/kept-tlapm; mkdir -p "$out"; tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
sha() { shasum -a 256 "$1" | cut -d' ' -f1; }
fetch() {  # name url want
  [ -f "$out/$1" ] || curl -sSLf --retry 3 -o "$out/$1" "$2"
  local got; got=$(sha "$out/$1")
  if [ -n "$3" ] && [ "$got" != "$3" ]; then echo "keep-tlapm: $1 is sha256 $got, expected $3" >&2; exit 1; fi
  echo "  $1  $got"
}
echo "keep-tlapm: assembling $release in $out"
fetch "$asset" "$upstream" "$tarball_sha"
for s in "${sources[@]}"; do IFS='|' read -r n u w <<< "$s"; fetch "$n" "$u" "$w"; done
# libsha1's source is the sha1/ directory of Isabelle2025's polyml-5.9.1 component, from which the tarball's
# libsha1.so and libgmp.so.10 are copied byte for byte.
if [ ! -f "$out/libsha1-src.tar.gz" ]; then
  curl -sSLf --retry 3 -o "$tmp/component.tar.gz" "$component_url"
  [ "$(sha "$tmp/component.tar.gz")" = "$component_sha" ] || { echo "keep-tlapm: $component_url changed" >&2; exit 1; }
  tar -xzf "$tmp/component.tar.gz" -C "$tmp" polyml-5.9.1/sha1 polyml-5.9.1/README
  tar -czf "$out/libsha1-src.tar.gz" -C "$tmp/polyml-5.9.1" sha1 README
fi
echo "  libsha1-src.tar.gz  $(sha "$out/libsha1-src.tar.gz")"
tar -czf "$out/licenses.tar.gz" licenses NOTICE LICENSE LICENSE-DOCS
echo "  licenses.tar.gz  $(sha "$out/licenses.tar.gz")"
(cd "$out" && shasum -a 256 $(ls | grep -v -e '^SHA256SUMS$' -e '^NOTES.md$') > SHA256SUMS)

cat > "$out/NOTES.md" <<EOF
The TLAPS tarball tla-kit pins, kept so that its images can be rebuilt after upstream rebuilds the rolling
\`1.6.0-pre\` tag (ADR-0005 item 2). This release is never deleted, and its tag is never moved (ADR-0014 items 2
and 5). No image is published from it: the version releases link to it.

| Asset | What it is |
|---|---|
| \`$asset\` | Upstream's tarball, built from \`tlaplus/tlapm\` at \`ff40755\`, byte for byte as served on 2026.11.15 (sha256 \`$tarball_sha\`) |
| \`licenses.tar.gz\` | tla-kit's notice of the third-party software in the tarball and the image, with the licence texts the tarball leaves out (\`licenses/THIRD-PARTY.md\`) |
| \`polyml-5.9.1-src.tar.gz\` | The source of Poly/ML 5.9.1 (LGPL-2.1), \`polyml/polyml\` at \`90c0dbb2514e\`, tag \`v5.9.1\`, which Isabelle2025's \`polyml-5.9.1\` component is built from |
| \`gmp-6.1.2.tar.xz\`, \`.sig\` | The source of GMP 6.1.2 (LGPL-3.0-or-later or GPL-2.0-or-later), the release the tarball's \`libgmp.so.10\` reports, from the GNU mirror, with its signature |
| \`libsha1-src.tar.gz\` | The source of \`libsha1.so\` (GPL-3.0-or-later): GNU coreutils 8.4's \`sha1.c\`, as Isabelle2025's \`polyml-5.9.1\` component builds it, with that component's README |
| \`SHA256SUMS\` | The sha256 of every asset above |

How each part's release and licence were settled: \`derived/tla-kit-copyleft-sources-2026.11.16.md\` in the repository.
EOF
echo
cat "$out/SHA256SUMS"
if ! $create; then
  echo
  echo "keep-tlapm: not created. With --create: gh release create $release --latest=false --title '$release' --notes-file $out/NOTES.md <assets>"
  exit 0
fi
if gh release view "$release" >/dev/null 2>&1; then echo "keep-tlapm: $release exists already; it is never replaced" >&2; exit 1; fi
gh release create "$release" --target main --latest=false --title "$release: the kept TLAPS tarball" \
  --notes-file "$out/NOTES.md" $(cd "$out" && ls | grep -v '^NOTES.md$' | sed "s|^|$out/|")
