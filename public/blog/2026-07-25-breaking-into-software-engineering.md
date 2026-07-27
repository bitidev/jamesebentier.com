---
slug: 2026-07-25-breaking-into-software-engineering
title: "The On-Ramp Moved"
description: "The old on-ramp, coasting in as a fast code-typer and absorbing judgment over years of grunt work, is the part AI is compressing. The bar to look competent is higher now, but the ceiling is higher too, and reachable faster. Here's what to build instead of typing speed."
published_at: 2026-07-25
keywords: "breaking into software engineering, junior developer AI, learning to code, engineering judgment, first principles, working with AI, verification, entry level software jobs, career change developer"
image: /logo.png
tags:
- ai
- career
- mentorship
- software-factories
kind: deep_dive
---

# The On-Ramp Moved

For a long time the advice was clean, and it mostly worked: learn to code, get a job. Grind through a CS degree or a bootcamp, get fast at turning tickets into working code, and the industry would hand you a junior seat. From there you'd absorb the real skill, judgment, slowly, over years, by writing a thousand small things and watching a few of them break. The typing got you in the door. The judgment came later, on the company's dime.

That path is closing. Not because the industry stopped hiring, but because the specific rung you used to climb in on, competent routine implementation, is exactly the thing AI is best at and cheapest at. **The part of the job that used to be your on-ramp is the part being automated first.**

I want to be honest with you about that, because a lot of the "learn to code" content still talks like it's 2015. But I don't want to strand you at "it's harder now," because that's both true and useless. The way in changed. So the way you prepare has to change with it. Let me walk you through what actually moved, and then what to build instead.

## Why the on-ramp changed

Here's the mechanism, stripped down, no prior reading required.

For most of software's history, writing code was slow. That slowness was quietly doing work for you that nobody named: it rate-limited the whole profession. Because a human had to type every line, companies needed a lot of hands to produce a normal amount of software, and a good chunk of those hands could be cheap, junior, and still learning. The routine middle of the work (well-specified tickets, glue code, first-draft tests) was both the bulk of the output *and* the training ground. You got paid to produce it, and while you produced it you were quietly learning why the boundaries go where they go.

AI collapsed the cost of exactly that middle. An agent will turn a well-specified ticket into working code in minutes, at a fraction of what it costs a junior to do it over an afternoon. So the economic reason to hire someone *just* to type out routine implementation is evaporating.

Now notice what didn't get cheaper. Deciding what to build. Choosing where the service boundaries go. Knowing that the confident-looking code the model just produced is subtly wrong. Owning the outage at 2 a.m. Those are judgment, and the cost of judgment hasn't moved an inch. **The floor of the profession got automated. The judgment above it did not. And the floor was the thing that used to teach you the judgment.**

That's the squeeze, and it's real: the rung you'd normally stand on to build judgment is the rung being pulled up.

> To be clear about what I'm *not* claiming: I don't think software is a shrinking field, and the net-jobs question is genuinely open. Cheaper software may well mean more software, and more people needed to steer it. My claim is narrower and more certain than that. The specific rung juniors used to enter on is the part getting compressed, so the way in has to change even if the field keeps growing.

## The bar to look competent went up. So did the ceiling.

Here's the quiet thing about the old on-ramp: it let you look competent before you were. You could get fast at typing out patterns you didn't fully understand, ship tickets that mostly worked, and coast on that for a year or two while real understanding caught up in the background. Typing speed was a decent costume for competence.

That costume doesn't fit anymore, because the thing it imitated is now free. **Nobody is impressed that you can produce code, because a machine produces code.** The moment you lean on "I can implement the ticket," you're competing head-on with the cheapest, fastest part of the factory, and that is a race you lose.

So yes, the bar to *look* competent went up. You can't fake it with output volume now. That sounds like bad news, and it's actually the opposite, because here's the flip side: **the stuff that's hard to fake is the stuff that was always the valuable part, and now it's the only thing left that distinguishes you.** Judgment. Reasoning from first principles. Catching the subtle bug. Knowing what's even worth building. Those used to be locked behind years of grunt work you had to grind through before anyone let you near them. They're not locked anymore. You can build them directly, starting now, without permission and without waiting a decade.

