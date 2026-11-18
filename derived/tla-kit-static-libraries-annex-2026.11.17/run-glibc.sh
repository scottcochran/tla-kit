#!/bin/bash
# run-glibc.sh BINARY: match.py against every jammy libc6-dev release downloaded
here=$(cd "$(dirname "$0")" && pwd)
# LIBS holds each package unpacked as LIBS/<package>_<version>/ (dpkg-deb -x, or ar x and tar -x)
LIBS=${LIBS:?set LIBS to the directory of unpacked packages}
args=()
for v in 3 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 3.10 3.11 3.12 3.13 3.14 3.15 3.18; do
  args+=("0ubuntu$v=$LIBS/libc6-dev_2.35-0ubuntu$v/usr/lib/x86_64-linux-gnu/libc.a")
done
exec python3 -I "$here/match.py" "$1" "${args[@]}"
