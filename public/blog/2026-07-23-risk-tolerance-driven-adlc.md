---
slug: 2026-07-23-risk-tolerance-driven-adlc
title: "Risk-Tolerance-Driven ADLC: Teach the Factory to Assess Risk"
description: "A software factory shouldn't apply uniform rigor everywhere. Calibrate guardrails to the risk tolerance of the area: heavy where the stakes are existential, light where a broken render is cheap. Teach the system to assess risk, then dial."
published_at: 2026-07-23
keywords: "ADLC, risk assessment, guardrails, software factory, progressive delivery, blast radius"
image: /logo.png
tags:
- research
- ai
- software-factories
- adlc
- guardrails
- platform-engineering
kind: note
---

# Risk-Tolerance-Driven ADLC: Teach the Factory to Assess Risk

A software factory or AI-driven development lifecycle that applies **uniform rigor everywhere** is wrong in both directions: too slow if it treats a marketing page like a payments system, too dangerous if it treats a payments system like a marketing page. The right model calibrates process to the **risk tolerance** of the area being worked. Low risk tolerance (you can afford almost no failure, as in life-impacting or existentially business-impacting work) demands maximum guardrails, human verification, and cautious rollout. High risk tolerance (a broken outcome is cheap and reversible, like a web page or an internal data render) can move fast on light guardrails. The core skill is teaching your system to assess risk correctly per change, then dialing the guardrails to match.

> A word on terminology, so it never confuses: risk tolerance is *inverse* to required rigor. Low tolerance means high stakes, which means more guardrails. High tolerance means low stakes, which means fewer. When in doubt, reason from "what does a failure here cost, and can we undo it?"

## Guardrails are a dial, not a switch

Review depth, test rigor (kinetic versus simulated), rollout strategy (instant versus progressive), and the human-in-the-loop ratio should all scale continuously with assessed risk, not sit at one global setting. A single company-wide rigor level is either strangling the cheap work or under-protecting the expensive work, usually both at once.

## Classify by the properties that actually predict harm

- **Blast radius:** how many systems and users a failure touches.
- **Reversibility:** whether you can roll back cheaply, or whether the damage is permanent (data loss, a leaked secret, money moved).
- **Data sensitivity:** PII, money, health, credentials.
- **User and business impact:** cosmetic annoyance versus safety or solvency.

A change touching auth or payments is low-tolerance regardless of how small the diff looks. A copy tweak on a landing page is high-tolerance even if it is highly visible. The size of the change is a poor proxy for its risk; these properties are the real signal.

## The factory must own the assessment, not just the execution

The differentiator is not generating code fast. It is the system knowing *which regime it is operating in* and selecting the guardrail profile automatically. An AI factory that cannot tell a cosmetic change from a money-moving one will either drown everything in ceremony or ship a catastrophe at machine speed.

This is where the platform earns its keep. The guardrail profiles (paved roads, policy-as-code, progressive delivery, blast-radius limits) are platform primitives; risk-tolerance-driven development is the routing layer that picks the right profile per change. Foundations, then guardrails, then factory, but with the guardrails parameterized by risk.

And low-tolerance work is exactly where AI over-reach is most expensive. It sits at the intersection of "AI can produce it fast" and "a subtle wrong answer is catastrophic and hard to reverse." That intersection is where trust-but-verify has to be at its most aggressive.
