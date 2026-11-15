#!/usr/bin/env bash
# snapshot_settings.sh   the GitHub settings of one repository, in the shape of references/baseline.json
#
# Usage: snapshot_settings.sh <owner/repo> > snapshot.json
#
# Reads only. Prints JSON with the same keys as the baseline so compare_settings.py can diff the two. Fields that are
# the repository's own (name, description, homepage, topics) are left out on purpose: they are not settings to copy.
# Anything the API refuses (a 403 from a proxy, a 404 on a private repository) comes back as null and is listed under
# "unreadable", so a gap is never mistaken for a value.
set -euo pipefail
[ $# -eq 1 ] || { echo "usage: $0 <owner/repo>" >&2; exit 2; }
repo="$1"
unreadable=()

get() {  # get <path> : JSON on stdout, or "null" with the path recorded as unreadable
  local out path="repos/$repo${1:+/$1}"
  if out="$(gh api "$path" 2>/dev/null)"; then printf '%s' "$out"; else unreadable+=("$1"); printf 'null'; fi
}

meta="$(get "")"
[ "$meta" = "null" ] && { echo "cannot read repos/$repo" >&2; exit 1; }

pvr="$(get private-vulnerability-reporting)"
csd="$(get code-scanning/default-setup)"
vuln_alerts="$(gh api -i "repos/$repo/vulnerability-alerts" 2>/dev/null | head -1 | awk '{print $2}' || true)"
case "$vuln_alerts" in 204) vuln_alerts=true ;; 404) vuln_alerts=false ;; *) vuln_alerts=null; unreadable+=(vulnerability-alerts) ;; esac

rulesets="[]"
list="$(get rulesets)"
if [ "$list" != "null" ]; then
  rulesets="$(printf '%s' "$list" | jq -r '.[].id' | while read -r id; do
      gh api "repos/$repo/rulesets/$id" | jq '{name, target, enforcement, conditions, rules, bypass_actors}'
    done | jq -s 'sort_by(.name)')"
fi

for p in actions/permissions actions/permissions/workflow environments autolinks hooks pages collaborators; do
  gh api "repos/$repo/$p" >/dev/null 2>&1 || unreadable+=("$p")
done

jq -n \
  --arg source "$repo" \
  --arg captured "$(date -u +%Y-%m-%d)" \
  --argjson meta "$meta" \
  --argjson pvr "$pvr" \
  --argjson csd "$csd" \
  --argjson va "$vuln_alerts" \
  --argjson rulesets "$rulesets" \
  --argjson unreadable "$(printf '%s\n' "${unreadable[@]:-}" | jq -R . | jq -s 'map(select(length > 0))')" \
'{
  source: $source,
  captured: $captured,
  visibility: $meta.visibility,
  default_branch: $meta.default_branch,
  repo: ($meta | {
    has_issues, has_projects, has_wiki, has_discussions, has_downloads, has_pull_requests,
    pull_request_creation_policy, is_template, allow_forking, web_commit_signoff_required,
    allow_merge_commit, allow_squash_merge, allow_rebase_merge, allow_auto_merge, allow_update_branch,
    delete_branch_on_merge, use_squash_pr_title_as_default,
    merge_commit_title, merge_commit_message, squash_merge_commit_title, squash_merge_commit_message
  }),
  security: {
    private_vulnerability_reporting: (if $pvr == null then null else $pvr.enabled end),
    vulnerability_alerts: $va,
    code_scanning_default_setup: (if $csd == null then null else $csd.state end),
    security_and_analysis: (if $meta.security_and_analysis == null then null
      else ($meta.security_and_analysis | with_entries(.value = .value.status)) end)
  },
  rulesets: $rulesets,
  unreadable: $unreadable
}'
