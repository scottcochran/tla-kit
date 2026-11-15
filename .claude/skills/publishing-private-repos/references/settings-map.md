# The baseline, setting by setting

`baseline.json` is TOPAK's settings as `scripts/snapshot_settings.sh scottcochran/TOPAK` read them on 2026-11-11. This
page says what each one does and why the corpus wants it, so that a difference can be judged instead of just
overwritten. If TOPAK's own settings change, recapture the baseline (see [Recapturing](#recapturing)); do not edit the
JSON by hand.

## Contents

- [Repository settings](#repository-settings)
- [Rulesets](#rulesets)
- [Security](#security)
- [What the snapshot cannot read](#what-the-snapshot-cannot-read)
- [Not copied](#not-copied)
- [Plan and visibility limits](#plan-and-visibility-limits)
- [Recapturing](#recapturing)

## Repository settings

| Setting | Baseline | Why |
|---|---|---|
| `allow_merge_commit` | `true` | The only merge method. Manifests, addenda and index rows cite commits by hash; a merge commit keeps every cited commit on `main`. |
| `allow_squash_merge`, `allow_rebase_merge` | `false` | Both rewrite the branch's commits, so a hash cited during review would not be on `main`. |
| `merge_commit_title` / `merge_commit_message` | `MERGE_MESSAGE` / `PR_TITLE` | "Merge pull request #n from …" with the PR title as body, as `git log` on `main` shows. |
| `delete_branch_on_merge` | `true` | Merged branches are deleted; their commits stay reachable through the merge. |
| `allow_auto_merge`, `allow_update_branch` | `false` | Nothing merges without the custodian, and GitHub does not write merge commits into a contributor's branch. |
| `has_issues`, `has_discussions`, `has_wiki`, `has_projects` | `false` | The record lives in the corpus (`decisions/`, `checkpoints/`), not in GitHub features. Safety findings go through private vulnerability reporting (SECURITY.md). |
| `has_downloads` | `false` | Nothing is released. |
| `has_pull_requests`, `pull_request_creation_policy` | `true`, `collaborators_only` | PRs are how changes reach `main`, and only collaborators may open them. If the API ignores the policy field, set it under Settings → General → Pull Requests. |
| `allow_forking` | `true` | Anyone may fork and read; the licences (Apache-2.0 for code, CC BY 4.0 for documents) allow it. |
| `web_commit_signoff_required` | `false` | No DCO sign-off is required on web commits. The disabled required-checks ruleset names a `DCO` check for when one is. |
| `is_template` | `false` | |

## Rulesets

All five use `~DEFAULT_BRANCH` or `~ALL`, so they carry over to any repository. The one bypass actor is
`RepositoryRole` 5, the **Admin** role: the custodian. Rulesets are matched by **name** when applied.

| Ruleset | Enforcement | Rules | Why |
|---|---|---|---|
| `main: integrity` | active | No deletion, no force push, **signed commits required**, changes by pull request (0 approvals, threads resolved, merge method `merge` only) | `main` is the history manifests and checkpoints are measured at. It cannot be rewritten or deleted, and every commit on it is signed. |
| `main: custodian review` | active | Pull request with 1 approval, code-owner review (`CODEOWNERS`: `* @scottcochran`), last push approved, stale approvals dismissed, threads resolved, merge only | Nothing reaches `main` without the custodian's review of the final push. |
| `main: required checks` | **disabled** | Strict status checks: `check-refs`, `frozen-files`, `verify-manifests`, `proof-sync`, `lean-sync`, `mechanism-tests`, `DCO` | Staged for when CI exists. The repository has no `.github/workflows/` yet, so turning it on would block every merge. Copy it disabled. |
| `tags: custodian creates` | active | Only the bypass actor (Admin) may create tags | Tags such as `ToO-rev15` mark the state of record; tags are the custodian's. |
| `tags: immutable` | active | No tag update, no tag deletion, **no bypass** | A tag, once cut, names one commit forever, even for the custodian. |

Signed commits plus code-owner review mean the target needs a `CODEOWNERS` naming someone who can review, and the
custodian needs a signing key registered on their GitHub account before their next push to `main`.

## Security

| Setting | Baseline | Applied how |
|---|---|---|
| Private vulnerability reporting | on | `PUT …/private-vulnerability-reporting`. **Public repositories only**, so it is always owed after the flip. SECURITY.md names it as the preferred channel, so the flip is not finished until it is on. |
| `security_and_analysis.*` (secret scanning, push protection, Dependabot security updates) | all `disabled` at capture | `apply_settings.sh` only turns on what the baseline has on. It never turns a protection off to match. Once the repository is public, secret scanning and push protection are free; whether to enable them is the custodian's call, and the report should say they are off. |
| Code scanning default setup | `not-configured` | Not applied. |
| Dependabot alerts (`vulnerability-alerts`) | unknown | Unreadable at capture; see below. |

## What the snapshot cannot read

The session's GitHub proxy refuses these paths, so their values are **unknown, not absent**. The custodian compares
them by hand in each repository's Settings, or runs the snapshot with an unproxied `gh`:

| Path | Settings page |
|---|---|
| `actions/permissions`, `actions/permissions/workflow` | Settings → Actions → General (which actions may run; the default `GITHUB_TOKEN` permissions; fork PR approval) |
| `vulnerability-alerts` | Settings → Code security → Dependabot alerts |
| `environments` | Settings → Environments |
| `autolinks` | Settings → Autolink references |
| `hooks` | Settings → Webhooks |
| `pages` | Settings → Pages |
| `collaborators` | Settings → Collaborators (who keeps write access once the repository is public) |

Actions secrets and variables are never copied. For a public repository, check Settings → Actions → General → "Fork
pull request workflows" before any workflow uses a secret.

## Not copied

`name`, `description`, `homepage`, `topics` and the default branch's name belong to the target. Labels are GitHub's
defaults on TOPAK, so a new repository has them already.

## Plan and visibility limits

- Rulesets on a **personal account's private** repository need GitHub Pro. On the Free plan the POST is refused with
  a 403; `apply_settings.sh` reports it as owed, and the rulesets are applied straight after the flip, before anything
  else is pushed.
- Private vulnerability reporting exists only on public repositories.
- Secret scanning and push protection are free only on public repositories.

## Recapturing

```sh
scripts/snapshot_settings.sh scottcochran/TOPAK > /tmp/snap.json
scripts/compare_settings.py references/baseline.json /tmp/snap.json   # what changed on TOPAK
```

If TOPAK changed deliberately, replace `baseline.json` with the new snapshot plus its `note` key, update the tables
above, and commit both together.
