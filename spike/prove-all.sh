#!/bin/bash
# Spike: re-prove every <M>_proof.tla of a spec directory with the image's tlapm and compare the obligation
# count with the newest committed <M>-proof-results-*.txt. Run inside the image, the project mounted read-only:
#
#   docker run --rm -v "$PROJECT:/work:ro" -v "$PWD/spike:/spike:ro" tla-kit:spike /spike/prove-all.sh /work/spec
#
# Nothing is written to the project: the modules are copied to a temp directory and proved there, with the
# command the project's own driver uses (tlapm --cleanfp --strict --cache-dir <tmp>). It writes no results file.
# One line per module: module | committed count | this run | seconds | SAME, DIFFERENT, FAILED or NO BASELINE.
# Arguments after the directory name the modules to run (without _proof); the default is all of them.
set -u
src=${1:?usage: prove-all.sh <spec-dir> [Module ...]}; shift
work=$(mktemp -d /tmp/prove-all.XXXXXX)
cp "$src"/*.tla "$work"/
cd "$work" || exit 2
mods=("$@")
[ ${#mods[@]} -eq 0 ] && mods=($(ls ./*_proof.tla | sed 's|^\./||; s|_proof\.tla$||'))
echo "prover: tlapm $(tlapm --version 2>&1 | tail -1) sha256 $(sha256sum "$(command -v tlapm)" | cut -c1-16) on $(uname -m), $(nproc) CPUs"
echo "module | committed | this run | seconds | verdict"
status=0; total=0
for m in "${mods[@]}"; do
  base=$(ls "$src/$m"-proof-results-*.txt 2>/dev/null | sort | tail -1)
  want=$([ -n "$base" ] && grep -oE 'All [0-9]+ obligations proved' "$base" | tail -1 | grep -oE '[0-9]+')
  start=$(date +%s)
  out=$(tlapm --cleanfp --strict --cache-dir "$work/cache-$m" "${m}_proof.tla" 2>&1); code=$?
  secs=$(( $(date +%s) - start ))
  got=$(echo "$out" | grep -oE 'All [0-9]+ obligations proved' | tail -1 | grep -oE '[0-9]+')
  if [ "$code" -ne 0 ] || [ -z "$got" ]; then
    verdict=FAILED; status=1
    got=$(echo "$out" | grep -oE '[0-9]+/[0-9]+ obligations failed' | tail -1); got=${got:-exit $code}
    echo "$out" | grep -vE '^\(\* ' | tail -25 > "$work/$m.fail"
  elif [ -z "$want" ]; then verdict="NO BASELINE"
  elif [ "$got" = "$want" ]; then verdict=SAME; total=$((total + got))
  else verdict=DIFFERENT; status=1; fi
  echo "$m | ${want:--} | $got | $secs | $verdict"
done
echo "obligations proved in modules that match their baseline: $total"
for f in "$work"/*.fail; do [ -f "$f" ] && { echo "--- $(basename "$f" .fail)"; cat "$f"; }; done
exit $status
