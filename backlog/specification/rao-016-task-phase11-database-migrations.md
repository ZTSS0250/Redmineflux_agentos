## Metadata
- **Task ID**: rao-016-task-phase11-database-migrations
- **Title**: ROADMAP.md Phase 11 — Database Migrations
- **Type**: task
- **Status**: specification
- **Complexity**: HIGH
- **Created**: 2026-07-02
- **Author**: Sheetal Sharma
- **Quality Gates**: Gate 1: approved (docs-scope) | Gate 2: approved (docs-scope) | Gate 3: approved (docs-scope)

---

## Planning

**Description**: Implements the schema fully designed in [docs/DATABASE-SCHEMA.md](../../docs/DATABASE-SCHEMA.md) and [docs/PHASE4-DATABASE-DESIGN.md](../../docs/PHASE4-DATABASE-DESIGN.md). This ticket specifies every migration file; it does not run them.

**Goal**: One migration per table (18 tables), each including the indexes/constraints already decided in `docs/PHASE4-DATABASE-DESIGN.md` §4-§5, so no migration needs a follow-up "add missing index" migration.

**Objectives**:
- [x] One `create_table` migration per table in `docs/DATABASE-SCHEMA.md`
- [x] Every index from `docs/PHASE4-DATABASE-DESIGN.md` §4 included in its table's migration, not added later
- [x] Foreign key constraints declared at the DB level (§5)
- [x] `to_prepare`-based `Project`/`Issue` association extension implemented per §10 (separate from migrations, but must ship in this phase since it depends on the tables existing) — **already present**, written as part of `rao-015`'s `config/initializers/redmineflux_agentos.rb`; verified during this implementation pass, no change needed

**Deliverables** (created when implemented):
- [x] 18 migration files under `db/migrate/`, timestamped in dependency order (`agents` and `configurations` first, since nothing depends on them; `dependencies`/`cost_trackings` last, since they reference other new tables)

**Implemented (2026-07-03) — untested**: all 18 `create_table` migrations written under `db/migrate/`, timestamped `20260703100001`-`20260703100018`. Every column, index, and FK sourced from `docs/DATABASE-SCHEMA.md` and `docs/PHASE4-DATABASE-DESIGN.md`, cross-checked against the exact FK column names already hardcoded in `rao-015`'s 18 models (e.g. `blocking_issue_id`, `depends_on_ai_task_id`) since the models are already-written code the migrations must match, not just the doc. **Status remains `specification`, not `done`** — this environment cannot boot Redmine or run `rake db:migrate`/`db:rollback` against a live instance; that verification is the developer's per the Golden Rule. Three implementation-time findings, none requiring a decision from the developer (mechanical corrections, not design changes):

1. **FK-ordering bug in this ticket's own Code Changes table** — the listed order (`agents`, `agent_runs`, `agent_memories`, `conversations`, ...) puts `agent_runs` (which has a nullable FK to `conversations`) before `conversations` itself. Gate 1 finding #1 asserted the listed order was already dependency-safe; it wasn't, for this one edge case. Fixed by creating `redmineflux_agentos_conversations` third in file order (timestamp `...002`) and `redmineflux_agentos_agent_runs` fourth (`...003`) — every other table keeps the ticket's original relative order. No other FK-ordering issues found across the remaining 16 tables.
2. **`t.integer` vs `t.bigint` for FK columns** — columns holding a foreign key to a table with a `bigint` primary key (every Redmine core table and every AgentOS table, both default to `bigint` PKs) must themselves be `t.bigint`, not `t.integer` — PostgreSQL rejects `add_foreign_key` when the referencing and referenced column types don't match. All plain-integer FK columns (not created via `t.references`, which already defaults to `bigint`) were written as `t.bigint` for this reason.
3. **MySQL 64-character index-identifier limit** — this is exactly the risk Gate 3 finding #1 flagged ("testing migrations only against SQLite... a MySQL-specific issue ships unnoticed"). Rails' auto-generated index names (`index_<table>_on_<col1>_and_<col2>`) would exceed 64 characters on several of this plugin's longer table names once a composite/unique index is involved (worst case with default naming: 63 characters, right at the edge). Every composite or unique multi-column index across all 18 migrations was given an explicit short `name:` (e.g. `idx_agentos_runs_agent_status`) so no engine-specific migration branch is needed, satisfying the ticket's own QA Test Plan goal of identical behavior across MySQL/PostgreSQL/SQLite.

