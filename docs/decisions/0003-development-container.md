# 0003 Development environment: a devcontainer, with Hugo pinned inside it

Status: Accepted · Date: 2026-11-01 · Decided by: the user (a container, set up by the user's
shared devcontainer rules); the details below were chosen by Claude within that decision

## Context
Hugo (decision 0001) has to be installed somewhere, and Go and browser test tools will follow.
The user keeps projects separate: one project's tools must not change another's, and nothing a
project needs should depend on what else happens to be installed on the user's computer.

## Options
| Option | Separation | Cost |
|---|---|---|
| Hugo installed machine-wide (`~/.local/bin`) | None: every project shares one `hugo`; an update for one changes the others | Simplest |
| Hugo downloaded into the project folder by a script | Hugo only; Go and test tools would each need the same treatment | One script |
| A devcontainer holding every tool | Complete: the host needs only Docker | A container definition to maintain; Docker must run |

Claude recommended the devcontainer; the user chose it, and had the container conventions for all
of the user's projects written down first, in the user's shared rules
(`~/.claude/DEVCONTAINER_SETUP.md`, not part of this repository).

## Decision
A devcontainer (`.devcontainer/`), following those shared rules:
- **Rootless Docker only.** The container runs as its own root, which rootless Docker maps to the
  user's own account on the host, so files written in the container belong to the user. A check
  run on the host before every start (`check-host-before-start.sh`) refuses to start under
  rootful Docker, where the same container root would be the host's system root.
- **Its own paths:** the repository is mounted at its host path; the container keeps its own
  Claude Code login in its own volume; its data folder on the host is mounted at `/data` and
  holds no other project's data; `hugo server` uses port 4313.
- **Files created in the container are not writable by others** (added 2026-11-01, found by the
  post-build checks). Since Docker 29.6, rootless Docker runs with umask 0000 and every process
  started into a container (VS Code, Claude Code, their shells) inherits it, so each file they
  create was writable by every account on the host (measured on Docker 29.9.2: `docker exec`
  printed `0000`, a test file was `-rw-rw-rw-`). The container is now created with
  `--umask 0022`, Docker's own option, which the upstream issue reports also fixes `exec`
  processes in rootless mode. It is a workaround for an open Docker bug, to be removed once the
  installed Docker includes the fix.
- **Every input pinned:**
  - base image `debian:trixie-slim` by digest;
  - Debian packages (git, jq, python3, curl, ca-certificates) from the Debian snapshot archive at
    the date the image was built, `20261027T000000Z`;
  - Hugo 0.169.0 (released 2026-10-27), standard edition, linux-amd64, checked against a SHA-256
    written in the Dockerfile.

## Why
- One place defines every tool and its exact version, for the user's machine now and for CI
  later.
- The standard edition is enough: Hugo's installation page lists Sass as the only feature that
  needs the extended edition, and the site uses plain CSS (decision 0002).
- The checksum lives in the repository, not only in the release: a download that changes after
  today fails the build instead of being trusted. It was taken from the release's own checksum
  file, so it proves the download is the one published on 2026-10-27, not who published it.

## Consequences
- The host needs rootless Docker and VS Code's Dev Containers support; the site is built and
  served inside the container.
- Updating Hugo or the packages means changing a pinned value here and rebuilding: deliberate,
  reviewable, and recorded.
- The Debian snapshot archive is slower than the regular mirrors and occasionally unavailable;
  a failed rebuild then waits for it. Accepted, for exact versions.
- apt's expiry check is turned off for the snapshot, because a snapshot's index is expired by
  design. That gives up apt's protection against replayed old indexes: someone on the network
  path could serve an older, still validly signed snapshot over the plain http connection. They
  could not serve anything Debian did not sign. Accepted (threat model A2).
- The start guard and the umask option are security controls with automated tests (decision
  0004) and entries in the threat model (T1, T2).
- The image is built for linux-amd64 only, the user's host. Another architecture needs its own
  Hugo checksum.
- The VS Code extensions installed in the container are not pinned to a version.
- **Accepted trade-off: the container can reach the user's other projects' Claude folders.** The
  shared rules mount the user's whole `~/.claude`, writable, so the container can see every
  project's sessions and memory and the user's prompt history, not only this project's. What
  guards them is Claude Code's permission prompts for reads and most shell commands, a hook that
  asks the user before any edit outside this project, and the rule that Claude asks before
  changing anything outside the project. This container mounts no Docker socket, so a narrower
  mount would have been a real wall here: the whole folder read-only with only this project's
  folder writable would block writes; mounting each shared file and this project's folder one
  by one would also block reads. The user kept the whole-folder mount (2026-11-01), as decided
  for all projects on 2026-10-30: approved edits to shared files stay possible from the
  container, and a new shared rule file needs no config change. This project holds nothing that
  needs a harder wall. Found during the post-build checks; the trade-off is now written into the
  shared rules (rule 5).

## Sources
- Hugo v0.169.0 release: https://github.com/gohugoio/hugo/releases/tag/v0.169.0
- Hugo installation, editions: https://gohugo.io/installation/linux/
- Debian snapshot archive: https://snapshot.debian.org/
- Docker umask 0000 for `exec` processes since 29.6: https://github.com/moby/moby/issues/53985
- Upstream fix, open and not yet released on 2026-11-01: https://github.com/moby/moby/pull/54026
