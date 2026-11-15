# tla-kit: one image of the TLA+ tool family, the same locally and in CI.
# Spike stage: TLC/SANY/PlusCal (tla2tools.jar) and TLAPS (tlapm with Z3, Zenon, Isabelle/TLA+, LS4).
#
# Both downloads are held to a sha256. The TLAPS tag is a rolling pre-release that upstream rebuilds under the
# same name, so when TLAPM_SHA256 stops matching, the build fails on purpose: moving the pin is a decision.
# The built image, referenced by digest, is the durable artifact; upstream will not serve this tarball forever.
#
# Linux x86_64 only: upstream publishes no Linux arm64 build of tlapm.

# tlapm is built against glibc 2.38, so the base has to be Ubuntu 24.04 or newer (Debian 12 is too old).
ARG BASE_IMAGE=eclipse-temurin:25-jre-noble

FROM ${BASE_IMAGE} AS fetch
ARG TLA2TOOLS_VERSION=v1.7.4
ARG TLA2TOOLS_SHA256=936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88
ARG TLAPM_TAG=1.6.0-pre
ARG TLAPM_SHA256=99db29f119cb6f43ffed653b212ba2d005e5bf8e242c53468876cb0d08da6bcc
ADD --checksum=sha256:${TLA2TOOLS_SHA256} \
    https://github.com/tlaplus/tlaplus/releases/download/${TLA2TOOLS_VERSION}/tla2tools.jar \
    /fetch/tla2tools.jar
ADD --checksum=sha256:${TLAPM_SHA256} \
    https://github.com/tlaplus/tlapm/releases/download/${TLAPM_TAG}/tlapm-${TLAPM_TAG}-x86_64-linux-gnu.tar.gz \
    /fetch/tlapm.tar.gz
RUN mkdir /fetch/tlaps && tar -xzf /fetch/tlapm.tar.gz -C /fetch/tlaps --strip-components=1

FROM ${BASE_IMAGE}
# python3: the writing-tla-specs-and-proofs scripts (standard library only). perl: shasum, which project
# scripts call. git: project-root detection and CI planning scripts.
RUN apt-get update \
 && apt-get install -y --no-install-recommends python3 perl git \
 && rm -rf /var/lib/apt/lists/*
COPY --from=fetch /fetch/tla2tools.jar /opt/tla/tla2tools.jar
COPY --from=fetch /fetch/tlaps /opt/tlaps
COPY bin/ /usr/local/bin/
# TLA_JAR and TLAPM are the variables the skill's scripts and TOPAK's run scripts already read.
ENV TLA_JAR=/opt/tla/tla2tools.jar \
    TLAPM=/opt/tlaps/bin/tlapm \
    PATH=/opt/tlaps/bin:$PATH
WORKDIR /work
CMD ["tla-kit-info"]
