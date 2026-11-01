#!/usr/bin/env bash
# Tests for check-host-before-start.sh, the guard that refuses to start the container unless
# Docker is rootless and the data folder exists (decision 0003; threat model T1).
#
# The guard asks `docker info`, so a stand-in `docker` is put first on PATH. It prints the
# security options of the Docker it imitates, or fails when no output is prepared. No real Docker
# is needed, so this runs anywhere: on the host or in the container.
#
# A refusal is checked by its exit code and by the message naming the offending value, never by
# the message's wording (TESTING_APPROACH.md).
#
# Usage: bash .devcontainer/tests/check-host-before-start.test.sh

set -euo pipefail

GUARD="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/check-host-before-start.sh"
readonly GUARD
# Modelled on `docker info --format '{{json .SecurityOptions}}'`: a rootless Docker lists
# name=rootless, a rootful one does not.
readonly ROOTLESS_OPTIONS='["name=seccomp,profile=builtin","name=rootless","name=cgroupns"]'
readonly ROOTFUL_OPTIONS='["name=apparmor","name=seccomp,profile=builtin","name=cgroupns"]'

work_folder="$(mktemp -d)"
readonly work_folder
trap 'rm -rf "$work_folder"' EXIT
readonly STAND_IN_FOLDER="$work_folder/bin"
readonly EXISTING_DATA_FOLDER="$work_folder/data"
readonly MISSING_DATA_FOLDER="$work_folder/no-such-folder"
cases_run=0
cases_failed=0

install_stand_in_docker() {
    mkdir -p "$STAND_IN_FOLDER" "$EXISTING_DATA_FOLDER"
    cat >"$STAND_IN_FOLDER/docker" <<'STAND_IN'
#!/usr/bin/env bash
# Stand-in for `docker info`: prints the prepared output, or fails like an unreachable Docker.
[[ -f "$(dirname "$0")/info-output" ]] || exit 1
cat "$(dirname "$0")/info-output"
STAND_IN
    chmod +x "$STAND_IN_FOLDER/docker"
}

# Prepares what the stand-in prints; an empty argument means `docker info` fails.
imitate_docker() {
    rm -f "$STAND_IN_FOLDER/info-output"
    [[ -z "$1" ]] || printf '%s\n' "$1" >"$STAND_IN_FOLDER/info-output"
}

run_guard() {
    PATH="$STAND_IN_FOLDER:$PATH" bash "$GUARD" "$@" 2>"$work_folder/stderr" >/dev/null
}

report() {
    local case_name="$1" failure_reason="$2"
    cases_run=$((cases_run + 1))
    if [[ -z "$failure_reason" ]]; then
        printf 'ok    %s\n' "$case_name"
        return
    fi
    cases_failed=$((cases_failed + 1))
    printf 'FAIL  %s: %s\n' "$case_name" "$failure_reason"
}

expect_start_allowed() {
    local case_name="$1" exit_code=0
    shift
    run_guard "$@" || exit_code=$?
    [[ $exit_code -eq 0 ]] || { report "$case_name" "expected exit 0, got $exit_code"; return; }
    report "$case_name" ""
}

# The offending value may be empty when the refusal has none to name (no argument given).
expect_start_refused() {
    local case_name="$1" offending_value="$2" exit_code=0
    shift 2
    run_guard "$@" || exit_code=$?
    [[ $exit_code -eq 1 ]] || { report "$case_name" "expected exit 1, got $exit_code"; return; }
    if [[ -n "$offending_value" ]] && ! grep -qF -- "$offending_value" "$work_folder/stderr"; then
        report "$case_name" "the message does not name '$offending_value'"
        return
    fi
    report "$case_name" ""
}

main() {
    install_stand_in_docker

    imitate_docker "$ROOTLESS_OPTIONS"
    expect_start_allowed "rootless Docker and an existing data folder: start allowed" "$EXISTING_DATA_FOLDER"
    expect_start_refused "rootless Docker, data folder missing: refused" "$MISSING_DATA_FOLDER" "$MISSING_DATA_FOLDER"
    expect_start_refused "no data folder argument: refused" ""

    imitate_docker "$ROOTFUL_OPTIONS"
    expect_start_refused "rootful Docker: refused" "name=apparmor" "$EXISTING_DATA_FOLDER"

    imitate_docker "[]"
    expect_start_refused "Docker reporting no security options: refused" "[]" "$EXISTING_DATA_FOLDER"

    imitate_docker ""
    expect_start_refused "docker info failing: refused" "" "$EXISTING_DATA_FOLDER"

    printf '\n%d run, %d failed\n' "$cases_run" "$cases_failed"
    [[ $cases_failed -eq 0 ]]
}

main
