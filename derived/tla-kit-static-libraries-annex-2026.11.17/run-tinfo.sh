#!/bin/bash
# run-tinfo.sh BINARY: match.py against every jammy libncurses-dev release's libtinfo.a
here=$(cd "$(dirname "$0")" && pwd)
# LIBS holds each package unpacked as LIBS/<package>_<version>/ (dpkg-deb -x, or ar x and tar -x)
LIBS=${LIBS:?set LIBS to the directory of unpacked packages}
args=()
for v in 6.3-2 6.3-2ubuntu0.1 6.3-2ubuntu0.2 6.3-2ubuntu0.3; do
  args+=("$v=$LIBS/libncurses-dev_$v/usr/lib/x86_64-linux-gnu/libtinfo.a")
done
exec python3 -I "$here/match.py" "$1" "${args[@]}"
