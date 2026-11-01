# 0001 Site framework: Hugo

Status: Accepted · Date: 2026-10-31 · Decided by: the user, after a survey prepared by Claude

## Context
The website of Direct Technical Solutions: a business site with a home page, the user's
projects, an account of how the site was built, and a contact form; later possibly a blog and
testimonials. The host is not decided; it is chosen by fit at deployment. The code is public
and the site is itself a showcase, so the user asked for the stack to be chosen by actual best
fit. Learning is one of the user's goals: an unfamiliar tool is not a cost in itself.

## History of this decision
- 2026-10-30: Claude recommended Astro from a comparison of six options drawn from its own
  knowledge; it was recorded as accepted.
- 2026-10-31: the user reopened it, judging that the recommendation had been taken without
  seeing the field. Claude surveyed fourteen options with current sources, then compared the
  three content-site tools (Astro, Hugo, Eleventy) on paper with code. The user chose Hugo.
- The survey corrected three things the first comparison had wrong or missed: Astro was on
  version 7, not 6; Cloudflare had acquired the company behind Astro; Astro had about ten
  security advisories in 2026, not two.

## Requirements
| #  | Requirement                                                           | Weight |
|----|-----------------------------------------------------------------------|--------|
| R1 | Mostly content: business pages, projects, the build story             | High   |
| R2 | Fast, accessible and good on phones                                   | High   |
| R3 | One maintainer: little upkeep, low running cost                       | High   |
| R4 | Adding a project is easy and hard to get wrong (validated entries)    | High   |
| R5 | Room to grow: contact form, interactive project demos, blog           | Medium |
| R6 | Testable and checkable in CI                                          | High   |
| R7 | The user understands the code and can explain it                      | Medium |
| R8 | Secure, with each control visible in the code, explained, and tested  | High   |
| R9 | SEO-ready output with little configuration effort                     | High   |

Honesty applies over all of them. Portability (how much is locked into the tool) was weighed
as well.

## Survey (state as of 2026-10-31)
| Option | State | Outcome |
|---|---|---|
| Astro | 7.3.x (7.0 in June 2026); team acquired by Cloudflare in January 2026, still MIT and multi-host; about ten 2026 advisories, mostly in server features | Finalist |
| Hugo | 0.164; one Go binary; security fixes in 2026 releases (0.159.2, 0.161.0) | Finalist, chosen |
| Eleventy (renamed Build Awesome, March 2026) | 3.1.7 stable, 4.0 in alpha; now stewarded by Font Awesome | Finalist |
| Jekyll | 4.4.1, January 2025; no release since | Out: inactive |
| Gatsby | Maintenance mode; last release February 2026 | Out: declining |
| Next.js | 16.4.x; 2026 advisories in May (13), September (critical), October (remote code execution) | Out: application framework |
| Nuxt | 4.6.1; July 2026 advisories | Out: application framework |
| SvelteKit | 3.0; October 2026 advisory includes XSS in pre-rendered pages, fixed only in 3.x | Out: application framework |
| React Router v7 | Pre-rendering supported; Remix 3 still in alpha | Out: application framework |
| Qwik | v2 status unclear | Out: unclear status |
| Hand-written with Vite | No framework; templating, layouts and validation built by hand | Out: too much to build and maintain |
| Hostinger Website Builder | Drag-and-drop editor | Out: no code to show (fails the showcase, R6, R8) |

## The finalists compared
| | Astro | Hugo | Eleventy |
|---|---|---|---|
| R1, R2 | ● | ● | ● |
| R3 upkeep | ◐ fast-moving | ● one binary, steady | ● slow, stable |
| R4 validation | ● schema built in | ◐ checks in templates (`errorf`) or CI | ◐ `eleventyDataSchema` hook |
| R5 growth | ● islands, server endpoints | ◐ bundled scripts; a separate handler for the form | ◐ |
| R6 testable | ● | ● output and browser tests | ● |
| R7 learning | Components, TypeScript | Go templates; Go for tooling and the form handler | Nunjucks, JavaScript |
| R8 security | ◐ npm supply chain; CSP hashing built in | ● almost no supply chain; context-aware escaping | ◐ npm supply chain |
| R9 SEO | ◐ official add-ons | ● sitemap, RSS, meta templates built in | ◐ plugins |
| Portability | ◐ `.astro` templates | ◐ Go templates | ◐ Nunjucks templates |

## Decision
Hugo, used as a static site generator. Content in Markdown; templates in Go's HTML template
language; no JavaScript toolchain in the site's build unless a later decision adds one. The
contact form is a separate, minimal handler, decided with the host.

## Why
- Strongest on security (R8): one binary instead of an npm dependency tree, and templates that
  escape output by context (HTML, attribute, URL, JavaScript) by default.
- Strongest on SEO plumbing (R9) and upkeep (R3), with no add-ons.
- Its weak points have workable answers: content validation through template checks that fail
  the build (R4); testing at the output and browser level, where a content site's behaviour is
  (R6).
- It fits the user's learning goal: Go templates now, and Go itself for site tooling and the
  contact form handler.

## Consequences
- No component islands: interactivity is written as scripts bundled by Hugo's built-in esbuild.
  Rich interactive demos, if ever needed, are a separate decision.
- Content validation is written by hand in templates (or a Go check in CI), not given by a
  schema library.
- Browser tests need a separate tool (Playwright, which has an official Java version, or a
  community Go version); chosen in its own decision when testing is set up.
- Hugo's code highlighting emits inline styles by default; it is configured to use CSS classes
  so that the Content-Security-Policy needs no `'unsafe-inline'`.
- The Hugo version is pinned exactly, locally and in CI.

## Sources
- Astro 7.0: https://astro.build/blog/astro-7/
- Astro joins Cloudflare: https://astro.build/blog/joining-cloudflare/
- Astro security advisories: https://github.com/withastro/astro/security
- Eleventy release history: https://www.11ty.dev/docs/versions/
- Build Awesome (Eleventy under Font Awesome): https://blog.fontawesome.com/build-awesome/
- Hugo releases and CVEs: https://releasealert.dev/chocolatey/hugo ,
  https://releasealert.dev/chocolatey/hugo/cves
- Hugo highlighting and CSP: https://discourse.gohugo.io/t/content-security-policy-vs-hugos-syntax-highlighting-in-code-blocks/31419
- Jekyll versions: https://rubygems.org/gems/jekyll/versions/4.3.4
- Gatsby under Netlify: https://www.netlify.com/blog/gatsby-cloud-evolution/
- Next.js 2026 security releases: https://vercel.com/changelog/next-js-may-2026-security-release ,
  https://nextjs.org/blog/upcoming-nextjs-security-release-september-22-2026
- Nuxt July 2026 advisory: https://vercel.com/changelog/nuxt-july-2026-security-advisory
- SvelteKit advisories: https://github.com/sveltejs/kit/security/advisories
- React Router v7: https://remix.run/blog/react-router-v7 ; Remix 3 alpha:
  https://remix.run/newsletter/41

Not yet verified: Hugo's exact current version and release date (checked at install); the
built-in SEO templates' current names; how the structured-data script block interacts with the
Content-Security-Policy.

*Note, 2026-11-01:* all three are now verified. Hugo 0.169.0, released 2026-10-27, is pinned
(decision 0003). The built-in SEO templates are `opengraph.html`, `twitter_cards.html` and
`schema.html`; `schema.html` writes meta tags, not a script block, so the
Content-Security-Policy needs nothing for it (decision 0005).