That's the reframe I want you to hold onto. The old path let mediocre-but-fast people coast in and *maybe* grow into judgment later. The new path is harder to fake and higher to climb, and the people who build the right skills early get further, faster, than the last generation ever could. The ceiling went up, and it moved closer. You just have to aim at it directly instead of expecting the job to drip-feed it to you.

And be clear about what you're aiming at, because the goal itself moved. Coding speed used to be the proxy for a good engineer; it isn't anymore. The new one is your ability to hold several complex things in your head at once: multi-threading real work, keeping multiple plans, architectures, and systems live in your mind at the same time (because you're directing several streams of machine-produced work now, not hand-typing one), and reading the risk budget of whatever you're touching accurately enough to know where to be careful and where to move fast. Typing is free. Holding the whole system in your head, and knowing what it can afford to get wrong, is not.

Let me get concrete about what to aim at.

## What to build instead of typing speed

This is not a laundry list of frameworks. Frameworks churn; these don't. Build these seven and you're building the part of yourself that AI makes *more* valuable, not less.

### 1. Engineering judgment: knowing what's worth building

The highest-value question on any team is not "how do I build this?" It's "should this exist, and is it the right thing?" A machine will happily build the wrong feature flawlessly. The person who says "wait, that's treating the symptom; the real problem is one layer upstream" is the person who stays valuable.

**How to build it:** stop treating the ticket as the truth. For everything you build, even a toy, force yourself to answer *why* before *how*. Who is this for? What breaks if it doesn't exist? What's the cheapest version that would actually work? Then go read the issues and pull requests on a mature open-source project and watch how the senior maintainers push back on proposals. That back-and-forth *is* judgment, out in the open, for free.

### 2. First-principles thinking

Models are pattern machines. They are extraordinary at "what usually comes next," which means pattern-matching is the first thing they commoditize. Your edge is the opposite skill: reasoning a problem down to its fundamentals and back up again, especially when the situation is new and there is no pattern to match.

**How to build it:** when something works, don't stop at "it works." Ask why, one layer down, and keep going until you hit something you genuinely understand from the ground up. Why does this index make the query fast? What is the database actually doing under there? Build the thing you rely on at least once from scratch: a tiny HTTP server, a little key-value store, a toy interpreter. You don't do it to use it. You do it so the abstraction stops being magic.

### 3. Verification instinct

This is the one I'd bet on hardest. When generation is free, the scarce skill is knowing whether what got generated is actually correct, and that applies to the AI's work *and to your own*. A model's output is fluent whether it's right or wrong; it sounds equally confident when it nails a function and when it hand-waves an architecture. You have to supply the skepticism the tone won't.

**How to build it:** never accept code you can't explain, yours or the machine's. If a model hands you a diff, make yourself narrate what every line does and why before it goes anywhere near `main`. Learn to write tests that check reality, not just restate your own assumptions. Get in the habit of asking "how would I know if this were wrong?" about everything, including your own reasoning. The person who catches the subtle bug is worth ten people who produce subtle bugs quickly.

### 4. Fluency working WITH AI, as the one in charge

The last generation broke in by being the hands. You break in by being the head: the one who directs the tools, edits their output, and owns the result. That is a real skill, and it is not the same thing as "using ChatGPT." It's knowing how to frame a problem so a model can actually help, how to keep it constrained enough to be reliable, and where its output stops being trustworthy so you know where to look hardest.

**How to build it:** use AI on everything, but never as an oracle. Use it as a fast, tireless, slightly unreliable junior partner that you supervise. Watch where it's brilliant (concrete, bounded, checkable tasks) and where it quietly falls apart (open, abstract, judgment-heavy ones), and calibrate how hard you check to match. The goal isn't to produce more. It's to become the person who can steer the machine and then stand behind whatever comes out of it.

### 5. System thinking, in parallel

Any one change is easy now. Understanding how a change ripples through a system that no single human fully holds in their head is not. And you rarely hold just one system anymore; when you're steering several streams of machine-produced work at once, the real feat is keeping multiple plans and architectures live in your head in parallel, without dropping the thread of any of them. The value lives at the seams: how services talk to each other, where the data lives, what happens under load, what breaks three systems over when you touch this one. That's where the expensive mistakes hide, and it's where the machine is weakest.

**How to build it:** whenever you learn a piece, immediately ask what it connects to. Don't just make the request work; trace it end to end, from the browser to the database and back, and name every hop along the way. Draw the system on paper before you touch it. Practice holding two or three of these mental maps at once, because that is what directing several agents actually feels like. And read a system you didn't write, because that's most of the actual job: follow the data, not just the code.

### 6. Reading the risk budget

Not every project deserves the same caution, and treating them as if they do is its own kind of failure. A marketing page and a payments flow sit at opposite ends of a risk spectrum: one can break and be fixed in five minutes, the other can lose money or trust you never win back. The skill is reading, quickly and accurately, how much a given piece of work can afford to get wrong, and then dialing your rigor to match. Move fast where mistakes are cheap and reversible; slow down and guard hard where they aren't. Uniform caution is just slowness; uniform recklessness is just a time bomb.

**How to build it:** for everything you touch, ask two questions before you start. If this breaks, what does it cost? And can I undo it cheaply? High cost or hard to reverse (money, data, security, safety) earns more tests, more review, and a slower rollout. Cheap and reversible earns "ship it and move on." Spending your caution where it actually matters, on purpose, is a skill, and it's one most engineers never make explicit. Make it explicit early.

### 7. The durable human skills, and fighting for yourself

I wrote a piece years ago on the thing nobody teaches you: being a good programmer is not enough to have a good career. That was true then, and it's more true now, because the purely-technical floor is exactly what got automated. Communicating clearly, writing well, working with people, and advocating for your own growth are not "soft" extras. They are the part of the job that is most durably, unavoidably human.

**How to build it:** practice explaining technical things to people who aren't technical; if you can't explain it simply, you don't understand it yet. Write. A blog, a README, a design doc, anything that forces you to organize a thought for a reader. And learn early to advocate for yourself, because no one else will do it for you. Set goals, ask directly where your gaps are, and treat feedback that you're "not ready" as a map, not a verdict. The engineer who can build judgment *and* make it legible to other people is the one who gets trusted with the decisions worth having.

## The door didn't close. It moved.

Here's the whole thing in one breath: the part of the job you used to break in on, competent typing, is the part getting automated, so you can't coast in as a code-typer anymore; you have to build judgment, first-principles reasoning, a verification instinct, fluency directing the machine, system thinking in parallel, a feel for the risk budget, and the human skills, directly and early, instead of waiting for years of grunt work to hand them to you.

That's a harder ask than the last generation got, and I'm not going to pretend it isn't. But it's a better deal than it sounds, because the ceiling moved closer. You don't have to spend three years proving you can type before anyone lets you think. You can start building the valuable part today, on your own projects, using the same AI tools that compressed the floor to now compress your learning curve.

The bottom rung is automated. So climb a different way. Build the head, not just the hands, and aim straight at the work the machine can't do.

## Go deeper

This piece stands on its own, but each of these takes one thread of it a level deeper:

- [The Software Factory Hollows the Middle](/writing/2026-07-19-the-software-factory-hollows-the-middle): why value is migrating away from the routine middle of the profession, and where it's going instead.
- [Generation Is Cheap, Verification Is Not](/writing/2026-07-25-generation-is-cheap-verification-is-not): why verifying, not producing, is the real bottleneck now, which is why your verification instinct is worth so much.
- [Trust but Verify: AI on Concrete vs. Abstract Work](/writing/2026-07-09-trust-but-verify-concrete-vs-abstract-ai): where AI is genuinely reliable and where it quietly isn't, so you know how hard to check its work.
- [Your AI Is Only as Smart as Your Data Structures](/writing/2026-07-06-your-ai-is-only-as-smart-as-your-data-structures): why the substrate you hand a model sets its ceiling; a system-thinking lens on working with AI.
- [Risk-Tolerance-Driven ADLC: Teach the Factory to Assess Risk](/writing/2026-07-23-risk-tolerance-driven-adlc): how to read the risk budget of a project and dial your rigor to match it.
- [Kinetic Tests vs. Logical Simulation](/writing/2026-07-11-kinetic-tests-vs-logical-simulation): how to write tests that check reality instead of just confirming your own assumptions.
