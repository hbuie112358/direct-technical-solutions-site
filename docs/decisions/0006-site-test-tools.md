# 0006 Testing the built site: Go tests

Status: Accepted · Date: 2026-11-01 · Decided by: the user, on Claude's recommendation

## Context
The scaffold (decision 0005) has security controls in its build settings (threat model T3 to
T6) and content validation that stops the build on an invalid project entry. Project rule 9 and
the global testing approach require automated tests that fail if a control is removed; the
scaffold is merged into `main` only once they exist. Shell scripts are tested with plain bash
(decision 0004); this decision covers tests of the built site.

What is tested: each test builds its own copy of the site, with small fixture pages, and checks
facts about the result or the failure: no generator tag, no inline styles from a code block, no
raw HTML from Markdown, a refused remote fetch, each embed shortcode refused, each invalid
project entry refused naming the file, a valid entry built, a wrong Hugo version refused.

## Options (state on 2026-11-01)
| | Go tests (`go test`) | Bash (extending 0004) | Python (`unittest`) |
|---|---|---|---|
| New dependency | The Go toolchain in the container (Go 1.27.3) | None | None: Python 3 is in the container for the user's shared tools |
| Reading HTML | A real HTML parser (`golang.org/x/net/html`, maintained by the Go team) | Text matching: fine for absence, fragile for structure | A real HTML parser (standard library) |
| Test runner | Built in: named tests, subtests, CI-friendly output | Hand-written | Built in |
| Fit | Go is already named for the site's tooling and the contact form handler (decision 0001); a Go browser-test library exists | A dead end once tests grow | A third language, outside the user's learning direction |

Claude recommended Go; the user chose it, over a bash gate now with Go later.

## Decision
The built site is tested with Go's own test tool. Go 1.27.3 is installed in the development
container, pinned by version and checksum, with `GOTOOLCHAIN=local` (decision 0003). The tests
live in their own Go module in the repository, and its `go.mod` and `go.sum` are committed
(security rule 7). Further libraries need their own record; `golang.org/x/net/html` is recorded
here when it is first used.

## Why
- One language for the project's own code: the tests now, site tooling and the contact form
  handler later, possibly browser tests.
- HTML is read by a parser, not by text matching, so a test checks the page's structure.
- Go's test tool needs nothing else: named tests, subtests, and output a CI can read.
- It serves the user's goal of learning Go.

## Consequences
- Adding Go to the container is a change to the development environment: reviewed, security
  reviewed and rebuilt before the tests are written.
- Go 1.27 has security support until Go 1.29 is released; patch releases are taken by changing
  the version and checksum in the Dockerfile.
- Link checking, accessibility checks and browser tests are separate decisions.

## Sources
- Go releases and their fixes (1.27.3: security fixes to `crypto/x509`, 2026-10-19):
  https://go.dev/doc/devel/release
- Go downloads and checksums: https://go.dev/dl/
- Go 1.27 release notes: https://go.dev/doc/go1.27
