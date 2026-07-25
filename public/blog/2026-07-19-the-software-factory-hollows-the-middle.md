---
slug: 2026-07-19-the-software-factory-hollows-the-middle
title: "The Software Factory Hollows the Middle"
description: "AI isn't a clean substitution for engineers. The software factory compresses the routine middle of the profession and raises the value of the two ends: system design above, platform and guardrails below."
published_at: 2026-07-19
keywords: "software factory, AI software engineering, apprenticeship, engineering judgment, platform engineering, system design"
image: /logo.png
tags:
- ai
- software-factories
- career
- platform-engineering
kind: deep_dive
---

# The Software Factory Hollows the Middle

There's a comfortable story going around that AI is coming for software engineering the way the tractor came for the farmhand: a clean substitution, one machine for many hands, and the only question is how many hands. That story is wrong in a way that matters. The software factory doesn't replace engineers. It **hollows out the middle of the profession** and leaves the two ends standing taller than before.

Let me make the claim precisely, because the imprecise version is what people are panicking about.

## Software factories industrialize code production, not engineering judgment

A "software factory" is an assembly line for software: standardized inputs (specs, tickets, prompts) feed an automated pipeline of codegen agents, scaffolding, and CI/CD, and software comes out the other end at volume, with humans supervising rather than authoring. The 2020s wave of agentic coding is what made the framing newly plausible. It collapsed the cost of exactly one step: implementation.

Notice what that *doesn't* collapse. It doesn't decide what problem you're solving. It doesn't choose where the service boundaries go, or which of two irreversible data-model decisions you'll regret in eighteen months. It doesn't sit in the incident channel at 2 a.m. and own the outage. Those are engineering *judgment*, and the marginal cost of judgment has not moved an inch.

So here's the shape of it. As the cost of generating code approaches zero, the scarce, valuable work migrates in **two directions at once**:

- **Upward**, into problem framing, system design, and tradeoff decisions. When the factory will faithfully mass-produce whatever architecture you point it at, the *pointing* becomes the whole game.
- **Downward**, into the platform, the guardrails, and the operational substrate that make machine-produced code safe to run at all.

The middle (routine, well-specified implementation) is what gets compressed. That's the part everyone thought *was* the job.

## The middle was the ladder

Here's the uncomfortable part, and the reason I think the jobs conversation is aimed at the wrong target.

The most exposed work isn't just boilerplate and glue code and first-draft tests. It's the **entry-level ticket-taking that engineers historically climbed to build judgment in the first place.** You became a senior engineer by writing a thousand mediocre implementations and slowly learning, in your hands, why the boundaries go where they go. The middle wasn't just output. It was the apprenticeship.

If the factory eats that rung, we have a second-order problem much bigger than the first-order one. Fewer juniors doing routine work is a headcount story. **A generation that never builds senior judgment because the practice field got automated is a capability story.** And capability stories take a decade to show up and a decade to fix.

I don't have a clean answer to this yet. Nobody does. But I'm certain the apprenticeship crisis is the part of this transition worth losing sleep over, and it's almost entirely absent from the "how many jobs" discourse.

## We have run this experiment before

The instinct to say "this time is different" is strong, so let's check it against history, because the *idea* of industrializing software isn't new at all.

CASE tools promised it in the 80s and 90s. Offshore "code factories" promised it. Low-code, no-code, and RAD each promised it in turn. They all under-delivered, and they under-delivered for the same reason every time: **the binding constraint on building software was never typing speed. It was understanding the problem.**

What's genuinely new this time is that agentic coding actually *does* compress implementation in a way those waves didn't. That's real, and I don't want to wave it away. But the old lesson still bites. If you move the bottleneck off of "producing code" and onto "knowing what to build and verifying that it's right," you haven't removed the constraint. You've relocated it to a place that's harder to staff and harder to automate. Garbage specs at machine speed are just garbage at scale.

## The role isn't disappearing. It's changing tense.

Play this forward and the engineer's job description shifts from **author** to **editor, orchestrator, and verifier**. Fewer people producing far more software. That's not a smaller profession; the net headcount question is genuinely open, and I'd put real weight on the Jevons-paradox case where cheaper software just means *more* software and more people to steer it. But it is a *different* profession, and the skills that make you valuable in it are not the skills the middle rewarded.

Which is why my advice, if you're trying to figure out where to stand, is blunt: **bet on the ends.**

Bet upward. Get dangerously good at problem framing, at system design, at reasoning from first principles about what actually needs to exist. The models are pattern machines; pattern-matching is the thing they commoditize first. Reasoning from fundamentals about the *right* problem is the thing they can't.

Bet downward. Get deep on the platform, the guardrails, the operational substrate: the paved roads that determine whether factory-scale output is an asset or a liability. When code volume goes up, a strong platform's leverage goes up with it, and a weak platform's damage does too.

The middle is where the compression happens. The ends are where the value went.

## Sources & further reading

This piece is a synthesis; the research behind it lives in two companion notes:

- [History of Software-Industrialization Waves](/writing/2026-07-15-history-of-software-industrialization-waves) on the CASE, 4GL, offshore, and low-code waves, and why each stalled (anchored on Brooks' *No Silver Bullet*).
- [Jevons Paradox for Software](/writing/2026-07-17-jevons-paradox-for-software) on whether cheaper code expands or contracts demand for engineers.

---

> First in a series on the industrialization of software engineering. Next: [Your Platform Is the Factory Floor](/writing/2026-07-22-your-platform-is-the-factory-floor).
