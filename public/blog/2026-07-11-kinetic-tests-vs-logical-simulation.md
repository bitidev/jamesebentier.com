---
slug: 2026-07-11-kinetic-tests-vs-logical-simulation
title: "Kinetic Tests vs. Logical Simulation"
description: "Kinetic tests exercise the real thing; logical simulation only verifies your model of it. As AI floods us with mock-heavy tests, don't let simulation quietly replace the tests that touch reality."
published_at: 2026-07-11
keywords: "kinetic testing, integration testing, mocks, simulation, test strategy, AI-generated tests"
image: /logo.png
tags:
- research
- ai
- testing
- software-factories
- quality
kind: note
---

# Kinetic Tests vs. Logical Simulation

A **kinetic test** exercises the real thing: the actual integration, the real dependency, the deployment path, real (or realistic) data flowing through the actual code. A **logical simulation test** verifies your *model* of the world: mocks, stubs, fakes, pure-logic unit assertions against assumptions you encoded. Both matter, but they prove different things. Simulation proves internal consistency with your assumptions. Kinetic proves contact with reality. Simulation must never be allowed to replace kinetic verification, and the AI era makes that substitution dangerously tempting.

## The two verify different universes

A logical test passes when the code agrees with your model. A kinetic test passes when the code agrees with the world. The gap between those two is exactly where outages live: integration drift, contract mismatches, environment differences, real-data edge cases, timing and concurrency. You do not find those by asserting harder against a fake.

## The AI-era failure mode is "green tests, red world"

Agents are very good at generating mock-heavy tests that pass. A factory can produce thousands of tests that assert against fabricated fixtures and never touch a real boundary, manufacturing false confidence at scale. The suite is green; the system is broken in production. That is the verification gap wearing a lab coat.

And simulation reproduces your blind spots uniformly. If your mental model is wrong, every simulated test encodes the same wrong assumption, and the factory copies it across the codebase. Kinetic tests are how you find out your model was wrong, because reality does not read your mocks.

## This is not anti-simulation

Logical and unit tests are fast, cheap, and correct for pure logic; they belong at the base of the pyramid. The point is proportion. The pyramid still needs a real top. When speed pressure (or an agent optimizing for a green bar) erodes the kinetic layer, the suite stops meaning anything, and you are left trusting a number that no longer measures whether the thing works.

The higher the blast radius of a change, the more its verification must be kinetic rather than simulated. Cheap, reversible surfaces can lean on fast simulation; the parts that can hurt you have to be exercised for real.
