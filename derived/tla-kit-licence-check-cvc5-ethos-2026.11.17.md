# tla-kit: the licence check of cvc5 and ethos, 2026.11.17

> **Provenance note.** Written 2026.11.17 by the assistant, at the custodian's direction to start the licence
> check of `PLAN.md` Phase 6, on branch `phase6` after `0689dfc`. ADR-0012 item 8, accepted that day, puts `cvc5`
> 1.4.0, `ethos` 0.2.4 and cvc5 1.4.0's CPC signature in the base. Its Consequences ask for this check before the
> pull request that installs them. The record answers what redistributing them needs, with findings and a
> recommendation. **It decides nothing**, and nothing here is legal advice. Every source is named where it is
> used. What could not be determined is said so.

## 1. The question

May tla-kit redistribute upstream's Linux x86_64 builds of `cvc5` and `ethos`, in a public image and in a release?
If so, on what conditions? And does tla-kit keep copies of the archives, as ADR-0005 item 2 does for the prover?
The 2026.11.15 check answered the same question for the TLAPS tarball (`PLAN.md` D7).

## 2. What was read

| What | sha256 | How |
|---|---|---|
| `cvc5-Linux-x86_64-static.zip`, release `cvc5-1.4.0` of `cvc5/cvc5` | `61d13483ec9c4e8d05c7f3d532225255b2183a0c03b161d37d942d1ba089ec6d` | Downloaded 2026.11.17; the digest GitHub lists for the asset. Unpacked; its `COPYING`, `licenses/`, `lib/pkgconfig/` and file list read. `bin/cvc5` has sha256 `d4c534360e602f07…`. |
| `ethos-linux-x86_64.zip`, release `ethos-0.2.4` of `cvc5/ethos` | `1582fd32d7ef8ae7b8d82b3da92fcc542939a4941402a9a71cf8b33a06a3d8bc` | The same. The tag is commit `8dc85c4db8d6cc612f02dc3bb627331732605eff`, the one TOPAK pins. `ethos` has sha256 `97e95d36dcb596e6…`. |
| The two binaries | | Run in `v0.3.0`: `cvc5 --show-config`, and an ELF header and `.comment` read in Python. Their strings read. |
| cvc5's build, at tag `cvc5-1.4.0` (commit `b432cd77ebeb…`) | | Through the GitHub API: `cmake/FindGMP.cmake`, `FindMPFR.cmake`, `FindPoly.cmake`, `FindCaDiCaL.cmake`, `FindSymFPU.cmake`, `FindEditline.cmake`, `.github/workflows/ci.yml` and `.github/actions/install-dependencies/action.yml` |
| ethos's build, at `8dc85c4` | | `cmake/FindGMP.cmake` and `.github/workflows/main.yml` |
| The licences of the parts | | LibPoly's `LICENCE` at tag `v0.2.1`; symfpu's `LICENSE` at the commit cvc5 names. Ubuntu 22.04's published source versions of `gmp`, `libedit`, `libbsd`, `ncurses` and `glibc`, from Launchpad's API. |

## 3. Findings

**K-1. Both are under the modified BSD licence, and both are fully static.** `cvc5`'s and `ethos`'s `COPYING` are
BSD-3-Clause. Both binaries are "statically linked" ELF executables, and they ran in the image with no library of
its own. Both were built on Ubuntu 22.04 with GCC 11.4.0, as the `.comment` of each says
(`Ubuntu 11.4.0-1ubuntu1~22.04.3`).

**K-2. `cvc5` 1.4.0 holds these parts.** `--show-config` reports GMP, LibPoly and editline on, and CLN, GLPK,
CryptoMiniSat, Kissat, CoCoA and Normaliz off. So it is the build without GPL libraries that its `COPYING` describes.

