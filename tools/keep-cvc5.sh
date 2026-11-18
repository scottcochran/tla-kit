#!/bin/bash
# Assemble the release that keeps cvc5's and ethos's zips (ADR-0017 item 1), and with --create, make it.
#   tools/keep-cvc5.sh            download and check every asset into build/kept-cvc5/, and print the release
#   tools/keep-cvc5.sh --create   the same, then create the release with gh (the custodian's step)
#
# The release is `cvc5-<version>`, made before the pull request that pins cvc5, ethos and the CPC signature, which
# move together (ADR-0017 item 4). It holds, beside the two zips, what the licence check's option A asks of every
# redistribution of them (derived/tla-kit-licence-check-cvc5-ethos-2026.11.17.md §5):
#   - licenses.tar.gz: this repository's licenses/ and NOTICE, with the notices the zips leave out (condition 1);
#   - the source of each copyleft part linked into the binaries (condition 2), at the release the bytes show
#     (condition 3, derived/tla-kit-static-libraries-2026.11.17.md):
#       glibc 2.35-0ubuntu3.14 (both) and GMP 6.2.1+dfsg-3ubuntu1 (ethos), as Ubuntu's source packages;
#       GMP 6.3.0 and MPFR 4.2.2 (cvc5), from the GNU mirror with their signatures; LibPoly 0.2.1 (cvc5);
#   - cvc5's source at its tag, which holds the CPC signature, and ethos's source at its tag;
#   - SHA256SUMS over all of them.
# Every download is checked against the sha256 below, and the script stops on any difference. GMP 6.3.0's, MPFR
# 4.2.2's and LibPoly 0.2.1's are the digests cvc5 1.4.0's own build names (cmake/FindGMP.cmake, FindMPFR.cmake,
# FindPoly.cmake). The tag is protected once made, and the release is never deleted (ADR-0014 items 2 and 5).
set -euo pipefail
export COPYFILE_DISABLE=1  # no macOS metadata in the archives
cd "$(dirname "$0")/.."
create=false; [ "${1:-}" = --create ] && create=true

