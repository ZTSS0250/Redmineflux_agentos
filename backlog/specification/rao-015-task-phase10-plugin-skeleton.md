## Metadata
- **Task ID**: rao-015-task-phase10-plugin-skeleton
- **Title**: ROADMAP.md Phase 10 — Plugin Skeleton
- **Type**: task
- **Status**: specification
- **Complexity**: HIGH
- **Created**: 2026-07-02
- **Author**: Sheetal Sharma
- **Quality Gates**: Gate 1: approved (docs-scope) | Gate 2: approved (docs-scope) | Gate 3: approved (docs-scope)

---

## Planning

**Description**: First implementation phase — generates the plugin skeleton per [docs/PHASE5-FOLDER-STRUCTURE.md](../../docs/PHASE5-FOLDER-STRUCTURE.md), with no business logic. This ticket specifies exactly what Phase 10 will create; it does not create it. **This ticket cannot move to `done` until code is written, tested against a running Redmine instance, and the developer confirms — none of which is possible in this environment.**

**Implemented (2026-07-02) — untested**: all code listed in the Code Changes table below has been written (123 files: `init.rb`, routes, locale, initializer, 18 models, 16 controllers + 22 placeholder views, 17 agent classes, the Provider/MCP/Engine/Services lib namespaces, 4 job skeletons, asset stubs, the AgentOS System user provisioner, and a companion rake task). **Status remains `specification`, not `done`** — none of this has been booted against a real Redmine instance, migrated, or exercised by the test cases below, which this environment cannot do. Two implementation-time decisions worth the developer's attention before that testing happens: (1) the AgentOS System user's `status: User::STATUS_LOCKED` is intended to block interactive login without affecting programmatic permission checks, but this interaction with `Principal#allowed_to?` has not been verified live; (2) a `before_destroy` callback on `Issue` sets the linked `ai_task.status` to `deleted` as a safety net for issue deletions that bypass the `delete_issue` MCP tool entirely — also unverified live.

**Unblocked (2026-07-02)**: the 5 open questions in `docs/PHASE1-SPECIFICATION.md` §7 that previously blocked this ticket are now resolved — background job backend and MCP transport by precedent (`redmineflux_devops`), confirmation UX by already-built consensus across every UI document, LLM provider by a stated (non-blocking) default recommendation, and code-writing-agent scope reservation by explicit decision (no reservation). This ticket is now blocked only on the ordinary "no code before spec, no merge before tests pass" constraint — i.e. it is ready to implement whenever the developer chooses to, not waiting on any further decision.

**Goal**: A gate-approved Code Changes table detailed enough that "implement rao-015" is an unambiguous instruction whenever the developer is ready to begin actual coding.

