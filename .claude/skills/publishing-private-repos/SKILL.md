---
name: publishing-private-repos
description: "Converts a private GitHub repository to public with TOPAK's own repository settings: scans all of its history (every branch, tag and pull-request ref) for secrets and files that should not be published, applies the baseline (merge-commit-only merges, disabled issues/wiki/discussions, the five rulesets for signed, custodian-reviewed main and immutable custodian-only tags, private vulnerability reporting), flips the visibility only on the custodian's explicit go, finishes the public-only steps, and verifies against the baseline. Use whenever the custodian asks to make a repo public, open-source or publish a private repo, to set up a new repo 'like TOPAK' or with TOPAK's settings, branch protection or rulesets, to check whether a repo is safe to make public, or to compare a repo's settings with TOPAK's. Not for changing TOPAK's own settings, and not for rewriting history to remove a secret (that is the custodian's decision, after this skill reports it)."
---

# Publishing Private Repos

## Contents

- [When to Use](#when-to-use)
- [When NOT to Use](#when-not-to-use)
- [Who does what](#who-does-what)
- [The sequence](#the-sequence)
- [Reading the preflight](#reading-the-preflight)
- [Quick reference](#quick-reference)
- [Rationalizations to reject](#rationalizations-to-reject)
- [References](#references)

How a private repository becomes public with the settings TOPAK runs under, captured from the live repository in
[baseline.json](references/baseline.json) and explained in [settings-map.md](references/settings-map.md).

**Core principle: going public publishes the whole history, at once, for good.** Every commit on every branch and tag,
and every pull request's commits, become readable the moment the visibility changes. A secret deleted three commits
later is still published, and switching back to private does not unpublish what was cloned. So everything that can be
checked is checked before the flip, the protections go on before or immediately after it, and the flip itself is the
custodian's.

## When to Use

- Making a private repository public
- Giving a new or existing repository TOPAK's settings
- Checking whether a repository is safe to publish
- Comparing a repository's settings with TOPAK's

## When NOT to Use

- Changing TOPAK's own settings. Recapture the baseline after the custodian does (settings-map.md, Recapturing).
- Removing a secret or a file from history. Report it; rewriting history (`git filter-repo`, force-pushing every
  branch, asking GitHub to purge PR refs) and rotating the credential are the custodian's.
- Archiving, transferring or deleting repositories.

## Who does what

| Step | The assistant | The custodian |
|---|---|---|
| Preflight scan, snapshot, compare, dry run | Runs them | Reads the report |
| Ruling a finding harmless (`--accept`) | Never alone | Decides, per finding |
| `apply_settings.sh --apply` | When asked to apply TOPAK's settings to that repository | Asks |
| `make_public.sh --confirm` | Only after the custodian says to make **that** repository public, in this conversation, after seeing the preflight | Decides |
| Secret rotation, history rewrite, signing key, collaborators, Actions settings | Reports | Does |

An instruction to "make it public" given before the preflight ran is not a go for a repository whose preflight then
stopped. Report and ask again.

## The sequence

`$S` below is the skill directory, `.claude/skills/publishing-private-repos`; `$TMP` is the scratchpad.

1. **Mirror it.** `git clone --mirror https://github.com/<owner>/<repo> $TMP/<repo>.git`. A mirror has every branch,
   tag and `refs/pull/*`; an ordinary clone misses the pull-request history that goes public too.
2. **Preflight.** `$S/scripts/preflight.py $TMP/<repo>.git`. Exit 1 means stop: report the findings (secrets are
   masked; never print one in full) and wait. See [Reading the preflight](#reading-the-preflight).
3. **Snapshot and compare.** `$S/scripts/snapshot_settings.sh <owner/repo> > $TMP/before.json`, then
   `$S/scripts/compare_settings.py $S/references/baseline.json $TMP/before.json`. Keep `before.json`: it is the
   record of what the repository was.
4. **Dry run.** `$S/scripts/apply_settings.sh <owner/repo>`. Show the custodian what will change, including any
   ruleset on the target that the baseline lacks (left alone) and any security feature the target has on that the
   baseline has off (left on).
5. **Apply.** `$S/scripts/apply_settings.sh <owner/repo> --apply`. On a Free personal account, the rulesets fail on a
   private repository and are reported **OWED**; private vulnerability reporting is always owed until public.
6. **Before the flip**, confirm with the custodian: a `CODEOWNERS` at HEAD names a reviewer (the code-owner rule needs
   one), they have a signing key on their account (the integrity ruleset requires signed commits), and the by-hand rows
   of settings-map.md (Actions permissions, collaborators, webhooks, Pages) are what they want public.
7. **Flip, on the custodian's go.** `$S/scripts/make_public.sh <owner/repo>` prints the consequences;
   `make_public.sh <owner/repo> --confirm <owner/repo>` flips it.
8. **Finish at once.** `apply_settings.sh <owner/repo> --apply` again, before anything else is pushed: it puts on
   whatever was owed. Then snapshot to `$TMP/after.json` and compare with the baseline. Done means the compare exits 0
   and the only lines under NOT COMPARED are the unreadable paths.
9. **Report**: the preflight result and anything accepted, `before` against `after`, what was owed and is now on, the
   unreadable settings left to the custodian, and that secret scanning and push protection are off in the baseline and
   free now that it is public.

## Reading the preflight

| Section | Blocks? | What to do |
|---|---|---|
| SECRETS | Yes | Name the file and commit, masked. A credential in history is compromised by publication: it needs rotating whatever happens, and removing it needs a history rewrite. Both are the custodian's. |
| PATHS | Yes | Each path, or directory group, is shown to the custodian. If they rule one harmless, rerun with `--accept '<regex>'` and list what was accepted in the report. TOPAK's own mirror shows `doc/adr/` (28 early ADRs, later moved to `decisions/`): `doc/` is in `.gitignore` for third-party material, so the scan cannot tell those apart and asks. |
| FILES | Yes | A public repository needs LICENSE, README, SECURITY.md, and CODEOWNERS for the review rule. Adding them is an ordinary change through a PR; drafting their text is not this skill's. |
| IDENTITIES | No | Every author and committer email goes public. Point out any that look private; changing them is a history rewrite. |
| LARGE, SUBMODULES | No | A submodule to a private repository breaks checkouts for everyone once public. |
| REFS | No | Counts what goes public. Zero pull-request refs on a repository with PRs means it was not a mirror: redo step 1. |

The built-in patterns read text diffs only. If `gitleaks` is installed, the script uses it instead, which also reads
binaries.

## Quick reference

| Task | Command |
|---|---|
| Mirror | `git clone --mirror https://github.com/<owner>/<repo> $TMP/<repo>.git` |
| Preflight | `scripts/preflight.py <mirror> [--accept REGEX …]` |
| Snapshot | `scripts/snapshot_settings.sh <owner/repo> > snap.json` |
| Compare | `scripts/compare_settings.py references/baseline.json snap.json` |
| Dry run / apply | `scripts/apply_settings.sh <owner/repo> [--apply]` |
| Flip | `scripts/make_public.sh <owner/repo> --confirm <owner/repo>` |

## Rationalizations to reject

| Rationalization | Reality |
|---|---|
| "The secret was deleted in a later commit." | It is in the history, and the history is what goes public. |
| "It's a test key / it's probably revoked." | That is the custodian's to say, and rotation is cheap next to finding out. |
| "The default branch is clean, so it's fine." | Every branch, tag and PR ref is published, not the tip of `main`. |
| "I'll `--accept` it so the run is green." | `--accept` records a ruling the custodian made. Without one it hides a finding. |
| "They said make it public, so I'll flip it." | Only after the preflight is clean or every finding ruled on, and they have seen it. |
| "I'll flip now and do the rulesets later." | The window between flip and protection is when a force push or tag goes unchecked. Apply in the same sitting. |
| "Secret scanning is off in the baseline, so turn it off here." | The apply never removes a protection. Report the difference. |
| "The required-checks ruleset should be active." | It is disabled in TOPAK because no CI exists; enabling it blocks every merge. Copy it as it is. |
| "The compare says ok, so Actions and collaborators match." | Those are unreadable here. They are listed for the custodian, not passed. |
| "I'll fix the history with filter-repo." | Rewriting history and force-pushing every branch is the custodian's, and the rulesets forbid it on `main`. |

## References

- [baseline.json](references/baseline.json): TOPAK's settings as captured, the input to every script.
- [settings-map.md](references/settings-map.md): each setting and ruleset, why TOPAK has it, what cannot be read here,
  plan limits, and how to recapture.
- `scripts/preflight.py`, `scripts/snapshot_settings.sh`, `scripts/compare_settings.py`, `scripts/apply_settings.sh`,
  `scripts/make_public.sh`.