release=cvc5-1.4.0
lp=https://launchpad.net/ubuntu/+archive/primary/+sourcefiles
# name | url | sha256, as downloaded on 2026.11.17
assets=(
  "cvc5-Linux-x86_64-static.zip|https://github.com/cvc5/cvc5/releases/download/cvc5-1.4.0/cvc5-Linux-x86_64-static.zip|61d13483ec9c4e8d05c7f3d532225255b2183a0c03b161d37d942d1ba089ec6d"
  "ethos-linux-x86_64.zip|https://github.com/cvc5/ethos/releases/download/ethos-0.2.4/ethos-linux-x86_64.zip|1582fd32d7ef8ae7b8d82b3da92fcc542939a4941402a9a71cf8b33a06a3d8bc"
  "cvc5-1.4.0-src.tar.gz|https://github.com/cvc5/cvc5/archive/refs/tags/cvc5-1.4.0.tar.gz|06c65b30693d1abf7c1393b497c799950de2833457920b9433da8e418bce9113"
  "ethos-0.2.4-src.tar.gz|https://github.com/cvc5/ethos/archive/refs/tags/ethos-0.2.4.tar.gz|5840d27051f298e210802a4a2ceec5387c2704b14b3ea06f240d5f86fc3ee0c6"
  "gmp-6.3.0.tar.bz2|https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.bz2|ac28211a7cfb609bae2e2c8d6058d66c8fe96434f740cf6fe2e47b000d1c20cb"
  "gmp-6.3.0.tar.bz2.sig|https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.bz2.sig|2a7df8bf6f026601dec3f21e00bf5b2901d81d48e64bba33a98b74b77cd41357"
  "mpfr-4.2.2.tar.xz|https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.2.tar.xz|b67ba0383ef7e8a8563734e2e889ef5ec3c3b898a01d00fa0a6869ad81c6ce01"
  "mpfr-4.2.2.tar.xz.sig|https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.2.tar.xz.sig|c63aa4c8a9e678b235e6bdeba3d79f0c0d35c355129ef478a5050655e636bfaa"
  "libpoly-0.2.1.tar.gz|https://github.com/SRI-CSL/libpoly/archive/refs/tags/v0.2.1.tar.gz|f9920afc876f998633348b9cbfcf180757ada48cc872040256c60ad0707b5a0f"
  "glibc_2.35-0ubuntu3.14.dsc|$lp/glibc/2.35-0ubuntu3.14/glibc_2.35-0ubuntu3.14.dsc|664a969f5ee1041221a3771e8a2956124a54ec40948287c34991a0a87d0fa0a4"
  "glibc_2.35-0ubuntu3.14.debian.tar.xz|$lp/glibc/2.35-0ubuntu3.14/glibc_2.35-0ubuntu3.14.debian.tar.xz|670206faef3f6baa3bbee01128c2a496d6aa5559c636fc6809ff111b2fd73ef4"
  "glibc_2.35.orig.tar.xz|$lp/glibc/2.35-0ubuntu3.14/glibc_2.35.orig.tar.xz|5123732f6b67ccd319305efd399971d58592122bcc2a6518a1bd2510dd0cf52e"
  "glibc_2.35.orig.tar.xz.asc|$lp/glibc/2.35-0ubuntu3.14/glibc_2.35.orig.tar.xz.asc|853aaaf17d7366817e814057a467625ee7c0b26240e8b878db0f33c389c7bcb6"
  "gmp_6.2.1+dfsg-3ubuntu1.dsc|$lp/gmp/2:6.2.1+dfsg-3ubuntu1/gmp_6.2.1+dfsg-3ubuntu1.dsc|aad30e80591b3a3bea84ef1c3d1c46657dcdd639a10f093b6a4a231461e015e6"
  "gmp_6.2.1+dfsg-3ubuntu1.debian.tar.xz|$lp/gmp/2:6.2.1+dfsg-3ubuntu1/gmp_6.2.1+dfsg-3ubuntu1.debian.tar.xz|371f81cd30902da41fb4cd084fa2d4e5e353c1f812e79184158479cc96aedd76"
  "gmp_6.2.1+dfsg.orig.tar.xz|$lp/gmp/2:6.2.1+dfsg-3ubuntu1/gmp_6.2.1+dfsg.orig.tar.xz|c6ba08e3f079260ab90ff44ab8801eae134cd62cd78f4aa56317c0e70daa40cb"
)
# The CPC signature's tree digest, as proof-cert.sh computes it over the .eo files of proofs/eo/cpc/ in cvc5's
# source. TOPAK's tools/cpc/ and its certified results files print the same value.
cpc_tree=633f74115700ad32

out=build/kept-cvc5; mkdir -p "$out"; tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
sha() { shasum -a 256 "$1" | cut -d' ' -f1; }
fetch() {  # name url want
  [ -f "$out/$1" ] || curl -sSLf --retry 3 -o "$out/$1" "$2"
  local got; got=$(sha "$out/$1")
  if [ "$got" != "$3" ]; then echo "keep-cvc5: $1 is sha256 $got, expected $3" >&2; exit 1; fi
  echo "  $1  $got"
}
echo "keep-cvc5: assembling $release in $out"
for a in "${assets[@]}"; do IFS='|' read -r n u w <<< "$a"; fetch "$n" "$u" "$w"; done
tar -xzf "$out/cvc5-1.4.0-src.tar.gz" -C "$tmp" cvc5-cvc5-1.4.0/proofs/eo/cpc
got=$(cd "$tmp/cvc5-cvc5-1.4.0/proofs/eo/cpc" && find . -type f -name '*.eo' | LC_ALL=C sort | xargs shasum -a 256 \
      | shasum -a 256 | cut -c1-16)
