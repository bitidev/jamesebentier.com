---
name: work
description: Take a GitHub issue from Ready to Done — claim it, design gate for features, implement via builder (+ test), open a PR with an advisory review and theatre-check, gate it on CI + Copilot review, then post-merge cleanup. Use when the operator says "work on #N", "implement #N", "fix #N", or similar.
---

# /work <issue-number>

You (the main session) coordinate the whole lifecycle directly and dispatch agents yourself —
there is no relay. Board mechanics: `docs/flow/board.md`.

Two hard rules:
- **Never commit to main, no exceptions.** All changes happen on the issue branch, in its
  worktree.
- **Never merge the PR unless the operator explicitly instructs it in that moment.** Default is
  always present-and-wait — the operator merges. A standing "you can merge these" from earlier
  in the conversation does not count; each merge needs its own explicit go-ahead.

## 1. Claim

- `gh issue view N` — title, body, labels, comments.
- Assign yourself (`gh issue edit N --add-assignee "@me"`) and set board status **In Progress**
  (`docs/flow/board.md`; add to the board first if it isn't on there yet).
- Create the worktree:
  ```bash
  git fetch origin
  git worktree add ../<repo>-issue-N -b personal/<git-user>/issue-N-<slug> origin/main
  git branch --show-current   # must print the new branch, never main/master
  ```
  All file changes for this issue happen there. Never remove or prune worktrees you don't own.

## 2. Design gate (features and enhancements only — bugs skip to step 3)

Write a short design doc at `docs/design/YYYY-MM-DD-<topic>-design.md` (in the worktree):
**problem, chosen approach, acceptance criteria, open questions.** Keep it to about a page —
cover the *what* and *why*; leave file layout, function signatures, and other implementation
detail to `builder` unless they're genuinely load-bearing decisions. Write it yourself by
default; dispatch **planner** (`.claude/agents/planner.md`) only when the design is genuinely
load-bearing — a new subsystem, a cross-cutting change, or a materially ambiguous approach.

Present it to the operator and **stop until they approve**. Fold in any feedback before moving on.

## 3. Implement

**Bugs:** dispatch **test** (`.claude/agents/test.md`) first, in bug-fix mode, to write a
**failing** regression test that reproduces the issue before anything else changes. Hand its
root-cause notes and the failing test to **builder** next.

**Features:** dispatch **builder** (`.claude/agents/builder.md`) with the issue number, worktree
path, the approved design doc path, and any constraints from the issue thread. `builder` writes
production code only and commits `[#N] <summary>` in the worktree — then dispatch **test** to
write/update the tests covering the change.

Both agents work inside the worktree from Step 1 and report back before you move to Step 4.

## 4. PR + review gate

- Push the branch; `gh pr create` with title `[#N] <summary>`, `Closes #N` in the body, and
  `--reviewer "@copilot"` to request a GitHub Copilot review up front.
- Set board status **In Review** (`docs/flow/board.md`).
- Run one review pass over the PR diff: the `code-review` skill at medium effort (or an
  equivalent single pass). Fix confirmed bugs and push; post remaining non-blocking notes as a
  PR comment.
- **Theatre-check:** dispatch `test` (`.claude/agents/test.md`) in audit mode over the tests
  this issue added or changed. Rewrite any theatre it finds via `test`, not inline.
- **Gate on CI + Copilot before handing off.** The PR is not handed off until both are green and
  addressed — never present a red PR:
  - **CI:** `gh pr checks N --watch` until it settles. Fix real failures in the worktree and
    push. Every push re-runs CI and re-triggers Copilot, so re-wait after each push.
  - **Copilot:** wait for its review to land (`gh pr view N --json reviews` shows a review from
    `copilot-pull-request-reviewer[bot]`). Triage the comments — dispatch `builder`/`test` for
    the correct ones and push, reply to or dismiss (with a reason) the ones you're intentionally
    not taking. If a push invalidates the review, re-request it with
    `gh pr edit N --add-reviewer "@copilot"`.
  - Loop until CI is green and every Copilot finding is either fixed or explicitly answered.
- **Escape hatch.** If CI can't reach green on its own (a flaky or infra failure unrelated to the
  change) or Copilot review is unavailable/not enabled on the repo, stop and surface exactly what
  is stuck to the operator — don't silently hand off, and don't loop forever. The operator decides
  how to proceed.
- Present the PR URL to the operator with a summary of what was built, the review notes, and
  CI/Copilot status, and **stop** — wait for the operator to merge, or to explicitly say to merge
  it now.

## 5. After the PR merges

- If — and only if — the operator explicitly instructed a merge **in this conversation, in the
  moment**, run `gh pr merge N` (respect the repo's merge method; never force-push or bypass
  required checks). A standing earlier "you can merge these" does not count. Otherwise wait for
  the operator to merge on GitHub themselves.
- Verify the merge landed cleanly per `docs/flow/board.md`'s post-merge verification — the
  `gh issue view N --json state` check is mandatory, not skippable, because a negated close
  keyword still auto-closes the issue. Set board status **Done**.
- Clean up:
  ```bash
  git worktree remove ../<repo>-issue-N
  git branch -d personal/<git-user>/issue-N-<slug>
  git checkout main && git pull origin main
  ```

## Failure handling

If a step fails (auth, a board mutation, `builder`/`test` coming back blocked), report exactly
what happened and what you tried — don't silently improvise around it. Board-update failures
alone never block the code work itself (`docs/flow/board.md`).
