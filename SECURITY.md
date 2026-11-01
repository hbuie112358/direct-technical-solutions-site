# Security policy

This repository holds the website of Direct Technical Solutions: a static site built with Hugo,
its build settings, its tests and its development container. Its security controls, and the
threats they answer, are described in [docs/security/threat-model.md](docs/security/threat-model.md).

## Reporting a vulnerability

Please report a suspected vulnerability privately, through GitHub: open the repository's
**Security** tab and choose **Report a vulnerability**. Please do not open a public issue or pull
request for it, so that it can be fixed before it is known.

A useful report says what is affected, how to reproduce it, and what an attacker could do with
it. The site is maintained by one person; reports are read and answered as soon as possible, and
a confirmed problem is fixed and recorded in the repository.

## Scope

In scope: everything in this repository, and the website built from it once it is published.
That includes the build configuration, the templates, the development container and the
continuous integration workflows.

Only the current `main` branch and the currently published site are maintained; older commits
are not patched.
