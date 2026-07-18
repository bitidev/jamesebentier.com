# rails-runtime

> Per-subsystem deep-dive. Linked from [`docs/architecture/overview.md`](../overview.md).

---

## Purpose

Provide the shared Rails controller base (`ApplicationController`) with production URL defaults and sitemap `noindex?` hooks that all web controllers inherit.

---

## Anchor Files

- `app/controllers/application_controller.rb` — Base controller; `default_url_options` for production host `jamesebentier.com`; class-level `noindex?`

---

## Public Contract

- **Exports**: `ApplicationController` — all controllers inherit; override `self.noindex?` to exclude from sitemap
- **Exports**: `ApplicationController#default_url_options` — production host injection for URL helpers

---

## Key Invariants

- Controllers that should be excluded from the auto-generated sitemap override `self.noindex?` to return `true`.
- Production URL generation always uses host `jamesebentier.com` (see `default_url_options`).

## Security Posture

- **Trust boundary**: Process boundary of the Rails app. Trusts Rails request/session primitives; does not authenticate users (public marketing site).
- **Sensitive data handled**: none in this subsystem today (no auth, no credentials in controller bases).
- **Log hygiene**: Uses Rails default logging. Never log credentials or secrets if added later.
- **Encryption posture**: HTTPS enforced at infrastructure (CloudFront/Heroku); no at-rest crypto in this layer.
- **Known risks**: None specific beyond inheriting Rails defaults.

---

## State Owned

- None persisted. Owns request-wide URL option defaults only.

---

## Dependencies

- None (leaf/framework-facing subsystem).

---

## Known Limitations

- No authentication/authorization layer — intentional for a public personal site.
- `lib/assets` and `lib/tasks` keepfiles are cataloged here as Rails scaffold placeholders, not active code.

---

## Last Hardened

_none yet_

---

## Hardening History

| Date | Commit | Bugs Found | Bugs Fixed | Theatre Tests | Pyramid Migrations | Notes |
|------|--------|------------|------------|---------------|---------------------|-------|
| _none yet_ | | | | | | |

---

## Key Design Notes

- Sitemap generation in `config/sitemap.rb` reflects on `ApplicationController.descendants` and `ApplicationRecord.descendants`, honoring `noindex?` — keep that class method available on both bases.
- Jobs, mailers, and Action Cable live under web-presentation as presentation/delivery scaffolds.
