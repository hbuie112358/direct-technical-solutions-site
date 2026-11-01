# 0004 Testing shell scripts: plain bash test scripts

Status: Accepted · Date: 2026-11-01 · Decided by: the user, on Claude's recommendation

## Context
The development container has two security controls (decision 0003; threat model T1 and T2): a
start guard script that refuses rootful Docker, and a umask option against a Docker bug. Project
rule 9 requires an automated test for each that fails if the control is removed. The project has
no test tooling yet; tools for the site's own test levels are chosen when the Hugo scaffold is
created.

## Options
| Option | For | Against |
|---|---|---|
| Plain bash test scripts | No dependency; readable without knowing a framework; bash is already in the container and on the host | Each script carries its own small helpers and its own count of results |
| bats-core | A standard format with readable output | A new dependency, needing its own record and pinning, for a handful of cases |
| Defer until the scaffold | Nothing to write now | Two security controls without a test, against rule 9 |

## Decision
Shell scripts are tested by plain bash scripts in a `tests/` folder next to the scripts they
test, named `<subject>.test.sh`. A test controls its own inputs (a stand-in command first on
`PATH` in place of a real one), checks exit codes and the values it set up, never message
wording, prints one line per case and a count (`6 run, 0 failed`), and exits non-zero on a
failure.

Current tests:
- `bash .devcontainer/tests/check-host-before-start.test.sh`: unit level, runs anywhere.
- `bash .devcontainer/tests/container-umask.test.sh`: scenario level, inside the running
  container.

## Why
The scripts under test are short, and a few dozen lines of bash test them fully without adding
anything to install, pin or keep up to date. Each test was checked against its control: with the
rootless check removed from the guard, two cases fail; with the data folder check removed, one
fails; under umask 0000, the umask test fails.

## Consequences
- If shell tests grow beyond a few files, a framework can replace this; that would be a new
  record replacing this one.
- CI, when it is set up, runs the unit-level test; the scenario test needs the running container.
- This record covers shell scripts only. The site's test tools are a separate decision.
