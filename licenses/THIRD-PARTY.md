# Third-party software in the tla-kit image

The image built from this repository's `Dockerfile` contains the software below. None of it is part of tla-kit,
and none of it is under tla-kit's licences (`NOTICE`). Each part keeps its own licence. This notice says which one,
where its text is in the image, and where the part's source is. It is the image's notice of bundled tools
(ADR-0011 item 4), and the outcome of the licence check of 2026.11.15
(`derived/tla-kit-licence-check-2026.11.15.md` in the repository), with the GMP release and `libsha1`'s licence
settled on 2026.11.16 (`derived/tla-kit-copyleft-sources-2026.11.16.md`). It is not legal advice.

In the image, this file is `/opt/tla-kit/licenses/THIRD-PARTY.md`, beside the licence texts that the TLAPS tarball
leaves out. `tla-kit-selftest` checks that every path in the "Licence text in the image" column exists, and that
each jar it names holds a `License.txt`.

## The base and the runtime

| Part | Version | Licence | Licence text in the image | Source |
|---|---|---|---|---|
| Ubuntu 26.04 base, and the packages the image adds (`python3`, `perl`, `git` and what they depend on) | Ubuntu 26.04.1 LTS; packages from Ubuntu's archive as of 2026-11-19T00:00:00Z | Each package's own; the copyleft ones include GPL-2.0 (`git`), GPL-1.0+ or Artistic (`perl`) | `/usr/share/doc` (one `copyright` file per package) and `/usr/share/common-licenses` | Ubuntu's source packages, at `https://snapshot.ubuntu.com/ubuntu/20261119T000000Z` for the added packages; the base layers are `ubuntu:26.04` as the Temurin image records it (`sha256:0d5255be…63c6`) |
| Eclipse Temurin JRE | 25.0.5+8 | GPL-2.0 with the Classpath Exception, and the notices of its own third-party parts | `/opt/java/openjdk/legal` | `https://github.com/adoptium/jdk25u`, at `7ec19fb1eda7` |

## The TLA+ tools

| Part | Version | Licence | Licence text in the image | Source |
|---|---|---|---|---|
| TLA+ tools: TLC, SANY, the PlusCal translator (`/opt/tla/tla2tools.jar`) | v1.7.4 | MIT, with the licences of the libraries the jar bundles inside it | `/opt/tla/tla2tools.jar` (`License.txt` and the other licence files inside the jar) | `https://github.com/tlaplus/tlaplus`, tag `v1.7.4` |

## The TLAPS tarball (`/opt/tlaps`)

`tlapm-1.6.0-pre-x86_64-linux-gnu.tar.gz`, built by upstream from `tlaplus/tlapm` at `9a52faf`. The tarball carries
the licence of `tlapm` only. The texts of the other parts are added here from their sources, at the versions the
tarball was built from. TLAPS's own licence page (`doc/web/content/Download/License.html` in `tlaplus/tlapm`)
lists Isabelle, Z3 and LS4, and says that Isabelle contains other software under its own licences. Poly/ML, GMP and
`libsha1` below are that other software.

