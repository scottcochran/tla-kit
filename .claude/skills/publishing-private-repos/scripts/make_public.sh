#!/usr/bin/env bash
# make_public.sh   flip one private repository to public, once the custodian has said so
#
# Usage: make_public.sh <owner/repo>                         (prints what would happen; changes nothing)
#        make_public.sh <owner/repo> --confirm <owner/repo>  (makes it public)
#
# The flip can be undone in name only: once public, anyone may have cloned, forked or indexed it, and a secret in the
# history is burned whatever happens next. So it runs only with the repository named twice, and only on a private
# repository. Run preflight.py and apply_settings.sh --apply first; run apply_settings.sh --apply again straight after,
# for the steps GitHub allows on public repositories only.
#
# What GitHub does on the flip, printed before it happens:
#   - every branch, tag and pull request, with all their history, becomes readable by anyone
#   - private forks of this repository are detached into their own network and stay private
#   - Actions minutes stop being billed; secret scanning becomes available free
set -euo pipefail
[ $# -ge 1 ] || { echo "usage: $0 <owner/repo> [--confirm <owner/repo>]" >&2; exit 2; }
repo="$1"; confirm=""
[ "${2:-}" = "--confirm" ] && confirm="${3:-}"

meta="$(gh api "repos/$repo")"
visibility="$(jq -r .visibility <<<"$meta")"
if [ "$visibility" != "private" ]; then
  echo "$repo is already $visibility; nothing to do"; exit 0
fi
forks="$(jq -r .forks_count <<<"$meta")"
echo "$repo is private. Making it public will:"
echo "  - publish every branch, tag and pull-request ref with all their history"
echo "  - detach its $forks private fork(s), which stay private in their own network"
echo "  - take effect at once; going back to private does not unpublish what was read or cloned"

if [ "$confirm" != "$repo" ]; then
  echo
  echo "not changed. To flip, after the custodian has said so: $0 $repo --confirm $repo"
  exit 1
fi
gh api -X PATCH "repos/$repo" -f visibility=public --jq '"now " + .visibility + ": " + .html_url'
echo "next: scripts/apply_settings.sh $repo --apply   (rulesets and private vulnerability reporting, if owed)"
