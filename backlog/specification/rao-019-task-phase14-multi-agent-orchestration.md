## Metadata
- **Task ID**: rao-019-task-phase14-multi-agent-orchestration
- **Title**: ROADMAP.md Phase 14 — Multi-Agent Orchestration
- **Type**: task
- **Status**: specification
- **Complexity**: HIGH
- **Created**: 2026-07-02
- **Author**: Sheetal Sharma
- **Quality Gates**: Gate 1: approved (docs-scope) | Gate 2: approved (docs-scope) | Gate 3: approved (docs-scope)

---

## Planning

**Description**: Implements the Agent Engine and orchestration model designed across [docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md](../../docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md) §A.5-§A.9, [docs/PHASE6-AGENT-ARCHITECTURE.md](../../docs/PHASE6-AGENT-ARCHITECTURE.md), and [docs/PHASE8-WORKFLOW-ENGINE-ORCHESTRATION.md](../../docs/PHASE8-WORKFLOW-ENGINE-ORCHESTRATION.md): Agent Scheduler, Workflow Engine, Dependency Resolution, Inter-Agent Communication, Event Bus, Parallel Execution, Retry & Recovery. This ticket specifies the implementation; it does not write it. Depends on `rao-017` (Provider) and `rao-018` (MCP) both being implemented first.

**Goal**: All 17 agents (16 active + 1 reserved) run correctly against the Mock Provider and real MCP tools, with Pause/Resume, dependency-driven blocking/resuming, and the Concurrency Guard all functioning exactly as specified.

