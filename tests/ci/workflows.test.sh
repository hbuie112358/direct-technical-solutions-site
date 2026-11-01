#!/usr/bin/env bash
# Tests that every GitHub Actions workflow keeps the rules of security rule 8 (decision 0008;
# threat model T8):
#   - every action is pinned to a full 40-character commit SHA, never to a tag or branch, which
#     its owner could move to different code;
#   - no workflow is triggered by pull_request_target, which runs a pull request's code with this
#     repository's permissions and secrets;
#   - every workflow declares its permissions at the top, and none grants write access;
#   - every checkout keeps no credentials (persist-credentials: false).
#
# The workflows are configuration, so the test reads them as text; it checks the values the
# rules are about, one line or key at a time. Runs anywhere.
#
# Usage: bash tests/ci/workflows.test.sh

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly WORKFLOW_FOLDER="$repository_root/.github/workflows"
# A step's `uses:` value: either a local action (./path), or owner/repo[/path]@<40 hex digits>.
readonly PINNED_ACTION='^[[:space:]-]*uses:[[:space:]]*("|'"'"')?([.]/|[^@[:space:]]+@[0-9a-f]{40}([[:space:]"'"'"']|$))'
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

# The workflow without its comment lines: a comment that mentions a rule (for example a warning
# against pull_request_target) is not a breach of it.
without_comments() {
    grep -v -E '^[[:space:]]*#' "$1" || true
}

check_actions_are_pinned() {
    local workflow="$1" unpinned
    unpinned="$(without_comments "$workflow" | grep -E '^[[:space:]-]*uses:' | grep -v -E "${PINNED_ACTION#^}" || true)"
    [[ -z "$unpinned" ]] || { report "$(basename "$workflow"): actions pinned to a commit SHA" "not pinned: $unpinned"; return; }
    report "$(basename "$workflow"): actions pinned to a commit SHA" ""
}

check_no_pull_request_target() {
    local workflow="$1" found
    found="$(without_comments "$workflow" | grep 'pull_request_target' || true)"
    [[ -z "$found" ]] || { report "$(basename "$workflow"): no pull_request_target" "found: $found"; return; }
    report "$(basename "$workflow"): no pull_request_target" ""
}

check_permissions_read_only() {
    local workflow="$1" case_name granted
    case_name="$(basename "$workflow"): permissions declared, none write"
    without_comments "$workflow" | grep -q -E '^permissions:' || { report "$case_name" "no top-level permissions"; return; }
    granted="$(without_comments "$workflow" | grep -E ':[[:space:]]*write([[:space:]]|$)|write-all' || true)"
    [[ -z "$granted" ]] || { report "$case_name" "write access granted: $granted"; return; }
    report "$case_name" ""
}

check_checkout_keeps_no_credentials() {
    local workflow="$1" case_name checkouts kept
    case_name="$(basename "$workflow"): checkouts keep no credentials"
    checkouts="$(without_comments "$workflow" | grep -c -E 'uses:[[:space:]]*actions/checkout@' || true)"
    kept="$(without_comments "$workflow" | grep -c -E 'persist-credentials:[[:space:]]*false' || true)"
    [[ "$kept" -ge "$checkouts" ]] || { report "$case_name" "$checkouts checkout(s), $kept with persist-credentials: false"; return; }
    report "$case_name" ""
}

main() {
    local workflows=("$WORKFLOW_FOLDER"/*.yml "$WORKFLOW_FOLDER"/*.yaml)
    local workflow found=0
    for workflow in "${workflows[@]}"; do
        [[ -f "$workflow" ]] || continue
        found=$((found + 1))
        check_actions_are_pinned "$workflow"
        check_no_pull_request_target "$workflow"
        check_permissions_read_only "$workflow"
        check_checkout_keeps_no_credentials "$workflow"
    done
    [[ $found -gt 0 ]] || report "workflows exist" "no workflow files in $WORKFLOW_FOLDER"
    printf '\n%d run, %d failed\n' "$cases_run" "$cases_failed"
    [[ $cases_failed -eq 0 ]]
}

main
