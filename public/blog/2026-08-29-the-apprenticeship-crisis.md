---
slug: 2026-08-29-the-apprenticeship-crisis
title: "Where Does Senior Judgment Come From"
description: "The real AI question isn't how many jobs it takes; it's where the next generation of senior judgment comes from once the factory eats the entry-level work engineers used to learn on. Apprenticeship can no longer be an accident; leaders have to make it deliberate."
published_at: 2026-08-29
keywords: "apprenticeship crisis, engineering judgment, AI software engineering, junior developers, mentorship, senior engineers, talent pipeline, software factory, engineering leadership"
image: /logo.png
tags:
- ai
- software-factories
- career
- mentorship
kind: deep_dive
---

# Where Does Senior Judgment Come From

Every conversation about AI and engineering jobs is stuck on one word: *how many*. How many roles vanish, how many juniors don't get hired this year, how many net seats the industry ends up with when the dust settles. It's a fair question. It's also the small one.

**The question that should actually keep leaders up at night isn't how many jobs the factory takes. It's where the next generation of senior judgment comes from once it takes them.**

That is a different problem, and it is bigger, slower, and almost entirely missing from the discourse. The headcount fight plays out in quarters. This one plays out over a decade, quietly, and by the time you can measure it you are already a decade behind on fixing it.

I've written the entrant's side of this before, in [The On-Ramp Moved](/writing/2026-07-25-breaking-into-software-engineering): if you're the one trying to get in, here's what to build now that the on-ramp moved. This piece is the other side of the same coin. Not "how do you personally get in," but the systemic question every engineering leader, hiring manager, and staff-plus engineer now owns whether they've noticed it or not. **As an industry, where is our senior judgment going to come from in ten years, and what do we do about it starting now?**

## The training ground was a byproduct

Here's the mechanism, because the whole argument rests on it.

For all of software's history, the routine middle of the work (well-specified tickets, glue code, first-draft tests, the boilerplate that made up most of a junior's day) did two jobs at once. It was output: the company needed that code, and someone had to produce it. And it was *tuition*: while a junior ground through a thousand small implementations, they were quietly learning, in their hands, why the boundaries go where they go, why that shortcut bites you in six months, what "done" actually means. Nobody designed it as a training program. It just was one. The apprenticeship rode along for free, bolted onto work the business needed anyway.

The factory unbundles those two jobs. It does the *output* part cheaply and at volume, which is exactly why it's attractive. But it does not do the *tuition* part at all. When an agent turns the well-specified ticket into working code in minutes, the code still gets produced; the learning that used to happen while a human produced it does not. **We automated the byproduct we were secretly depending on, and we did it without noticing we depended on it.**

That's the trap. The training ground was never on anyone's balance sheet, so cutting it doesn't show up as a cost. It shows up as an absence, years later, in the shape of a senior engineer who never got made.

## Why this is second-order, and worse

The direct jobs story is a first-order effect: fewer people doing routine work. You can see it, argue about it, and it resolves one way or the other. I genuinely don't know which way, and neither does anyone selling you certainty; the net-jobs question is open. Cheaper software may well mean far more software and more people to steer it (I put real weight on that case; see [Jevons Paradox for Software](/writing/2026-07-17-jevons-paradox-for-software)). The *composition* shift, though, is not open. Even in the bullish world where total engineering demand grows, the entry-level rung is the part thinning, and that's the rung the pipeline ran through.

The apprenticeship crisis is the second-order effect, and second-order effects are the ones that hurt, because they're slow and invisible until they aren't.

Two things make it worse than the headcount version.

**Judgment takes about a decade to build, and about a decade to notice missing.** I don't offer that as a precise number; I mean that senior judgment is not a course you take, it's a sediment that accumulates from years of being wrong in instructive ways. You can't compress it with a bootcamp and you can't hand it over in a doc. So a gap in the pipeline today is a gap in your staff-plus bench in the late 2030s, and you won't feel it until you reach for depth that isn't there and close your hand on nothing.

**You cannot buy senior judgment on demand.** Every leader's instinct, when the junior work dries up, is "fine, we'll just hire seniors." That works right up until everyone tries it at once. If the whole industry stops making seniors and starts poaching them instead, the pool doesn't refill; it gets smaller, older, and more expensive every year. **It's a classic commons problem.** Any single company is better off skipping the slow, expensive work of growing people and hiring ready-made talent from someone else. If every company runs that same math, nobody grows anyone, and the commons collapses on all of them together. Training the next generation was always a partly-public good. The factory just removed the accident that used to fund it.

## What a hollowed middle does to an org

Play it forward inside a single company and the shape is ugly.

You get an org chart with a fat layer of agents and orchestration at the bottom, a thin and graying layer of seniors at the top, and very little in between. The seniors carry all the judgment, so they become the bottleneck on every decision that actually matters: every design review, every incident, every "is this AI output actually right" call routes to the same shrinking group. That is not leverage. That is key-person risk spread across an entire organization, a bus-factor problem you scaled up instead of solving.

And the people you *do* have coming in never get the reps, because the reps got automated, so the pipeline that's supposed to refill the top from below runs dry at exactly the moment you're leaning on the top harder than ever. It compounds. The more you rely on your seniors, the less slack they have to make new ones; the less they make, the more you rely on the ones you've got.

