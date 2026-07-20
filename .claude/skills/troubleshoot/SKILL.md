---
name: troubleshoot
description: Diagnose and fix a development-environment problem — missing deps, gh/RTK auth, .env, PATH/toolchain issues — encountered during work. Use when a command fails with an environment-shaped error (command not found, auth failure, missing dependency, permission denied) or the operator asks to set up or fix their environment.
---

# /troubleshoot [symptom]

This runs **inline in the main session** — no worktree, no PR; an environment fix isn't a durable
product-code change unless Step 4 below applies. This is for a specific problem hit mid-task (or a
standalone one-off complaint) — first-time machine onboarding is `.claude/skills/setup-machine/SKILL.md`'s
job, not this skill's. Confirm the root cause before touching anything; a guess can make it worse.

## 1. Confirm the root cause

Read the actual failing command's output rather than guessing from the symptom alone. Common
shapes: `command not found` → missing install or PATH; `ImportError`/`ModuleNotFoundError`/`npm
ERR!` → package missing or the wrong environment (venv/container) active; `Permission denied`/
`EACCES` → file permissions or elevation needed; `Connection refused` → service down or port
conflict; `401`/`403`/auth failed → missing or stale credentials.

Lead with this project's own stack knowledge — `docs/code/conventions.md` (Technology Stack),
`docs/code/adlc-init.md`, and `docs/code/troubleshooting-playbook.md` (known issues already
documented for this project) — over generic assumptions about what it uses.

## 2. Fix it

- **GitHub auth:** `gh auth status`; if not authenticated, walk the operator through
  `gh auth login`.
- **RTK (Rust Token Killer):** `rtk --version`, then `rtk gain` as a collision guard (must show
  token-killer analytics, not silence or an error — a different `rtk` binary may be installed) and
  confirm the `PreToolUse` hook is present in `~/.claude/settings.json`. RTK is non-blocking —
  record the gap and continue if it can't be fixed immediately.
- **`.env`:** create it from `.env.sample` if missing; prompt only for variables `.env.sample`
  actually marks required, ignoring its placeholder example values. Never assume a default for a
  user-specific value.
- **Dependencies/toolchain:** identify the stack's manifest and lockfile, run its install/sync
  command, check for a version or lockfile mismatch, clear a corrupted cache if that's the cause,
  and confirm the work is happening inside the project's isolated environment (venv/container/
  equivalent) rather than against global tooling.
- **Editor settings:** never edit `.vscode/settings.json` unless explicitly asked to; suggest a
  per-project config file instead (`.env`, `.eslintrc`, `tsconfig.json`, a project MCP config).

## 3. Validate

Re-run the original failing command (or the closest health check — `gh auth status`,
`gh issue list --state open --limit 3`, the tool's `--version`) and confirm it now succeeds.

## 4. Escalate when this is bigger than a quick fix

- **Comprehensive onboarding** (fresh machine, new developer, `.env` needs full population — not
  one symptom): hand off to `.claude/skills/setup-machine/SKILL.md` instead of patching piecemeal.
- **An actual code bug** (e.g. a config-loading bug, not a missing `.env` value): report the root
  cause and dispatch **builder** (`.claude/agents/builder.md`) to fix it as a normal change —
  worktree, PR, the works — following the same bug-fix shape `.claude/skills/work/SKILL.md` uses
  (test writes the failing repro first, then builder fixes it). Don't patch around a code bug from
  inside this skill.

## Failure handling

Report environment state (ready / partially ready / blocked), the exact actions taken (commands
run, files touched), a one-line root-cause explanation, and the next step — resume the interrupted
work, or name the skill/agent that should run next. Don't silently improvise past a genuine
blocker, such as credentials only the operator can supply.