| Part | Version | Licence | Licence text in the image | Source |
|---|---|---|---|---|
| `tlapm`, `tlapm_lsp`, `translate`, `ptl_to_trp`, and the Isabelle/TLA+ theories behind the `TLA+` heap | `9a52faf` | BSD-2-Clause (Inria, Microsoft Corporation, Linux Foundation) | `/opt/tlaps/doc/tlapm/LICENSE` | `https://github.com/tlaplus/tlapm`, at `9a52faf` |
| Zenon (`backends/bin/zenon`) | 0.8.4 [a268] | BSD-3-Clause (Inria) | `/opt/tla-kit/licenses/zenon-LICENSE.txt` | `tlaplus/tlapm` at `9a52faf`, `zenon/` |
| Z3 (`backends/bin/z3`) | 4.8.9 | MIT (Microsoft Corporation) | `/opt/tla-kit/licenses/z3-LICENSE.txt` | `https://github.com/Z3Prover/z3`, tag `z3-4.8.9` (upstream's `x64-ubuntu-16.04` binary) |
| LS4 (`backends/bin/ls4`) | 1.0, with `tlapm`'s `deps/ls4/ls4.patch` | MIT, as MiniSat (Martin Suda; Niklas Eén, Niklas Sörensson) | `/opt/tla-kit/licenses/ls4-LICENSE.txt` | `https://github.com/quickbeam123/ls4`, tag `v1.0` |
| Isabelle: the `Pure`, `TLA+` and `Options` heaps (`backends/Isabelle-install`) | Isabelle2025 | BSD-3-Clause (University of Cambridge, Technische Universität München, and contributors) | `/opt/tla-kit/licenses/isabelle-COPYRIGHT.txt` | `https://isabelle.in.tum.de/website-Isabelle2025/` |
| Poly/ML: `poly`, `polyc`, `polyimport`, `libpolyml`, `libpolymain` (`backends/Isabelle-install/poly`) | 5.9.1, as packaged in Isabelle2025's `polyml-5.9.1` component | LGPL-2.1 | `/opt/tla-kit/licenses/polyml-COPYING.txt` | `https://github.com/polyml/polyml`, tag `v5.9.1`; `polyml-5.9.1-src.tar.gz`, in this repository's release `tlapm-9a52faf` |
| GMP: `libgmp.so.10` (`backends/Isabelle-install/poly`) | 6.1.2, as built for Isabelle2025's `polyml-5.9.1` component | LGPL-3.0-or-later or GPL-2.0-or-later | `/usr/share/common-licenses/LGPL-3` and `/usr/share/common-licenses/GPL-2` | `gmp-6.1.2.tar.xz`, in this repository's release `tlapm-9a52faf`, and at `https://ftp.gnu.org/gnu/gmp/` |
| `libsha1.so` (`backends/Isabelle-install/poly`) | GNU coreutils 8.4's `sha1.c`, as built for Isabelle2025's `polyml-5.9.1` component | GPL-3.0-or-later (Free Software Foundation) | `/usr/share/common-licenses/GPL-3` | `libsha1-src.tar.gz`, in this repository's release `tlapm-9a52faf`: the component's `sha1/` directory |
| A second TLA+ tools jar, used by `tlapm` (`backends/bin/tla2tools.jar`) | upstream build of 2026-11-15, `bc1b506`; not the image's checker | MIT, with the licences of the libraries it bundles inside it | `/opt/tlaps/lib/tlapm/backends/bin/tla2tools.jar` (`License.txt` and the other licence files inside the jar) | `https://github.com/tlaplus/tlaplus`, at `bc1b506` |

## cvc5 and ethos

`cvc5` 1.4.0 and `ethos` 0.2.4, with cvc5 1.4.0's CPC signature, are in the base from the pull request that
installs them (ADR-0012 item 8). An image built before it does not hold them. Each is upstream's static Linux
x86_64 build, kept in this repository's release `cvc5-1.4.0` (ADR-0017). Both link the libraries below into the
binary. The libraries' releases were settled from the bytes (`derived/tla-kit-licence-check-cvc5-ethos-2026.11.17.md`
and `derived/tla-kit-static-libraries-2026.11.17.md` in the repository). The release `cvc5-1.4.0` holds the two zips,
cvc5's and ethos's source, and the source of every copyleft part below.

