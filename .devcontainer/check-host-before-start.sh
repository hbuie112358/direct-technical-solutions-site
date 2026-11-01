#!/usr/bin/env bash
# Runs on the host before every container start (devcontainer.json initializeCommand) and stops
# the start when the host is not set up as ~/.claude/DEVCONTAINER_SETUP.md requires.
#
# Rootless Docker is the reason the container may run as root: container root then maps to the
# user's own host account. Under rootful Docker the same container would write root-owned files
# into the user's home folder, so a start there must fail rather than quietly do damage.
#
# Usage: check-host-before-start.sh <data folder on the host>

set -uo pipefail

fail() {
    printf 'devcontainer host check: %s\n' "$1" >&2
    exit 1
}

data_folder="${1:-}"
[[ -n "$data_folder" ]] || fail "no data folder given (devcontainer.json passes it)"

security_options="$(docker info --format '{{json .SecurityOptions}}' 2>/dev/null)" \
    || fail "'docker info' failed: is Docker running, and is it the Docker a host terminal reaches?"

[[ "$security_options" == *'"name=rootless"'* ]] \
    || fail "Docker is not rootless (security options: ${security_options}); see ~/.claude/DEVCONTAINER_SETUP.md"

# Docker would create a missing bind-mount source itself, empty and silently; refusing here
# makes a wrong path visible instead.
[[ -d "$data_folder" ]] \
    || fail "the data folder ${data_folder} does not exist; create it on the host first"
