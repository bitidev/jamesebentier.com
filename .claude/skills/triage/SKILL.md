---
name: triage
description: Screen new GitHub issues onto the board and move Triage items to Ready, Backlog, or closed, judged against strategic priorities. Use when the operator asks to triage issues, groom the board, or screen new issues.
---

# /triage

Board mechanics: `docs/flow/board.md`. Strategic fit: `docs/strategic-priorities.md` (decides
Ready vs. not — read it fresh every run, priorities change). Execution urgency, once something
is Ready: `docs/internal/priorities.md` if present (internal-only P0/P1/P2 weighting; never
surfaced to the issue author or any public comment).

## 1. Sweep for strays

`gh issue list --state open` across every tracked repo, compared against the board — add any
open issue that isn't on the board yet, with status **Triage**. New issues from `gh issue create`
are never auto-added (`docs/flow/board.md`).

Filing destination rule: if the operator asks to file a new bug/feature, create it on **this
project's own tracked repo**, never on an upstream/third-party dependency's repo — an issue filed
there is invisible to this board. If the root cause is genuinely upstream, still track it here
(note "External dependency" in scope) and only file upstream after explicit confirmation.

## 2. Screen each Triage item

For every item currently in **Triage**, read the full issue and decide:

- **Illegitimate** (malicious intent, corporate-hijacking a specific vendor's API as a hard
  dependency, license-incompatible or IP-transferring proposals, sabotage, offensive content,
  spam/off-topic/bot noise) → close with a one-line comment. Never close without stating why.
- **Valid, well-formed, aligned with current priorities** (bugs: has repro steps and
  expected-vs-actual; features: has a "why" and connects to current focus) → **Ready**. If
  `docs/internal/priorities.md` exists, note which P0/P1/P2 tier it falls under.
- **Valid but deferred or not aligned with current focus** → **Backlog**, with a one-line
  rationale.
- **A "Chunk N of Epic M" or similar auto-sliced placeholder** → don't move it to Ready as-is.
  Check whether its acceptance criteria are already satisfied by shipped work; if a real gap
  remains, file a focused new issue for it; close the chunk-tracker as superseded, linking the
  new issue if one was filed.
- **Underspecified but promising, or you're just not sure** → leave it in **Triage**, comment
  with exactly what's missing. When in doubt, don't guess — a false negative (rejecting a good
  issue) is worse than triaging a borderline one conservatively.

Comment on every disposition:
```markdown
## Triage Decision: [Ready|Backlog|Won't Do|Needs Info]
**Strategic fit:** ...
**Rationale:** ...
```

## 3. Hygiene pass

Any item **In Progress** or **In Review** whose PR already merged → **Done**
(`docs/flow/board.md`'s stale-item check).

## 4. Report

Every decision made, with its one-line rationale, grouped by disposition (Ready / Backlog /
Won't Do / Needs Info / left in Triage) plus the hygiene-pass count. Note any pattern worth the
operator's attention (a spam spike, a cluster of related requests).

Don't start implementation from here — that's `/work`.
