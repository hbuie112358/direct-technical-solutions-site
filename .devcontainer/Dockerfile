# The development container for this site (decision 0003). Every input is pinned, so a rebuild
# months from now produces the same tools: the base image by digest, the Debian packages by the
# snapshot the image was built from, and Hugo by version and checksum.

# debian:trixie-slim, multi-platform index digest as of 2026-11-01. Its default user is root,
# which the setup relies on (rootless Docker maps container root to the user's host account).
FROM debian:trixie-slim@sha256:f6b08b09a05725f9431502d3b5714f5c4576e82c1a84fa1debe0c24a7e0c3ec4

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# The image names its own snapshot in /etc/apt/sources.list.d/debian.sources. Pointing apt at it
# instead of the moving mirror fixes every package version. Plain http is safe here: apt checks
# each index against the signed Release file using the image's Debian keyring.
# Check-Valid-Until=false is needed because a snapshot's Release file is past its expiry date by
# design. It gives up apt's protection against replayed old indexes: someone on the network path
# could serve an older, still validly signed snapshot. Accepted: they could not serve anything
# Debian did not sign, and the installed versions are visible in the build output.
ARG DEBIAN_SNAPSHOT=20261027T000000Z

# git: version control. jq: the global edit-path hook. python3: the global time-report tool.
# curl and ca-certificates: the Hugo download below.
RUN sed -i \
        -e "s|^URIs: http://deb.debian.org/debian-security$|URIs: http://snapshot.debian.org/archive/debian-security/${DEBIAN_SNAPSHOT}|" \
        -e "s|^URIs: http://deb.debian.org/debian$|URIs: http://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT}|" \
        /etc/apt/sources.list.d/debian.sources \
    && grep -q "snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT}" /etc/apt/sources.list.d/debian.sources \
    && apt-get -o Acquire::Check-Valid-Until=false update \
    && apt-get install --yes --no-install-recommends ca-certificates curl git jq python3 \
    && rm -rf /var/lib/apt/lists/*

# Hugo, standard edition (no Sass needed: the site uses plain CSS). The checksum is written here,
# not read from the release at build time, so a changed download fails the build instead of
# being trusted. linux-amd64 only, the user's host architecture.
ARG HUGO_VERSION=0.169.0
ARG HUGO_SHA256=2d2f0bfe357d8cb4cec02f6bb28a3bff34978c8dda44b618029c5eb9d66765a7
RUN curl --fail --silent --show-error --location --output /tmp/hugo.tar.gz \
        "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_linux-amd64.tar.gz" \
    && echo "${HUGO_SHA256}  /tmp/hugo.tar.gz" | sha256sum --check --strict \
    && tar -xzf /tmp/hugo.tar.gz -C /usr/local/bin hugo \
    && rm /tmp/hugo.tar.gz \
    && hugo version