Migration style follows the sibling `redmineflux_devops` plugin's established convention (`t.references ..., foreign_key: true` for plugin-to-plugin links; `t.bigint :xxx_id` + a standalone trailing `add_foreign_key` for links to Redmine core tables; `t.string` for all enum/status columns; `t.text` for all JSON-shaped columns). All 18 files pass `ruby -c` syntax checks.

---

## Specification

**Complexity**: HIGH — 18 tables, cross-database portability requirements (Phase 4 §5's constraint tradeoffs), and the Redmine-core association extension all need to be correct on the first migration, since altering a shipped migration after the fact is exactly the kind of rework the SDD process exists to prevent.

**Reason**: A wrong index or missing FK here is expensive to fix retroactively (a second migration, potential data migration) compared to getting it right before Phase 12+ starts writing code against the schema.

### Code Changes

| File | Action | Description |
|---|---|---|
| `db/migrate/XXXX_create_redmineflux_agentos_agents.rb` | create | Per `docs/DATABASE-SCHEMA.md` |
| `db/migrate/XXXX_create_redmineflux_agentos_agent_runs.rb` | create | Includes `(status)`, `(agent_id, status)`, `(project_id, status)`, `(blocking_issue_id)` indexes |
| `db/migrate/XXXX_create_redmineflux_agentos_agent_memories.rb` | create | Unique index `(agent_id, project_id, scope, key)` |
| `db/migrate/XXXX_create_redmineflux_agentos_conversations.rb` | create | Indexes per Phase 4 §4 |
| `db/migrate/XXXX_create_redmineflux_agentos_messages.rb` | create | `(conversation_id, created_at)` index |
| `db/migrate/XXXX_create_redmineflux_agentos_project_plans.rb` | create | `(project_id, status)`, `(conversation_id)` |
| `db/migrate/XXXX_create_redmineflux_agentos_releases.rb` | create | `(project_plan_id, sequence)` |
| `db/migrate/XXXX_create_redmineflux_agentos_sprints.rb` | create | `(release_id, status)` |
| `db/migrate/XXXX_create_redmineflux_agentos_ai_tasks.rb` | create | `(project_id, status)`, `(sprint_id)`, `(agent_id)`, `(issue_id)`; `status` enum includes `deleted` (Phase 4 §6/§10) |
| `db/migrate/XXXX_create_redmineflux_agentos_dependencies.rb` | create | Unique `(ai_task_id, depends_on_ai_task_id)` |
| `db/migrate/XXXX_create_redmineflux_agentos_prompt_templates.rb` | create | `(key, is_active)` index — **no** partial unique index (Phase 4 §5 cross-DB decision) |
| `db/migrate/XXXX_create_redmineflux_agentos_knowledge_base_entries.rb` | create | `(project_id)` |
| `db/migrate/XXXX_create_redmineflux_agentos_execution_logs.rb` | create | FK to `agent_runs` |
| `db/migrate/XXXX_create_redmineflux_agentos_mcp_tool_calls.rb` | create | `(agent_run_id)`, `(status)` |
| `db/migrate/XXXX_create_redmineflux_agentos_token_usages.rb` | create | `(agent_run_id)`, `(project_id, created_at)` |
| `db/migrate/XXXX_create_redmineflux_agentos_cost_trackings.rb` | create | Unique `(project_id, period)` |
| `db/migrate/XXXX_create_redmineflux_agentos_configurations.rb` | create | Unique `(project_id, key)` |
| `db/migrate/XXXX_create_redmineflux_agentos_audit_logs.rb` | create | `(target_type, target_id)`, `(user_id)`, `(agent_id)` |
| `config/initializers/redmineflux_agentos.rb` | modify | Fill in the `Project`/`Issue` `has_many ... dependent: :destroy` extension (Phase 4 §10) — depends on tables existing |

### Implementation Notes

- **Application-layer enforcement, not a DB constraint, for "one active prompt version per key"** (Phase 4 §5) — the migration must *not* attempt a partial unique index; that decision was deliberate for MySQL portability.
- **`audit_logs` immutability is enforced in the model, not the migration** (Phase 4 §9) — no DB trigger is created; this is a model-layer `readonly?`/callback concern for whichever task adds the model logic.

---

## Test Cases

### Unit Tests
| # | Test Name | Input / Condition | Expected Result | Status |
|---|-----------|-------------------|-----------------|--------|
| 1 | All migrations run cleanly | `rake db:migrate` on a fresh Redmine DB | No errors, all 18 tables exist with expected columns | pending |
| 2 | Rollback works | `rake db:rollback` for each migration | Clean rollback, no orphaned indexes/constraints | pending |
| 3 | Concurrent prompt-version activation | Two simultaneous "activate" calls for the same `key` | Exactly one row ends up `is_active: true` (Phase 4 §5's carried-forward race-condition test) | pending |

### QA Test Plan

**Scope**: Schema correctness against `docs/DATABASE-SCHEMA.md` and `docs/PHASE4-DATABASE-DESIGN.md` on all three supported DB engines (MySQL, PostgreSQL, SQLite).

**Pre-conditions**: `rao-015` (Plugin Skeleton) implemented first.

**QA Steps**: 1. Run migrations against each of the three engines. 2. Confirm every index/constraint from Phase 4 §4-§5 exists. 3. Confirm the `to_prepare` association extension fires under both eager and lazy loading (Phase 4 §10 Gate 3 finding #2).

**Expected Outcomes**: Identical schema behavior across all three engines — no engine-specific migration branch needed, per Phase 4's portability decisions.

**Out of Scope**: Model business logic (Phases 12-14).

---

## Quality Gates

### Gate 1 — Senior Developer Review
Date: 2026-07-02 | Status: approved (docs-scope, code-level Gate 1 deferred to implementation)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | MEDIUM | Migration ordering must respect FK dependencies (e.g. `ai_tasks` before `dependencies`) | Code Changes | Resolved — table listed in dependency order in the Code Changes table above |

Verdict: Approved as a specification.

**Revision pass (2026-07-03, during implementation)** — building the actual migration files surfaced one genuine gap in finding #1's resolution:

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 2 | MEDIUM | The Code Changes table's listed order is not actually fully FK-dependency-safe: `agent_runs` (2nd) has a nullable FK to `conversations` (4th) | Code Changes | Resolved during implementation — `conversations` created before `agent_runs` on disk (see Planning's "Implemented" note); every other table's relative order unchanged |

Verdict (revised): Approved. The implementation-time reordering is a mechanical fix within the spirit of the original finding, not a new design decision — no re-review of Gates 2/3 required.

### Gate 2 — Security & Performance Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | HIGH | Migrations must not silently add a DB-level partial unique index for prompt template versioning — would only partially work (PostgreSQL/SQLite) and create engine-inconsistent behavior on MySQL | Implementation Notes | Resolved — explicitly called out as prohibited in this ticket, reiterating Phase 4 §5's decision |

Verdict: Approved for Phase 11 documentation scope.

### Gate 3 — Pre-Development Sweep
Date: 2026-07-02 | Status: approved (docs-scope)

**Part A**: Confirmed both resolutions present.

**Part B — Predicted implementation bugs**:
| # | Pattern | Predicted Bug | Edge Case Added? |
|---|---------|--------------|-----------------|
| 1 | Testing migrations only against SQLite (the fastest local dev default) | A MySQL-specific issue (e.g. index name length limits, which are stricter on MySQL than PostgreSQL/SQLite) ships unnoticed | Logged as a required test case: migrations must be verified against all three supported engines before merge, not just the developer's local default |

Verdict: Approved. No unresolved HIGH/CRITICAL findings in spec text.

---

## Done

*(Not applicable until this ticket is actually implemented and tested against a running Redmine instance)*
