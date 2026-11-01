# 0005 Site scaffold: layout, Hugo settings and the logo

Status: Accepted · Date: 2026-11-01 · Decided by: the user (layout, warnings as failures, the
logo's place), on Claude's recommendation; the details below were chosen by Claude within that

## Context
Hugo is chosen (decision 0001), styling is plain CSS with tokens (decision 0002), and Hugo
0.169.0 runs in the development container (decision 0003). The site needs its skeleton: where
content, templates and styles live, and the settings that the project's rules depend on.

Before proposing, Claude checked the Hugo details against the installed 0.169.0 on a throwaway
site, because three were unverified in decision 0001: the built-in SEO templates are
`opengraph.html`, `twitter_cards.html` and `schema.html`, and `schema.html` writes meta tags,
not a script block; Hugo's `module.hugoVersion` setting only warns on a wrong version; code
highlighting defaults to inline styles (`noClasses = true`). It also found that Hugo adds a
`generator` meta tag naming its version to the home page.

## Decisions
| Question | Options | Chosen |
|---|---|---|
| Layout | Hugo's current layout system (`layouts/baseof.html`, `home.html`, `page.html`, `section.html`, `_partials/`); a theme in `themes/` | Current layout system, no theme: every template is the site's own and explainable (R7) |
| Wrong Hugo version | `module.hugoVersion` (warns only); the same with `--panicOnWarning` (stops, with a Go crash trace); a template check with `errorf` | Template check: stops with a message naming both versions |
| Hugo's warnings | Shown and ignored; failures (`--panicOnWarning`) | Failures, locally and in CI: a missing template or a deprecated setting is fixed, not lived with |
| The logo's original | In the repository, sized by Hugo at build; in `/data`, with an optimised copy in the repository | In the repository (`assets/images/`): one source; it costs 1.7 MB in the history once |

## The settings and why
- **Version check:** `layouts/_partials/check-hugo-version.html` compares `hugo.Version` with
  `params.requiredHugoVersion` and stops the build on a mismatch; it runs once per build.
- **Content validation (R4):** `layouts/_partials/validate-project.html` checks every published
  project for the required fields (`title`, `description`, `status`) and an allowed status, and
  stops the build naming the file. Both lists are in `hugo.toml`. The archetype
  (`archetypes/projects.md`) gives every new entry the fields, with `draft: true`.
- **Security settings, each written out with its reason in `hugo.toml`:** code highlighting by
  CSS classes (`noClasses = false`), raw HTML in Markdown off (`renderer.unsafe = false`, Hugo's
  default, made visible), and the generator tag off (`disableHugoGeneratorInject`), so no page
  shows Hugo's version (security rule 5).
- **Nothing from other origins at build time (security rule 2):** Hugo's defaults allow
  templates to fetch any https address and to run sass, go, git, node and postcss. `[security]`
  in `hugo.toml` allows neither; checked on 0.169.0: a fetch is refused with "access denied", and
  `enableGitInfo` fails instead of running git. Hugo's six embed shortcodes in 0.169.0
  (`youtube`, `vimeo`, `vimeo_simple`, `x`, `x_simple`, `instagram`) are overridden in
  `layouts/_shortcodes/` to stop the build, naming the file. Hugo's own switch
  (`privacy.<service>.disable`) was tried and rejected: it drops the embed silently, so a page
  would lose content without anyone noticing. An embed that is wanted needs a decision first.
- **One stylesheet,** concatenated from the token file and three component files in a fixed
  cascade-layer order, minified and fingerprinted, with an `integrity` attribute.
- **Address:** `baseURL` is `https://example.invalid/` until the domain is chosen; `.invalid` is
  reserved and can never be a real site.
- **Tags and categories** are switched off until wanted; without templates for them Hugo warns,
  and warnings fail the build.
- **Pages not written yet** (the build story, contact) are drafts: they are not built and do not
  appear in the menu.

## The logo
The logo was generated with AI: the original's embedded content credentials (a signed C2PA
manifest) name OpenAI's image model (`gpt-image`), the source type "trainedAlgorithmicMedia",
and the date 2026-08-13. The manifest stays in the original in the repository; the published
WebP copy does not carry it, so the site states the logo's origin on its "How this site was
built" page.

The original (1752 × 898 PNG) is cropped at build time to remove its empty margin and resized to
twice its display height, as WebP. Hugo's image colour analysis gave the logo's two dominant
colours: the background `#f5f4f3` and the navy `#103451`. The page background uses the
logo's own background colour, so the logo shows without a box around it, and the navy is the
link colour. The other colours were chosen around them, and every text colour was measured
against WCAG 2.2 AA (contrast ratios noted in `assets/css/tokens.css`). This is a starting
point for the visual design, not the design itself.

## Checked by hand
- The build passes with `--panicOnWarning` and no warnings.
- The output has no generator tag, inline styles, inline scripts or event handlers.
- A wrong required version, a project without a description and a project with an unknown
  status each stop the build (exit 1), naming the version, or the file and the field or value; a
  valid project builds and shows its status.

These are not automated yet: the site's test tools are the next decision, and the scaffold is
merged into `main` only once the security controls (threat model T3 to T6) have their tests.

## Consequences
- Adding a project: `hugo new content projects/<name>.md`, fill in the fields, set
  `draft: false`.
- Upgrading Hugo: change `HUGO_VERSION` and its checksum in the Dockerfile and
  `requiredHugoVersion` in `hugo.toml` together; the build refuses a mismatch.
- The home and projects pages have no description and no share image yet; both come with the
  site's content, whose wording is the user's.
- `locale = 'en'` names no regional variant yet; the site's spelling (British or American) is
  still to be decided with its content.
- The visual design (type, colour beyond the logo's two, dark mode, fonts) is a later step;
  fonts, when chosen, are self-hosted (security rule 2).
