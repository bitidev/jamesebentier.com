# P1.11 — Legal: Impressum + privacy policy (#1190)

## Problem

The site is operated from Berlin. Two legal obligations are currently unmet:

1. **Impressum (§ 5 DDG, formerly § 5 TMG).** German law requires any commercial /
   business-facing website (this is a professional services site) to carry a reachable
   *Impressum* — provider identification: legal name, physical address, and a means of
   fast electronic contact. Missing/incomplete Impressum is *abmahnfähig* (subject to
   cease-and-desist). There is no `/impressum` route or page today; the footer partial
   (`_footer.html.erb`) explicitly notes it omitted the Impressum link because no page
   existed to link to.

2. **Privacy policy (GDPR Art. 13 + TTDSG/TDDDG).** `/privacy` exists but is an explicit
   **placeholder** — its body opens "This page is a placeholder." It already describes the
   newsletter and analytics data accurately, but it is not structured as a real Art. 13
   notice (no controller identity, no legal bases, no retention, no data-subject rights,
   no supervisory-authority complaint right).

Both P1.7 (newsletter, `#1222`) and P1.9 (first-party analytics, `#1225`) already shipped,
so their data flows are known and must be reflected accurately.

## What the code actually collects (ground truth for the policy)

- **Newsletter** (`Subscriber` model): `email`; `consent_at`; `consent_source` (which page);
  `ip_hash` — a **one-way SHA-256 digest** of the IP + a secret pepper (raw IP never stored);
  `confirmation_token`, `confirmed_at`, `unsubscribed_at`. Double opt-in; stored in our own
  Postgres, **no third-party ESP**. No email sent until confirmed. Unsubscribe link in every email.
- **Analytics** (`PageView` model, `#1188`): `path`, `referrer`, optional `utm_source/medium/campaign`,
  `recorded_at`, `visitor_type` (human/bot). **Cookieless**, no per-visitor IDs, no raw IP,
  own Postgres, no third-party trackers.
- **Client storage:** exactly one `localStorage` key — `theme` (light/dark preference). Strictly
  functional, no tracking, no cookies used for analytics or advertising.
- **Server logs:** standard Rails request logs (transient, operational).

## Chosen approach

Mirror the existing terminal-identity page pattern (same as `about.html.erb` /
`privacy.html.erb`: `set_meta_tags`, mono headings, `prose` body, narrow reading column).

1. **`/impressum`** — new route `get "impressum" => "welcome#impressum"`, empty `#impressum`
   controller action (view-only, like `#privacy`), new `app/views/welcome/impressum.html.erb`.
   Contains the § 5 DDG disclosures. **The real legal identity (address, contact, VAT/USt-IdNr.
   if any, professional/regulatory info) is owner-supplied** — see Open questions. The view
   uses clearly-marked placeholders until the owner provides final values, so nothing false
   is published.
2. **`/privacy`** — rewrite `privacy.html.erb` from placeholder into a proper GDPR Art. 13
   notice: controller identity (points at the Impressum), what's collected + legal basis +
   retention for newsletter / analytics / theme storage / server logs, third parties (hosting;
   none for tracking), data-subject rights (access/rectification/erasure/restriction/portability/
   objection/withdraw consent), right to lodge a complaint with a supervisory authority
   (Berliner Beauftragte für Datenschutz und Informationsfreiheit), and a "last updated" date.
   Keep the factual newsletter/analytics descriptions already present — they're correct.
3. **Footer** — add an `Impressum` link next to the existing `Privacy` link in
   `_footer.html.erb`, and remove the now-stale code comment explaining its omission.

No new gems, models, migrations, or JS. Content-and-routing only.

## Acceptance criteria

- `GET /impressum` returns 200 and renders the Impressum with § 5 DDG fields (owner identity
  as clearly-marked placeholders where real data is pending).
- `GET /privacy` renders a structured Art. 13 policy covering newsletter, analytics, theme
  localStorage, and server logs — with legal basis, retention, rights, and complaint right —
  and no longer says "placeholder."
- Footer links to **both** `/impressum` and `/privacy`; the stale omission comment is gone.
- Request specs cover 200 + key content for both pages; the footer link is asserted.
- Copy is reviewable by the owner against current GDPR/TTDSG/Impressum needs before it's
  treated as legally final (Manual ops in the issue).

## Open questions (need owner input)

1. **Impressum identity** — I cannot fabricate these. What should be published for:
   legal name, physical address (an Impressum legally requires a reachable postal address —
   a PO box is generally insufficient), contact email/phone? Is there a **USt-IdNr. (VAT ID)**?
   Any regulated-profession disclosures? → Ship with clearly-marked `[[ placeholder ]]`
   values and a note, or wait for real values before merging?
2. **Professional review** — the issue's Manual ops suggests considering professional legal
   review. Treat this PR's copy as a solid, accurate draft pending the owner's (optional)
   lawyer review, not as certified-final.
3. **Supervisory authority** — assume Berlin (Berliner BfDI) as the competent authority for
   the complaint-right line? (Yes unless the owner says otherwise.)
