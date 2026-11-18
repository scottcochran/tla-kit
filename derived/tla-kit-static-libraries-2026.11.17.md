# tla-kit: the libraries linked into cvc5 and ethos, read from the bytes, 2026.11.17

> **Provenance note.** Written 2026.11.17 by the assistant, at the custodian's direction to settle the two facts
> that `derived/tla-kit-licence-check-cvc5-ethos-2026.11.17.md` left open (its K-7). That day the custodian chose
> its option A, upstream's builds on D7's three conditions, and chose to keep the two zips. This is condition 3.
> Branch `phase6`, after `0689dfc`. It decides nothing, and nothing here is legal advice. The annex beside it,
> [`tla-kit-static-libraries-annex-2026.11.17/`](tla-kit-static-libraries-annex-2026.11.17/), holds the script, every
> output and the digest of every package read.

## 1. The question

Which Ubuntu 22.04 release of glibc 2.35 does each of `cvc5` 1.4.0 and `ethos` 0.2.4 contain? Which `ncurses` 6.3
release does `cvc5` contain? Neither binary carries a version string for them. Both were built on GitHub's
`ubuntu-22.04` runners, which held whichever release their image had.

## 2. The method

`match.py` reads a static archive's object files. For each executable section, it masks every field the linker
fills in, using the section's relocations, along with the instruction bytes a GOT or TLS relaxation may rewrite.
It then looks for the masked code in the binary's executable sections. One archive is given per candidate release.
For every section whose code differs between candidates, it prints which candidates' code is in the binary. A
release is consistent when every such section agrees with it. It uses the Python standard library only.

| Read | Candidates | From |
|---|---|---|
| `libc.a` from `libc6-dev` | `2.35-0ubuntu3` and `3.1` to `3.15` and `3.18`, all 17 releases Ubuntu 22.04 published. Launchpad serves no `3.16` or `3.17` for it. | Launchpad's librarian (`launchpad.net/ubuntu/+archive/primary/+files/`) |
| `libtinfo.a` from `libncurses-dev` | `6.3-2`, `6.3-2ubuntu0.1` to `0.3` | The same |
| `libgmp.a` from `libgmp-dev` | `2:6.2.1+dfsg-3ubuntu1`, the only release in 22.04, against cvc5's GMP 6.3.0 | The same, and cvc5's zip |
| `libgmp.a`, `libmpfr.a`, `libpicpoly.a`, `libpicpolyxx.a`, `libcadical.a` | The libraries cvc5's zip carries beside its binary | cvc5's zip |

The binaries are those of the licence check: `cvc5` sha256 `d4c534360e602f07…` and `ethos` sha256
`97e95d36dcb596e6…`, from zips `61d13483…ec6d` and `1582fd32…a3d8bc`.

## 3. Findings

**S-1. Both binaries contain glibc `2.35-0ubuntu3.14`.** It is the only candidate consistent with every
differing section, in each binary: 25 sections in `cvc5` and 22 in `ethos`. Three bound it:
- `tsearch.o`'s code is present as it is up to `3.14`, and changed in `3.15`;
- `vfscanf-internal.o` and `wgenops.o` are present as they are from `3.14` on.

The rest agree. For example, `malloc.o` is present as it is from `3.13`, and `dl-load.o` and `fileops.o` as they
are before `3.18`.

**S-2. `cvc5` contains `ncurses` `6.3-2ubuntu0.2` or `0.3`, and the two have the same `libtinfo.a`.** The code of
`db_iterator.o`, `read_entry.o` and `lib_tparm.o` rules out `6.3-2` and `0.1`. The `libtinfo.a` of `0.2` and of
`0.3` are identical, byte for byte and member for member (sha256 `76b8cb22c48d5668…`), so no binary can tell them
apart. Whichever it was, the code linked is the same. `ncurses` is under the X11 (MIT) licence, which asks for its
notice and not its source.

**S-3. `ethos`'s GMP is Ubuntu's 6.2.1.** 154 of `libgmp-dev` 6.2.1's sections are present, against 7 of
cvc5's 6.3.0. Of the sections whose code differs between the two, 146 are present as 6.2.1's alone. The other 7
match both, since they differ only in masked bytes, and none matches 6.3.0's alone. This agrees with ethos's release
job (K-3).

**S-4. `cvc5` contains the libraries its zip carries.** Present in its binary are 275 of the GMP's searchable
sections, 22 of MPFR's, 32 and 49 of LibPoly's two, and 323 of CaDiCaL's. The zip's `pkg-config` files name GMP
6.3.0 and MPFR 4.2.2, and cvc5's build names LibPoly 0.2.1 (K-2). MPFR's count is low because `cvc5` uses only
floating-point constant folding from it.

**S-5. A control.** The same search for `libtinfo.a` in `ethos`, which does not link it, finds none of its 42
searchable sections.

**Limits.** Sections shorter than 24 bytes of unmasked code are not searched. The candidates are what Launchpad
publishes for Ubuntu 22.04. Two variants of one section can both match when they differ only in masked bytes, as
`access.o` in `libtinfo.a` does, and such a section decides nothing. The conclusion rests on the sections that
differ in unmasked code.

## 4. What follows

D7's condition 3, as the licence check's option A restates it, is met:
- **glibc** is `2.35-0ubuntu3.14` in both binaries.
- **`ncurses`** is the `libtinfo.a` that `6.3-2ubuntu0.2` and `0.3` share, and it owes no source.

So the kept release of condition 2 offers this source for the copyleft parts:

| Part | In | Source | Licence |
|---|---|---|---|
| glibc 2.35 | both | Ubuntu's source package `glibc_2.35-0ubuntu3.14` | LGPL-2.1-or-later |
| GMP 6.3.0 | `cvc5` | `gmp-6.3.0.tar.bz2`, sha256 `ac28211a…20cb`, as cvc5's build names it | LGPL-3.0-or-later or GPL-2.0-or-later |
| GMP 6.2.1 | `ethos` | Ubuntu's source package `gmp_6.2.1+dfsg-3ubuntu1` | LGPL-3.0-or-later or GPL-2.0-or-later |
| MPFR 4.2.2 | `cvc5` | `mpfr-4.2.2.tar.xz`, sha256 `b67ba038…6ce01`, as cvc5's build names it | LGPL-3.0-or-later |
| LibPoly 0.2.1 | `cvc5` | tag `v0.2.1` of `SRI-CSL/libpoly`, archive sha256 `f9920afc…5a0f` | LGPL-3.0 |

Beside them go cvc5's and ethos's own source at `cvc5-1.4.0` and `ethos-0.2.4`, the two zips the custodian chose
to keep, and `licenses/`. Each digest is checked when the release is made.

## 5. The annex

| File | What it is |
|---|---|
| `match.py` | The search of §2 |
| `run-glibc.sh`, `run-tinfo.sh` | `match.py` over every candidate, with the packages unpacked under `LIBS` |
| `glibc-cvc5.txt`, `glibc-ethos.txt` | S-1 |
| `tinfo-cvc5.txt`, `tinfo-0.2-vs-0.3.txt` | S-2 |
| `gmp-ethos.txt` | S-3 |
| `zip-libs-cvc5.txt` | S-4 |
| `tinfo-ethos.txt` | S-5 |
| `packages.txt` | The sha256 of each of the 22 packages read |
