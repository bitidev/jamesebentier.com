# Design: Split #1148 — Heroku → Linode + Kamal

**Date:** 2026-07-18  
**Epic:** [#1148 — Migrate from Heroku to Linode + Kamal](https://github.com/bitidev/jamesebentier.com/issues/1148)  
**Status:** Approved in conversation; pending issue filing

## Goal

Restore production on a Linode host via Kamal, cut public DNS directly to that host, and automate Kamal deploys after a green `main` build — as a sequence of ADLC-sized issues, not one multi-subsystem epic.

## Decisions

| Topic | Choice |
|--------|--------|
| Public traffic | Direct to Linode (Route53 A/AAAA). Retire CloudFront from the live path. |
| Postgres | Kamal accessory on the same Linode. Fresh DB only — **no restore / data migration**. |
| Host provisioning | Manual (outside ADLC). Agents assume a host IP/user and document bootstrap only. |
| Manual ops | You apply secrets, first `kamal setup`/deploy, DNS apply, and GitHub deploy secrets once repo changes land. |
| Decomposition | Thin vertical slices (Approach 1). |

## Out of scope

- Creating the Linode / SSH bootstrap as an implementation issue
- Database restore or Heroku data migration
- Keeping CloudFront or Heroku as a fallback after cutover
- Mega-PRs that span multiple child issues

## Child issues

Parent #1148 remains the epic. Children are real, self-contained units of work (not “Chunk N of Epic” placeholders). Close #1148 when all children are done.

### 1. Kamal baseline + Postgres accessory

**Ready first.**

**ADLC delivers**

- Kamal config for a single Linode host (IP/user via env or documented placeholder)
- Postgres as a Kamal accessory on that host
- App wired for a fresh DB (`db:prepare` / migrate on boot — no restore)
- Secrets pattern (`RAILS_MASTER_KEY`, DB password, etc.) and a short first-deploy runbook

**You do after merge**

- Create Linode, fill secrets, run first `kamal setup` / deploy

**Done when**

- From a clean clone + filled secrets + your Linode, Kamal is the intended deploy path and the app answers on the host (HTTP(S) on the box; public domain optional at this step)

### 2. DNS cutover (Terraform)

**Depends on:** Linode IP known (may be before or after first deploy).

**ADLC delivers**

- Route53 points `jamesebentier.com` (and `www` if used) at the Linode
- CloudFront removed from the live path (deleted or clearly unused)

**You do after merge**

- `terraform apply` / set IP; verify the public hostname

**Done when**

- `terraform plan` matches the intended DNS/CDN state; after apply, the public hostname reaches the Linode app

**Note:** Because Heroku is already down, you may cut DNS by hand as soon as the host serves traffic. This issue still codifies that state in Terraform and removes CloudFront from the managed path.

### 3. CI → Kamal after green `main`

**Depends on:** #1 mergeable/deployable.

**ADLC delivers**

- On `main`, after existing `ci-gate` (or equivalent) succeeds, a deploy job runs Kamal
- Deploy failures are visible in Actions; PRs do not deploy

**You do after merge**

- Add deploy secrets/keys in GitHub

**Done when**

- Merge to green `main` triggers an automated Kamal deploy

### 4. Retire Heroku from Terraform

**Depends on:** Public cutover complete (so Heroku/CloudFront are not load-bearing).

**ADLC delivers**

- Remove Heroku app/addons/config association from Terraform
- Drop Heroku-only assumptions that block a clean Linode teardown (only as needed)

**You do after merge**

- `terraform apply` teardown; cancel Heroku if needed

**Done when**

- Heroku is gone from Terraform state/config; no remaining “must use Heroku” deploy path in-repo

## Ordering & board posture

```text
1 (Ready) → you bring up + optional early DNS
       → 2 (Backlog until Linode IP known)
       → 3 (Backlog until #1 deployable)
       → 4 (Backlog until public cutover)
```

- File four children linked to #1148; update #1148 with this split and links.
- Triage: move **#1** to **Ready**; keep **#2–#4** on **Backlog** with dependency notes.
- Each child is its own full ADLC loop (spec → code → review → merge).

## Success for the epic

Production is served from Linode via Kamal with a fresh Postgres accessory, public DNS points directly at that host, CloudFront/Heroku are retired from the live/managed path, and green `main` deploys via Kamal automatically.