[ "$got" = "$cpc_tree" ] || { echo "keep-cvc5: the CPC signature's tree is $got, expected $cpc_tree" >&2; exit 1; }
echo "  (the CPC signature in cvc5-1.4.0-src.tar.gz, tree $got)"
tar -czf "$out/licenses.tar.gz" licenses NOTICE LICENSE LICENSE-DOCS
echo "  licenses.tar.gz  $(sha "$out/licenses.tar.gz")"
(cd "$out" && shasum -a 256 $(ls | grep -v -e '^SHA256SUMS$' -e '^NOTES.md$') > SHA256SUMS)

cat > "$out/NOTES.md" <<'EOF'
cvc5's and ethos's Linux x86_64 builds, which tla-kit's image installs, kept so that its images can be rebuilt
after upstream stops serving them (ADR-0017). The two binaries are static, and link LGPL libraries. This release
also holds those libraries' source, at the releases their bytes show. This release is never deleted, and its tag
is never moved (ADR-0014 items 2 and 5). No image is published from it: the version releases link to it.

| Asset | What it is |
|---|---|
| `cvc5-Linux-x86_64-static.zip` | Upstream's cvc5 1.4.0 (`b432cd7`), its static build without GPL libraries, byte for byte as served on 2026.11.17 |
| `ethos-linux-x86_64.zip` | Upstream's ethos 0.2.4 (`8dc85c4`), the commit cvc5 1.4.0 names, byte for byte as served on 2026.11.17 |
| `cvc5-1.4.0-src.tar.gz` | cvc5's source at tag `cvc5-1.4.0` (BSD-3-Clause), which holds the CPC signature at `proofs/eo/cpc/` |
| `ethos-0.2.4-src.tar.gz` | ethos's source at tag `ethos-0.2.4` (BSD-3-Clause) |
| `gmp-6.3.0.tar.bz2`, `.sig` | The source of GMP 6.3.0 (LGPL-3.0-or-later or GPL-2.0-or-later), linked into cvc5, from the GNU mirror, with its signature |
| `mpfr-4.2.2.tar.xz`, `.sig` | The source of MPFR 4.2.2 (LGPL-3.0-or-later), linked into cvc5, from the GNU mirror, with its signature |
| `libpoly-0.2.1.tar.gz` | The source of LibPoly 0.2.1 (LGPL-3.0), linked into cvc5, `SRI-CSL/libpoly` at tag `v0.2.1` |
| `glibc_2.35-0ubuntu3.14.*`, `glibc_2.35.orig.tar.xz`, `.asc` | Ubuntu 22.04's source package of glibc `2.35-0ubuntu3.14` (LGPL-2.1-or-later), linked into both |
| `gmp_6.2.1+dfsg-3ubuntu1.*`, `gmp_6.2.1+dfsg.orig.tar.xz` | Ubuntu 22.04's source package of GMP `2:6.2.1+dfsg-3ubuntu1`, linked into ethos |
| `licenses.tar.gz` | tla-kit's notice of the third-party software in the image, with the licence texts the zips leave out (`licenses/THIRD-PARTY.md`) |
| `SHA256SUMS` | The sha256 of every asset above |

How each library's release and licence were settled: `derived/tla-kit-licence-check-cvc5-ethos-2026.11.17.md` and
`derived/tla-kit-static-libraries-2026.11.17.md` in the repository.
EOF
echo
cat "$out/SHA256SUMS"
if ! $create; then
  echo
  echo "keep-cvc5: not created. With --create: gh release create $release --latest=false --title '$release' --notes-file $out/NOTES.md <assets>"
  exit 0
fi
if gh release view "$release" >/dev/null 2>&1; then echo "keep-cvc5: $release exists already; it is never replaced" >&2; exit 1; fi
gh release create "$release" --target main --latest=false --title "$release: the kept cvc5 and ethos" \
  --notes-file "$out/NOTES.md" $(cd "$out" && ls | grep -v '^NOTES.md$' | sed "s|^|$out/|")