**Objectives**:
- [x] `init.rb` registers the plugin (with `requires_redmine version_or_higher:` per CLAUDE.md's 5.x/6.x compatibility target), declares `project_module :agentos` (disabled by default per project, per standard Redmine convention), all permissions (`docs/PHASE1-SPECIFICATION.md` §5), and both menu trees (§4)
- [x] `config/routes.rb` declares all routes (HTML + `.json`/`.api`) for every controller in `docs/PHASE9-UI-UX-SPECIFICATION.md`'s 13 pages, with the REST API portion scoped under `/agentos` with `defaults: { format: 'json' }` (matching the `redmineflux_devops` precedent already cited elsewhere in this project)
- [x] Every directory in `docs/PHASE5-FOLDER-STRUCTURE.md` §1 exists, with skeleton (near-empty) files
- [x] Controllers/models/services/jobs exist with class definitions and associations only — no business logic
- [x] Initializer (`docs/PHASE5-FOLDER-STRUCTURE.md` §9) exists with `to_prepare` blocks, registration bodies stubbed (raise `NotImplementedError` or no-op, filled in by Phases 11-14)
- [x] A dedicated **AgentOS System user** is provisioned (see Specification below) — the `User.current` identity for every autonomous, non-human-triggered agent action

**Deliverables** (written 2026-07-02 — see Specification's Implementation Notes; still unverified against a live Redmine instance):
- [x] `init.rb`, `config/routes.rb`, `config/locales/en.yml`
- [x] `app/{controllers,models,views,jobs}/redmineflux_agentos/` (skeletons — `app/helpers`, `app/serializers` intentionally left empty, nothing to stub yet)
- [x] `lib/redmineflux_agentos/{agents,services,providers,mcp,engine,prompts,hooks}/` (namespace shells, 17 agent classes, provider/MCP/engine interfaces)
- [x] `config/initializers/redmineflux_agentos.rb`
- [x] `assets/{javascripts,stylesheets}/redmineflux_agentos/` (stub files, no behavior)
- [x] `lib/redmineflux_agentos/system_user_provisioner.rb` + `lib/tasks/redmineflux_agentos.rake` (not originally itemized above — added during implementation, see Specification)

---

## Specification

**Complexity**: HIGH — not because the skeleton itself is complex, but because it's the first code this plugin will ever contain, and every naming/registration mistake here (permission keys, route names, menu hook points) would ripple through every later phase.

**Reason**: `docs/PHASE1-SPECIFICATION.md` §7 originally gated this phase on 5 open questions — all five are now resolved (see Planning above); this remains HIGH complexity because it's the first code the plugin will contain, not because any decision remains outstanding.

### Code Changes

| File | Action | Description |
|---|---|---|
| `init.rb` | create | Plugin registration, `requires_redmine version_or_higher:`, `project_module :agentos`, permission declarations, menu items — **no `settings partial:`/`settings default:` block** (see Implementation Notes) |
| `config/routes.rb` | create | HTML routes for project-scoped pages; REST API routes scoped `\agentos`, `defaults: { format: 'json' }`, matching `redmineflux_devops`'s own routing convention |
| `app/controllers/redmineflux_agentos/*.rb` | create | One per page in `docs/PHASE9-UI-UX-SPECIFICATION.md` — empty actions, `before_action :require_login`, `accept_api_auth` |
| `app/models/redmineflux_agentos/*.rb` | create | One per table in `docs/DATABASE-SCHEMA.md` — associations and validations only, no business methods |
| `lib/redmineflux_agentos/**/*.rb` | create | Namespace/class shells per `docs/PHASE5-FOLDER-STRUCTURE.md` §3-§7 |
| `config/initializers/redmineflux_agentos.rb` | create | `to_prepare` block, registration bodies stubbed |
| `db/migrate/XXXX_create_agentos_system_user.rb` *(or a `rake redmineflux_agentos:provision_system_user` task, decided at implementation time)* | create | Provisions the AgentOS System user (see Specification) |

### Implementation Notes

- **Previously blocked on the 5 open questions, now resolved** (`docs/PHASE1-SPECIFICATION.md` §7): background job backend (plain `ActiveJob`, `rao-007`), MCP transport (in-process `Mcp::Executor` + REST exposure for the shared external MCP server, matching `redmineflux_devops`), and confirmation UX (Pending Approvals queue on Agent Dashboard, already built into every UI doc) directly shape this ticket's routes/initializer and are now settled. LLM provider and code-writing-agent scope reservation don't affect this ticket's shape at all (Mock-only in v1; no reservation made).
- **No business logic is a hard rule, not a suggestion**: every method body in this phase is either absent, a association/validation declaration, or a stub — Gate 1 review of the actual implementation must reject any real logic sneaking into "skeleton" work.
- **`project_module :agentos` is opt-in per project, disabled by default** — matching standard Redmine plugin convention and the "additive to human workflows, never a silent replacement" rule (CLAUDE.md Rules) — AgentOS never appears in a project until a project admin explicitly enables it in Settings > Modules.
- **No Redmine built-in plugin settings block**: Redmine's `Redmine::Plugin.register` supports a classic `settings partial:`/`settings default:` mechanism (the "Configure" link most plugins use) — AgentOS deliberately does **not** use it, since `Configuration::Store` (Phase 2 §B.6, backed by `redmineflux_agentos_configurations`) is already the fully-designed configuration system, with project-override precedence and explicit-invalidation caching that the built-in mechanism doesn't provide. Using both would create two parallel, inconsistent config systems — a common but avoidable mistake when a developer defaults to Rails/Redmine's most familiar pattern out of habit. The Settings admin page (`docs/PHASE9-UI-UX-SPECIFICATION.md` §4.2) is a custom AgentOS controller/view reading and writing `Configuration::Store`, not Redmine's plugin-settings partial.

### AgentOS System User (new — closes a previously unaddressed gap)

Every design document so far (`docs/MCP-TOOLS.md`, `docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md` §B.8) states MCP calls require an explicit, non-superuser `User.current` — but `redmineflux_agentos_agent_runs` (`docs/DATABASE-SCHEMA.md`) has no `user_id`/`triggered_by` column, and not every agent action has a human request in flight to inherit a user from (e.g. the Project Manager Agent's periodic health-check tick, or the Documentation Agent's passive reaction to a ticket closing). This was an unstated assumption everywhere else — here is the resolution:

- **A dedicated Redmine `User` record, `login: "agentos_system"`**, is provisioned once (at first plugin boot or via an explicit rake task — implementation detail to decide, not a design question). It is **not an admin** and **cannot log in interactively** (Redmine's `status: locked`, or no password ever issued) — it exists solely to be a `User.current` value for programmatic calls, never a login target.
- **It is added as a `Member`** (with a dedicated "AgentOS System" Role scoped to exactly the AgentOS permission set, `docs/PHASE1-SPECIFICATION.md` §5 — no core Redmine permissions like `edit_issues` beyond what an MCP tool call actually needs) **of every project where the `:agentos` module is enabled** — automatically, on module enablement, not manually per project.
- **Rule for which `User.current` applies**: human-initiated actions (SRS approval, a Pending Approvals confirmation) use the real logged-in user's session, exactly as already designed. **Agent-initiated MCP calls — anything originating from `AgentEngine::Runner`, not a controller request — use the AgentOS System user.** This is not a superuser bypass (AD-3/Gate 2's standing rule): Permission Model Layer 1 (Redmine's own `authorize`) still meaningfully constrains the System user to exactly its Role's grants.
- **Why Phase 10, not later**: this is a user-provisioning and permission-registration concern, the same category of work already in this ticket's scope — deferring it to Phase 14 (Multi-Agent Orchestration) would mean that phase discovers mid-implementation that there's no valid `actor:` to pass for autonomous calls, when it should have been available from the moment permissions exist.

---

## Test Cases

### Functional Tests
| # | Test Name | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Plugin loads without error | Start Redmine with the plugin installed | No boot errors; plugin appears in Administration > Plugins | pending |
| 2 | Permissions registered | Check Redmine role permission matrix | All permission keys from `docs/PHASE1-SPECIFICATION.md` §5 appear | pending |
| 3 | Menus render, permission-gated | Log in as a user without `create_ai_project` | "AI Chat" menu item is absent, not just disabled | pending |
| 4 | AgentOS System user provisioned correctly | Enable the `:agentos` module on a project | System user (`agentos_system`) is added as a `Member` with the AgentOS System role; cannot log in interactively; has no permission beyond that role's grants | pending |

### QA Test Plan

**Scope**: Plugin boots cleanly, no business logic present, all routes/permissions/menus registered correctly.

**Pre-conditions**: A running Redmine 5.x/6.x instance. (The 5 open questions in `docs/PHASE1-SPECIFICATION.md` §7 are resolved — no longer a pre-condition.)

**QA Steps**: 1. Install plugin. 2. Run migrations (none exist yet at this phase — `rao-016` follows). 3. Confirm boot, permissions, menus, empty pages render without 500s.

**Expected Outcomes**: A working, empty shell — every page reachable and renders (even if blank), no business logic anywhere.

**Out of Scope**: Any actual functionality (all subsequent phases).

---

## Quality Gates

### Gate 1 — Senior Developer Review
Date: 2026-07-02 | Status: approved (docs-scope, code-level Gate 1 deferred to implementation)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | HIGH | This ticket lists implementation actions but could not previously be executed while the 5 open questions remained unanswered | Planning | **Resolved (2026-07-02)** — all 5 questions are now answered in `docs/PHASE1-SPECIFICATION.md` §7; this ticket is gate-approved *as a specification* and is now unblocked for implementation whenever the developer chooses. Its `[ ]` (unchecked) objectives still reflect that implementation has not started, unlike doc-only tickets whose objectives were checked at authoring time |

**Revision pass (2026-07-02, before implementation begins)** — a follow-up review found a genuinely missing design decision, not previously caught:

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 2 | HIGH | No document (`docs/MCP-TOOLS.md`, `docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md` §B.8) ever specified *whose* `User.current` an autonomous, non-human-triggered agent action uses — `agent_runs` has no `user_id` column, so there was no way to answer this without a new decision | Specification, "AgentOS System User" | Resolved — a dedicated, non-admin, non-interactively-logged-in `agentos_system` Redmine user is provisioned and added as a project `Member` with a scoped Role on module enablement; used as `actor:` for every agent-initiated (non-human-request) MCP call |
| 3 | MEDIUM | Routes and `init.rb` had no explicit convention preventing two parallel configuration systems (Redmine's built-in plugin settings vs. the already-designed `Configuration::Store`) | Implementation Notes | Resolved — explicit rule: no `settings partial:`/`settings default:` block; the Settings admin page reads/writes `Configuration::Store` exclusively |

Verdict: Approved as a specification. **The 5 open questions are now resolved (see Planning) — this ticket is ready for implementation whenever the developer chooses to begin.** The revision-pass findings are incorporated into the specification, not left as separate follow-up notes.

### Gate 2 — Security & Performance Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | MEDIUM | Skeleton controllers must have `before_action :require_login` and `accept_api_auth` from the very first commit, not added later "once real logic exists" | Code Changes | Resolved — stated as a Code Changes requirement for every controller file, not deferred |
| 2 | HIGH | An AgentOS System user with a misconfigured Role (e.g. accidentally granted `edit_issues` or other core Redmine permissions beyond what AgentOS itself needs) would be a standing, always-available privilege-escalation surface — worse than a per-call risk, since it's a persistent account | Specification, "AgentOS System User" | Resolved — the System user's Role is explicitly scoped to *only* the AgentOS permission set (`docs/PHASE1-SPECIFICATION.md` §5), never core Redmine permissions; carried forward as a mandatory implementation-time check (Role grants must be reviewed against that exact list, nothing more) |

Verdict: Approved for Phase 10 documentation scope. Finding #2 is a mandatory implementation-time check, not advisory.

### Gate 3 — Pre-Development Sweep
Date: 2026-07-02 | Status: approved (docs-scope)

**Part A**: Confirmed both resolutions are present in spec text.

**Part B — Predicted implementation bugs**:
| # | Pattern | Predicted Bug | Edge Case Added? |
|---|---------|--------------|-----------------|
| 1 | "Skeleton, no business logic" is easy to violate incrementally | A developer adds "just a little" real logic to make a skeleton page look functional during a demo, and it never gets refactored back out before Phase 11-16 build on top of it | Logged as a required Gate 1 check specifically for this ticket's implementation PR: reviewer must reject any method body beyond associations/validations/stubs |
| 2 | AgentOS System user membership is granted "automatically on module enablement" | If the enablement hook is implemented as a one-time `after_create` on the module-enable action rather than an idempotent check, re-enabling a previously-disabled module (or a project imported/restored from backup) could leave the project without the System user as a member, silently breaking every autonomous agent action for that project until someone notices | Logged as a required test case for the Phase 10 implementation: enabling `:agentos` on a project must be idempotent — verified membership exists, added if missing, never assumed from a one-time creation hook |

Verdict: Approved. No unresolved HIGH/CRITICAL findings in spec text; finding #2 carried forward as a required test case.

---

## Done

*(Not applicable until this ticket is actually implemented, tested against a running Redmine instance, and the developer confirms — per the Golden Rule, this stays in `backlog/specification/` until then)*
