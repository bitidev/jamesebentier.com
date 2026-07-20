---
name: audit
description: Implement WCAG/accessibility fixes directly in HTML, CSS, JS, and framework components, aware of whatever component library the project already uses. Use when the operator asks to fix accessibility/a11y issues, or when /work identifies an issue as an accessibility fix.
---

# /audit [issue-or-report]

You (the main session) parse the accessibility issue against WCAG and the codebase, then dispatch
the **builder** agent (`.claude/agents/builder.md`) to make the fix — builder owns all committed
production code, so this skill hands it the WCAG rules below rather than editing markup itself.
Board mechanics: `docs/flow/board.md`.

Hard rule: fix the **underlying barrier** the WCAG criterion describes, not just the reported
symptom, and never regress existing functionality to do it.

## 1. Claim

Standalone issue ("fix accessibility issues in X"): claim and open a worktree exactly as
`.claude/skills/work/SKILL.md` Step 1 does (assign, board status **In Progress**, worktree).
Already inside a `/work` invocation: skip this and continue in that worktree.

## 2. Parse the issue and scope the fix

- Pull from the report: severity, the WCAG success criteria and conformance level (A/AA/AAA),
  category (keyboard / structure / color / forms / images), repro steps, actual vs. expected
  behavior. Ask rather than assume if these are missing.
- Locate the affected files/components (search for the pattern the issue names — e.g. missing
  `alt`, unlabeled inputs, `outline: none`, a broken heading hierarchy).
- Detect whether the project uses a component library or design system. If it does, its accessible
  primitives take precedence over a hand-rolled ARIA implementation.

## 3. Dispatch builder with the WCAG rules

Dispatch builder with: the WCAG criteria and conformance level, the affected files, the detected
component library (if any), and these rules:

- Semantic HTML before ARIA — reach for ARIA only where no semantic element covers the case.
- Make the **narrowest edit that removes the barrier**: change only the element(s) at fault,
  preserving surrounding markup, indentation, and unrelated attributes.
- Prefer the detected component library's accessible components over a custom implementation.
- Cover whichever of these the issue touches: heading hierarchy and landmarks; keyboard handling
  and focus management (including modal focus save/restore); color contrast (4.5:1 at AA, 7:1 at
  AAA) and visible focus indicators; form labels with error association and announced validation;
  alt text appropriate to informative / decorative / complex images.
- Base functionality keeps working without JavaScript wherever the rest of the project does.
- Out of scope: backend/API changes, unrelated visual redesign, application-architecture changes
  — flag those instead of expanding into them.

Then dispatch **test** (`.claude/agents/test.md`) to write or update tests for the fix (keyboard
interaction, focus management, form-error association, or a rendered-output assertion, as the fix
calls for). Builder never writes tests — that's true here too, even for a markup-only fix.

## 4. Verify

Run whatever accessibility toolchain the project already has configured — an ESLint a11y plugin,
axe-core, `pa11y`, Lighthouse's accessibility category — detected from its dependencies/scripts,
never assumed. If none is configured, surface that gap rather than inventing a toolchain. Manually
confirm keyboard-only navigation, visible focus indicators, contrast, and that the full user
journey (not just the flagged element) still works.

## 5. PR, or hand back

Standalone: push, `gh pr create` (`[#N] <summary>`, `Closes #N`), board status **In Review**, one
`code-review` pass, present the PR URL and stop — wait for the operator to merge or say so.
Mid-`/work`: hand control back to `/work`'s own PR step instead of opening a second PR. Either way,
report the WCAG criteria addressed, the conformance level, and any related accessibility gaps
noticed but not fixed.

## Failure handling

Issue report missing required fields (criteria, severity, repro): ask rather than guess at scope.
No accessibility tooling configured: report the gap instead of inventing one. Environment
failures: hand off to `troubleshoot` (`.claude/skills/troubleshoot/SKILL.md`), then resume.
