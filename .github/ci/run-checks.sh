#!/usr/bin/env bash
# Every check continuous integration runs (decision 0008), in one place, so that the same checks
# can be run by hand inside the development container: bash .github/ci/run-checks.sh
#
# CI runs this inside the image built from .devcontainer/Dockerfile, so the checks use exactly
# the pinned Hugo and Go of the development container. Build output and caches go to temporary
# folders, never into the repository.
#
# Left out on purpose: .devcontainer/tests/container-umask.test.sh. CI's Docker is not rootless
# and does not start the checks with `docker exec`, so that test would pass without proving
# anything about the problem it guards against (decision 0008).

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly repository_root
cd "$repository_root"

section() {
    printf '\n== %s\n' "$1"
}

check_site_build() {
    section "Site build (warnings fail the build)"
    hugo --panicOnWarning --gc --minify --destination "$(mktemp -d)" --cacheDir "$(mktemp -d)"
}

check_go_module() {
    section "Go: formatting, vet, tidy module, verified dependencies"
    local unformatted
    unformatted="$(gofmt -l tests/site)"
    if [[ -n "$unformatted" ]]; then
        printf 'not formatted with gofmt:\n%s\n' "$unformatted" >&2
        return 1
    fi
    (cd tests/site && go vet ./... && go mod tidy -diff && go mod verify)
}

check_site_tests() {
    section "Go site tests"
    (cd tests/site && go test -shuffle=on -count=1 ./...)
}

check_shell_tests() {
    section "Shell tests"
    bash .devcontainer/tests/check-host-before-start.test.sh
    bash .devcontainer/tests/container-go-toolchain.test.sh
    bash tests/ci/workflows.test.sh
}

main() {
    check_site_build
    check_go_module
    check_site_tests
    check_shell_tests
    section "All checks passed"
}

main
