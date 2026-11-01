# Direct Technical Solutions

What this file is: what is true of this project alone, loaded only in this repository; the
shared rules are in `~/.claude/CLAUDE.md`; "the user" is the person Claude works with.

## About
The website of Direct Technical Solutions, the user's business: it presents the business and
the user's software projects, and takes enquiries. The site is itself a showcase: built by the
user in partnership with Claude, with its decisions, rules and controls on public record in
this repository.

## Where things are
- `docs/decisions/`: the decision log, one file per decision, indexed in its `README.md`. The
  site's requirements (R1–R9) are stated in decision 0001.
- `docs/security/threat-model.md`: the threat model (not written yet).
- `project-state.yaml`: the session state, written at each pause and read at resume.
- Hosting: not decided; chosen by fit when deployment is planned, after the site is built
  locally. The site goes on a new domain (not chosen yet).

## Commands
Not set up yet; added with the project scaffold.

## Testing
Not set up yet. The tools for each level of the global `TESTING_APPROACH.md` are chosen in a
decision record when the scaffold is created.

## Framework
Hugo, as a static site generator (decision 0001); plain CSS with design tokens (decision
0002).
- The site is static. The contact form is a separate, minimal handler, decided with the host.
- No JavaScript toolchain in the site's build unless a decision adds one; scripts that are
  needed are plain JavaScript, bundled by Hugo's built-in esbuild. TypeScript would need a
  decision: esbuild strips its types without checking them.
- The Hugo version is pinned exactly, locally and in CI.
- Content (projects; later blog posts and testimonials) is Markdown in `content/`. Templates
  check required fields and allowed values and stop the build with `errorf`, naming the file,
  on an invalid entry.
- Project status is one of: `live`, `completed`, `in-development`, `prototype`, `paused`,
  `retired`. Unpublished work uses `draft: true`.
- Code highlighting uses CSS classes (`markup.highlight.noClasses = false`), never inline
  styles.
- Every design value (colour, spacing, type scale, radius, shadow, motion duration) is a token
  defined in one file; component styles use tokens, never raw values.
- Motion is subtle and respects `prefers-reduced-motion`.
- Accessibility target: WCAG 2.2 level AA.

## Project rules

### Honesty, throughout
The site's claims and the repository's records are true and checkable. *Why:* the site exists
to be trusted evidence of the user's work; one inflated claim discredits the rest.
- Every claim on the site is backed by evidence in this repository or a cited source; what
  cannot be shown is not claimed.
- No invented testimonials, clients, figures, skills or results. Testimonials are real,
  published with the person's consent and attributed as that person agreed.
- Project status is stated as it is (in progress, prototype, paused, abandoned).
- AI involvement is disclosed plainly: what Claude did, what the user decided and reviewed.
  A blog post Claude helped write says so.
- Scores and measurements shown on the site carry their date or link to a live check.
- The decision log records the real reasoning, including reversals and accepted trade-offs; a
  replaced decision is marked, never rewritten. Corrections to published posts are marked as
  corrections.
- Claude labels what it has not verified as unverified, and verifies a fact, with a source,
  before it goes onto the site or into the decision log.

### Security rules for Claude
The site is secure, and visibly so: each control is in the code, explained, and tested. *Why:*
the code is public; it is the evidence that the user directed an AI agent to a security
standard.
1. No inline scripts or inline event handlers, and nothing that needs `'unsafe-inline'` or
   `'unsafe-eval'` in the Content-Security-Policy.
2. No scripts, styles, fonts or other resources from other origins unless a decision allows
   it; fonts are self-hosted.
3. Hugo's escape bypasses (`safeHTML`, `safeHTMLAttr`, `safeCSS`, `safeJS`, `safeURL`) are
   never used with content that did not come from this repository, and each use carries a
   comment saying why it is safe. Markdown's raw HTML stays disabled (Goldmark
   `renderer.unsafe = false`, Hugo's default).
4. Every input from outside (form fields, query parameters, headers) is validated on the server
   against a schema; invalid input gets a generic rejection.
5. Responses to visitors never reveal internals (stack traces, file paths, versions).
6. No secrets in the repository, its history or the built output; secrets come from the
   environment; `.env` files are ignored by git.
7. A new dependency needs a decision record: what it does, the alternatives (including none),
   its maintenance and its security record. Every tool version is pinned exactly; any lockfile
   (Go modules, npm) is committed and installs follow it.
8. CI actions are pinned to a full commit SHA; workflow tokens get the least permissions they
   need.
9. Every security control has an automated test that fails if the control is removed, and an
   entry in the threat model.
10. A change to a security control, the contact endpoint, dependencies, CI or deployment gets
    a security review (`/security-review`) in addition to the code review.

### Code review in this project
- Go code (site tooling, the contact form handler) and JavaScript: Approach A, each in its
  language's own idioms (no Go or JavaScript standards file yet).
- Templates and styles (`layouts/**/*.html`, `.css`): Approach A for structure, naming and
  comments, plus a check against the Framework rules above (tokens, accessibility, escaping,
  no inline styles).
- Configuration, CI and deployment files (`hugo.toml`, workflows, server configuration):
  Approach B.

*Why:* the global methodology names application code and configuration; web files are partly
both.

### Decisions are recorded
Every choice of tool, dependency, architecture or security control gets a record in
`docs/decisions/` before or with the commit that applies it: the options weighed, Claude's
recommendation, and the user's decision. *Why:* the log is the evidence behind the site's
"How this site was built" page.
