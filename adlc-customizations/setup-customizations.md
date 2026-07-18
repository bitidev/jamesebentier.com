# Setup Customizations

## Upstream / jb-brown quarantine (HARD)

- Do **not** run `setup.sh`, `sync-self.sh`, or other framework maintenance scripts in a way that prepares commits/PRs for `jb-brown/Invoca-ADLC` or sibling upstream remotes.
- Do **not** restore or add a git remote on the linked ADLC checkout pointing at jb-brown / Invoca.
- Environment setup for this project targets `bitidev/jamesebentier.com` only (`gh` auth, board, `.env`). Framework clone remotes are the human’s to point at a personally owned GitHub repo when ready.
- If setup detects the `adlc/` symlink resolving into a tree that still has an upstream jb-brown remote, warn the user — do not “fix” it by pushing or opening upstream issues.
