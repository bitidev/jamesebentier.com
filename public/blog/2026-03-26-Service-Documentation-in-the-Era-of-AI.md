---
slug: 2026-03-26-service-documentation-in-the-era-of-ai
title: Service Documentation in the Era of AI
description: We are witnessing a fundamental shift in the "User" of our documentation, let's embrace it!
published_at: 2026-03-26
keywords: coding agents, technical documentation, software development, ADR, MADR, AI
image: /logo.png
tags:
- coding-agents
- technical-documentation
- software-development
kind: deep_dive
medium_url: https://engineering.invoca.com/service-documentation-in-the-era-of-ai-f81e2ebc418d
---

*Originally published on the [Invoca Engineering Blog](https://engineering.invoca.com/service-documentation-in-the-era-of-ai-f81e2ebc418d).*

We are witnessing a fundamental shift in the "User" of our documentation. For decades, we wrote for the junior dev or the frantic on-call engineer. Today, our primary consumers are IDE-based LLMs (Cursor, Copilot), Terminal Agents (Claude Code), and CI-level Automations.

The "Confluence-First" era is officially over. If your service's soul is trapped in a browser tab instead of your repository, your AI tools are effectively working with a lobotomy. To win in this era, we must move the "brain" of the service back into the repo.

## Documentation as a "System Prompt"

The future of engineering is Agentic. We aren't just using autocomplete; we are using agents that can refactor entire modules, hunt for security vulnerabilities, and automate PR reviews.

However, an agent's intelligence is capped by its context window. When your documentation lives in Confluence, it is "invisible" to the agentic loop. By moving documentation into the repository, you transform it into a permanent system prompt. You are giving the AI the "Why" and the "How" alongside the code, allowing it to reason with the same context as the lead architect.

Note: we put "invisible" in quotes due to the fact that, yes, you technically can expose Confluence documentation via MCP and with exact prompting ensure the agent will search Confluence for additional context. But this comes with the following huge assumptions: all agents will have this MCP installed and configured, their prompts will be properly configured, and there will be a strong enough connection between the service repo and its Confluence documentation for the agent to find them relevant.

## The Triad of Truth

To realize this vision, we must be disciplined about where information lives based on its purpose and mutability.

### 1. The Immutable History: ADRs and the MADR Standard

**Location:** `docs/adrs/`  
**Format:** Markdown Architecture Decision Records (MADR)  
**The Rule:** If a decision changes the "DNA" of the service, it requires an ADR.

The most common mistake in service documentation is trying to keep one giant "Architecture" file up to date. As systems evolve, the "why" gets lost in the "what."

Using the MADR (Markdown Architecture Decision Record) format ensures that when a tool like Claude Code analyzes your repo, it sees a chronological log of why things are the way they are. It won't suggest a refactor that violates a decision you made six months ago because that decision is part of its indexed context.

Most teams struggle with when to write an ADR. We must adopt a prescriptive "Trigger List." You write an ADR when:

- You introduce a new library or framework.
- You change the data schema or persistence strategy.
- You make a trade-off (e.g., "Choosing Latency over Consistency").
- You define a communication pattern (Sync vs. Async).

### 2. The Living Service Manual: Mutable Docs

**Location:** `docs/` (Usage, Development, API)  
**Format:** Markdown  
**The Rule:** If it describes how to use or develop the current code, it stays with the code.

A service's documentation covers both its history and its present state. Specifically, while Architecture Decision Records (ADRs), a key subset of the documentation, explain why the service is structured the way it is, the remainder of the `docs/` folder dictates how to maintain and operate the service going forward. This is the mutable layer, it should always reflect the current state of the main branch.

- **Usage Docs:** How to consume this service? (Endpoints, Events, Client SDKs).
- **Dev Docs:** How to run it locally? How do the internal modules interact?

Currently, we bury most, if not all, this important context in Confluence. This is a failure of discovery.

- **For IDE Agents:** When you open a file, tools like Copilot index adjacent Markdown files. If your "Service Auth Flow" is in `docs/auth.md`, the AI can explain the code to you. If it's in Confluence, the AI will guess.
- **For CI Agents:** Security and linting agents can cross-reference your documentation against your implementation. If your docs say "We use AES-256" but your code uses "MD5," an agent can flag that discrepancy during a PR.

### 3. The Shared Context: Confluence

**Location:** Central Wiki (Confluence)  
**Format:** Rich Text / Collaborative  
**The Rule:** If the code doesn't care about it, it goes here.

There is a temptation to "put everything in the repo." This is a mistake. Repositories should contain documentation that is coupled to the code. Confluence (or your central wiki) is for documentation that spans across services, organizations, and business units:

- **Cross-team dependencies:** How does the "Checkout" service fit into the "2025 Payments Initiative"?
- **Business Logic/Product Vision:** Why does this feature exist for the customer?
- **Roadmaps:** When are we sunsetting this version?
- **Compliance:** Legal sign-offs and SOC2 audit trails.
- **Organizational Alignment:** Onboarding guides for the whole department, security compliance policies, and meeting minutes.

AI agents operating at the IDE level (Copilot) care about the repo. AI agents operating at the Manager/Director level (Enterprise AI) care about the Confluence data. Keeping them separate ensures that your repository remains a lean, technical source of truth, while Confluence remains the accessible bridge for non-technical stakeholders.

## "In-Repo" is the Only Way Forward

Moving away from Confluence for technical documentation isn't just about convenience; it's about Discovery and Versioning.

1. **Atomic Changes:** When you change a feature, you update the code and the documentation in the same commit. The documentation is never "out of date" because it evolves with the logic.
2. **Zero-Latency Context:** When an agent clones your repo to fix a bug, it has 100% of the knowledge required to solve the problem without ever leaving the terminal.
3. **Governance through Linting:** We can now write scripts (or use AI) to "lint" our docs. We can ensure every new service has a `docs/adrs/0001-record-architecture-decisions.md` before it ever hits production.

## Conclusion

The era of "browsing the wiki" to understand a service is a relic of the past. The future belongs to teams who treat their documentation as a high-fidelity input for their AI coworkers.

Our mandate is clear: Stop documenting for the archive. Start documenting for the agent. Move your technical soul into the repo, adopt the MADR standard, and give your AI tools the context they deserve.

## Sources and Further Reading

- [Context Engineering for AI Agents in OSS](https://engineering.invoca.com/service-documentation-in-the-era-of-ai-f81e2ebc418d) — Research highlights that "Context Engineering" (the deliberate structuring of repo info) is the primary way to reduce hallucinations in tools like Claude Code and GitHub Agentic Workflows.
- [AGENTS.md is the New ADR](https://engineering.invoca.com/service-documentation-in-the-era-of-ai-f81e2ebc418d) — Discusses the move of context from ADRs to `AGENTS.md` to assist in the knowledge (or context) transfer to AI Agents, and reinforcing best practices and past knowledge to move them forward.
- [Vibe ADR: Building with Intention in the Age of AI](https://engineering.invoca.com/service-documentation-in-the-era-of-ai-f81e2ebc418d) — Shares the experience of using AI Agents to produce code and leave documentation and humans to produce intent. Documentation, and ADRs specifically, are that intent.
