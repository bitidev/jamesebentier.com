#!/usr/bin/env bash
# Blocks Edit and Write tool calls when running in the main repo working tree.
# All file changes must go through a worktree (ADLC mandatory worktree rule).
#
# Detection: `git rev-parse --git-dir` returns ".git" (relative) in the main
# working tree and an absolute path ending in .git/worktrees/<name> in any
# linked worktree created by `git worktree add`.
#
# Known assumption: detection relies on git's internal convention that linked
# worktree git-dirs are always under .git/worktrees/. Repos using
# --separate-git-dir with a path that happens to contain "/worktrees/" would
# be treated as a linked worktree (false negative). This is not expected in
# standard ADLC setups.
#
# To bypass in an emergency: set ALLOW_MAIN_EDIT=1 in the environment.

if [ "${ALLOW_MAIN_EDIT}" = "1" ]; then
  exit 0
fi

# Separate the existence check from the value capture so a transient git error
# doesn't silently allow an edit (exit 0 with empty git_dir).
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  # Not a git repo — nothing to enforce
  exit 0
fi

git_dir=$(git rev-parse --git-dir 2>/dev/null)

# In a linked worktree, git-dir is an absolute path ending in .git/worktrees/<name>
if [[ "$git_dir" == *"/worktrees/"* ]]; then
  exit 0
fi

# Main working tree — block the edit
echo "WORKTREE VIOLATION: file edits are not allowed in the main repo working tree." >&2
echo "Create a worktree first:" >&2
echo "  git worktree add ../REPO-branch-name -b branch-name origin/main" >&2
echo "Then cd into the worktree and retry." >&2
echo "Emergency bypass (use sparingly): set ALLOW_MAIN_EDIT=1" >&2
exit 1
