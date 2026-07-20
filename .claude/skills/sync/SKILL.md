---
name: sync
description: Refresh this project's skills, agents, hooks, and flow docs from the framework's source, preserving customizations and project-specific docs. Use when the operator asks to update, sync, or refresh the ADLC framework in this project.
---

# /sync

Pulls framework updates **down** into this already-installed project. The inverse direction —
pushing a local edit back up into core ADLC — is `.claude/skills/contribute/SKILL.md`.

## 1. Locate the framework source

Read `.claude/adlc.manifest.json` for `source`. Prefer the local path if it resolves on this
machine; otherwise `git fetch`/clone the recorded URL to a temp checkout. If neither resolves,
stop and report — there's nothing to sync from.

## 2. Re-copy the framework-owned surface

From that source, refresh:
- `.claude/skills/` — core + meta skills, plus whichever opt-in skills this project already has
  installed. Don't add a *new* opt-in on your own initiative — detecting and adding one is
  `.claude/skills/adlc-init/SKILL.md`'s job, not this skill's.
- `.claude/agents/`, `.claude/hooks/`.
- `.claude/code-quality/` — all 5 shared-knowledge docs, unconditionally (the always-deployed
  island, same as a fresh `setup.sh` bootstrap).
- `docs/flow/{board.md,models.md}` — template-merge: refresh the mechanical content, but keep
  this project's filled `{OWNER}`/`{NUMBER}` board coordinates and any operator edits to either
  file.

If a shipped `scripts/adlc-sync.sh` exists, prefer it for the mechanical copy/diff — it's the
same engine `/contribute` uses in reverse, so the copy logic lives in one place, not two.

## 3. Refresh the Cursor adapter

Cursor stays in sync the same way `/adlc-init` first provisioned it (§5.9 of the migration
design; `scripts/adlc-sync.sh` doesn't cover this yet, so do it directly): refresh
`.cursor/rules/adlc-rules.mdc` from the source's `adlc/templates/cursor-rules.mdc` —
copy-if-absent, **preserve operator edits** (unlike this repo's own dogfood mirror, which
overwrites unconditionally); and regenerate `.cursor/commands/<skill-name>.md` for every
currently-deployed skill (core + meta + installed opt-ins) as a thin pointer to that skill's own
`.claude/skills/<name>/SKILL.md` — regenerating this reference-form stub fresh on every sync is
expected and not an "edit," so no preserve-edits concern there (fall back to copying the full
`SKILL.md` body into the command file instead, per `runner-capability-contract.md`, only if the
operator's Cursor session shows the `@path` reference isn't resolving).

## 4. Preserve — never overwrite

`adlc-customizations/**`, every project doc (`docs/code/**`, `docs/architecture/**`,
`docs/design/**`, `docs/specs/**`), this project's own `CLAUDE.md` content, and
`.claude/settings.json` local edits. These are what make the copy model self-contained per
project — sync must never clobber them.

## 5. Bump the manifest

Update `version` in `.claude/adlc.manifest.json` to the source's current version.

## 6. Report

A diff summary: what changed, what was preserved untouched, and anything that couldn't be
resolved automatically — e.g. an operator edit to a file that also changed upstream. Surface a
conflict like that explicitly; never silently pick a side.

## Failure handling

If the source can't be located or fetched, or a conflict can't be resolved automatically, stop
and report exactly what's blocking — never guess at a merge.
