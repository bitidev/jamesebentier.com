# Board Flow

Issue tracking lives on the project's GitHub Project board (owner `jebentier`, project number
`1`). The board can track issues from more than one repository — a status check or
update always keys off the issue, not the repo it lives in.

This is invoked directly by the skills (`/work`, `/triage`, `/release`, `/harden`,
`/address-feedback`) — there is no relay agent that owns board mechanics; every skill reads
and writes the board itself, following this doc.

## Statuses

This is the canonical status vocabulary for the whole framework — every skill, template, and
generated doc uses exactly these seven names, never a synonym.

| Status | Meaning |
|---|---|
| Triage | New issue awaiting triage (`/triage`) |
| Backlog | Valid but deferred — not aligned with current strategic focus |
| Ready | Screened, ready to start — the ONLY status available to claim |
| In Progress | Being worked (`/work`) |
| In Review | PR open, awaiting review |
| Blocked | Work is blocked on something external |
| Done | Merged and cleaned up |

## Rules

- **Only `Ready` is available to start.** `Triage`/`Backlog` aren't yet approved for work —
  promoting them is `/triage`'s job. `In Progress`/`In Review`/`Done` are claimed by another
  session — don't touch, don't re-implement, don't open a competing PR, even if it looks quick
  or stale. If an item looks wrongly parked, flag it rather than grabbing it.
- **Board updates never block work.** If a mutation fails, note it and continue — the one
  exception is the post-merge issue-state check below, which is not a board mutation and is
  never skipped. A genuine GraphQL error (permission denied, invalid ID, rate limit) is a
  failure; "item not yet on the board" is NOT a failure — it's Step 2 below, and it is always
  add-then-set, never a skip.
- **New issues are not auto-added to the board.** `gh issue create` does not add to a Project
  board — add explicitly (Step 2 below).
- **Closing an issue does not move the board.** A merged PR's `Closes #N` closes the issue but
  leaves board Status untouched. After every merge, verify with
  `gh issue view N --json state` and set `Done` explicitly (see "Post-merge verification").
- **No project board configured for this repo at all** (the discovery query below returns
  nothing) is the only legitimate reason to skip a board update entirely.

## Claiming an issue (`/work` step 1)

```bash
gh issue edit NUMBER --add-assignee "@me"
```

Then set Status to `In Progress` via the sequence below (add-then-set if not yet on the board).

## Updating a status

All `PVT_*` / `PVTSSF_*` / `PVTI_*` IDs must be discovered fresh **every session** — never
reuse, cache, or guess a prior session's IDs; a stale ID returns `NOT_FOUND`.

`repositoryOwner` (not `user`/`organization`) is deliberate — it resolves through the
`ProjectV2Owner` interface regardless of whether `jebentier` is a personal account or an
organization, so the same query works for both.

```bash
# 1. Discover project, field, and option IDs
DATA=$(gh api graphql -f query='query {
  repositoryOwner(login: "jebentier") {
    ... on ProjectV2Owner {
      projectV2(number: 1) {
        id
        field(name: "Status") {
          ... on ProjectV2SingleSelectField { id options { id name } }
        }
      }
    }
  }
}')
PROJECT_ID=$(echo "$DATA" | jq -r '.data.repositoryOwner.projectV2.id')
FIELD_ID=$(echo "$DATA" | jq -r '.data.repositoryOwner.projectV2.field.id')
OPTION_ID=$(echo "$DATA" | jq -r '.data.repositoryOwner.projectV2.field.options[] | select(.name == "In Progress") | .id')  # pick the target status

# 2. Get the issue's item ID on the board — empty means it's not on the board yet
ISSUE_ID=$(gh issue view NUMBER --json id --jq .id)
ITEM_ID=$(gh api graphql -f query='query($id: ID!) {
  node(id: $id) { ... on Issue { projectItems(first: 10) { nodes { id } } } }
}' -f id="$ISSUE_ID" --jq '.data.node.projectItems.nodes[0].id')

# 3. Not on the board yet? Add it — this is never a skip, always add-then-set.
if [ -z "$ITEM_ID" ]; then
  ITEM_ID=$(gh api graphql -f query='mutation($p: ID!, $c: ID!) {
    addProjectV2ItemById(input: {projectId: $p, contentId: $c}) { item { id } }
  }' -f p="$PROJECT_ID" -f c="$ISSUE_ID" --jq '.data.addProjectV2ItemById.item.id')
fi

# 4. Set the status
gh api graphql -f query='mutation($p: ID!, $i: ID!, $f: ID!, $v: String!) {
  updateProjectV2ItemFieldValue(input: {projectId: $p, itemId: $i, fieldId: $f,
    value: {singleSelectOptionId: $v}}) { projectV2Item { id } }
}' -f p="$PROJECT_ID" -f i="$ITEM_ID" -f f="$FIELD_ID" -f v="$OPTION_ID"
```

## Listing items by status

Always pass `--limit 1000` — the default of 30 silently truncates, and GraphQL `first:` caps at
100 (`EXCESSIVE_PAGINATION` beyond that).

```bash
gh project item-list 1 --owner jebentier --format json --limit 1000 |
  jq -r '.items[] | select(.status == "Ready") | "\(.content.number)\t\(.title)"'
```

## Status transition matrix

| From | To | Trigger | Worktree action |
|------|----|---------|-----------------|
| Ready | In Progress | `/work` claims the issue | Create worktree |
| In Progress | In Review | PR created | — |
| In Review | In Progress | Addressing PR feedback (`/address-feedback`) | — |
| In Progress | In Review | Feedback fixes pushed | — |
| In Review | Done | Operator merges the PR | Remove worktree, delete branch |

## Post-merge verification (mandatory, not skippable)

Closing an issue does **not** move the board, and a negated close phrase in a PR body
(`does not close #N`) still auto-closes `#N` on merge — GitHub's parser does not detect
negation. So after every merge:

```bash
gh issue view NUMBER --json state --jq .state
# Expected: CLOSED. If unexpectedly OPEN, close it manually (the closing keyword was missing
# or malformed). If an issue this PR did NOT intend to close is now CLOSED, reopen it —
# `gh issue reopen <OTHER_NUMBER>`.
```

Only after this check passes, set Status to `Done` (Step 4 above, add-then-set if needed).

## Board hygiene — stale item detection

Since there is no automation tying board state to merge state, a session that ends before
post-merge cleanup can leave an item stuck in `In Progress`/`In Review`. Run this check when
starting work on any issue, before beginning the new work:

```bash
gh project item-list 1 --owner jebentier --format json --limit 1000 |
  jq -r '.items[] | select(.status == "In Progress" or .status == "In Review") | "\(.content.number) \(.status)"'
# For each: gh pr list --search "closes #NUMBER" --state merged --json number --jq '.[0].number'
# If a merged PR exists, the board is stale — set Status to Done (Steps 1-4 above).
```