This is the failure mode of doing nothing. Not a dramatic collapse; a slow, expensive stiffening, until one day you notice you have nobody who could replace the three people who understand your hardest systems, and no way to grow a replacement in under a decade.

## Apprenticeship has to become deliberate

Here's the turn, and the good news: this is a solvable problem, but only if you stop expecting it to solve itself. Apprenticeship can no longer be an incidental byproduct of grunt work, because the grunt work is gone. It has to become an intentional, budgeted, on-purpose thing. That's a real shift in how teams operate, and it's the leader's job to make it, not the junior's.

Concretely, here's what "intentional" looks like:

- **Hire juniors anyway, and onboard them into the actual job.** The reflex to just stop hiring entry-level is the single most expensive short-term saving available, because it's borrowing against your own senior bench a decade out. But don't hire them into the old job that no longer exists. Bring them in as **verifiers, orchestrators, and editors from day one**: reading and interrogating agent output, tracing blast radius, owning the "is this correct" question. The role changed tense from author to editor; onboard them into the tense the work is actually in.
- **Make verification the first thing they apprentice into.** The new scarce skill is knowing whether generated code is right (see [Generation Is Cheap, Verification Is Not](/writing/2026-07-25-generation-is-cheap-verification-is-not)), and it happens to be a superb teacher. Forcing a junior to explain, defend, and stress-test a diff builds the exact judgment the ticket queue used to build, faster and more deliberately. But it only works if you *require the understanding*. A junior who rubber-stamps agent output learns nothing; a junior who has to narrate why every line is correct learns the system. Design the process so the understanding is mandatory, not optional.
- **Turn ambient osmosis into an explicit curriculum.** The learning that used to seep in through proximity now has to be staged on purpose: rotate juniors through incidents as shadows, put them in design reviews with a real speaking part, hand them a mature system they didn't write and make them explain it, have them defend a decision and get pushed on it. Everything the ticket queue taught by accident, teach on purpose.
- **Make "grows people" a real part of a senior's job, with real time for it.** Mentorship has always been the thing that gets dropped first when the quarter gets tight. That was survivable when apprenticeship happened for free in the background. It isn't anymore. If seniors are the only remaining source of new seniors, their teaching output is a first-class deliverable; it needs protected time and it needs to count at promotion, not sit as an "if there's slack" afterthought.
- **Measure the pipeline, not just the throughput.** You get exactly what you instrument. If the only number on the wall is features shipped, you'll optimize the factory and starve the bench. So track whether you're actually producing seniors: are your juniors taking on harder judgment calls each quarter, or just supervising more agents? One of those is a pipeline. The other is a plateau wearing a productivity costume.

None of this is free, and that's the point. The apprenticeship was never actually free; the cost was just hidden inside work you were paying for anyway. The factory pulled the work out and left the cost exposed. Now you have to fund the training on purpose, as a line item, because the accident that used to fund it is gone.

## Naming it is step one

I want to be honest about where this lands, because I distrust anyone who wraps a genuinely hard, unsolved problem in a bow. **We do not have this figured out.** I don't have a validated playbook for manufacturing senior judgment without the decade of reps that used to make it, and neither does anyone else; the industry is running this experiment live, right now, on the current cohort of juniors.

But "unsolved" is not the same as "hopeless," and it is very much not the same as "ignore it." The most common failure here won't be a bad answer. It'll be never asking the question, because the question is slow and quiet and the quarterly numbers look great while the pipeline silently drains.

So name it. The factory can produce the code. It cannot produce the engineer who knows whether the code is right, and it cannot produce your own replacement. Those we still have to grow. Degrees, bootcamps, and formal apprenticeship schemes were always deliberate; the judgment that got built on the job never was, and now that part has to be **on purpose** too. Start now, because the one input you can't generate on demand is time.

## Go deeper

This is the industry-side treatment of a thesis I keep circling; each of these takes a different cut at it:

- [The On-Ramp Moved](/writing/2026-07-25-breaking-into-software-engineering): the same problem from the entrant's chair. This piece asks where senior judgment comes from as an industry; that one asks how you personally build it now that the on-ramp moved.
- [The Software Factory Hollows the Middle](/writing/2026-07-19-the-software-factory-hollows-the-middle): why the routine middle (and the apprenticeship hidden inside it) is exactly the part getting compressed.
- [Generation Is Cheap, Verification Is Not](/writing/2026-07-25-generation-is-cheap-verification-is-not): why verification is the new scarce skill, which is precisely the skill juniors should apprentice into first.
- [Jevons Paradox for Software](/writing/2026-07-17-jevons-paradox-for-software): the honest accounting on net jobs. The headcount question is open; the composition shift is not.
- [First Principles in the Age of Pattern Machines](/writing/2026-08-23-first-principles-in-the-age-of-pattern-machines): the durable human skill a deliberate apprenticeship has to build.

> Fifth in a series on the industrialization of software engineering. Previous: [First Principles in the Age of Pattern Machines](/writing/2026-08-23-first-principles-in-the-age-of-pattern-machines). Series opener: [The Software Factory Hollows the Middle](/writing/2026-07-19-the-software-factory-hollows-the-middle). Entrant-side companion: [The On-Ramp Moved](/writing/2026-07-25-breaking-into-software-engineering).
