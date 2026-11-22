#!/bin/bash
# tla-kit experiment 2026.11.21: inside the tla-kit container, prove every <M>_proof.tla of a spec directory
# (mounted read-only) with the image's tlapm, as spike/prove-all.sh does, and write the outcome under /out:
# summary.tsv (module, committed count, this run, seconds, verdict), and <M>.txt with tlapm's full output.
#   run-leg.sh <spec-dir> [Module ...]
set -u
src=${1:?usage: run-leg.sh <spec-dir> [Module ...]}; shift
out=/out; mkdir -p "$out"
work=$(mktemp -d /tmp/leg.XXXXXX)
cp "$src"/*.tla "$work"/
cd "$work" || exit 2
mods=("$@")
[ ${#mods[@]} -eq 0 ] && mods=($(ls ./*_proof.tla | sed 's|^\./||; s|_proof\.tla$||'))
{
  echo "prover: tlapm $(tlapm --version 2>&1 | tail -1) sha256 $(sha256sum "$(command -v tlapm)" | cut -c1-16) on $(uname -m), $(nproc) CPUs"
  echo "z3 at backends/bin: $(/opt/tlaps/lib/tlapm/backends/bin/z3 -version 2>&1 | head -1); Z3_SERVER=${Z3_SERVER:-none}"
  echo "started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$out/run.txt"
printf 'module\tcommitted\tthis_run\tseconds\tverdict\n' > "$out/summary.tsv"
status=0; T0=$(date +%s)
for m in "${mods[@]}"; do
  base=$(ls "$src/$m"-proof-results-*.txt 2>/dev/null | sort | tail -1)
  want=$([ -n "$base" ] && grep -oE 'All [0-9]+ obligations proved' "$base" | tail -1 | grep -oE '[0-9]+')
  start=$(date +%s%N)
  tlapm --cleanfp --strict --cache-dir "$work/cache-$m" "${m}_proof.tla" > "$out/$m.txt" 2>&1; code=$?
  ms=$(( ($(date +%s%N) - start) / 1000000 )); secs=$((ms / 1000)).$(( (ms % 1000) / 100 ))
  got=$(grep -oE 'All [0-9]+ obligations proved' "$out/$m.txt" | tail -1 | grep -oE '[0-9]+')
  if [ "$code" -ne 0 ] || [ -z "$got" ]; then
    verdict=FAILED; status=1
    got=$(grep -oE '[0-9]+/[0-9]+ obligations failed' "$out/$m.txt" | tail -1); got=${got:-exit $code}
  elif [ -z "$want" ]; then verdict="NO BASELINE"
  elif [ "$got" = "$want" ]; then verdict=SAME
  else verdict=DIFFERENT; status=1; fi
  printf '%s\t%s\t%s\t%s\t%s\n' "$m" "${want:--}" "$got" "$secs" "$verdict" | tee -a "$out/summary.tsv"
done
echo "finished: $(date -u +%Y-%m-%dT%H:%M:%SZ), total $(( $(date +%s) - T0 )) s, exit $status" | tee -a "$out/run.txt"
exit $status
