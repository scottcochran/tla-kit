# tla-kit: one image of the TLA+ tool family, the same locally and in CI.
# TLC/SANY/PlusCal (tla2tools.jar) and TLAPS (tlapm with Z3, Zenon, Isabelle/TLA+, LS4), with the vendored scripts
# of the writing-tla-specs-and-proofs skill and a self-test; cvc5 and ethos, which check SMT proofs, with cvc5's
# CPC signature (ADR-0012 item 8).
#
# Every input is held to a digest or a date (ADR-0002): the base image by digest, the apt packages by a snapshot
# of Ubuntu's archive, both downloads and the tlapm binary by sha256. Every pin is listed, with its values, in
# PINS.json, and tools/pins.py fails CI if a default below differs from it (ADR-0013 item 7). The TLAPS tag is a
# rolling pre-release that upstream rebuilds under the same name, so the tarball is taken from the copy kept in
# this repository's release `tlapm-<commit>`, not from upstream (ADR-0005 item 2). cvc5's and ethos's zips, and
# cvc5's source for the signature, are taken from the copies kept in its release `cvc5-<version>` (ADR-0017).
#
# A build is fixed in time to its commit (ADR-0014 item 8): CI and the release workflow set SOURCE_DATE_EPOCH to
# the commit's time and TLA_KIT_REVISION and TLA_KIT_CREATED for the OCI labels, and the files a build would
# otherwise stamp with the day are cleared, so two builds of one commit give one digest.
#
# Linux x86_64 only (ADR-0003): upstream publishes no Linux arm64 build of tlapm. The platform is fixed in the
# FROM lines, so a plain `docker build .` on an arm64 machine builds the x86_64 image, to run under emulation.

# tlapm needs glibc 2.38 at ff40755 and 2.42 at 9a52faf, so the base is Ubuntu 26.04, with glibc 2.43 (Ubuntu 24.04
# has 2.39). The tag is kept beside the digest to say what the digest was resolved from (2026.11.19); Docker uses
# the digest.
ARG BASE_IMAGE=eclipse-temurin:25-jre-resolute@sha256:fa681c5833ecc085202c0923e909f9de888d80d22a7f38d6c51268ae5978c1d7

# The TLAPS tarball, from the kept copy. CI downloads it with `gh` and passes it as the build context
# `tlapm-tarball` instead, so that a missing release fails with a message that says so;
# the install step below checks its sha256 either way.
FROM scratch AS tlapm-tarball
ARG TLAPM_SHA256=d9c06a04eb6b1b4192d3e22d5378143d09c9801414b9ad7ff6e918d34093c1f0
ARG TLAPM_URL=https://github.com/scottcochran/tla-kit/releases/download/tlapm-9a52faf/tlapm-1.6.0-pre-x86_64-linux-gnu.tar.gz
ADD --checksum=sha256:${TLAPM_SHA256} ${TLAPM_URL} /tlapm.tar.gz

# cvc5's and ethos's zips and cvc5's source, from the kept copies (ADR-0017 items 1 and 2). CI downloads them with
# `gh` and passes them as the build context `kept-cvc5` instead, as it does the TLAPS tarball; the install step
# below checks their sha256 either way.
FROM scratch AS kept-cvc5
ARG CVC5_VERSION=1.4.0
ARG CVC5_ZIP_SHA256=61d13483ec9c4e8d05c7f3d532225255b2183a0c03b161d37d942d1ba089ec6d
ARG CVC5_SRC_SHA256=06c65b30693d1abf7c1393b497c799950de2833457920b9433da8e418bce9113
ARG ETHOS_ZIP_SHA256=1582fd32d7ef8ae7b8d82b3da92fcc542939a4941402a9a71cf8b33a06a3d8bc
ARG CVC5_KEPT=https://github.com/scottcochran/tla-kit/releases/download/cvc5-1.4.0
ADD --checksum=sha256:${CVC5_ZIP_SHA256} ${CVC5_KEPT}/cvc5-Linux-x86_64-static.zip /cvc5.zip
ADD --checksum=sha256:${CVC5_SRC_SHA256} ${CVC5_KEPT}/cvc5-${CVC5_VERSION}-src.tar.gz /cvc5-src.tar.gz
ADD --checksum=sha256:${ETHOS_ZIP_SHA256} ${CVC5_KEPT}/ethos-linux-x86_64.zip /ethos.zip

