# Third-party software in the tla-kit image

The image built from this repository's `Dockerfile` contains the software below. None of it is part of tla-kit,
and none of it is under tla-kit's licences (`NOTICE`). Each part keeps its own licence. This notice says which one,
where its text is in the image, and where the part's source is. It is the image's notice of bundled tools
(ADR-0011 item 4), and the outcome of the licence check of 2026.11.15
(`derived/tla-kit-licence-check-2026.11.15.md` in the repository). It is not legal advice.

In the image, this file is `/opt/tla-kit/licenses/THIRD-PARTY.md`, beside the licence texts that the TLAPS tarball
leaves out. `tla-kit-selftest` checks that every path in the "Licence text in the image" column exists, and that
each jar it names holds a `License.txt`.

## The base and the runtime

| Part | Version | Licence | Licence text in the image | Source |
|---|---|---|---|---|
| Ubuntu 24.04 base, and the packages the image adds (`python3`, `perl`, `git` and what they depend on) | Ubuntu 24.04.5 LTS; packages from Ubuntu's archive as of 2026-11-15T00:00:00Z | Each package's own; the copyleft ones include GPL-2.0 (`git`), GPL-1.0+ or Artistic (`perl`) | `/usr/share/doc` (one `copyright` file per package) and `/usr/share/common-licenses` | Ubuntu's source packages, at `https://snapshot.ubuntu.com/ubuntu/20261115T000000Z` for the added packages; the base layers are `ubuntu:24.04` as the Temurin image records it (`sha256:77eb101c…57ec`) |
| Eclipse Temurin JRE | 25.0.5+8 | GPL-2.0 with the Classpath Exception, and the notices of its own third-party parts | `/opt/java/openjdk/legal` | `https://github.com/adoptium/jdk25u`, at `7ec19fb1eda7` |

## The TLA+ tools

| Part | Version | Licence | Licence text in the image | Source |
|---|---|---|---|---|
| TLA+ tools: TLC, SANY, the PlusCal translator (`/opt/tla/tla2tools.jar`) | v1.7.4 | MIT, with the licences of the libraries the jar bundles inside it | `/opt/tla/tla2tools.jar` (`License.txt` and the other licence files inside the jar) | `https://github.com/tlaplus/tlaplus`, tag `v1.7.4` |

## The TLAPS tarball (`/opt/tlaps`)

`tlapm-1.6.0-pre-x86_64-linux-gnu.tar.gz`, built by upstream from `tlaplus/tlapm` at `ff40755`. The tarball carries
the licence of `tlapm` only. The texts of the other parts are added here from their sources, at the versions the
tarball was built from. TLAPS's own licence page (`doc/web/content/Download/License.html` in `tlaplus/tlapm`)
lists Isabelle, Z3 and LS4, and says that Isabelle contains other software under its own licences. Poly/ML, GMP and
`libsha1` below are that other software.

| Part | Version | Licence | Licence text in the image | Source |
|---|---|---|---|---|
| `tlapm`, `tlapm_lsp`, `translate`, `ptl_to_trp`, and the Isabelle/TLA+ theories behind the `TLA+` heap | `ff40755` | BSD-2-Clause (Inria, Microsoft Corporation, Linux Foundation) | `/opt/tlaps/doc/tlapm/LICENSE` | `https://github.com/tlaplus/tlapm`, at `ff40755` |
| Zenon (`backends/bin/zenon`) | 0.8.4 [a268] | BSD-3-Clause (Inria) | `/opt/tla-kit/licenses/zenon-LICENSE.txt` | `tlaplus/tlapm` at `ff40755`, `zenon/` |
| Z3 (`backends/bin/z3`) | 4.8.9 | MIT (Microsoft Corporation) | `/opt/tla-kit/licenses/z3-LICENSE.txt` | `https://github.com/Z3Prover/z3`, tag `z3-4.8.9` (upstream's `x64-ubuntu-16.04` binary) |
| LS4 (`backends/bin/ls4`) | 1.0, with `tlapm`'s `deps/ls4/ls4.patch` | MIT, as MiniSat (Martin Suda; Niklas Eén, Niklas Sörensson) | `/opt/tla-kit/licenses/ls4-LICENSE.txt` | `https://github.com/quickbeam123/ls4`, tag `v1.0` |
| Isabelle: the `Pure`, `TLA+` and `Options` heaps (`backends/Isabelle-install`) | Isabelle2025 | BSD-3-Clause (University of Cambridge, Technische Universität München, and contributors) | `/opt/tla-kit/licenses/isabelle-COPYRIGHT.txt` | `https://isabelle.in.tum.de/website-Isabelle2025/` |
| Poly/ML: `poly`, `polyc`, `polyimport`, `libpolyml`, `libpolymain` (`backends/Isabelle-install/poly`) | 5.9.1, as packaged in Isabelle2025's `polyml-5.9.1` component | LGPL-2.1 | `/opt/tla-kit/licenses/polyml-COPYING.txt` | `https://github.com/polyml/polyml`, tag `v5.9.1` |
| GMP: `libgmp.so.10` (`backends/Isabelle-install/poly`) | the GMP 6 series; the exact release was not determined | LGPL-3.0-or-later or GPL-2.0-or-later | `/usr/share/common-licenses/LGPL-3` and `/usr/share/common-licenses/GPL-2` | `https://gmplib.org`; bundled by Isabelle2025's `polyml-5.9.1` component |
| `libsha1.so` (`backends/Isabelle-install/poly`) | as built by Isabelle's `sha1` component; the release was not determined | GPL, per polyml.org's description of the library; its exact version was not determined | `/usr/share/common-licenses/GPL-3` | GNU `sha1.c`, as Isabelle builds it: `https://isabelle.sketis.net/repos/sha1` |
| A second TLA+ tools jar, used by `tlapm` (`backends/bin/tla2tools.jar`) | upstream build of 2026-11-06, `d8fb231`; not the image's checker | MIT, with the licences of the libraries it bundles inside it | `/opt/tlaps/lib/tlapm/backends/bin/tla2tools.jar` (`License.txt` and the other licence files inside the jar) | `https://github.com/tlaplus/tlaplus`, at `d8fb231` |

## tla-kit's own files in the image

`/usr/local/bin` (the wrappers, `tla-kit-info`, `tla-kit-selftest`) is tla-kit's code, under Apache-2.0. The
vendored skill at `/opt/tla-kit/skill` is TOPAK's, under the licence it has there (ADR-0011 item 5; its
`VENDOR-PIN`). Their licence texts are `/opt/tla-kit/LICENSE`, `/opt/tla-kit/LICENSE-DOCS` and
`/opt/tla-kit/NOTICE`.
