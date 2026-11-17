#!/bin/sh
# Make the agent's project: a git repository holding the skill's fixture, with NextBounded's proof broken as
# server/test_prove.py breaks it. The same project serves a local session and the Actions job (PLAN.md Phase 5).
#   examples/agent-repair/make-project.sh DIR      DIR must not exist
set -eu
dir=${1:?usage: make-project.sh DIR}
here=$(cd "$(dirname "$0")" && pwd)
fix="$here/../../vendor/writing-tla-specs-and-proofs/assets/selftest"
[ ! -e "$dir" ] || { echo "make-project: $dir exists" >&2; exit 1; }
mkdir -p "$dir/spec"
cp "$fix/Counter.tla" "$fix/Counter-rows.txt" "$dir/spec/"
sed 's/^  BY LimitNat DEF TypeOK, Bounded, Next, Step, vars$/  BY DEF Bounded/' "$fix/Counter_proof.tla" \
  > "$dir/spec/Counter_proof.tla"
if cmp -s "$fix/Counter_proof.tla" "$dir/spec/Counter_proof.tla"; then
  echo "make-project: the step to break was not found in the fixture" >&2; exit 1
fi
git -C "$dir" init -q
git -C "$dir" add -A
git -C "$dir" -c user.name=tla-kit -c user.email=tla-kit@invalid commit -qm "The fixture, with NextBounded broken"
echo "make-project: $dir, with NextBounded's proof broken"