**Objectives**:
- [ ] `AgentEngine::{Registry,Lifecycle,Runner}` implemented (Phase 2 §A.5)
- [ ] `WorkflowEngine::StateMachine` implemented as one class, two configured instances (Phase 2 §A.6)
- [ ] `EventBus` implemented on `ActiveSupport::Notifications` (Phase 2 §A.7)
- [ ] `DependencyEngine::{Graph,Scheduler}` implemented, including the Pause/Resume scheduling gate (Phase 8 §7)
- [ ] All 17 agent classes implemented, each per its full `docs/AGENTS.md` + `docs/PHASE6-AGENT-ARCHITECTURE.md` profile
- [ ] `ConcurrencyGuard` implemented with an atomic DB operation (Phase 2 §B.9, `rao-009`'s carried-forward test requirement)
- [ ] Reserved Code Review Agent explicitly rejected by the Registry if scheduling is attempted (`rao-011`'s carried-forward test requirement)

**Deliverables** (created when implemented):
- [ ] `lib/redmineflux_agentos/engine/agent_engine/{registry,lifecycle,runner}.rb`
- [ ] `lib/redmineflux_agentos/engine/workflow_engine/state_machine.rb`
- [ ] `lib/redmineflux_agentos/engine/event_bus.rb`
- [ ] `lib/redmineflux_agentos/engine/dependency_engine/{graph,scheduler}.rb`
- [ ] `lib/redmineflux_agentos/agents/*.rb` (17 files)
- [ ] `app/jobs/redmineflux_agentos/agent_run_job.rb`

---

## Specification

**Complexity**: HIGH — the largest implementation phase by file count and by the number of previously-flagged carried-forward requirements it must satisfy simultaneously (atomicity, non-blocking Event Bus subscribers, Pause/Resume, reserved-agent rejection).

**Reason**: This phase is where every "carried forward as mandatory" finding from `rao-007`, `rao-008`, `rao-009`, `rao-011`, and `rao-013` converges — it has the highest concentration of previously-identified risk of any single implementation phase.

### Code Changes

| File | Action | Description |
|---|---|---|
| `lib/redmineflux_agentos/engine/agent_engine/registry.rb` | create | Agent key → class/tool-allowlist/enabled mapping; rejects `code_review` scheduling |
| `lib/redmineflux_agentos/engine/agent_engine/lifecycle.rb` | create | Delegates to `WorkflowEngine::StateMachine` for the 7-state agent-run machine |
| `lib/redmineflux_agentos/engine/agent_engine/runner.rb` | create | Full execution sequence per Phase 2 §A.5's diagram |
| `lib/redmineflux_agentos/engine/workflow_engine/state_machine.rb` | create | Generic transition-table engine, two configured instances |
| `lib/redmineflux_agentos/engine/event_bus.rb` | create | `ActiveSupport::Notifications` wrapper, `agentos.*` namespace |
| `lib/redmineflux_agentos/engine/dependency_engine/graph.rb` | create | Cycle-checked edge insertion |
| `lib/redmineflux_agentos/engine/dependency_engine/scheduler.rb` | create | Priority-ordered enqueueing, Pause/Resume gate, atomic Concurrency Guard check |
| `lib/redmineflux_agentos/agents/*.rb` | create | 17 files per `docs/AGENTS.md`/`docs/PHASE6-AGENT-ARCHITECTURE.md` |
| `app/jobs/redmineflux_agentos/agent_run_job.rb` | create | `ApplicationJob` wrapper invoking `Runner.execute` |

### Implementation Notes

- **Every carried-forward requirement from Phases 2/3/4/6/8 is mandatory here**: Event Bus subscribers non-blocking (`rao-007`); Concurrency Guard atomic (`rao-007`, `rao-009`); dependency-graph cache invalidated on both insert and delete (`rao-007`); reserved-agent rejection (`rao-011`); Pause/Resume check atomic with the scheduling transition, config cache invalidated synchronously (`rao-013`).
- **No new design decisions are made in this ticket** — every mechanism is already fully specified; this phase's job is faithful implementation, and Gate 1 review at implementation time should treat any deviation from the cited designs as a finding, not a discretionary choice.

---

## Test Cases

### Integration Tests
| # | Test Name | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Full dependency chain | Seed a project through Tier 0-6 per `docs/AGENTS.md`'s default chain | Tickets close in dependency order; parallel tiers (4/5/6) run concurrently | pending |
| 2 | Blocking/resuming | Manually hold a Tier 1 ticket open | Tier 2 agent run enters `waiting_on_dep`; closing the Tier 1 ticket resumes it automatically | pending |
| 3 | Pause/Resume | Pause a project mid-execution, then resume | No new `agent_run` scheduled while paused; queued work resumes correctly after | pending |
| 4 | Concurrency cap race | Fire two `queued → running` transition attempts simultaneously at the cap boundary | Exactly one succeeds, cap is never exceeded | pending |
| 5 | Reserved agent rejection | Attempt to schedule `code_review` | Explicit, clear error — not a silent no-op or crash | pending |
| 6 | Event Bus non-blocking | A subscriber with an artificially slow handler | Publisher's own execution time stays within budget (per `rao-007`'s required test) | pending |

### QA Test Plan

**Scope**: End-to-end orchestration across all 17 agents (16 active), the full WORKFLOW.md §28 EMS walkthrough as a reference integration test.

**Pre-conditions**: `rao-015`, `rao-016`, `rao-017`, `rao-018` all implemented.

**QA Steps**: Run the `docs/WORKFLOW.md` §28 walkthrough end-to-end against the Mock Provider; confirm every dashboard reflects state correctly throughout.

**Expected Outcomes**: A complete project (idea → SRS → tickets → dependency-ordered execution → release) runs to completion with no manual intervention beyond the SRS approval and any triggered confirmations.

**Out of Scope**: UI implementation (Phase 15) — this phase can be validated via tests/console even before views exist.

---

## Quality Gates

### Gate 1 — Senior Developer Review
Date: 2026-07-02 | Status: approved (docs-scope, code-level Gate 1 deferred to implementation)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | HIGH | This phase converges the largest number of carried-forward mandatory requirements from prior phases — a checklist is needed so none is silently missed during implementation | Implementation Notes | Resolved — every carried-forward requirement is explicitly re-listed here, not left to the implementer to rediscover across five separate prior tickets |

Verdict: Approved as a specification.

### Gate 2 — Security & Performance Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | HIGH | The atomic Concurrency Guard and atomic Pause check are both concurrency-correctness requirements that are easy to implement incorrectly (naive check-then-act) under real load | Test Cases #3-#4 | Resolved — both have dedicated required test cases exercising the race condition directly, not just unit-testing the happy path |

Verdict: Approved for Phase 14 documentation scope.

### Gate 3 — Pre-Development Sweep
Date: 2026-07-02 | Status: approved (docs-scope)

**Part A**: Confirmed.

**Part B — Predicted implementation bugs**:
| # | Pattern | Predicted Bug | Edge Case Added? |
|---|---------|--------------|-----------------|
| 1 | 17 agent classes implemented over time by different contributors | Agent contract drift — one agent's class doesn't correctly implement the common input/output/memory/tools contract (`docs/AGENTS.md` intro), breaking the Runner's uniform handling (Liskov Substitution, Phase 2 §A.3) | Logged as a required shared test: one contract-conformance test suite run against every agent class, not 17 independent ad hoc tests |

Verdict: Approved. No unresolved HIGH/CRITICAL findings in spec text.

---

## Done

*(Not applicable until this ticket is actually implemented and tested against a running Redmine instance)*
