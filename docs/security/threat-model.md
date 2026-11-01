# Threat model

What this file is: the threats this project guards against, the control for each, and the
automated test that fails if the control is removed (project rule 9). "The user" is the site's
owner; "Claude" is the AI coding agent the user builds the site with.

Scope so far: the development environment (decision 0003). The site itself (its pages, the
Content-Security-Policy, the contact form, deployment) is not built yet; its threats are added
as it is.

## Threats with a control

### T1. The container's root becomes the host's system root
- **Threat:** the container runs as root. Under rootless Docker that root is the user's own
  account on the host; under rootful Docker it would be the host's system root, writing
  root-owned files into the user's home folder and holding root over everything mounted.
- **Control:** `.devcontainer/check-host-before-start.sh` runs on the host before every start
  and refuses unless `docker info` reports rootless mode. It also refuses a missing data folder,
  which Docker would otherwise create empty and silently.
- **Test:** `.devcontainer/tests/check-host-before-start.test.sh` (stand-in `docker`; six cases:
  rootless allowed; rootful, no security options, `docker info` failing, data folder missing,
  no argument, each refused).
- **Record:** decision 0003.

### T2. Files created in the container are writable by every account on the host
- **Threat:** since Docker 29.6, rootless Docker runs with umask 0000, and every process started
  into a container inherits it (moby/moby#53985). Files that VS Code and Claude create, in the
  repository too, would be writable by any other account or process on the host, including the
  start guard of T1, which runs on the host.
- **Control:** the container is created with `--umask 0022` (`runArgs` in
  `.devcontainer/devcontainer.json`). Temporary: removed once the installed Docker includes the
  upstream fix (moby/moby#54026).
- **Test:** `.devcontainer/tests/container-umask.test.sh`, run inside the container (it refuses
  to run on the host, where it would prove nothing).
- **Record:** decision 0003.

## Accepted risks

### A1. The container can reach the user's other projects' Claude folders
The user's shared rules mount the whole `~/.claude` into the container, writable, so the
container can read and change other projects' sessions and memory and the user's prompt history.
Guarded by Claude Code's permission prompts, a hook that asks the user before any edit outside
this project, and the rule that Claude asks first. These guards belong to the user's shared
setup, not to this repository; the hook was checked here by hand (2026-11-01). Accepted by the
user; the reasons are in decision 0003.

### A2. An older signed Debian package index could be replayed during an image build
The Dockerfile installs packages from the Debian snapshot archive over plain http, with apt's
expiry check turned off (a snapshot's index is expired by design). Someone on the network path
could serve an older, still validly signed snapshot. They could not serve anything Debian did not
sign. Accepted; see decision 0003.

## Controls without a test yet
- **Hugo download checksum** (Dockerfile): the build fails if the download does not match the
  SHA-256 written in the Dockerfile. Nothing fails if that check is removed. Open.
