# Strategic Priorities — Personal ADLC Capacity Building

> This document is the project's strategic-fit reference. The product agent reads it at the start of every triage cycle to evaluate issues for strategic fit and to decide Ready vs. Needs Info vs. Backlog vs. Won't Do. Keep it current — a stale priorities doc produces stale triage decisions.

---

## Current Priority

Use ADLC as the default way of working on this repo, and learn its real operating envelope.

Trust in the process is already established — ADLC is the intended workflow, not an experiment to validate. The work now is **capability discovery**: run real issues through the full loop and learn, with evidence, what size of change the system handles cleanly and how much ambiguity it can absorb before specs, reviews, or outcomes degrade.

Prefer issues that teach something about that envelope (scope size, ambiguity, cross-subsystem blast radius, review load) over issues chosen only for product urgency or raw throughput.

---

## In Focus

Ready candidates exercise ADLC while expanding comfort with size and ambiguity:

- Issues that deliberately vary **size** — from small, single-subsystem fixes up through medium, multi-file changes — so capacity limits become clear
- Issues that deliberately vary **ambiguity** — some with crisp acceptance criteria, some that require the scribe/architect loop to sharpen vague intent — so ambiguity tolerance becomes clear
- Work that completes the full ADLC loop (triage → spec → code → review → merge) on **this** repo’s board
- Process clarity that improves *this* personal ADLC setup: `adlc-customizations/`, local docs, machine/setup notes — never upstream framework contribution
- Site work (blog, projects, resume, Rails/Hotwire presentation) that is still reviewable in one sitting at the chosen size tier

## Out of Focus (Backlog)

Valid work that is deferred until the size/ambiguity envelope is better understood:

- Large, multi-subsystem epics whose diffs cannot be meaningfully reviewed in one sitting
- High-ambiguity greenfield product directions that need a settled capacity baseline first
- Pure throughput pushes that skip learning about ADLC’s limits

---

## Won't Do Criteria

Categories of request that are out of scope for this project regardless of quality or effort. Issues matching these criteria are candidates for **Won't Do**, closed with an explanation referencing the specific criterion.

- Duplicates of an issue already tracked or already closed
- Requests out of scope for this repo (not about jamesebentier.com / its ADLC working method)
- **Upstream / jb-brown isolation (hard)** — anything that contributes to, syncs with, files issues/PRs against, pushes to, or otherwise updates:
  - `jb-brown/*` GitHub accounts or orgs
  - `Invoca-ADLC`, public `adlc` mirrors maintained by others, or any upstream ADLC framework remote
  - The live `adlc/` symlink checkout when the intent is to send changes back upstream
- Telemetry, usage reporting, or “report this to the framework author” style feedback loops aimed at upstream ADLC maintainers
- Evolving ADLC for anyone other than this personal-project fork — framework changes stay local / personally owned remotes only

---

## Operating Posture (ADLC Isolation)

This installation is a **personal fork of practice**: testing and evolving ADLC for personal projects only.

- GitHub work (issues, PRs, project board) stays on `bitidev/jamesebentier.com` (and later other personal remotes you own)
- Framework method edits, if any, stay in a personally owned ADLC clone/remote — never upstreamed to jb-brown
- Agents must follow `adlc-customizations/*` quarantine rules that reinforce this Won't Do

---

## As Capacity Is Learned

When size and ambiguity limits are understood in practice, update this doc:

- Record what sizes / ambiguity levels are Ready vs Backlog by default
- Layer in product-facing site priorities (content, UX, infra) atop the capacity baseline
- Keep the upstream-isolation Won't Do permanent unless you explicitly rewrite this section

---

## Last Updated

2026-07-16 — jebentier — ADLC trusted as default workflow; priority shifted to size/ambiguity capacity discovery; hard isolation from jb-brown / upstream ADLC
