# Code Customizations

## Upstream / jb-brown quarantine (HARD)

- **Never** Edit/Write/create files under the live `adlc/` symlink for upstream contribution. Treat `adlc/` as **read-only reference** in this consumer.
- Project code changes belong under this repo’s trees (`app/`, `lib/`, `docs/`, `adlc-customizations/`, `.claude/` deploy surface as allowed by session rules, etc.).
- If a task requires evolving ADLC methods/agents, stop and tell the user to do that in a **personally owned** ADLC clone/remote — not via this symlink while it tracks someone else’s framework history.
- Do not open PRs or push commits toward `jb-brown/*` / `Invoca-ADLC`.
