# tla-kit: the licence check of the bundled tools, 2026.11.15

> **Provenance note.** Written 2026.11.15 by the assistant, at the custodian's direction to carry out `PLAN.md`
> Phase 1a, on branch `phase1a` after `8b01d1c`. It answers the question of `PLAN.md` D7 with findings and a
> recommendation. **It decides nothing.** D7 is the custodian's, and nothing here is legal advice. Every source is
> named where it is used. What could not be determined is said so.

## 1. The question

`PLAN.md` D7: may tla-kit redistribute what the TLAPS tarball bundles? Three things wait on the answer:
- the kept copy of the tarball as a release asset (ADR-0005 item 2);
- a public image (ADR-0010);
- the SBOM (ADR-0014 item 3).

A public image also redistributes the base and the runtime, so those are covered here as well.

## 2. What was read

| What | How |
|---|---|
| The tarball, `tlapm-1.6.0-pre-x86_64-linux-gnu.tar.gz` | Downloaded from upstream on 2026.11.15. It has sha256 `99db29f1…6bcc`, the pin, so upstream still serves the build the image holds. Its file list read, and the version strings in its binaries. |
| How upstream builds it | `tlaplus/tlapm` at `ff40755` (committed 2026-11-10T23:22:30Z): `deps/*/Makefile`, `deps/isabelle/dune.mk`, `LICENSE`, `zenon/LICENSE`, and the licence page `doc/web/content/Download/License.html` |
| Each part's licence at its source | Z3 `LICENSE.txt` at tag `z3-4.8.9`; LS4 `LICENSE` at tag `v1.0` of `quickbeam123/ls4`; Poly/ML `COPYING` at tag `v5.9.1` (GitHub reports LGPL-2.1); Isabelle2025's `COPYRIGHT` and `Admin/components/main` from `isabelle.in.tum.de` |
| The image as built | `tla-kit:phase1a` at `8b01d1c`: `/usr/share/doc/*/copyright`, `/usr/share/common-licenses`, `/opt/java/openjdk/legal` and `/opt/java/openjdk/release` |
| `libsha1` | Its exported symbols, and a web search. polyml.org describes the SHA-1 library Isabelle bundles as GPL. |

## 3. Findings

**L-1. The tarball carries one licence text, and bundles nine other parts.** The only licence file in it is
`doc/tlapm/LICENSE`, `tlapm`'s BSD-2-Clause. It also holds:
- Zenon 0.8.4, Z3 4.8.9 and LS4 1.0;
- `ptl_to_trp` and `translate`, which are `tlapm`'s own code;
- the Isabelle2025 `Pure`, `TLA+` and `Options` heaps;
- Poly/ML 5.9.1, GMP (`libgmp.so.10`) and `libsha1.so`;
- a second TLA+ tools jar.

None of these carries a licence text in the tarball.

**L-2. Every part allows binaries to be redistributed.**

| Licence | Parts |
|---|---|
| BSD-2-Clause | `tlapm` |
| BSD-3-Clause | Zenon, Isabelle |
| MIT | Z3, LS4 (as MiniSat), both TLA+ tools jars |
| LGPL-2.1 | Poly/ML |
| LGPL-3.0-or-later or GPL-2.0-or-later | GMP |
| GPL (per polyml.org; version not determined) | `libsha1` |

Nothing found forbids redistribution.

**L-3. The permissive licences have a condition the tarball as served does not meet.** BSD-2, BSD-3 and MIT ask
that the copyright notice and licence go with a binary redistribution. The tarball has them for `tlapm` only.
TLAPS's licence page lists Isabelle, Z3 and LS4, but it is not in the tarball, and it does not list Zenon, though
`zenon/LICENSE` is in the same repository. It also says that Isabelle contains other software under its own
licences. Poly/ML, GMP and `libsha1` are that software. So anyone who redistributes the tarball unchanged repeats
upstream's omission, and tla-kit's kept copy would do the same unless it adds the notices itself.

