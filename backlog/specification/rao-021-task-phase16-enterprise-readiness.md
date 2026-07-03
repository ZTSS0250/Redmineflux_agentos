## Metadata
- **Task ID**: rao-021-task-phase16-enterprise-readiness
- **Title**: ROADMAP.md Phase 16 — Enterprise Readiness
- **Type**: task
- **Status**: specification
- **Complexity**: HIGH
- **Created**: 2026-07-02
- **Author**: Sheetal Sharma
- **Quality Gates**: Gate 1: approved (docs-scope) | Gate 2: approved (docs-scope) | Gate 3: approved (docs-scope)

---

## Planning

**Description**: Final phase — production hardening across Caching, Background Processing, Performance Optimization, Audit Logging, RBAC, Notifications, Metrics, Health Checks, Monitoring, Scalability Enhancements, Documentation Finalization, and Deployment & Upgrade Guides. This ticket specifies the work; it does not perform it. Depends on all of `rao-015`-`rao-020` being implemented first — this phase hardens an already-functioning system, it doesn't build new features.

**Goal**: Every strategy already designed in Phase 2 (§B.1-§B.10) and Phase 4 (§12) is actually running in production, plus the observability/health-check surface a production deployment needs that wasn't yet in scope for earlier phases.

**Objectives**:
- [ ] `Rails.cache`-backed caching implemented per Phase 2 §B.3 (prompt templates, agent registry, dependency graph snapshots), with explicit invalidation hooks verified for both insert and delete paths (`rao-007`'s carried-forward requirement)
- [ ] `LogRetentionJob` implemented per Phase 4 §12, excluding non-terminal `agent_run`s (`rao-009`'s carried-forward requirement)
- [ ] RBAC audited end-to-end: every AgentOS permission (`docs/PHASE1-SPECIFICATION.md` §5) actually gates what it claims to
- [ ] Notification Center implemented per `WORKFLOW.md` §23
- [ ] Health check endpoint (plugin boot state, Provider registry populated, Event Bus subscribers registered)
- [ ] Metrics: agent run throughput, token/cost trends, dependency-graph depth — surfaced for ops, not just the product dashboards
- [ ] `RELEASE_NOTES.md` finalized for v1; a deployment guide and an upgrade guide authored

**Deliverables** (created when implemented):
- [x] Caching implementation across the modules named in Phase 2 §B.3
- [x] `app/jobs/redmineflux_agentos/log_retention_job.rb`
- [x] `lib/redmineflux_agentos/notification_center.rb` (or equivalent)
- [x] A health-check controller/route
- [x] `docs/DEPLOYMENT-GUIDE.md`, `docs/UPGRADE-GUIDE.md` (new — proposed, not yet created)

**Implemented (2026-07-03) — untested against a live Redmine instance**:

- **Caching (Phase 2 §B.3), all three named targets, all explicit-invalidation, never time-based**: `DependencyEngine::Graph.edges_for_project`/`.add_edge`/`.remove_edge` (per-project snapshot, invalidated on both insert and — new in this ticket — delete: `remove_edge` did not exist anywhere before, so there was no delete path to invalidate on); `Prompts::TemplateResolver` (active template per key, a generation-counter scheme so `Admin::PromptTemplatesController#activate!`/`#create_new_draft!`'s `update_all`-based deactivation, which skips AR callbacks, still gets invalidated correctly); `AgentEngine::Registry.enabled?`/`.invalidate!` (agent enabled/disabled state).
- **`LogRetentionJob`**: implements the Phase 10 skeleton stub (`raise NotImplementedError`) for real — one SQL `DELETE` (via a `where.not` subquery, not a `pluck` into Ruby) pruning `debug`-level `execution_logs` older than 90 days, excluding any non-terminal `agent_run` regardless of age (`RedminefluxAgentosAgentRun::TERMINAL_STATUSES`, a new constant).
- **RBAC audit — one real bug found and fixed**: `admin/audit_logs` (routed, menu-linked, `Admin::BaseController`-derived) had **zero** permission mapping anywhere in `init.rb` — every request would have been denied for every user, including admins, because Redmine's `authorize_global` fails closed on an undeclared controller/action pair. Fixed by adding it to the existing `manage_agentos` permission. Every other controller/action in `config/routes.rb` was cross-referenced against `init.rb`'s permission declarations 1:1 — no other gap found. The "attempt the gated action as an unauthorized user" half of the audit (Gate 2 finding #1, Test Case #3) needs a live Redmine instance — out of this environment's reach, same category of gap as every prior phase.
- **`NotificationCenter`**: implements 4 of `WORKFLOW.md` §23's 6 rows against real (previously-missing) trigger events — see the two Gate 1 revisions below for what closed and what's explicitly deferred. Delivers through a new minimal `NotificationMailer` (plain `ActionMailer::Base`, no view template — this ticket doesn't own email copy/design).
- **Health check + metrics** (`HealthController`, deliberately unauthenticated — see its own class comment and the Deployment Guide's §5): `GET /agentos/health.json` (3 checks mapping 1:1 to what the boot-time `to_prepare` block does: agent registry populated, provider registry populated, Event Bus subscribed — 503 on any failure, never a false-positive 200) and `GET /agentos/metrics.json` (cross-project aggregates only: agent run throughput by status, 7-day cost/token trend via the already-aggregated `cost_trackings` table, dependency edge/project counts).
- **`docs/DEPLOYMENT-GUIDE.md`/`docs/UPGRADE-GUIDE.md`**: created per the proposal in Implementation Notes below.
- **`RELEASE_NOTES.md`**: `[Unreleased]` entry updated with this ticket's work; **not** renamed to a version tag — per this ticket's own Code Changes row ("`[Unreleased]` renamed... at release time"), that rename happens at actual release, which hasn't occurred (no live Redmine has ever run this plugin, per every prior phase's own Done section).

Three additional, small, closely-related fixes were required to make the above genuinely work rather than pass superficially — each is a real bug this ticket's own verification pass exists to catch (see Gate 1 revisions):
1. `Mcp::Executor.call` gained an additive, optional `agent_run:` keyword — `mcp_tool_calls.agent_run_id` had a real DB column and model association (since `rao-016`/`rao-018`) that no call path ever populated, which meant `NotificationCenter.approval_needed` could never resolve a project from a `pending_confirmation` row.
2. `ConcurrencyGuard.acquire` now publishes `agent_run.running` — no code anywhere published it before, so "Agent Started" could never fire regardless of `NotificationCenter`.
3. `AgentEngine::Lifecycle`'s `:start` transition now checks `Registry.enabled?(agent_run.agent)` — nothing anywhere read `RedminefluxAgentosAgent#status` before this; a disabled agent's queued runs would have executed anyway.

---

## Specification

**Complexity**: HIGH — this phase is where every "carried forward as mandatory" requirement across the entire roadmap gets its final verification pass; missing one here means it ships silently unverified into v1.

**Reason**: Enterprise readiness is inherently cross-cutting — a caching bug, a missing health check, or an unaudited permission is each individually capable of being a production incident, even though none of them is "new functionality."

### Code Changes

| File | Action | Description |
|---|---|---|
| Various (Phase 2 §B.3 modules) | modify | Add `Rails.cache` reads/writes with explicit invalidation |
| `app/jobs/redmineflux_agentos/log_retention_job.rb` | create | Per Phase 4 §12, excludes non-terminal `agent_run`s |
| `lib/redmineflux_agentos/notification_center.rb` | create | Routes events to Redmine notifications (`WORKFLOW.md` §23) |
| `app/controllers/redmineflux_agentos/health_controller.rb` | create | Boot-state health check |
| `docs/DEPLOYMENT-GUIDE.md` | create (proposed) | Installation, migration, first-boot configuration steps |
| `docs/UPGRADE-GUIDE.md` | create (proposed) | Version-to-version migration notes, starting from v1 |
| `RELEASE_NOTES.md` | modify | `[Unreleased]` renamed to the actual v1 version tag at release time |

**Actual files touched at implementation** (the "Various" row above, made concrete, plus the Gate 1 revision fixes):

| File | Action | Description |
|---|---|---|
| `lib/redmineflux_agentos/engine/dependency_engine/graph.rb` | modify | `edges_for_project`/`invalidate!` cache + new `remove_edge` |
| `lib/redmineflux_agentos/prompts/template_resolver.rb` | modify | Generation-counter cache + `invalidate!` |
| `lib/redmineflux_agentos/engine/agent_engine/registry.rb` | modify | `enabled?`/`invalidate!`/`registered_keys` |
| `lib/redmineflux_agentos/engine/agent_engine/lifecycle.rb` | modify | Disabled-agent guard on `:start` |
| `lib/redmineflux_agentos/engine/concurrency_guard.rb` | modify | Publishes `agent_run.running` |
| `lib/redmineflux_agentos/engine/event_bus.rb` | modify | `subscribed_events` tracking (for the health check) |
| `lib/redmineflux_agentos/mcp/executor.rb` | modify | Additive `agent_run:` keyword; publishes `mcp_tool_call.pending_confirmation` |
| `lib/redmineflux_agentos/engine/agent_engine/runner.rb` | modify | Passes `agent_run:` through to `Executor.call` |
| `lib/redmineflux_agentos/configuration/store.rb` | modify | New `notify_on_agent_started` config key |
| `app/models/redmineflux_agentos_agent_run.rb` | modify | New `TERMINAL_STATUSES` constant |
| `app/mailers/redmineflux_agentos/notification_mailer.rb` | create | Plain `ActionMailer::Base`, no view template |
| `app/controllers/redmineflux_agentos/dependency_dashboards_controller.rb` | modify | Reads through `Graph.edges_for_project` instead of querying directly |
| `app/controllers/redmineflux_agentos/admin/prompt_templates_controller.rb` | modify | Calls `TemplateResolver.invalidate!` after activation/new-draft |
| `config/routes.rb` | modify | `health`/`metrics` routes |
| `config/initializers/redmineflux_agentos.rb` | modify | 4 new `EventBus.subscribe` calls routing to `NotificationCenter` |
| `init.rb` | modify | Gate 1 finding #2 fix — `admin/audit_logs` added to `manage_agentos` |

### Implementation Notes

- **This phase is a verification pass on prior carried-forward requirements, not new design** — every item in Objectives traces back to a specific earlier Gate finding (`rao-007`, `rao-009`) or an already-designed strategy (Phase 2 §B.1-§B.10) that simply hasn't been implemented and confirmed working yet.
- **RBAC audit is end-to-end, not per-controller** — a permission "gates what it claims to" must be verified by actually attempting the gated action as an unauthorized user, not just confirming a `before_action` exists.
- **`docs/DEPLOYMENT-GUIDE.md`/`docs/UPGRADE-GUIDE.md` are proposed new documents** — per the Documentation Updates process established in `rao-008` §14, any new document must be explicitly proposed with rationale rather than silently created; rationale: a production deployment needs installation/upgrade instructions that don't belong in any existing specification document (which are all pre-implementation design artifacts, not operational runbooks).

---

## Test Cases

### Integration Tests
| # | Test Name | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Cache invalidation, insert and delete | Add then remove a dependency edge | Dependency Dashboard reflects both changes immediately, no stale cache | pass (`test/unit/engine/dependency_graph_test.rb`) |
| 2 | Log retention excludes in-flight runs | A `waiting_on_dep` run older than the retention window | Its logs are NOT pruned | pass (`test/unit/jobs/log_retention_job_test.rb`) |
| 3 | RBAC end-to-end | Attempt every gated action as a user missing the specific permission | Every attempt is denied, not just hidden from the UI | partial — permission-table-to-route cross-reference done by code reading (found and fixed the `admin/audit_logs` gap); actually attempting each action as an unauthorized user needs a live Redmine instance |
| 4 | Health check | Query the health endpoint with the Mock Provider unregistered (simulated boot failure) | Health check reports unhealthy, not a false positive | verified by code reading (`Providers::Registry.registered?(:mock)` false → `healthy: false`, HTTP 503) — a live HTTP request needs a live Redmine instance |

### Test Results (ad hoc Minitest+Mocha harness, real repo test files copied into a scratchpad standing in for a live Redmine instance — same methodology as every prior phase)

61 test runs, 60 pass. The 1 non-pass (`EventBusTest#test_the_real_boot_time_subscriptions_are_registered`) is an accepted environment-only gap: it asserts the boot-time `to_prepare` block's Event Bus subscriptions are registered, which requires actually loading the full plugin boot sequence (17 agent classes, 6 MCP tool files, Mock Provider fixtures) — verified correct by reading `config/initializers/redmineflux_agentos.rb` directly instead. Real, previously-unknown bugs this pass caught and fixed (beyond the RBAC gap above):

- `Mcp::Executor` never populated `mcp_tool_calls.agent_run_id` on any path — fixed (see Implemented notes).
- `agent_run.running` was never published by `ConcurrencyGuard.acquire` — fixed.
- `RedminefluxAgentosAgent#status` (enable/disable) was never read anywhere before scheduling a run — fixed via `Registry.enabled?` + a `Lifecycle` guard.
- `NotificationCenter`'s first draft used two different, inconsistent mechanisms (`project.users` vs. `project.members.map(&:principal)`) to enumerate project members across its own methods — caught by a test double only implementing one of them; standardized on `project.users`.
- A self-referential Mocha stub bug in this ticket's own `template_resolver_test.rb` draft (`.returns(Real.where(...))` computed the real call *after* `.expects` had already replaced the method, corrupting its own invocation count) — fixed before being committed.

### QA Test Plan

**Scope**: All enterprise-readiness concerns across the full, by-now-complete plugin.

**Pre-conditions**: `rao-015` through `rao-020` implemented.

**QA Steps**: Run the full test suite; perform a manual RBAC audit against the permission table; verify the health check under both healthy and simulated-unhealthy conditions.

**Expected Outcomes**: A production-ready v1 with no unresolved carried-forward requirement from any prior ticket.

**Out of Scope**: v2 features (real LLM provider, expanded dashboards — `docs/PRODUCT-ROADMAP.md`).

---

## Quality Gates

### Gate 1 — Senior Developer Review
Date: 2026-07-02 | Status: approved (docs-scope, code-level Gate 1 deferred to implementation)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | MEDIUM | "Enterprise readiness" as a phase name risks becoming a catch-all where things quietly get deferred again ("we'll harden it later") | Planning | Resolved — every objective traces to a specific, already-identified requirement from an earlier ticket, not an open-ended aspiration; nothing new is invented here that could itself be deferred |

Verdict: Approved as a specification.

**Revision pass (2026-07-03, during implementation)**:

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 2 | HIGH | `admin/audit_logs` (routed, menu-linked to Administration, `Admin::BaseController`-derived) had zero permission declared for it anywhere in `init.rb` — every request fails closed for every user including admins, since Redmine's `authorize_global` denies an action with no matching permission | Code Changes (init.rb, implied) | Fixed — added to the existing `manage_agentos` permission (the documented "full administrative control" superset), matching the pattern every other `Admin::*Controller` already uses |
| 3 | MEDIUM | `mcp_tool_calls.agent_run_id` (column + `belongs_to` association, both present since `rao-016`/`rao-018`) was never populated by any call path — `NotificationCenter.approval_needed` cannot resolve a project (and so a recipient list) from a `pending_confirmation` row without it | Objectives (Notification Center) | Fixed — additive, backward-compatible `agent_run:` keyword added to `Mcp::Executor.call`, threaded through from `AgentEngine::Runner` |
| 4 | MEDIUM | Nothing anywhere published `agent_run.running` — "Agent Started" (`WORKFLOW.md` §23) could never fire regardless of `NotificationCenter`'s own correctness | Objectives (Notification Center) | Fixed — `ConcurrencyGuard.acquire` now publishes it on a successful `queued -> running` transition |
| 5 | HIGH | Nothing anywhere read `RedminefluxAgentosAgent#status` before scheduling a run — disabling an agent via the (still-stub) Admin UI would have had no effect on already-queued or newly-queued work | Objectives (Caching — "Agent registry ... invalidated on config_json updated") | Fixed — `AgentEngine::Registry.enabled?` (cached) + a guard in `Lifecycle`'s `:start` transition, same "not now, stays queued" contract `Scheduler.paused?` already uses |
| 6 | LOW | `DependencyEngine::Graph` had no delete/`remove_edge` path at all — this ticket's own caching requirement ("invalidated on... insert **and delete**") has nothing to invalidate on for the delete half without one | Objectives (Caching) | Fixed — `remove_edge` added, symmetric with `add_edge`, both invalidating the per-project cache |
| 7 | LOW | `NotificationCenter`'s first draft used two different mechanisms (`project.users` vs. `project.members.map(&:principal)`) across its own methods to enumerate "everyone in the project" — caught by a test double implementing only one of them | Objectives (Notification Center) | Fixed — standardized on `project.users` throughout |
| 8 | MEDIUM | `Admin::AgentsController#update`/`Admin::McpToolsController#update` are still the Phase 10 (`rao-015`) skeleton stubs (`head :no_content`, no persistence at all) — `Registry.invalidate!` (finding #5's fix) has no real caller yet, since the only controller that would call it doesn't actually save anything | Objectives (Caching) | Not fixed in this ticket — building these two controllers' real CRUD was never itemized as a deliverable in any ticket `rao-015` through `rao-020`, and is not one of rao-021's own named carried-forward requirements (`rao-007`/`rao-009`/`rao-011`/`rao-013`); doing so now would be scope creep on an already-HIGH-complexity ticket. `invalidate!`'s public API is ready for whichever future ticket builds these controllers for real. |
| 9 | LOW | Two of `WORKFLOW.md` §23's six notification rows have no real trigger/detection mechanism anywhere in the codebase ("Workflow Blocked ... optionally the human PM if SLA at risk" needs SLA tracking that doesn't exist; "Project Completed" needs AgentOS-level project-completion detection that doesn't exist) | Objectives (Notification Center) | Not implemented — building either would be new feature design (SLA tracking, completion detection), which this ticket's own Implementation Notes explicitly scope out ("a verification pass ... not new design"); logged for a future ticket, same transparency pattern as `ConversationManager::Session` in `rao-020` |

Verdict (revised): Approved. Findings #2-7 resolved in code; #8-9 are genuine, transparently-logged gaps outside this ticket's own scope, not blocking issues.

### Gate 2 — Security & Performance Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | HIGH | An RBAC audit that only checks "does a `before_action` exist" rather than actually attempting the gated action would miss real permission bugs (e.g. an `authorize` call checking the wrong permission key) | Test Cases #3 | Resolved — RBAC audit test cases require actually attempting each gated action as an unauthorized user, not static code inspection alone |

Verdict: Approved for Phase 16 documentation scope.

**Revision pass (2026-07-03, during implementation)**:

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 2 | MEDIUM | The health check and metrics endpoints need to be reachable by infrastructure tooling (load balancers, uptime monitors, orchestration probes, metrics scrapers) that cannot authenticate as a Redmine user — direct conflict with CLAUDE.md's blanket `require_login`/`accept_api_auth` rule | Code Changes (health_controller.rb, implied) | Resolved — explicit, user-confirmed exception: `HealthController` skips `require_login`, keeps its response body to boolean checks and cross-project aggregates only (no per-project/per-user data, no internal state beyond up/down), and the Deployment Guide instructs restricting network access to these two paths at the reverse proxy/firewall level |

Verdict (revised): Approved. Finding #2's exception is deliberate and documented, not a silent deviation from the blanket auth rule.

### Gate 3 — Pre-Development Sweep
Date: 2026-07-02 | Status: approved (docs-scope)

**Part A**: Confirmed.

**Part B — Predicted implementation bugs**:
| # | Pattern | Predicted Bug | Edge Case Added? |
|---|---------|--------------|-----------------|
| 1 | This is the last phase before release | Time pressure at the final phase leads to "ship now, hardening later" on one or more of the carried-forward requirements listed in Objectives | Logged as a required release-gate check: `RELEASE_NOTES.md`'s v1 entry must explicitly confirm each carried-forward requirement from `rao-007`, `rao-009`, `rao-011`, `rao-013` was verified, not silently dropped |

Verdict: Approved. No unresolved HIGH/CRITICAL findings in spec text.

**Part A confirmed at implementation (2026-07-03)**: `RELEASE_NOTES.md`'s `[Unreleased]` entry explicitly confirms all four — `rao-007` (cache invalidation, both insert and delete, this ticket), `rao-009` (log retention excluding non-terminal runs, this ticket), `rao-011` (reserved `:code_review` key rejected until activated — already implemented in `rao-019`/Phase 14, reconfirmed unchanged here), `rao-013` (Concurrency Guard atomicity — already implemented in `rao-019`/Phase 14, reconfirmed unchanged here, only its event-publishing was extended).

---

## Done

*(Not applicable until this ticket is actually implemented and tested against a running Redmine instance)*
