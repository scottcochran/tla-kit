# tla-kit: one image of the TLA+ tool family, the same locally and in CI.
# TLC/SANY/PlusCal (tla2tools.jar) and TLAPS (tlapm with Z3, Zenon, Isabelle/TLA+, LS4), with the vendored scripts
# of the writing-tla-specs-and-proofs skill and a self-test.
#
# Every input is held to a digest or a date (ADR-0002): the base image by digest, the apt packages by a snapshot
# of Ubuntu's archive, both downloads and the tlapm binary by sha256. Every pin is listed, with its values, in
# PINS.json, and tools/pins.py fails CI if a default below differs from it (ADR-0013 item 7). The TLAPS tag is a
# rolling pre-release that upstream rebuilds under the same name, so the tarball is taken from the copy kept in
# this repository's release `tlapm-<commit>`, not from upstream (ADR-0005 item 2).
#
# A build is fixed in time to its commit (ADR-0014 item 8): CI and the release workflow set SOURCE_DATE_EPOCH to
# the commit's time and TLA_KIT_REVISION and TLA_KIT_CREATED for the OCI labels, and the files a build would
# otherwise stamp with the day are cleared, so two builds of one commit give one digest.
#
# Linux x86_64 only (ADR-0003): upstream publishes no Linux arm64 build of tlapm. The platform is fixed in the
# FROM lines, so a plain `docker build .` on an arm64 machine builds the x86_64 image, to run under emulation.

# tlapm is built against glibc 2.38, so the base has to be Ubuntu 24.04 or newer (Debian 12 is too old).
# The tag is kept beside the digest to say what the digest was resolved from (2026.11.15); Docker uses the digest.
ARG BASE_IMAGE=eclipse-temurin:25-jre-noble@sha256:5b5a79b85aeb03a859d4b5196482a08d39ec2714102aecae2c66223323bdf2e5

# The TLAPS tarball, from the kept copy. While this repository is private the copy cannot be fetched without a
# token, so CI downloads it and passes it as the build context `tlapm-tarball` instead; the fetch stage below
# checks its sha256 either way.
FROM scratch AS tlapm-tarball
ARG TLAPM_SHA256=99db29f119cb6f43ffed653b212ba2d005e5bf8e242c53468876cb0d08da6bcc
ARG TLAPM_URL=https://github.com/scottcochran/tla-kit/releases/download/tlapm-ff40755/tlapm-1.6.0-pre-x86_64-linux-gnu.tar.gz
ADD --checksum=sha256:${TLAPM_SHA256} ${TLAPM_URL} /tlapm.tar.gz

FROM --platform=linux/amd64 ${BASE_IMAGE} AS fetch
ARG TLA2TOOLS_VERSION=v1.7.4
ARG TLA2TOOLS_SHA256=936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88
ARG TLAPM_SHA256=99db29f119cb6f43ffed653b212ba2d005e5bf8e242c53468876cb0d08da6bcc
ARG TLAPM_BINARY_SHA256=6182df63c4513b09c31c8de12c37f8045ace9cab2517c017a2fa75f466685bb2
ADD --checksum=sha256:${TLA2TOOLS_SHA256} \
    https://github.com/tlaplus/tlaplus/releases/download/${TLA2TOOLS_VERSION}/tla2tools.jar \
    /fetch/tla2tools.jar
COPY --from=tlapm-tarball /tlapm.tar.gz /fetch/tlapm.tar.gz
# ADD from a URL makes the file readable by root only; the image runs as tla. Its time comes from the server's
# Last-Modified header, so it is set to a fixed one.
RUN echo "${TLAPM_SHA256}  /fetch/tlapm.tar.gz" | sha256sum -c - \
 && chmod 0644 /fetch/tla2tools.jar && touch -d 2000-01-01T00:00:00Z /fetch/tla2tools.jar \
 && mkdir /fetch/tlaps && tar -xzf /fetch/tlapm.tar.gz -C /fetch/tlaps --strip-components=1 \
 && echo "${TLAPM_BINARY_SHA256}  /fetch/tlaps/bin/tlapm" | sha256sum -c -

FROM --platform=linux/amd64 ${BASE_IMAGE}
ARG BASE_IMAGE
ARG TLA2TOOLS_VERSION=v1.7.4
ARG TLA2TOOLS_SHA256=936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88
ARG TLAPM_TAG=1.6.0-pre
ARG TLAPM_SHA256=99db29f119cb6f43ffed653b212ba2d005e5bf8e242c53468876cb0d08da6bcc
ARG TLAPM_BINARY_SHA256=6182df63c4513b09c31c8de12c37f8045ace9cab2517c017a2fa75f466685bb2
ARG SOURCE_DATE_EPOCH
ARG TLA_KIT_REVISION=
ARG TLA_KIT_CREATED=
# The state of Ubuntu's archive the packages are taken from, so a rebuild gets the same versions. The sources are
# pointed at snapshot.ubuntu.com for that moment and at nothing else, and the build fails if any other source is
# left (apt's own --snapshot also fetches the live archive's indices). Moving the date is a runtime refresh,
# together with the base (ADR-0013 item 2).
ARG APT_SNAPSHOT=20261115T000000Z
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
COPY --from=fetch /fetch/tlaps /opt/tlaps
COPY bin/ /usr/local/bin/
COPY vendor/writing-tla-specs-and-proofs/ /opt/tla-kit/skill/
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
      revision "${TLA_KIT_REVISION:-unknown}" created "${TLA_KIT_CREATED:-unknown}" \
      > /opt/tla-kit/build-args
# The image says where and from which commit it was built, and when that commit was made: not when it was built,
# and not under which version tag, which would make the digest depend on the tag (ADR-0014 item 8). The base's
# version label is Ubuntu's (24.04), so it is emptied rather than left to read as tla-kit's.
LABEL org.opencontainers.image.source="https://github.com/scottcochran/tla-kit" \
      org.opencontainers.image.revision="${TLA_KIT_REVISION}" \
      org.opencontainers.image.created="${TLA_KIT_CREATED}" \
      org.opencontainers.image.licenses="Apache-2.0 AND CC-BY-4.0" \
      org.opencontainers.image.title="tla-kit" \
      org.opencontainers.image.version="" \
      org.opencontainers.image.description="The TLA+ tool family in one image: TLC, SANY, PlusCal and TLAPS, held to digests"
# TLA_JAR and TLAPM are the variables the skill's scripts and the projects' run scripts already read (ADR-0004).
ENV TLA_JAR=/opt/tla/tla2tools.jar \
    TLAPM=/opt/tlaps/bin/tlapm \
    TLA_KIT_SKILL=/opt/tla-kit/skill \
    HOME=/home/tla \
    PATH=/opt/tlaps/bin:$PATH
USER tla
WORKDIR /work
CMD ["tla-kit-info"]
