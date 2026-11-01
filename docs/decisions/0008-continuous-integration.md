# 0008 Continuous integration: GitHub Actions, inside the development container's image

Status: Accepted · Date: 2026-11-01 · Decided by: the user (approach, Dependabot), on Claude's
recommendation (also for the runner)

## Context
The repository is public on GitHub (decision 0007), and `main` changes only through pull
requests (a GitHub ruleset). Until now the checks ran only when someone ran them. Continuous
integration runs them on every pull request and every change to `main`, so a change that breaks
the build, a test or a security control is seen before it is merged.

## Options
| | A. Build the development container's image in CI, run every check inside it | B. Install Hugo and Go directly on the runner |
|---|---|---|
| Versions | One source: the Dockerfile's pins (image digest, Debian snapshot, Hugo and Go by version and checksum) | Written again in the workflow, where they can drift from the container's |
| Third-party actions | `actions/checkout` only | Also a Go set-up action and a Hugo installer, each to pin and trust |
| Speed | Slower: the image is built on each run (the Debian snapshot archive is slow) | Faster |
| Fidelity | CI runs exactly what runs on the user's computer | Close, not identical |

Claude recommended A; the user chose it. For the runner, Claude recommended `ubuntu-24.04` over
the newer `ubuntu-26.04`: with A the runner only provides Docker, and the longer-established
image is the safer base. Dependabot version updates were recommended and chosen.

## Decision
- **Workflow** `.github/workflows/ci.yml`: on every pull request and every push to `main`, on
  `ubuntu-24.04`, check out the repository, build the image from `.devcontainer/Dockerfile`, and
  run `.github/ci/run-checks.sh` inside it. The script holds every check, so the same checks run
  by hand in the container: the site build with warnings as failures; `gofmt`, `go vet`,
  `go mod tidy -diff` and `go mod verify`; the Go site tests; the start-guard, Go-toolchain and
  workflow tests.
- **Left out:** the umask test (`container-umask.test.sh`). CI's Docker is not rootless and does
  not start the checks with `docker exec`, so the test would pass without showing anything about
  the problem it guards against; it stays a check in the development container.
- **Security (security rule 8; threat model T8):** the action is pinned to a full commit SHA
  (`actions/checkout` v7.0.1, `3d3c42e5aac5ba805825da76410c181273ba90b1`, checked on GitHub on
  2026-11-01); the workflow token can only read (`contents: read`); the checkout keeps no
  credentials; no `pull_request_target`; a timeout; a newer commit cancels an older run.
  `tests/ci/workflows.test.sh` fails if any of these is removed; it was checked against eight
  ways of breaking the rules, and each one fails it.
- **Dependabot** (`.github/dependabot.yml`): weekly version updates for the actions, the Go test
  module and the base image's digest, as pull requests that go through CI and review. The Hugo
  and Go versions and the Debian snapshot date in the Dockerfile's `ARG` lines are not covered
  and stay manual.
- **On GitHub (repository settings, set by the user on 2026-11-01):** only actions created by
  GitHub are allowed, and must be pinned to a full commit SHA; workflows from external
  contributors' pull requests need the user's approval to run; the default workflow token is
  read-only and cannot create or approve pull requests. After the first successful run, the
  `main` ruleset requires this workflow's check to pass.

## Consequences
- A pull request cannot be merged with a failing check, once the ruleset requires it.
- Each run builds the image from scratch; if that becomes too slow, caching is a later decision.
- The workflow cannot be run on this computer before it reaches GitHub; its first run is on its
  own pull request, and the check script it runs is already tested in the container.

## Sources
- actions/checkout releases: https://github.com/actions/checkout/releases
- GitHub Actions settings for a repository: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository
- GitHub-hosted runner images: https://github.com/actions/runner-images
