# tla-kit: the copyleft parts of the TLAPS tarball, their releases and their source, 2026.11.16

> **Provenance note.** Written 2026.11.16 by the assistant, at the custodian's direction to carry out `PLAN.md`
> Phase 1c, on branch `phase1c` after `c250b1d`. It settles the two facts `PLAN.md` D7's condition 3 left open:
> which GMP release the TLAPS tarball bundles, and `libsha1`'s licence. It also names the source the kept release
> offers for each copyleft part (condition 2). It decides nothing, and nothing here is legal advice. Every source
> is named where it is used, and its sha256 is given.

## 1. What was read

| What | sha256 | How |
|---|---|---|
| The TLAPS tarball, `tlapm-1.6.0-pre-x86_64-linux-gnu.tar.gz`, from upstream on 2026.11.16 | `99db29f1…6bcc` | The pin: upstream still served the build the image holds. Extracted, and `lib/tlapm/backends/Isabelle-install/poly/` read. |
| Isabelle2025's `Admin/components/main` | | From `isabelle.in.tum.de/repos/isabelle/raw-file/Isabelle2025/`. It names the component `polyml-5.9.1` and no separate `sha1` component. |
| Isabelle's component `polyml-5.9.1.tar.gz`, from `isabelle.in.tum.de/components/` | `f633d451…e871` | Last modified 2023-10-14. Its `README`, `sha1/` directory and `x86_64-linux/` binaries read. |
| Ubuntu 18.04's `libgmp10_6.1.2+dfsg-2_amd64.deb`, from `archive.ubuntu.com` | | To compare its `libgmp.so.10` with the tarball's |
| GMP 6.1.2's source, `gmp-6.1.2.tar.xz`, and its signature, from `ftp.gnu.org/gnu/gmp/` | `87b565e8…1912` | `gmplib.org` refused the connection on the day. The signature was not checked: `gpg` is not installed where this was done. |
| Poly/ML 5.9.1's source, `polyml/polyml` tag `v5.9.1` as GitHub archives it | `52f56a57…663c` | The tag is commit `90c0dbb2514e`, which the component's `README` names |

## 2. Findings

**C-1. The tarball's `libgmp.so.10` and `libsha1.so` are Isabelle's, byte for byte.** Both have the same sha256
as the files of the same names in the `polyml-5.9.1` component's `x86_64-linux/`. So does `libpolymain.a`.
`poly`, `polyimport` and `libpolyml.a` differ from the component's. TLAPS's build makes its own Isabelle
installation, which was not read here. Their source is still Poly/ML 5.9.1.

**C-2. The GMP release is 6.1.2.** The library's version string is `6.1.2`, and its build comment is
`GCC: (Ubuntu 7.5.0-3ubuntu1~18.04) 7.5.0`. It is not Ubuntu 18.04's own `libgmp10` package: that library has
different bytes and no build comment. So Isabelle built GMP 6.1.2 itself on Ubuntu 18.04, or copied it from a
build that did. The configuration it was built with is not recorded in the component. The source that corresponds
to it is GMP 6.1.2's release, `gmp-6.1.2.tar.xz`.

**C-3. `libsha1` is GPL-3.0-or-later.** The component's `sha1/README` (Sascha Böhme, 2010-04-14) says the
library is GNU coreutils 8.4's `sha1.c`, `sha1.h` and `COPYING`, copied without change, and that coreutils'
licence applies. `sha1.c`'s header says GPL version 3 or any later version (Free Software Foundation, 2000 to 2010;
written by Scott G. Miller). `COPYING` is GPL-3.0. The library's exported symbols are `sha1.c`'s. The
corresponding source is the component's `sha1/` directory, with its `build` script.

**C-4. Poly/ML is 5.9.1, at `90c0dbb2514e`.** The component's `README` says it is built from that commit, which
is the `v5.9.1` tag. Its licence is LGPL-2.1, as the licence check found.

## 3. What follows

`PLAN.md` D7's condition 3 is met: the GMP release is 6.1.2, and `libsha1`'s licence is GPL-3.0-or-later.
`licenses/THIRD-PARTY.md` says so in their rows.

For condition 2, the kept release (`tools/keep-tlapm.sh`, release `tlapm-ff40755`) holds, beside the tarball and
`licenses/`:

| Asset | Part | Licence |
|---|---|---|
| `polyml-5.9.1-src.tar.gz` (`52f56a57…663c`) | Poly/ML 5.9.1 | LGPL-2.1 |
| `gmp-6.1.2.tar.xz` (`87b565e8…1912`) and `gmp-6.1.2.tar.xz.sig` | GMP 6.1.2 | LGPL-3.0-or-later or GPL-2.0-or-later |
| `libsha1-src.tar.gz` | `libsha1`: the component's `sha1/` and its `README` | GPL-3.0-or-later |

**Not determined:** the configure options GMP was built with, and how TLAPS's build changes the Poly/ML binaries.
Neither changes which source corresponds to them.
