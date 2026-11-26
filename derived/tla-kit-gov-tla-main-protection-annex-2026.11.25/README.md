# Annex: gov-tla's `main` protection, 2026.11.25

The raw output that [`../tla-kit-gov-tla-main-protection-2026.11.25.md`](../tla-kit-gov-tla-main-protection-2026.11.25.md)
cites. Everything was read from the GitHub API with the custodian's token. Times are UTC, on 2026-11-26.

| File | What it is |
|---|---|
| `settings-before.json` | gov-tla's settings and rulesets before the change: `snapshot_settings.sh scottcochran/gov-tla` from the `publishing-private-repos` skill |
| `settings-after.json` | The same snapshot after the change; it differs from the first in the three places the document names |
| `compare-before.txt`, `compare-after.txt` | `compare_settings.py` against TOPAK's baseline (`references/baseline.json`, captured 2026-11-11), with the exit status |
| `commands.sh` | The three `PUT`s that made the change, as run, and how to undo them |
| `effective-rules-after.txt` | The rules GitHub applies to `main` after the change, and each ruleset's `current_user_can_bypass` for the custodian's token |
| `check-names.txt` | The check names gov-tla's workflows report: on PR #17's head, where `tlc` and `proofs` were skipped, and on `ef8ef9a`, where `proofs` ran as `proofs (Elections)` |
| `other-repos.txt` | tla-kit's and TOPAK's rulesets, read the same day, unchanged |
