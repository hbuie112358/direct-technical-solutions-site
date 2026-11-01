#!/usr/bin/env bash
# Scenario test, run inside the running container: files that processes started into the
# container create (VS Code, Claude Code, their shells) must not be writable by other accounts on
# the host (decision 0003; threat model T2).
#
# It fails if the `--umask 0022` run option in devcontainer.json is removed while the installed
# Docker still has moby/moby#53985 (exec processes inheriting umask 0000). A shell in the
# container is itself such an exec process, so the files it creates show the real behaviour.
#
# Usage, inside the container: bash .devcontainer/tests/container-umask.test.sh

set -euo pipefail

# Docker creates /.dockerenv in every container. On the host the test would only measure the
# host shell's umask and prove nothing, so it refuses to run there.
if [[ ! -f /.dockerenv ]]; then
    printf 'container-umask test: run it inside the container\n' >&2
    exit 2
fi

probe_folder="$(mktemp -d)"
readonly probe_folder
trap 'rm -rf "$probe_folder"' EXIT

# mktemp -d always creates 0700, whatever the umask, so the probes are created inside it with
# the plain defaults (0666 for a file, 0777 for a folder) that the umask then narrows.
touch "$probe_folder/probe-file"
mkdir "$probe_folder/probe-folder"

world_writable="$(find "$probe_folder" -mindepth 1 -perm -o+w)"
if [[ -n "$world_writable" ]]; then
    printf 'FAIL  new files are writable by others (umask %s):\n%s\n' "$(umask)" "$world_writable"
    printf '\n1 run, 1 failed\n'
    exit 1
fi
printf 'ok    new files and folders are not writable by others (umask %s)\n' "$(umask)"
printf '\n1 run, 0 failed\n'
