#!/bin/bash
# tla-kit experiment 2026.11.21, host side: run one leg.
#   drive.sh LEG SIDECAR_TAG|none SPEC_DIR [Module ...]
# SIDECAR_TAG names z3srv:<tag> (489-amd64, 541-amd64, 541-arm64). With `none`, the image's own z3 is used, unwrapped.
set -u
S=/private/tmp/claude-501/-Users-scott-dev-sandbox-tla-kit/90e76ea0-1116-4f6a-9c5c-54e6b0824870/scratchpad
leg=$1; tag=$2; spec=$3; shift 3
img=tla-kit:9a52faf
rm -rf "$S/logs/$leg" "$S/keep/$leg"; mkdir -p "$S/logs/$leg" "$S/keep/$leg"
docker rm -f "z3srv-$leg" >/dev/null 2>&1 || true
wrap=()
if [ "$tag" != none ]; then
  docker run -d --name "z3srv-$leg" --network z3net -e Z3_KEEP=/keep -v "$S/keep/$leg:/keep" "z3srv:$tag" >/dev/null
  sleep 1
  wrap=(-e "Z3_SERVER=z3srv-$leg:7777" -e Z3_LOG=/out/z3calls.tsv -v "$S/harness/z3wrap.py:/opt/tlaps/lib/tlapm/backends/bin/z3:ro")
fi
{ echo "leg $leg sidecar z3srv:$tag ($(docker image inspect -f '{{.Architecture}} {{.Id}}' "z3srv:$tag" 2>/dev/null)) image $img ($(docker image inspect -f '{{.Id}}' $img)) spec $spec modules: $*"; } > "$S/logs/$leg/leg.txt"
start=$(date +%s)
docker run --rm --platform linux/amd64 --network z3net ${wrap[@]+"${wrap[@]}"} -v "$spec:/spec:ro" -v "$S/harness:/h:ro" -v "$S/logs/$leg:/out" $img /h/run-leg.sh /spec "$@"
rc=$?
echo "wall $(( $(date +%s) - start )) s, exit $rc" | tee -a "$S/logs/$leg/leg.txt"
if [ "$tag" != none ]; then docker logs "z3srv-$leg" > "$S/logs/$leg/server.log" 2>&1; docker rm -f "z3srv-$leg" >/dev/null; fi
exit $rc
