---
slug: 2026-07-09-trust-but-verify-concrete-vs-abstract-ai
title: "Trust but Verify: AI on Concrete vs. Abstract Work"
description: "AI is excellent at concrete, checkable tasks and much shakier at abstract objectives like research and planning. The danger is that its output reads equally confident either way. Verify in proportion to abstraction."
published_at: 2026-07-09
keywords: "AI reliability, trust but verify, agentic planning, research automation, human oversight"
image: /logo.png
tags:
- research
- ai
- software-factories
- engineering
- judgment
kind: note
---

# Trust but Verify: AI on Concrete vs. Abstract Work

AI is genuinely strong at **concrete** tasks: closed, well-bounded work with a checkable right answer, like writing a function, refactoring a module, converting a format, or applying a rename. It is far less trustworthy at **abstract** objectives: open-ended, judgment-laden work like research, planning, and architecture. The trap is that the *fluency* of the output is uniform across both. You cannot tell concrete-confidence from abstract-confidence by tone. So the rule is simple: trust-but-verify in proportion to abstraction. The more abstract the objective, the harder you verify, and the more you decompose it into concrete, checkable pieces before you rely on it.

## Concrete tasks are close to self-verifying

Does it compile, pass the tests, match the spec, produce the right diff? Cheap to check, one roughly-right answer. This is where agents shine, and light verification suffices.

## Abstract objectives resist verification

"Research this," "plan the migration," "choose the architecture" have no single checkable answer, reward plausible-sounding output, and punish subtle wrongness that only shows up later. AI will confidently cite from memory, optimize the wrong objective very efficiently, or produce a plan that is coherent and wrong. None of those failures announce themselves.

## Uniform fluency is the hazard

The model sounds equally authoritative when it is right about a regex and when it is hand-waving a strategy. Humans anchor on fluency as a competence signal, and with LLMs that signal is decoupled from correctness. So you have to apply *external* scrutiny calibrated to the task, not to how confident the output reads. Counterintuitively, the more impressive and fluent the output feels, the more that is a reason to check it, not less.

## The move: down-convert abstract into concrete

Verification scales when you turn open questions into closed ones.

- Don't ask AI to "do the research" and trust it. Ask it to gather sources, then verify each source exists and says what it claims.
- Don't trust a plan wholesale. Break it into concrete, individually-checkable steps.
- Don't accept an architecture because it sounds coherent. Extract the specific, testable claims underneath it and check those.

This reframes the human job. The scarce work is judgment on the abstract end: framing the problem, checking the reasoning, and owning the decision. That is precisely where AI is weakest and where accountability is non-transferable.
