#!/usr/bin/env bash
# Scenario test, run inside the running container: the go command keeps the pinned Go and never
# downloads another toolchain by itself (GOTOOLCHAIN=local in the Dockerfile; decisions 0003 and
# 0006; threat model, controls without a test).
#
# By default (GOTOOLCHAIN=auto), a go.mod that asks for a newer Go makes the go command download
# that toolchain and run it, outside the checksum in the Dockerfile. With the control in place it
# refuses instead. The test tells the two apart by a fact, not a message: an attempted download
# leaves golang.org/toolchain in the module cache, which here is a fresh, empty one.
#
# Usage, inside the container: bash .devcontainer/tests/container-go-toolchain.test.sh

set -euo pipefail

# Docker creates /.dockerenv in every container; the control lives in the container's image.
if [[ ! -f /.dockerenv ]]; then
    printf 'container-go-toolchain test: run it inside the container\n' >&2
    exit 2
fi

work_folder="$(mktemp -d)"
readonly work_folder
trap 'rm -rf "$work_folder"' EXIT
cases_run=0
cases_failed=0

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

check_setting() {
    local setting
    setting="$(go env GOTOOLCHAIN)"
    [[ "$setting" == local ]] || { report "GOTOOLCHAIN is local" "it is '$setting'"; return; }
    report "GOTOOLCHAIN is local" ""
}

# A module asking for a Go that does not exist yet: the go command must refuse without trying to
# fetch it. The module cache and GOPATH are fresh folders, so anything in them came from this run.
check_newer_go_is_refused_without_download() {
    local case_name="a module asking for Go 1.99 is refused, nothing downloaded"
    local module_folder="$work_folder/module" exit_code=0
    mkdir -p "$module_folder"
    printf 'module toolchainprobe\n\ngo 1.99\n' >"$module_folder/go.mod"
    printf 'package toolchainprobe\n' >"$module_folder/probe.go"
    (cd "$module_folder" && GOMODCACHE="$work_folder/modcache" GOPATH="$work_folder/gopath" \
        go list . >/dev/null 2>&1) || exit_code=$?
    [[ $exit_code -ne 0 ]] || { report "$case_name" "the go command accepted it"; return; }
    if [[ -e "$work_folder/modcache/cache/download/golang.org/toolchain" ]]; then
        report "$case_name" "the go command tried to download a toolchain"
        return
    fi
    report "$case_name" ""
}

main() {
    check_setting
    check_newer_go_is_refused_without_download
    printf '\n%d run, %d failed\n' "$cases_run" "$cases_failed"
    [[ $cases_failed -eq 0 ]]
}

main
