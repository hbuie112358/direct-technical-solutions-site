# 0002 Styling: plain CSS with design tokens

Status: Accepted · Date: 2026-10-30 · Decided by: the user, on Claude's recommendation

## Context
The user wants a smooth, professional, polished look, "nothing flashy", with styling that is
capable and configurable. The site's code is public and must stay readable (R7) and compatible
with a strict Content-Security-Policy (R8).

## Options
| Option | For | Against |
|---|---|---|
| Plain modern CSS with design tokens | One file controls the whole look; no dependency; works with a strict CSP; every line explainable | More written up front |
| Tailwind CSS | Fast, consistent spacing and colour | A build dependency; utility classes crowd the markup |
| Component library (e.g. Bootstrap) | Ready-made components | A recognisable stock look; heavier |

## Decision
Plain modern CSS (custom properties, cascade layers, nesting, container queries) with every
design value defined as a token in one file. No CSS framework.

## Why
"Polished, not flashy" comes from typography, spacing, restraint and consistency, which is
exactly what a token system enforces. It adds no dependency and no supply-chain risk, and a
reviewer can read the styles without knowing a framework.

## Consequences
- Components use tokens, never raw values; changing the look means changing the token file.
- Motion stays subtle and respects `prefers-reduced-motion`.
- The base styles (reset, type scale, layout) are written for this site rather than taken from
  a framework.
