#!/usr/bin/env bash
# apply_settings.sh   bring a repository's settings up to the baseline (never changes visibility)
#
# Usage: apply_settings.sh <owner/repo> [--apply] [--baseline FILE]
#
# Without --apply it is a dry run: it reads the target and prints every call it would make, with its body, and
# changes nothing. With --apply it makes them.
#
# What it does, in order:
#   1. PATCH the repository with the baseline's "repo" block (features, merge methods, merge-commit wording, forking).
#   2. Rulesets, matched by name: PUT over a same-named ruleset, POST a missing one. A ruleset only on the target is
#      left alone and reported. A personal account's private repository needs GitHub Pro for rulesets; a refusal is
#      reported and the step is owed again straight after the flip.
#   3. Private vulnerability reporting, when the baseline has it on. GitHub offers it on public repositories only, so
#      on a private one it is reported as owed after the flip.
#   4. Security features: it only ever turns ON what the baseline has on. It never turns one off to match the
#      baseline. A protection the target has and the baseline lacks is reported for the custodian to decide.
#
# Visibility is not touched: that is make_public.sh, and the custodian's call.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
baseline="$here/../references/baseline.json"
apply=0; repo=""
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) apply=1 ;;
    --baseline) baseline="$2"; shift ;;
    -*) echo "unknown option $1" >&2; exit 2 ;;
    *) repo="$1" ;;
  esac
  shift
done
[ -n "$repo" ] || { echo "usage: $0 <owner/repo> [--apply] [--baseline FILE]" >&2; exit 2; }
[ -f "$baseline" ] || { echo "no baseline at $baseline" >&2; exit 2; }

owed=()
call() {  # call <METHOD> <path> [json body] : print it; under --apply, make it
  local method="$1" path="$2" body="${3:-}"
  echo "$method $path"
  [ -n "$body" ] && printf '%s\n' "$body" | jq -c . | sed 's/^/    /'
  [ "$apply" -eq 1 ] || return 0
  local out
  if [ -n "$body" ]; then out="$(printf '%s' "$body" | gh api -X "$method" "$path" --input - 2>&1)"
  else out="$(gh api -X "$method" "$path" 2>&1)"; fi && { echo "    -> ok"; return 0; }
  echo "    -> FAILED: $(printf '%s' "$out" | tail -1)"
  return 1
}

meta="$(gh api "repos/$repo")"
visibility="$(jq -r .visibility <<<"$meta")"
echo "target $repo ($visibility), baseline $(jq -r '.source + " " + .captured' "$baseline")"
[ "$apply" -eq 1 ] && echo "mode: APPLY" || echo "mode: dry run (nothing is changed; pass --apply to make these calls)"
echo

echo "## 1. repository settings"
call PATCH "repos/$repo" "$(jq '.repo | with_entries(select(.value != null))' "$baseline")" || owed+=("repository settings")
echo

echo "## 2. rulesets"
existing="$(gh api "repos/$repo/rulesets" 2>/dev/null || echo '[]')"
while IFS= read -r rs; do
  name="$(jq -r .name <<<"$rs")"
  id="$(jq -r --arg n "$name" '.[] | select(.name == $n) | .id' <<<"$existing" | head -1)"
  if [ -n "$id" ]; then call PUT "repos/$repo/rulesets/$id" "$rs" || owed+=("ruleset '$name'")
  else call POST "repos/$repo/rulesets" "$rs" || owed+=("ruleset '$name'"); fi
done < <(jq -c '.rulesets[]' "$baseline")
jq -r --slurpfile b "$baseline" '.[] | select(.name as $n | ($b[0].rulesets | map(.name) | index($n)) == null)
  | "    left alone, not in baseline: ruleset \"\(.name)\""' <<<"$existing"
echo

echo "## 3. private vulnerability reporting"
if [ "$(jq -r .security.private_vulnerability_reporting "$baseline")" = "true" ]; then
  if [ "$visibility" = "public" ]; then call PUT "repos/$repo/private-vulnerability-reporting" || owed+=("private vulnerability reporting")
  else echo "    owed after the flip: GitHub offers it on public repositories only"; owed+=("private vulnerability reporting (after the flip)"); fi
else echo "    baseline has it off; nothing to do"; fi
echo

echo "## 4. security features (only ever turned on, never off)"
target_sa="$(jq -c '.security_and_analysis // {} | with_entries(.value = .value.status)' <<<"$meta")"
on="$(jq -c --argjson t "$target_sa" '.security.security_and_analysis // {} | to_entries
       | map(select(.value == "enabled" and ($t[.key] // "disabled") != "enabled")) | from_entries' "$baseline")"
if [ "$on" != "{}" ]; then
  call PATCH "repos/$repo" "$(jq -c '{security_and_analysis: with_entries(.value = {status: "enabled"})}' <<<"$on")" \
    || owed+=("security features")
else echo "    nothing the baseline has on is off here"; fi
jq -r --argjson t "$target_sa" '.security.security_and_analysis // {} | to_entries[]
  | select(.value != "enabled" and $t[.key] == "enabled")
  | "    target has \(.key) on and the baseline has it off: left on for the custodian to decide"' "$baseline"
echo

if [ "${#owed[@]}" -gt 0 ]; then
  echo "OWED:"; printf '  %s\n' "${owed[@]}"
fi
echo "next: scripts/snapshot_settings.sh $repo > snap.json && scripts/compare_settings.py references/baseline.json snap.json"
