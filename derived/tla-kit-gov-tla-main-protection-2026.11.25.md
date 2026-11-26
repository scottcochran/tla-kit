# tla-kit: gov-tla's `main`, closed to direct pushes and gated on its checks, 2026.11.25

> **Provenance note.** Written 2026.11.25 by the assistant, at the custodian's request, after configuring branch
> protection for `main` in [gov-tla](https://github.com/scottcochran/gov-tla), a consumer of tla-kit
> ([`CONSUMERS.md`](../CONSUMERS.md)). The change was made with the custodian's token on 2026-11-26 at
> 04:35:51–52 UTC (23:35 on 2026.11.25, Eastern), after the custodian said to configure branch protection for `main`.
> It was compared with TOPAK's settings baseline, the `publishing-private-repos` skill's `references/baseline.json`
> (captured 2026-11-11; gov-tla's copy has sha256 `99933818…365a`). The raw output is in the annex beside this
> document, [`tla-kit-gov-tla-main-protection-annex-2026.11.25/`](tla-kit-gov-tla-main-protection-annex-2026.11.25/).
> Nothing in tla-kit or TOPAK was changed. It decides nothing for either.

## 1. What happened

gov-tla's `main` had TOPAK's three `main` rulesets: a pull request with the code owner's review, signed commits with
no force-push or deletion, and a required-checks ruleset left disabled. Its settings matched TOPAK's baseline except
that Dependabot security updates were on (annex `compare-before.txt`).

Those rulesets did not stop a direct push. On 2026.11.25 the assistant, asked to "commit and push to the PR" (gov-tla
PR #17), committed and pushed from a working copy that had been switched back to `main` between turns. The push
went to `origin/main` and was accepted: `f01f141` ("release.yml: notes without the tag's signature; refuse a commit
already released"), signed, never reviewed. The custodian chose to leave it on `main`. PR #17 then merged on top of it
as `ba9a1c2`, at 04:30:34 UTC.

The push was accepted because both active `main` rulesets name one bypass actor, the repository's Admin role
(`RepositoryRole` 5), with bypass mode `always`. The custodian is an admin, and the assistant acts with the
custodian's token, so every rule in those rulesets was bypassable on a plain `git push`.

## 2. What `main` had

| Ruleset | Rules | Enforcement | Bypass |
|---|---|---|---|
| `main: custodian review` | pull request: 1 approval, code-owner review, approval of the last push, stale reviews dismissed, threads resolved, merge commits only | active | Admin, `always` |
| `main: integrity` | no deletion, no force-push, signed commits, pull request (0 approvals, threads resolved, merge commits only) | active | Admin, `always` |
| `main: required checks` | TOPAK's seven checks: `check-refs`, `frozen-files`, `verify-manifests`, `proof-sync`, `lean-sync`, `mechanism-tests`, `DCO`; branch up to date | **disabled** | none |

TOPAK's required checks are copied disabled by the skill, because TOPAK has no CI to report them (the skill's
"Rationalizations to reject"). gov-tla has CI, but none of the seven names is a job it runs. Enabled as copied, the
ruleset would block every merge.

## 3. What changed

Three `PUT`s to the rulesets API, as run in annex `commands.sh`:

1. `main: custodian review`: bypass mode `always` → `pull_request`.
2. `main: integrity`: bypass mode `always` → `pull_request`.
3. `main: required checks`: enforcement `disabled` → `active`, with gov-tla's checks `plan`, `pins` and `regenerate`,
   each pinned to the GitHub Actions app (integration 15368). Up-to-date branches still required, and still no bypass
   actors.

The tag rulesets (`tags: custodian creates`, `tags: immutable`) were not touched. The snapshots before and after
(annex `settings-before.json`, `settings-after.json`) differ in exactly those three places.

With bypass mode `pull_request`, an admin may bypass the two rulesets only when merging a pull request: the
custodian can still merge their own PR without a second approver, which a one-person repository needs, since nobody
can approve their own PR. A push of commits to `main` is held to every rule, and the pull-request rule then refuses
it. The required checks have no bypass, so not even a custodian's merge passes a failing or missing check.

## 4. Which checks, and why only three

gov-tla's workflows report five job names on a pull request: `plan`, `pins`, `tlc` and `proofs` from `checks.yml`,
and `regenerate` from `diagrams.yml` (annex `check-names.txt`). `tlc` and `proofs` are matrix jobs over the modules a
change can affect, and their names depend on whether they run:

| Change | `tlc` reports as | `proofs` reports as |
|---|---|---|
| no spec changed (PR #17's head, `25b82ae`) | `tlc`, skipped | `proofs`, skipped |
| `Elections_proof.tla` changed (`ef8ef9a`, the merge of PR #16) | `tlc`, skipped | `proofs (Elections)` |

A required check is matched by name. Requiring `proofs` would leave any PR that runs a proof waiting forever for a
check that never reports, and `proofs (Elections)` names one module. So only the three names that every run reports
were required. A skipped job counts as passing, so the matrix's names would also pass on a PR where nothing ran.

The cost is that a failing TLC row or proof does not block a merge under this ruleset: the PR shows it failed, and
the custodian has to look.

## 5. What was verified, and what was not

Verified:

- The rules GitHub applies to `main` (annex `effective-rules-after.txt`): `pull_request` twice, `deletion`,
  `non_fast_forward`, `required_signatures`, `required_status_checks`.
- For the custodian's token, `current_user_can_bypass` is `pull_requests_only` on the two `main` rulesets and `never`
  on required checks. Before the change, the first two were bypassable on any push.
- Compared with the baseline (annex `compare-after.txt`), the only differences are the three changes and Dependabot.

Not verified:

- **No push was tried.** A test push would have landed on `main` if the change had failed. That a direct push is now
  refused is GitHub's documented meaning of `pull_requests_only`, not an observed refusal.
- **No PR has merged under the new rules.** PR #17 merged five minutes before the change. The first merge after it
  will show whether the custodian's bypass at merge works as described in §3, and whether the three checks are
  matched as named.

## 6. The same rulesets in tla-kit and TOPAK

Read on the same day, unchanged by this work (annex `other-repos.txt`):

| Repository | `main` bypass | `main: required checks` |
|---|---|---|
| gov-tla, after this change | Admin, `pull_request` | active: `plan`, `pins`, `regenerate` |
| tla-kit | Admin, `always` | active: `records`, `image`, `reproduce` |
| TOPAK | Admin, `always` | disabled (TOPAK's seven names, no CI) |

tla-kit and TOPAK each allow a direct admin push to `main` to bypass review and signed-commit checks, which is how
`f01f141` landed in gov-tla. tla-kit's required checks are active with no bypass actors, and GitHub requires a
commit pushed to the branch to have passed them already, so a fresh commit pushed straight to tla-kit's `main`
should be refused by that ruleset alone. That was not tried. gov-tla had no such backstop: its required checks were
disabled.

## 7. What the custodian may decide

1. **tla-kit and TOPAK.** Whether to make the same change to bypass mode in either. In TOPAK it would also need a
   new baseline (`publishing-private-repos`, settings-map.md, Recapturing): `compare_settings.py` now reports gov-tla
   as differing from the baseline in these three places, and will until it is recaptured or the change is undone.
2. **`tlc` and `proofs` in gov-tla.** Whether to add a summary job to `checks.yml` that needs both matrix jobs and
   fails when either failed, and require that one job's name in place of the gap in §4.
3. **The up-to-date requirement.** Kept from TOPAK: a PR must be up to date with `main` before it merges, so a PR
   opened before another merges has to be updated and its checks run again. Not a fault; a cost worth knowing.
4. **`CONSUMERS.md`.** It lists gov-tla as private. gov-tla is public (annex `settings-after.json`). Not corrected
   here: this document is a record of gov-tla's settings, not a revision of the living one.
