# Orchestrator Customizations

## Upstream / jb-brown quarantine (HARD)

This consumer evolves ADLC only for personal projects. The orchestrator must never:

- Create, update, comment on, or close GitHub issues/PRs on `jb-brown/*`, `Invoca-ADLC`, or any upstream ADLC framework repository
- Pass `--repo` targeting those remotes (or any non-personal ADLC remote)
- Instruct sub-agents to edit files through the `adlc/` symlink for the purpose of contributing upstream
- Push, fetch, or otherwise use git remotes on the linked ADLC checkout aimed at jb-brown / Invoca

All issue work stays on **this** repo (`bitidev/jamesebentier.com`) and its board. Framework experiments belong only in a personally owned ADLC remote (when one exists) — never upstream.

If a user or issue implies contributing back to jb-brown / upstream ADLC, refuse, cite `docs/strategic-priorities.md` Won't Do, and keep the work local or Won't-Do the issue.