FROM --platform=linux/amd64 ${BASE_IMAGE} AS fetch
ARG TLA2TOOLS_VERSION=v1.7.4
ARG TLA2TOOLS_SHA256=936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88
ADD --checksum=sha256:${TLA2TOOLS_SHA256} \
    https://github.com/tlaplus/tlaplus/releases/download/${TLA2TOOLS_VERSION}/tla2tools.jar \
    /fetch/tla2tools.jar
# ADD from a URL makes the file readable by root only; the image runs as tla. Its time comes from the server's
# Last-Modified header, so it is set to a fixed one.
RUN chmod 0644 /fetch/tla2tools.jar && touch -d 2000-01-01T00:00:00Z /fetch/tla2tools.jar

FROM --platform=linux/amd64 ${BASE_IMAGE}
ARG BASE_IMAGE
ARG TLA2TOOLS_VERSION=v1.7.4
ARG TLA2TOOLS_SHA256=936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88
ARG TLAPM_TAG=1.6.0-pre
ARG TLAPM_SHA256=d9c06a04eb6b1b4192d3e22d5378143d09c9801414b9ad7ff6e918d34093c1f0
ARG TLAPM_BINARY_SHA256=faa92f2606242ce239584e665978f33c7378ba23991c6f318a74525dcb892cc0
ARG CVC5_VERSION=1.4.0
ARG CVC5_ZIP_SHA256=61d13483ec9c4e8d05c7f3d532225255b2183a0c03b161d37d942d1ba089ec6d
ARG CVC5_SRC_SHA256=06c65b30693d1abf7c1393b497c799950de2833457920b9433da8e418bce9113
ARG CVC5_BINARY_SHA256=d4c534360e602f07adcbb2aafbe833e73ce1e7c6f2572cb7eee03de73d6e2e5b
ARG CVC5_CPC_TREE=633f74115700ad32
ARG ETHOS_VERSION=0.2.4
ARG ETHOS_ZIP_SHA256=1582fd32d7ef8ae7b8d82b3da92fcc542939a4941402a9a71cf8b33a06a3d8bc
ARG ETHOS_BINARY_SHA256=97e95d36dcb596e6439d935af68e9005a508620f667af546d92d6d3700f26538
ARG SOURCE_DATE_EPOCH
ARG TLA_KIT_REVISION=
ARG TLA_KIT_CREATED=
# The state of Ubuntu's archive the packages are taken from, so a rebuild gets the same versions. The sources are
# pointed at snapshot.ubuntu.com for that moment and at nothing else, and the build fails if any other source is
# left (apt's own --snapshot also fetches the live archive's indices). Moving the date is a runtime refresh,
# together with the base (ADR-0013 item 2).
ARG APT_SNAPSHOT=20261119T000000Z
# python3: the skill's scripts (standard library only). perl: shasum, which project scripts call. git:
# project-root detection and CI planning scripts. Their installed versions are recorded in /opt/tla-kit/packages.
# apt's and dpkg's logs and caches, which hold the day of the build, are removed.
RUN sed -i -E "s#^URIs: http://(archive|security)\.ubuntu\.com/ubuntu/?#URIs: https://snapshot.ubuntu.com/ubuntu/${APT_SNAPSHOT}/#" \
      /etc/apt/sources.list.d/ubuntu.sources \
 && ! grep -E '^URIs:' /etc/apt/sources.list.d/ubuntu.sources | grep -v "snapshot.ubuntu.com/ubuntu/${APT_SNAPSHOT}/" \
 && ! grep -sE '^[[:space:]]*deb' /etc/apt/sources.list \
 && apt-get update \
 && ! ls /var/lib/apt/lists/ | grep -E '_dists_' | grep -v "^snapshot.ubuntu.com_ubuntu_${APT_SNAPSHOT}_dists_" \
 && apt-get install -y --no-install-recommends python3 perl git \
 && mkdir -p /opt/tla-kit \
 && dpkg-query -W -f '${Package} ${Version}\n' python3 perl git > /opt/tla-kit/packages \
 && rm -rf /var/lib/apt/lists/* /var/log/apt/* /var/log/dpkg.log /var/log/alternatives.log \
      /var/cache/ldconfig/aux-cache /var/cache/debconf/*-old /var/lib/dpkg/*-old
# The image runs as tla (uid 1000), so files it writes to a mounted project are not owned by root (ADR-0003 item 4).
# Ubuntu's own uid-1000 user is removed to make way for it. HOME is world-writable, so the image also runs under
# `--user "$(id -u):$(id -g)"` for a project owned by another uid; Isabelle keeps its user state there. The day
# useradd writes into /etc/shadow is cleared; the account has no password.
RUN userdel --remove ubuntu 2>/dev/null || true \
 && useradd --uid 1000 --user-group --create-home --home-dir /home/tla --shell /bin/bash tla \
 && chmod 1777 /home/tla \
 && sed -i -E 's/^(tla:[^:]*:)[0-9]*:/\1:/' /etc/shadow \
 && rm -f /etc/shadow- /etc/gshadow- /etc/passwd- /etc/group- /etc/subuid- /etc/subgid-
COPY --from=fetch /fetch/tla2tools.jar /opt/tla/tla2tools.jar
# The archives below are extracted with Python's tarfile, not GNU tar. Ubuntu 26.04's tar opens files with openat2,
# which Docker Desktop's amd64 emulation on Apple Silicon does not implement, and a plain `docker build .` there has
# to work (ADR-0003 item 3). The `data` filter leaves files owned by root, as tar's --no-same-owner and COPY did,
# and keeps the archive's modes and times. The tarball is mounted, not copied, so no layer holds it.
RUN --mount=type=bind,from=tlapm-tarball,source=/tlapm.tar.gz,target=/kept/tlapm.tar.gz \
    echo "${TLAPM_SHA256}  /kept/tlapm.tar.gz" | sha256sum -c - \
 && python3 -m tarfile --filter data -e /kept/tlapm.tar.gz /tmp/tlaps \
 && mv /tmp/tlaps/tlapm /opt/tlaps && rmdir /tmp/tlaps \
 && echo "${TLAPM_BINARY_SHA256}  /opt/tlaps/bin/tlapm" | sha256sum -c -
# cvc5 and ethos, upstream's static builds, and cvc5's CPC signature from its source (ADR-0012 item 8): each archive
# checked by sha256, each binary by its own, and the signature by the tree digest TOPAK's proof-cert.sh prints over
# its .eo files. The archives are mounted, not copied, so no layer holds them. Their times are fixed.
RUN --mount=type=bind,from=kept-cvc5,target=/kept \
    printf '%s  %s\n' "${CVC5_ZIP_SHA256}" /kept/cvc5.zip "${CVC5_SRC_SHA256}" /kept/cvc5-src.tar.gz \
      "${ETHOS_ZIP_SHA256}" /kept/ethos.zip | sha256sum -c - \
 && mkdir -p /opt/cvc5/bin /opt/ethos/bin \
 && python3 -c 'import sys, zipfile; open(sys.argv[3], "wb").write(zipfile.ZipFile(sys.argv[1]).read(sys.argv[2]))' \
      /kept/cvc5.zip cvc5-Linux-x86_64-static/bin/cvc5 /opt/cvc5/bin/cvc5 \
 && python3 -c 'import sys, zipfile; open(sys.argv[3], "wb").write(zipfile.ZipFile(sys.argv[1]).read(sys.argv[2]))' \
      /kept/ethos.zip ethos /opt/ethos/bin/ethos \
 && chmod 0755 /opt/cvc5/bin/cvc5 /opt/ethos/bin/ethos \
 && printf '%s  %s\n' "${CVC5_BINARY_SHA256}" /opt/cvc5/bin/cvc5 "${ETHOS_BINARY_SHA256}" /opt/ethos/bin/ethos \
      | sha256sum -c - \
 && python3 -m tarfile --filter data -e /kept/cvc5-src.tar.gz /tmp/cvc5-src \
 && mv "/tmp/cvc5-src/cvc5-cvc5-${CVC5_VERSION}/proofs/eo/cpc" /opt/cvc5/cpc && rm -rf /tmp/cvc5-src \
 && tree=$(cd /opt/cvc5/cpc && find . -type f -name '*.eo' | LC_ALL=C sort | xargs sha256sum | sha256sum | cut -c1-16) \
 && { [ "$tree" = "${CVC5_CPC_TREE}" ] || { echo "the CPC signature's tree is $tree, not ${CVC5_CPC_TREE}"; exit 1; }; } \
 && find /opt/cvc5 /opt/ethos -exec touch -h -d 2000-01-01T00:00:00Z {} +
COPY bin/ /usr/local/bin/
COPY vendor/writing-tla-specs-and-proofs/ /opt/tla-kit/skill/
# The MCP server, standard library only (ADR-0008), started as `tla-kit mcp`; and the lemma graph beside it, which
# the server imports and `tla-kit lemma-graph` runs (ADR-0024, Proposed).
COPY server/tla_kit_mcp.py server/lemma_graph.py /opt/tla-kit/server/
# tla-kit's licences, and the notice of the third-party software in the image with the licence texts the TLAPS
# tarball leaves out (ADR-0011 item 4; licenses/THIRD-PARTY.md).
COPY LICENSE LICENSE-DOCS NOTICE /opt/tla-kit/
COPY licenses/ /opt/tla-kit/licenses/
# The inventory: what the image is meant to hold, and where each part came from (ADR-0013 item 7). The self-test
# checks every installed digest against it.
COPY PINS.json /opt/tla-kit/PINS.json
# What the image was built with, for tla-kit-info and the self-test, beside the inventory of what it is meant to
# hold. A build with other arguments than PINS.json's fails the self-test.
RUN printf '%s %s\n' \
      base_image "${BASE_IMAGE}" apt_snapshot "${APT_SNAPSHOT}" \
      tla2tools_version "${TLA2TOOLS_VERSION}" tla2tools_sha256 "${TLA2TOOLS_SHA256}" \
      tlapm_tag "${TLAPM_TAG}" tlapm_tarball_sha256 "${TLAPM_SHA256}" tlapm_binary_sha256 "${TLAPM_BINARY_SHA256}" \
      cvc5_version "${CVC5_VERSION}" cvc5_zip_sha256 "${CVC5_ZIP_SHA256}" cvc5_binary_sha256 "${CVC5_BINARY_SHA256}" \
      cvc5_src_sha256 "${CVC5_SRC_SHA256}" cvc5_cpc_tree "${CVC5_CPC_TREE}" \
      ethos_version "${ETHOS_VERSION}" ethos_zip_sha256 "${ETHOS_ZIP_SHA256}" ethos_binary_sha256 "${ETHOS_BINARY_SHA256}" \
      revision "${TLA_KIT_REVISION:-unknown}" created "${TLA_KIT_CREATED:-unknown}" \
      > /opt/tla-kit/build-args
# The image says where and from which commit it was built, and when that commit was made: not when it was built,
# and not under which version tag, which would make the digest depend on the tag (ADR-0014 item 8). The base's
# version label is Ubuntu's (26.04), so it is emptied rather than left to read as tla-kit's.
LABEL org.opencontainers.image.source="https://github.com/scottcochran/tla-kit" \
      org.opencontainers.image.revision="${TLA_KIT_REVISION}" \
      org.opencontainers.image.created="${TLA_KIT_CREATED}" \
      org.opencontainers.image.licenses="Apache-2.0 AND CC-BY-4.0" \
      org.opencontainers.image.title="tla-kit" \
      org.opencontainers.image.version="" \
      org.opencontainers.image.description="The TLA+ tool family in one image: TLC, SANY, PlusCal and TLAPS, with cvc5 and ethos, held to digests"
# TLA_JAR and TLAPM are the variables the skill's scripts and the projects' run scripts already read (ADR-0004).
# So are CVC5 and ETHOS, which a project's certified run reads (TOPAK's spec/proof-cert.sh).
ENV TLA_JAR=/opt/tla/tla2tools.jar \
    TLAPM=/opt/tlaps/bin/tlapm \
    CVC5=/opt/cvc5/bin/cvc5 \
    ETHOS=/opt/ethos/bin/ethos \
    TLA_KIT_SKILL=/opt/tla-kit/skill \
    HOME=/home/tla \
    PATH=/opt/tlaps/bin:/opt/cvc5/bin:/opt/ethos/bin:$PATH
USER tla
WORKDIR /work
CMD ["tla-kit-info"]
