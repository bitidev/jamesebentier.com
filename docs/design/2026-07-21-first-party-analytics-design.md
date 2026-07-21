# P1.9 — First-party analytics + retire GA/Metricool

> **Status:** Approved · **Issue:** [#1188](https://github.com/bitidev/jamesebentier.com/issues/1188) · **Parent:** Phase 1 epic (#1179), `docs/design/redesign-2026.md` §6.5

## Problem

Production layout loads Google Analytics (`G-TWP4CV64DK`) and Metricool — third-party
beacons that send visitor data off-site. The redesign commits to **first-party, Postgres-backed,
cookieless** metrics queryable through the existing COMMAND layer (P1.8 / #1187).

## Chosen approach

### 1. Remove third-party analytics

Delete the Metricool + gtag blocks from `app/views/layouts/application.html.erb`
(`Rails.env.production?` gate goes away with the snippets). Update architecture/docs references.

### 2. Event storage — `PageView` model

New `analytics` subsystem table via `declare_schema`:

| Column | Purpose |
|--------|---------|
| `path` | Request path (e.g. `/writing/foo`) |
| `referrer` | `HTTP_REFERER` host+path, truncated; blank allowed |
| `utm_source`, `utm_medium`, `utm_campaign` | From query string when present |
| `recorded_at` | Event timestamp (default `Time.current`) |
| `visitor_type` | `human` or `bot` — UA-based bot detection at ingest |

No cookies, no client IDs, no raw IP. Index on `(recorded_at)` and `(path, recorded_at)` for
range/top-N queries. **Track all traffic**; label bots at write time so stats can split or
filter human vs bot.

**Capture paths:**

1. **Full page loads** — `Analytics::PageViewRecorder` called from an
   `after_action` on `ApplicationController` (skip XHR/Turbo-frame requests, health check,
   `/newsletter`, `/up`, assets).
2. **Turbo Drive visits** — tiny Stimulus controller (`analytics_visit_controller`) on
   `<body>` listens for `turbo:load`, `POST`s JSON to `POST /analytics/page_views` with
   `path` + `document.referrer` (still cookieless; CSRF token from meta). Same recorder
   service dedupes same-path-same-second if needed.

UTM params captured on the **initial** full request only (Turbo navigations won't re-send
UTMs — acceptable for v1).

### 3. COMMAND-layer queries (P1.8 extension)

Add a `stats` command to `COMMAND_REGISTRY` with subcommand parsing in `run(args, context)`:

| Invocation | Behavior |
|------------|----------|
| `:stats views --last 7d` | Total page views in window (default 7d if `--last` omitted) |
| `:stats top posts --last 30d` | Top writing paths by view count |
| `:stats referrers --last 7d` | Top referrers (excluding blank) |

Output via existing `commandFeedback` row (tabular text, not a new UI). Parse `--last Nd`
with a simple regex (`7d`, `30d`, `24h`).

**Scope (v1):** stats are **public** — any visitor in COMMAND mode can run them (“build in
public” per §6.5). Owner-only gating waits for identity/OIDC (Phase 2). No secrets in
responses (aggregates only).

Guide dialog (`?` / `:help`) picks up new commands automatically via `COMMAND_REGISTRY`.

### 4. Privacy / GDPR posture

Cookieless server-side + sessionless aggregates minimize consent-banner need; `/privacy`
stub already notes analytics will be detailed in P1.11 (#1190). This issue adds one sentence
there linking to first-party page-view logging (no third-party trackers).

## Acceptance criteria

- GA + Metricool snippets removed from layout.
- Page views recorded in Postgres on full loads and Turbo navigations.
- At least `:stats views --last 7d` works in COMMAND mode with real data.
- `:stats top posts` and `:stats referrers` implemented (issue ADLC list).
- Model + request specs; command unit tests; no theatre.

## Out of scope (v1)

- Dashboard UI, charts, or public `/stats` page
- Bot filtering beyond skipping obvious non-HTML requests
- Owner-only / auth-gated stats
- Real-time streaming, sampling, or retention TTL jobs

## Decisions (operator)

1. **Traffic:** record everything; label bot UA as `visitor_type: bot`, else `human`.
2. **Turbo beacon:** yes — Stimulus + `POST /analytics/page_views`.
3. **Public stats:** yes — COMMAND-mode aggregates for all visitors.