| Part | Version | Where from | Licence |
|---|---|---|---|
| cvc5, with MiniSat's code | 1.4.0, `b432cd7` | its source | BSD-3-Clause; MiniSat MIT |
| GMP | 6.3.0 | built by cvc5 (`-DBUILD_GMP=1`) from `gmp-6.3.0.tar.bz2`, sha256 `ac28211a…20cb`; the zip's `gmp.pc` says 6.3.0 | LGPL-3.0-or-later or GPL-2.0-or-later |
| MPFR | 4.2.2 | built by cvc5 from `mpfr-4.2.2.tar.xz`, sha256 `b67ba038…6ce01`; the zip's `mpfr.pc` says 4.2.2 | LGPL-3.0-or-later |
| LibPoly | 0.2.1 | built by cvc5 from tag `v0.2.1` (`3d5e6fbd`), archive sha256 `f9920afc…5a0f` | LGPL-3.0 |
| CaDiCaL | `rel-2.1.3-elevate` | built by cvc5, archive sha256 `15e1e82f…ef92` | MIT |
| symfpu | `40bdec00e99f` | built by cvc5 | BSD-3-Clause or GPL-3.0, at the user's choice |
| libedit, with `libbsd` and `libtinfo` | 3.1-20210910-1build1; `libbsd` 0.11.5-1; `ncurses` 6.3-2 or a later 22.04 update | Ubuntu 22.04's `-dev` packages (`install-dependencies`) | BSD-3-Clause; `libbsd` BSD and ISC family; `ncurses` X11 (MIT) |
| libstdc++ and libgcc | GCC 11.4.0 | Ubuntu 22.04 | GPL-3.0 with the GCC Runtime Library Exception |
| glibc | 2.35, Ubuntu patch release not determined | Ubuntu 22.04 | LGPL-2.1-or-later |

**K-3. `ethos` 0.2.4 holds fewer.** Its release job runs on `ubuntu-22.04`, installs `libgmp-dev`, and links what
CMake finds there.

| Part | Version | Where from | Licence |
|---|---|---|---|
| ethos | 0.2.4, `8dc85c4` | its source | BSD-3-Clause |
| GMP | 6.2.1, as `2:6.2.1+dfsg-3ubuntu1`, the only version Ubuntu 22.04 publishes | Ubuntu 22.04's `libgmp-dev` | LGPL-3.0-or-later or GPL-2.0-or-later |
| libstdc++ and libgcc | GCC 11.4.0 | Ubuntu 22.04 | GPL-3.0 with the GCC Runtime Library Exception |
| glibc | 2.35, Ubuntu patch release not determined | Ubuntu 22.04 | LGPL-2.1-or-later |

Neither binary carries a version string for GMP, MPFR or glibc that could be read, so those versions rest on the
build files and the packages, not on the bytes.

**K-4. The CPC signature is cvc5's own source.** It is `proofs/eo/cpc/` at tag `cvc5-1.4.0`, under cvc5's
BSD-3-Clause, and it is not in either zip. TOPAK vendors the same directory, unchanged, with cvc5's `COPYING`
beside it.

**K-5. The archives leave out some of the notices their parts ask for.** `cvc5`'s zip carries its `COPYING` and
`licenses/` with five texts: LGPL-3.0, GPL-3.0, the GCC Runtime Library Exception, Apache-2.0 with LLVM exceptions,
and MiniSat's licence. Its `COPYING` names CaDiCaL and symfpu by URL only, and says nothing of glibc, libedit,
`libbsd` or `ncurses`. `ethos`'s zip carries `COPYING` and the LGPL-3.0 text, without the GPL-3.0 text that the
LGPL-3.0 builds on. Neither carries LGPL-2.1, glibc's licence. This is the gap the 2026.11.15 check found in the
TLAPS tarball (its L-3). Redistributing the zips or the binaries unchanged repeats it.

**K-6. Static linking makes the LGPL parts' conditions bite.** Upstream's `COPYING` files say the combined works stay
under BSD, which is so. Conveying them still carries the LGPL's conditions for a combined work:
- **LGPL-3.0 §4, for GMP, MPFR and LibPoly.** A static binary cannot use a shared-library mechanism, §4(d)(1). So
  §4(d)(0) applies: the Minimal Corresponding Source of each library is conveyed, and the application in a form
  that lets the user relink it. Here that form is cvc5's and ethos's source, which is public and BSD-3-Clause.
  §4(a) and (b) also ask for a notice that the library is used, with the GPL-3.0 and LGPL-3.0 texts.
- **LGPL-2.1 §6, for glibc.** It asks the same in substance: glibc's source, and the application in a relinkable
  form or its source.
- **The GPL-3.0 §6 rule on where the source is.** The LGPL-3.0 conveys source "under the terms of" the GPL-3.0.
  Under §6(d) the source may be on another server, but the distributor stays obliged to keep it available. The
  URLs cvc5 builds GMP and MPFR from are `github.com/cvc5/cvc5-deps/blob/main/…`, on a branch, not at a fixed
  commit.

