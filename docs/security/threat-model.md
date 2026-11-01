# Threat model

What this file is: the threats this project guards against, the control for each, and the
automated test that fails if the control is removed (project rule 9). "The user" is the site's
owner; "Claude" is the AI coding agent the user builds the site with.

Scope so far: the development environment (decision 0003) and the site's build settings
(decision 0005). The Content-Security-Policy, the contact form and deployment are not built yet;
their threats are added as they are.

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

### T3. Pages reveal the software version
- **Threat:** Hugo adds `<meta name="generator" content="Hugo 0.169.0">` to the home page. A
  visible version lets an attacker match the site to known vulnerabilities (security rule 5).
- **Control:** `disableHugoGeneratorInject = true` in `hugo.toml`.
- **Test:** `TestNoPageHasAGeneratorTag` in `tests/site/security_test.go`: no built page has a
  `generator` meta tag.
- **Record:** decision 0005.

### T4. Inline styles force a weaker Content-Security-Policy
- **Threat:** Hugo's code highlighting writes inline `style` attributes by default. A policy that
  allowed them would need `'unsafe-inline'`, which also lets injected styles through (security
  rule 1).
- **Control:** `markup.highlight.noClasses = false` in `hugo.toml`: highlighting by CSS classes.
- **Test:** `TestCodeHighlightingUsesClassesNotInlineStyles`: a page with a code block is
  built; no element has a `style` attribute, and the code is highlighted by classes.
- **Record:** decisions 0001 and 0005.

### T5. Markdown carries raw HTML or script into a page
- **Threat:** raw HTML in a Markdown file, including `<script>`, would be published as it is
  (security rule 3).
- **Control:** `markup.goldmark.renderer.unsafe = false` in `hugo.toml` (Hugo's default, written
  out so a change is a visible, reviewed edit). Hugo leaves the raw HTML out and warns, naming
  the file; the build treats warnings as failures (decision 0005), so such a page stops the
  build instead of being published without its HTML.
- **Test:** `TestRawHTMLInMarkdownStopsTheBuild`: a page with a `<script>` and a `<div>` stops
  the build, naming the file and Hugo's warning `warning-goldmark-raw-html`.
- **Record:** decision 0005.

### T6. The build pulls in another origin's content or runs other programs
- **Threat:** Hugo's defaults let templates fetch from any https address and run sass, go, git,
  node and postcss during a build; its built-in shortcodes embed YouTube, Vimeo, X and Instagram
  frames and scripts. Either would put another origin's content into the site (security rule 2).
- **Control:** `[security]` in `hugo.toml` allows no remote fetches and no commands; overrides in
  `layouts/_shortcodes/` (`youtube`, `vimeo`, `vimeo_simple`, `x`, `x_simple`, `instagram`)
  stop the build, naming the file.
- **Tests:** `TestRemoteFetchIsRefusedByPolicy` (a fetch from a `.test` address fails, naming
  `security.http.urls`; without the policy it fails from DNS, which the test rejects),
  `TestRunningProgramsIsRefusedByPolicy` (Hugo's git use fails, naming `security.exec.allow`),
  `TestEmbedShortcodesAreRefused` (each of the six fails, naming the file and the shortcode, and
  not stopped by the fetch policy instead).
- **Record:** decision 0005.

### T7. The go command runs a toolchain that was never checked
- **Threat:** by default, a `go.mod` that asks for a newer Go makes the `go` command download
  that toolchain and run it, bypassing the version and checksum pinned in the Dockerfile.
- **Control:** `GOTOOLCHAIN=local` in the Dockerfile: the `go` command refuses instead.
- **Test:** `.devcontainer/tests/container-go-toolchain.test.sh`, run inside the container: the
  setting is `local`, and a module asking for Go 1.99 is refused with nothing downloaded into a
  fresh module cache.
- **Record:** decisions 0003 and 0006.

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
- **Hugo and Go download checksums** (Dockerfile): the image build fails if a download does not
  match the SHA-256 written in the Dockerfile. Nothing fails if that check is removed. Open.