**L-4. The copyleft parts ask for their source.** Distributing their binaries means making the corresponding source
available as well.
- **In the TLAPS tarball:**
  - Poly/ML, under LGPL-2.1 §4;
  - GMP, under LGPL-3 or GPL-2;
  - `libsha1`, under the GPL.
- **In the base:**
  - Temurin, under GPL-2.0 with the Classpath Exception;
  - `git`, under GPL-2.0;
  - other Ubuntu packages under GPL-family licences.

For the base and Temurin the source is public at exactly the versions in the image: Ubuntu's source packages are
at `snapshot.ubuntu.com/ubuntu/20261115T000000Z`, and Temurin's `release` file names `adoptium/jdk25u` at
`7ec19fb1eda7`. For the parts bundled through Isabelle, the exact source was not determined:
- Poly/ML 5.9.1 is a tag;
- which GMP release Isabelle2025's `polyml-5.9.1` component links is not recorded in the binary;
- `libsha1` comes from Isabelle's `sha1` component, which was not read.

**L-5. The base already carries its licence texts.** All 141 Ubuntu packages in the image have a `copyright` file
under `/usr/share/doc`, the common licence texts are in `/usr/share/common-licenses`, and Temurin's notices are
in `/opt/java/openjdk/legal`. The gap is only in the TLAPS tarball.

**L-6. The image holds two builds of the TLA+ tools.** Besides the pinned checker `/opt/tla/tla2tools.jar`
(v1.7.4), the tarball carries `backends/bin/tla2tools.jar`, sha256 `e1f11b75…cd7f`, an upstream build of 2026-11-06
at `d8fb231`. `tlapm` uses it. The tarball's digest covers it, and nothing else names it. The
installed-file digests that ADR-0013 item 7 asks the inventory to list should include it.

## 4. What is done in Phase 1a

- `licenses/THIRD-PARTY.md`, the image's notice of bundled tools (ADR-0011 item 4). It lists every part in §3 and
  the base, each with its version, licence, the path of its licence text in the image, and where its source is.
- The licence texts the tarball leaves out, taken from each part's source at the version bundled: Zenon, Z3, LS4,
  Isabelle2025 and Poly/ML 5.9.1. GMP and `libsha1` point to the GPL and LGPL texts in `/usr/share/common-licenses`.
- The image carries the notice, those texts, and tla-kit's `LICENSE`, `LICENSE-DOCS` and `NOTICE`, under
  `/opt/tla-kit/`. `tla-kit-selftest` fails if any licence text the notice names is missing.

## 5. Recommendation on D7

**Yes. tla-kit may redistribute the TLAPS tarball's contents, both in a public image and as a kept copy, on three
conditions:**
1. **Every redistribution carries the notices.** The image does, since Phase 1a. The release that holds a kept
   tarball (ADR-0005 item 2, ADR-0014 item 3) attaches `licenses/` beside it.
2. **The release offers the copyleft parts' source from the same place.** Poly/ML 5.9.1, GMP and `libsha1` would
   be attached as source archives beside the kept tarball. For the base and Temurin, the release names the
   snapshot date and the Temurin commit, where the source is public.
3. **Two facts are settled before the first public release:** which GMP release is bundled, and `libsha1`'s exact
   licence. Both are in Isabelle2025's `polyml-5.9.1` and `sha1` components, which were not read here.

Condition 2 could instead point to upstream's source archives rather than keep copies. That is cheaper, and it
leaves the obligation resting on upstream continuing to serve them, which ADR-0005 found it does not always do for
TLAPS.

## 6. What changes if this is accepted

| Record | Change |
|---|---|
| ADR-0005 | Item 2's kept copy may proceed under §5's conditions; its Pending line can name this document |
| ADR-0011 | Item 4's notice exists: `licenses/THIRD-PARTY.md` |
| ADR-0013 | Item 7's installed digests include the second jar (L-6) and each backend binary |
| ADR-0014 | Item 3's release gains `licenses/` and the source archives of §5 condition 2 |
