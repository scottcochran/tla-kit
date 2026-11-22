#!/bin/bash
S=/private/tmp/claude-501/-Users-scott-dev-sandbox-tla-kit/90e76ea0-1116-4f6a-9c5c-54e6b0824870/scratchpad
spec=/Users/scott/dev/sandbox/TOPAK/spec
echo "TOPAK $(git -C /Users/scott/dev/sandbox/TOPAK rev-parse --short HEAD) $(date -u +%FT%TZ)" > $S/logs/all-legs.txt
for leg in "A-z3-4.8.9-amd64-emulated 489-amd64" "C-z3-5.4.1-arm64-native 541-arm64" "B-z3-5.4.1-amd64-emulated 541-amd64" "A0-pristine none"; do
  set -- $leg
  echo "=== $1 start $(date -u +%FT%TZ)" >> $S/logs/all-legs.txt
  $S/harness/drive.sh "$1" "$2" "$spec" 2>&1 | grep -v WARNING >> $S/logs/all-legs.txt
  echo "=== $1 end $(date -u +%FT%TZ)" >> $S/logs/all-legs.txt
done
echo "ALL DONE $(date -u +%FT%TZ)" >> $S/logs/all-legs.txt
