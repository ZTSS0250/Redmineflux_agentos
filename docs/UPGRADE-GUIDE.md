# Upgrade Guide — redmineflux_agentos

**Status**: Operational runbook, not a design document — see [docs/DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md)'s status note; both were proposed and approved together as part of `rao-021` (Phase 16, Enterprise Readiness) per the Documentation Updates process (`rao-008` §14).
**Audience**: whoever upgrades an existing AgentOS installation to a newer plugin version.

---

## 1. General upgrade procedure

```bash
cd redmine/plugins/redmineflux_agentos
git fetch
git checkout <target-tag-or-branch>
cd ../..
bundle install
bin/rails redmine:plugins:migrate RAILS_ENV=production
sudo systemctl restart redmine
```

Always back up the database before running migrations on a production instance — standard Redmine plugin upgrade practice, not AgentOS-specific.

## 2. Version-to-version notes

This is the first version of the plugin (`0.0.1`, still pre-release as of `rao-021` — see this ticket's own `Done` section: "Not applicable until this ticket is actually implemented and tested against a running Redmine instance"). There is no prior version to upgrade *from* yet. This section exists now, structured the same way `RELEASE_NOTES.md` is, so the first real version bump has a place to record what changed:

| From | To | Notes |
|---|---|---|
| — | — | (nothing yet — first release) |

## 3. Configuration on upgrade

New configuration keys are always added to `RedminefluxAgentos::Configuration::Store::DEFAULTS` with a safe default value (`nil` or an inert default) — a config row is only ever created in `redmineflux_agentos_configurations` when an administrator explicitly saves one via Admin → AgentOS → Settings. This means upgrading to a version that adds a new key never requires an administrator to do anything; the new key silently falls back to its documented default until someone chooses to override it. (Precedent: `global_concurrency_cap`/`project_concurrency_cap` in `rao-019`, `notify_on_agent_started` in `rao-021` — both added mid-project without any migration or forced admin action.)

## 4. Cache considerations on upgrade

Every `Rails.cache` entry AgentOS writes (`docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md` §B.3 — active prompt template per key, agent enabled-state, per-project dependency graph snapshot) uses an explicit cache key scheme with a version- or generation-suffixed key where the underlying data can change out from under a running process (prompt templates use a generation counter; agent enabled-state and dependency graph snapshots are deleted outright on write, not versioned). None of them are time-based expiry. **A plugin code upgrade does not require manually clearing `Rails.cache`** — if a future version ever changes what a cache key's value represents (not just its content), that migration step will be called out explicitly in this section at that time, not assumed silently safe.

## 5. Migrations

All 18 `db/migrate/*.rb` files (`rao-016`, Phase 11) are additive-only as of this release — no destructive schema change (column removal, type change, table drop) has shipped yet. When one does, it will be documented here with the specific `rails db:rollback`-safety notes for that migration, per [CLAUDE.md](../CLAUDE.md)'s backward-compatibility discipline ("additive params/columns with defaults").
