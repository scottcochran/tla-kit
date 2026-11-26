# Projects served

The projects that run their checks in the tla-kit image, and the file in each that holds its tla-kit pin
(ADR-0014 item 6). The list has two uses:

- the evidence for a pin move runs over the projects it names (ADR-0013 item 3, `.github/workflows/evidence.yml`);
- the weekly check reads each pin, and reports which release each project uses (ADR-0013 item 4,
  `tools/weekly.py`).

A project joins by a pull request here. Nothing is sent to the projects. A project learns of a release by watching
this repository's releases.

| Project | Pin file | Visibility | Evidence run here |
|---|---|---|---|
| [TOPAK](https://github.com/scottcochran/TOPAK) | `tools/TLA-KIT-PIN` | public | its TLC results (`tools/check-results.sh`, `pr` tier), its full proof run and its defect run |
| [gov-tla](https://github.com/scottcochran/gov-tla) | `tools/TLA-KIT-PIN` | public (since 2026.11.20) | none yet: it can now be read without a token, and `evidence.yml` does not run it yet. Its evidence would be its TLC results (`scripts/tlc_rows.py` over `rows/`, compared with `results/`) and its proof runs (six proof modules) |

Both pin files exist: on 2026.11.20, TOPAK's names `v0.4.0` and gov-tla's `v0.1.0`, each by digest, added in each
project by its own decision (ADR-0005 item 5). The log below is filled by the weekly check's reports, not by hand.

## Log of each project's pin

One dated entry for each change the weekly check finds in a project's pin: from what date the project pins which
release. Entries are added by pull request and never edited (ADR-0014 item 6).

| From | Project | Release | Digest |
|---|---|---|---|
