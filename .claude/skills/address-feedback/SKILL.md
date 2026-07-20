---
name: address-feedback
description: Process a pull request's own review feedback item by item — discover the PR, pull reviewer comments via gh, dispatch builder/test for fixes, and push updates for re-review. Use when the operator asks to address, process, resolve, or implement PR/review feedback.
---

# /address-feedback [PR]

You (the main session) coordinate this directly: discover the PR, work through its feedback item by item, and dispatch fixes yourself — no relay. Board mechanics: `docs/flow/board.md`.

Hard rules:
- **Never commit to main.** Everything happens as commits on the PR's own existing branch, in its worktree.
- **Stay scope-constrained to this PR's own feedback.** Never scan for unrelated TODO/FIXME comments, and never suggest or implement work beyond what reviewers actually raised on it.

## 1. Discover the PR

- Explicit `#N` or a PR URL in the request → use it directly. No identifier given → `git branch --show-current`, then `gh pr list --state open --head <branch> --json number,title,url` to find the PR for the current branch.
- PR identity and content always come from `gh pr view`/`gh api` — never infer feedback from `git log` or guess at it.
- Resolve the worktree tied to the PR's head branch: if the one `/work` created is still around, work there; otherwise recreate it (`git fetch origin && git worktree add <path> <head-branch>`). Never address feedback from the main tree.

## 2. Retrieve feedback (gh-first)

Pull the full picture, not a summary:
```bash
gh pr view <N> --json reviews,comments,reviewThreads
gh api repos/{owner}/{repo}/pulls/<N>/comments   # inline, code-level review comments
gh api repos/{owner}/{repo}/issues/<N>/comments  # PR-level discussion comments
gh pr checks <N>                                 # CI failures tied to this PR
```
`gh auth status` must succeed first (or a `GITHUB_TOKEN` fallback) — if neither works, stop and report; don't fall back to scraping git state for feedback.

Flatten the result into one list of items, each with its file/line (if inline), the reviewer's comment, and a rough severity (blocking, improvement, documentation, suggestion) so blocking items surface first.

## 3. Process item-by-item

Present one item at a time — location, category, the reviewer's comment, your proposed fix — and get explicit approval before touching anything. Never batch-approve. On approval, implement immediately (Step 4) and confirm before moving to the next item; on skip, note it and move on. Keep a running tally (implemented / skipped / deferred) for the closing report. If the operator stops early, report progress so far and stop cleanly rather than pushing through the rest.

## 4. Dispatch fixes

Route each approved item by what it actually needs:

- **Code fix** → dispatch **builder** (`.claude/agents/builder.md`) with the file/line, the reviewer's comment, and the required change.
- **Test fix or missing coverage** → dispatch **test** (`.claude/agents/test.md`) with the same context, scoped to that item.
- **Genuine design/spec gap** the feedback exposes → update the relevant `docs/design/` or `docs/specs/` file yourself; dispatch **planner** (`.claude/agents/planner.md`) only if the implications are big enough to be genuinely load-bearing — the same judgment call as `/work`'s design gate, not the default.
- **Trivial doc/comment wording** → fix it directly, no dispatch needed.

Validate each result actually addresses the reviewer's comment before moving to the next item. If the fixes are substantial enough that the PR is effectively back under active development, move the board status to In Progress while you work and back to In Review once pushed (`docs/flow/board.md`); for smaller fixes it just stays In Review throughout.

## 5. Re-request review / report

Push fixes to the PR's existing branch — never open a new PR. Dispatch **reviewer** (`.claude/agents/reviewer.md`) for a fresh static pass only if the operator asks for one; otherwise let CI and the original reviewers re-review as normal (a short summary comment on the PR itself is a nice touch, not required). Report to the operator: items implemented / skipped / deferred, files touched, and that the PR is ready for re-review. Never merge from here — merging is the operator's call via `/work`.

## Failure handling

If `gh` auth fails, a dispatched agent comes back blocked, or an item's fix fails outright, stop and report exactly what happened and what you tried — don't skip it silently or improvise a workaround. Board-update failures never block the fix work itself; note them and continue.