**K-7. Two facts are open, as GMP's release and `libsha1`'s licence were for D7.** The first is which Ubuntu 22.04
patch release of glibc 2.35 each binary links. Ubuntu has published `2.35-0ubuntu3` to `2.35-0ubuntu3.18`, and the
GitHub runners took whichever their image held. The second is which `ncurses` 6.3 release `cvc5` links. Each can be
settled from the bytes, as C-2 settled GMP: compare the binary's code with `libc.a` and `libtinfo.a` from each
candidate `-dev` package. That has not been done.

**K-8. TOPAK runs different builds of the same versions.** TOPAK's certified results name `cvc5 1.4.0 [git b432cd7
on branch HEAD]`, the version string this `cvc5` prints. Their binary digest (`a4ce24a1…`) is of the macOS arm64
build, and TOPAK built its `ethos` from source on macOS. A result made in the image names the image's digests.
TOPAK's `proof-cert.sh` already prints each binary's digest.

## 4. Options

| | What the image installs | What a release keeps | What is owed |
|---|---|---|---|
| **A** | Upstream's binaries, by digest | A release beside the image's, like `tlapm-ff40755`, holding the two zips, `licenses/`, and the source of every copyleft part: GMP 6.3.0 and 6.2.1 (Ubuntu's source package), MPFR 4.2.2, LibPoly 0.2.1, glibc 2.35 at the patch release K-7 finds, and cvc5's and ethos's source at their tags | K-7's two facts, before a public release |
| **B** | Both built from source in the `Dockerfile`, linked dynamically against the image's Ubuntu 24.04 libraries | cvc5's and ethos's source, and LibPoly's if Ubuntu 24.04 has no package for it. glibc, GMP, MPFR and `libedit` come from the snapshot, whose source the image's notice already names (L-4 of 2026.11.15) | A build of cvc5 is long, and it has to give the same image digest on two runners (ADR-0014). The binary is not the one upstream tested |
| **C** | `cvc5` as A; `ethos` as B | As A for `cvc5`; ethos's source only | K-7's two facts for `cvc5` |

Under every option, `licenses/THIRD-PARTY.md` gains a row for each part of K-2 to K-4. `licenses/` gains the texts
K-5 finds missing: CaDiCaL's MIT, symfpu's BSD-3-Clause, `libedit`'s, `libbsd`'s and `ncurses`'s notices, cvc5's
and ethos's `COPYING`, LGPL-3.0, GPL-3.0 and the GCC exception. LGPL-2.1 is already in
`/usr/share/common-licenses`. `tla-kit-selftest` fails if any text the notice names is missing, as it does now.

## 5. Recommendation

**Option A: yes, tla-kit may redistribute upstream's builds of `cvc5` and `ethos`, on three conditions**, the same
three as D7:
1. **Every redistribution carries the notices of §4.** The image carries them under `/opt/tla-kit/`, and the kept
   release attaches `licenses/`.
2. **A kept release offers the copyleft parts' source from one place,** together with cvc5's and ethos's own source
   and the two zips. It is made before the pull request that pins them, as ADR-0005 item 2 orders for the prover.
   K-6's last point argues against relying on `cvc5-deps`' branch.
3. **K-7's two facts are settled before the release that first carries them:** glibc's patch release in each
   binary, and `ncurses`'s in `cvc5`.

Option A keeps the binaries upstream tested and that TOPAK's results name by version, and keeps the image's build
as reproducible as it is now. Option B would remove condition 3, since the image's own libraries replace the static
ones. It costs a long C++ build in every CI run and release, and a reproducibility question ADR-0014 has not met.
Option C saves little: `ethos` is the smaller and simpler part.

Keeping the two zips themselves goes past ADR-0013 item 8. It says only the prover's download is kept here, and
that keeping a copy of anything else needs a new record (ADR-0015, gap 3). Condition 2 makes the release anyway,
and an upstream can stop serving a release asset, as upstream did with the prover's tarball. So the recommendation
is to keep them, by a new record. That record also says whether `spec/PinLifecycle.tla`, which models the prover's
kept copy, has to model these.

## 6. What changes if this is accepted

| Record | Change |
|---|---|
| A new record | The kept release holds the two zips, as ADR-0005 item 2 holds the prover's tarball, and the weekly check compares them with upstream. ADR-0013 item 8 asks for a record to keep a copy |
| ADR-0011 | Item 4's notice gains the rows and texts of §4, by a History row |
| ADR-0014 | Item 3: the release that first carries them names the kept release, as `v0.1.0` named `tlapm-ff40755` |
| `PLAN.md` Phase 6 | The licence step is done, and the next is K-7's two facts and the kept release, before the pull request that installs them |
