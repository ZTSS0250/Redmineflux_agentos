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
- [ ] Caching implementation across the modules named in Phase 2 §B.3
- [ ] `app/jobs/redmineflux_agentos/log_retention_job.rb`
- [ ] `lib/redmineflux_agentos/notification_center.rb` (or equivalent)
- [ ] A health-check controller/route
- [ ] `docs/DEPLOYMENT-GUIDE.md`, `docs/UPGRADE-GUIDE.md` (new — proposed, not yet created)

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

### Implementation Notes

- **This phase is a verification pass on prior carried-forward requirements, not new design** — every item in Objectives traces back to a specific earlier Gate finding (`rao-007`, `rao-009`) or an already-designed strategy (Phase 2 §B.1-§B.10) that simply hasn't been implemented and confirmed working yet.
- **RBAC audit is end-to-end, not per-controller** — a permission "gates what it claims to" must be verified by actually attempting the gated action as an unauthorized user, not just confirming a `before_action` exists.
- **`docs/DEPLOYMENT-GUIDE.md`/`docs/UPGRADE-GUIDE.md` are proposed new documents** — per the Documentation Updates process established in `rao-008` §14, any new document must be explicitly proposed with rationale rather than silently created; rationale: a production deployment needs installation/upgrade instructions that don't belong in any existing specification document (which are all pre-implementation design artifacts, not operational runbooks).

---

## Test Cases

### Integration Tests
| # | Test Name | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Cache invalidation, insert and delete | Add then remove a dependency edge | Dependency Dashboard reflects both changes immediately, no stale cache | pending |
| 2 | Log retention excludes in-flight runs | A `waiting_on_dep` run older than the retention window | Its logs are NOT pruned | pending |
| 3 | RBAC end-to-end | Attempt every gated action as a user missing the specific permission | Every attempt is denied, not just hidden from the UI | pending |
| 4 | Health check | Query the health endpoint with the Mock Provider unregistered (simulated boot failure) | Health check reports unhealthy, not a false positive | pending |

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

### Gate 2 — Security & Performance Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | HIGH | An RBAC audit that only checks "does a `before_action` exist" rather than actually attempting the gated action would miss real permission bugs (e.g. an `authorize` call checking the wrong permission key) | Test Cases #3 | Resolved — RBAC audit test cases require actually attempting each gated action as an unauthorized user, not static code inspection alone |

Verdict: Approved for Phase 16 documentation scope.

### Gate 3 — Pre-Development Sweep
Date: 2026-07-02 | Status: approved (docs-scope)

**Part A**: Confirmed.

**Part B — Predicted implementation bugs**:
| # | Pattern | Predicted Bug | Edge Case Added? |
|---|---------|--------------|-----------------|
| 1 | This is the last phase before release | Time pressure at the final phase leads to "ship now, hardening later" on one or more of the carried-forward requirements listed in Objectives | Logged as a required release-gate check: `RELEASE_NOTES.md`'s v1 entry must explicitly confirm each carried-forward requirement from `rao-007`, `rao-009`, `rao-011`, `rao-013` was verified, not silently dropped |

Verdict: Approved. No unresolved HIGH/CRITICAL findings in spec text.

---

## Done

*(Not applicable until this ticket is actually implemented and tested against a running Redmine instance)*
