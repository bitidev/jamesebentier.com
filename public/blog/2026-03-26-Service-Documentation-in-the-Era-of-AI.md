---
slug: 2026-03-26-service-documentation-in-the-era-of-ai
title: Service Documentation in the Era of AI
description: We are witnessing a fundamental shift in the "User" of our documentation — move the service brain into the repo for AI agents.
published_at: 2026-03-26
keywords: documentation, AI agents, ADR, MADR, confluence, technical writing
image: /logo.png
tags:
- documentation
- ai-agents
- software-development
kind: deep_dive
medium_url: https://engineering.invoca.com/service-documentation-in-the-era-of-ai-f81e2ebc418d
---

*Originally published on the [Invoca Engineering Blog](https://engineering.invoca.com/service-documentation-in-the-era-of-ai-f81e2ebc418d).*

We are witnessing a fundamental shift in software engineering, and it centers on a deceptively simple question: **who is the user of your documentation?**

For most of software history, the answer was obvious — other humans. Developers read READMEs, architects consulted Confluence pages, and oncall engineers skimmed runbooks. Documentation was written for people, reviewed by people, and decayed in proportion to how often people actually opened it.

That assumption is breaking down. AI coding assistants and autonomous agents are becoming first-class consumers of service documentation. They parse your ADRs, your architecture diagrams, your runbooks — and they act on what they find. A missing context document isn't just a gap for a new hire; it's a blank space where an AI agent will hallucinate plausible-sounding but wrong behavior.

The implication is significant: **the quality of your documentation is now part of the quality of your engineering system.**

---

## Documentation as System Prompt

The most useful mental model shift is to think of your service's documentation as its system prompt for AI agents. A system prompt defines what the agent knows, what constraints it operates under, and what decisions it's already made. When an agent opens a pull request, refactors a module, or investigates an incident, it is drawing on exactly that context.

This means documentation has a new quality criterion beyond "is it accurate?" — it must be **machine-parseable, structurally consistent, and co-located with the code it describes**. An 80-page Confluence page written in narrative prose may serve a senior architect reading it on a Tuesday afternoon. It will fail an AI agent that needs to know in 500 tokens whether this service owns its own database or shares one with a monolith.

The shift is less about adding AI-specific documents and more about being precise and structural in the documentation you were already writing.

---

## The Triad of Truth: ADRs, MADR, and the Architecture Overview

Three artifact types form the backbone of machine-useful service documentation:

**Architecture Decision Records (ADRs)** capture *why* the system is built the way it is — specifically the decisions that were consciously made and the alternatives that were rejected. For AI agents, ADRs answer the question "is this a known design choice or a bug?" An agent that encounters a surprising pattern without a corresponding ADR has no signal either way. An agent that finds an ADR explaining "we chose denormalization here because reads are 1000x more common than writes, and the join cost was measurable in production" knows not to refactor it away.

**MADR (Markdown Any Decision Record)** is a lightweight ADR format that stores decisions as Markdown files in the repository itself — typically under `docs/decisions/` or `docs/adr/`. Unlike wiki-based ADRs, MADR files travel with the code, appear in pull request diffs, and are as natural to grep as source files. For AI agents operating inside a git worktree, MADR files are the most accessible form of recorded design intent.

**The Architecture Overview** is a living index of what subsystems exist, what each owns, and how they depend on each other. The critical property is that it must be **maintained in the same commit as the code changes it describes** — not as a follow-up, not "when we get to it." An architecture overview that lags the codebase by two weeks is worse than no overview, because it actively misleads anyone (human or agent) who reads it.

---

## The Living Service Manual

Beyond decisions, AI agents benefit from a structured service manual — the operational context that would otherwise live only in the heads of experienced engineers:

- **What does this service do, in one paragraph?** Not the mission statement. The actual behavior: what it consumes, what it produces, and what breaks if it goes down.
- **What are the known failure modes?** Not an exhaustive list — the top three or four patterns that recur in incidents, with what to look for.
- **What are the runbooks for the most common operations?** Deployment, rollback, feature flag management, database maintenance windows.
- **What are the performance and scale characteristics?** P99 latency targets, expected QPS, known hot paths.

The Living Service Manual doesn't need to be a single document. It needs to be discoverable from the root of the repository — linked from the README, co-located in `docs/`, and structured so that an agent starting from `git ls-files docs/` can find the right file for the right question.

---

## Shared Context and the Confluence Problem

Confluence, Notion, and similar wiki tools are optimized for human discovery — they have search, navigation, spaces, and permissions. They are poor contexts for AI agents: they are not in the repository, they are not versioned with the code, and their content structure is optimized for readability rather than machine parsing.

This does not mean abandon Confluence. It means recognize the distinction between **reference documentation** (stable, human-authored, suitable for wiki) and **operational context** (frequently updated, code-adjacent, must be in-repo). Architecture decision records, service manuals, and runbooks belong in the repository. Product specifications, roadmaps, and team policies can stay in the wiki.

The test: if the document would help an AI agent understand a pull request or diagnose an incident, it belongs in the repository. If it would help a product manager understand a feature prioritization, it belongs in the wiki.

---

## Move the Service Brain into the Repository

The practical recommendation is simple to state and requires sustained discipline to execute:

1. **Every significant design decision gets a MADR file.** Not a Jira comment, not a Slack thread, not a Confluence page — a Markdown file in `docs/decisions/` that travels with the code.

2. **The architecture overview is a first-class artifact.** It is updated in the same commit as every file add, rename, and delete. It is reviewed at PR time. It is never allowed to lag.

3. **The README is a map, not a description.** It tells agents (and people) where to find the detailed context: the architecture overview, the service manual, the runbook index, the decision log.

4. **Runbooks are tested.** The best runbook is one that was used in a real incident and updated afterward. An untested runbook is documentation debt.

5. **Documentation drift is a bug.** When an agent (or a new team member) acts on stale documentation and produces a wrong output, the root cause is a documentation bug, not a human or agent error. Treat it as such.

---

## Sources

- [IndieWeb POSSE](https://indieweb.org/POSSE)
- [MADR — Markdown Architectural Decision Records](https://adr.github.io/madr/)
- [Michael Nygard — Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
- [RFC 2119 — Key words for use in RFCs](https://www.rfc-editor.org/rfc/rfc2119)