| Part | Version | Licence | Licence text in the image | Source |
|---|---|---|---|---|
| `cvc5` | 1.4.0, `b432cd7`, upstream's `cvc5-Linux-x86_64-static.zip` | BSD-3-Clause (the authors of cvc5 and their institutions) | `/opt/tla-kit/licenses/cvc5-COPYING.txt` | `https://github.com/cvc5/cvc5`, tag `cvc5-1.4.0`; `cvc5-1.4.0-src.tar.gz` in release `cvc5-1.4.0` |
| MiniSat's code, in `cvc5` | as in cvc5 1.4.0 | MIT (Niklas Eén, Niklas Sörensson) | `/opt/tla-kit/licenses/cvc5-minisat-LICENSE.txt` | cvc5's source, `src/prop/minisat` |
| cvc5's CPC signature | as at tag `cvc5-1.4.0`, `proofs/eo/cpc/` | BSD-3-Clause, as cvc5 | `/opt/tla-kit/licenses/cvc5-COPYING.txt` | cvc5's source |
| `ethos` | 0.2.4, `8dc85c4`, upstream's `ethos-linux-x86_64.zip` | BSD-3-Clause (the authors of ethos and their institutions) | `/opt/tla-kit/licenses/ethos-COPYING.txt` | `https://github.com/cvc5/ethos`, tag `ethos-0.2.4`; `ethos-0.2.4-src.tar.gz` in release `cvc5-1.4.0` |
| GMP, in `cvc5` | 6.3.0 | LGPL-3.0-or-later or GPL-2.0-or-later | `/usr/share/common-licenses/LGPL-3` and `/usr/share/common-licenses/GPL-2` | `gmp-6.3.0.tar.bz2`, with its signature, in release `cvc5-1.4.0`, and at `https://ftp.gnu.org/gnu/gmp/` |
| GMP, in `ethos` | 6.2.1, as Ubuntu 22.04's `2:6.2.1+dfsg-3ubuntu1` | LGPL-3.0-or-later or GPL-2.0-or-later | `/opt/tla-kit/licenses/gmp-6.2.1-ubuntu-copyright.txt`, `/usr/share/common-licenses/LGPL-3` and `/usr/share/common-licenses/GPL-2` | Ubuntu's source package `gmp_6.2.1+dfsg-3ubuntu1`, in release `cvc5-1.4.0` |
| MPFR, in `cvc5` | 4.2.2 | LGPL-3.0-or-later | `/usr/share/common-licenses/LGPL-3` | `mpfr-4.2.2.tar.xz`, with its signature, in release `cvc5-1.4.0`, and at `https://ftp.gnu.org/gnu/mpfr/` |
| LibPoly, in `cvc5` | 0.2.1 | LGPL-3.0 | `/usr/share/common-licenses/LGPL-3` | `https://github.com/SRI-CSL/libpoly`, tag `v0.2.1`; `libpoly-0.2.1.tar.gz` in release `cvc5-1.4.0` |
| CaDiCaL, in `cvc5` | `rel-2.1.3-elevate` | MIT (Armin Biere and others) | `/opt/tla-kit/licenses/cadical-LICENSE.txt` | `https://github.com/arminbiere/cadical`, tag `rel-2.1.3-elevate` |
| symfpu, in `cvc5` | `40bdec00e99f` | BSD-3-Clause, taken here from its choice of BSD-3-Clause or GPL-3.0 | `/opt/tla-kit/licenses/symfpu-LICENSE.txt` and `/opt/tla-kit/licenses/symfpu-LICENSE-BSD.txt` | `https://github.com/martin-cs/symfpu`, at `40bdec00e99f` |
| `libedit`, in `cvc5` | Ubuntu 22.04's `3.1-20210910-1build1` | BSD-3-Clause | `/opt/tla-kit/licenses/libedit-copyright.txt` | Ubuntu's source package `libedit_3.1-20210910-1build1` |
| `libbsd`, in `cvc5` | Ubuntu 22.04's `0.11.5-1` | BSD-2-Clause, BSD-3-Clause, BSD-4-Clause, ISC, Expat, Beerware and public domain, file by file, as its copyright file lists | `/opt/tla-kit/licenses/libbsd-copyright.txt` | Ubuntu's source package `libbsd_0.11.5-1` |
| `libtinfo` (`ncurses`), in `cvc5` | Ubuntu 22.04's `6.3-2ubuntu0.2` or `0.3`, whose `libtinfo.a` is the same | X11 (MIT), and BSD-3-Clause for some files, as its copyright file lists | `/opt/tla-kit/licenses/ncurses-copyright.txt` (from `0.3`) | Ubuntu's source package `ncurses_6.3-2ubuntu0.3` |
| glibc, in both | Ubuntu 22.04's `2.35-0ubuntu3.14` | LGPL-2.1-or-later, with the other licences its copyright file lists | `/opt/tla-kit/licenses/glibc-2.35-copyright.txt` and `/usr/share/common-licenses/LGPL-2.1` | Ubuntu's source package `glibc_2.35-0ubuntu3.14`, in release `cvc5-1.4.0` |
| `libstdc++` and `libgcc`, in both | GCC 11.4.0, Ubuntu 22.04's | GPL-3.0 with the GCC Runtime Library Exception 3.1 | `/usr/share/common-licenses/GPL-3` and `/opt/tla-kit/licenses/gcc-runtime-exception-3.1.txt` | Ubuntu's source package `gcc-11`; the exception asks no source of the combined work |

## tla-kit's own files in the image

`/usr/local/bin` (the wrappers, `tla-kit-info`, `tla-kit-selftest`) is tla-kit's code, under Apache-2.0. The
vendored skill at `/opt/tla-kit/skill` is TOPAK's, under the licence it has there (ADR-0011 item 5; its
`VENDOR-PIN`). Their licence texts are `/opt/tla-kit/LICENSE`, `/opt/tla-kit/LICENSE-DOCS` and
`/opt/tla-kit/NOTICE`.
