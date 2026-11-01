# 0007 The repository is public, on GitHub

Status: Accepted · Date: 2026-11-01 · Decided by: the user (public, account and name), on
Claude's recommendation for the name

## Context
The site is meant to be checkable evidence of how it was built: its decisions, rules, controls
and tests on public record. Until now the repository existed only on the user's computer. A
remote is also needed for pull requests (the branch rule), for continuous integration, and for
the Go test module's real path.

## Decisions
| Question | Options | Chosen |
|---|---|---|
| Visibility | Private until there is content; public from the start | Public from the start: the record is the point, work in progress included |
| Host | GitHub | GitHub, under the user's account `hbuie112358` |
| Name | `direct-technical-solutions` (Claude's first suggestion), `direct-technical-solutions-site`, `dts-website` | `direct-technical-solutions-site`: the business's name, clearly marked as its site |

Address: `https://github.com/hbuie112358/direct-technical-solutions-site`.

## Before the first push
- The whole history was searched on 2026-11-01 for secrets, keys, tokens, sensitive file names
  and personal data (local paths, host names, network addresses, personal email): none found,
  and the search is repeated over all commits just before the first push. Every commit uses the user's GitHub
  noreply address. The user kept `project-state.yaml` in the repository, with its history, and
  set a rule that committed files contain no personal data from now on (the project's
  `CLAUDE.md`, "No personal data in committed files").
- **The history was rewritten once, before the first push** (2026-11-01, the user's decision, to
  start the public record clean). Older versions of the project's `CLAUDE.md` contained a business
  detail, and older versions of `project-state.yaml` held session notes with
  local paths and details of the user's setup and habits. The rewrite removed the sentence from
  every version of `CLAUDE.md` and removed every earlier version of `project-state.yaml`; its
  history starts with the commit "remove business and personal details before publishing", which
  therefore shows the file as added. Commits that contained only the state file (the session
  pauses) dropped out. Every other file and commit message is unchanged; commit identifiers
  changed. The original history is kept privately, outside the repository.
- The user's credentials stay on the host: the repository is created on github.com and pushed
  from a host terminal, never from the development container.

## Is a public repository a security risk?
Not in itself: no control of this site depends on its code being secret, and the tests show
publicly that each control is in place. The real risks of a public repository, and what covers
each:
- secrets in the code or its history: none found before the first push; security rule 6;
- personal data: the project's rule against personal data in committed files;
- code that attackers can read, such as the future contact form handler: it must hold up when
  its logic is known (security rules 4 and 5);
- continuous integration triggered by strangers' pull requests: actions pinned, permissions
  minimal (security rule 8), and no workflow triggers that run untrusted code with the
  repository's permissions;
- contributions that change what runs on the user's computer: threat model A3.

On GitHub, right after the repository is created, the user turns on secret scanning with push
protection, Dependabot alerts, private vulnerability reporting, and protection for `main`
(changes only through pull requests, with continuous integration passing once it exists).
`SECURITY.md` tells visitors to report vulnerabilities privately.

## Consequences
- Everything committed is public, including its history; the personal-data rule and the review
  gates apply before every commit.
- The branch rule's merges become pull requests on GitHub.
- Continuous integration is a separate decision, with actions pinned to commit SHAs and minimal
  workflow permissions (security rule 8).
- A licence and a README are still to be decided; until there is a licence, the code is visible
  but all rights are reserved.
