---
name: release
description: Cut a release — determine what shipped since the last tag, bump semver (patch/minor/major from args), generate customer-facing release notes, tag, and publish. Use when the operator asks to cut, tag, or publish a release.
---

# /release [patch|minor|major]

The pipeline is ordered and transactional: scope → bump → notes → land + tag + push → optional
build/publish → annotate, in that exact sequence. If any step fails, stop there and report the
exact state left behind — never proceed past a failed step, and never push a tag if the
version-bump commit didn't land.

## 1. Scope

`git describe --tags --abbrev=0` for the last tag (no prior tag → use full history). Enumerate
commits since it, merged PRs (`gh pr list --state merged --search "merged:>=<tag-date>"`), and the
issues they closed. If nothing shipped, say so and stop. This enumeration is the single source
for the notes (Step 3) and the annotation (Step 6) below — don't re-derive it twice.

## 2. Version

Bump per the argument — **an explicit argument always wins** over any inferred level. If
omitted, propose one (breaking → major, features → minor, fixes only → patch) and confirm with
the operator before proceeding. Stamp it into whatever this project declares as its version
location (`docs/code/conventions.md`'s release-protocol note, or a location declared in
`adlc-customizations/release-customizations.md` if the project's version lives elsewhere —
never assume this framework's own `CHANGELOG.md` + bare version-file convention is universal).

## 3. Notes

Draft customer-facing notes from Step 1's enumeration. Lead each bullet with the value delivered,
not the engineering; group into themes (e.g. "Smoother setup", "New capabilities"); 3-8 bullets;
confident, product-update tone. Never: file/function/schema names, "refactored"/"migrated"/
"fixed race condition"-style engineering language, issue/PR numbers, or chore/CI/dependency-bump
commits that don't affect users. Never reveal a past security/privacy/compliance weakness — "now
does X" implies "used not to," so generalize ("Continued security hardening") or omit rather than
describe what changed. Never describe attack surfaces or exploit vectors.

## 4. Land, tag, push — confirm first

This is outward-facing — **confirm the version, notes, and landing path with the operator**
before touching anything below. Work in your own worktree, on a short-lived release-prep branch
off an up-to-date release branch (Rule 1, worktree isolation, is not waived for release) — the
version-bump + notes-stamp commit is made there, never in the main checkout.

Landing that commit onto the release branch is project-policy: **PR → merge is the ADLC
default** (consistent with never committing to main and never auto-merging — a human decides
when it lands); a project may declare **direct push** allowed instead, but only if
`adlc-customizations/release-customizations.md` states so explicitly.

Once the commit is on the release branch:
```bash
git tag -a vX.Y.Z -m "vX.Y.Z"
git push origin vX.Y.Z
gh release create vX.Y.Z --title "vX.Y.Z" --notes "<Step 3 notes>"
```
**Never force-push. If the tag already exists, abort** — never overwrite an existing tag.

## 5. Build/sign/publish (customization hook)

Check `adlc-customizations/release-customizations.md` for a build/sign/notarize/publish
procedure and run it if present. If absent, say so explicitly in the completion report — never
assume a toolchain (npm, cargo, Electron, or otherwise). There is no generic fallback; the
hook-check itself is the entire generic-side responsibility for this step.

## 6. Close out

Comment `Released in vX.Y.Z` on every item from Step 1's enumeration (`gh issue comment` /
`gh pr comment`) — this is annotation only, never a board Status mutation
(`docs/flow/board.md`'s statuses have no post-`Done` "Released" state by default). Verify each
shipped issue is actually closed and its board status is **Done**; fix any that drifted. A
project-declared "Released" column (rare; stated in `release-customizations.md`) is the one case
where this is a real status transition — treat it exactly like any other board update in
`docs/flow/board.md`.

## Report back

Version bumped (from → to), the notes, which landing path was used and the resulting commit,
the tag and confirmation it wasn't a force-push, whether a build/publish step ran (or the
explicit "none configured" statement), the shipped items annotated, and whether a GitHub Release
was created.

## Failure handling

Stop at the first failing step; report which step, why, and the exact state left behind (e.g.
"version bumped and committed locally, not pushed — tag never created"). Never proceed to a later
step on a failed earlier one; re-invoke to resume from the failed step once fixed, never re-run a
step that already completed.
