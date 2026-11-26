#!/usr/bin/env bash
# The three changes made to scottcochran/gov-tla's rulesets on 2026-11-26 at 04:35:51-52 UTC, as run, with the
# custodian's token (gh). Ruleset ids: 27444792 main: custodian review, 27444793 main: integrity,
# 27444794 main: required checks. A PUT with only some fields changes those and keeps the rest.
set -euo pipefail
R=repos/scottcochran/gov-tla/rulesets

# 1, 2. The Admin role (RepositoryRole 5) may bypass the two main rulesets only by merging a pull request,
#       not by pushing ("always" before).
for name in "main: custodian review" "main: integrity"; do
  id=$(gh api $R -q ".[]|select(.name==\"$name\").id")
  gh api -X PUT $R/$id --input - <<<'{"bypass_actors":[{"actor_id":5,"actor_type":"RepositoryRole","bypass_mode":"pull_request"}]}'
done

# 3. Required checks on (disabled before), with gov-tla's three check names in place of TOPAK's seven, each
#    pinned to the GitHub Actions app (15368) so no other app or status can satisfy it. No bypass actors.
id=$(gh api $R -q '.[]|select(.name=="main: required checks").id')
gh api -X PUT $R/$id --input - <<'JSON'
{"enforcement":"active","rules":[{"type":"required_status_checks","parameters":{"do_not_enforce_on_create":false,"strict_required_status_checks_policy":true,"required_status_checks":[{"context":"plan","integration_id":15368},{"context":"pins","integration_id":15368},{"context":"regenerate","integration_id":15368}]}}]}
JSON

# To undo: the same PUTs with "bypass_mode":"always", and {"enforcement":"disabled"} for the third.
