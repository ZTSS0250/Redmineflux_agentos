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
- [x] `AgentEngine::{Registry,Lifecycle,Runner}` implemented (Phase 2 §A.5)
- [x] `WorkflowEngine::StateMachine` implemented as one class, two configured instances (Phase 2 §A.6)
- [x] `EventBus` implemented on `ActiveSupport::Notifications` (Phase 2 §A.7)
- [x] `DependencyEngine::{Graph,Scheduler}` implemented, including the Pause/Resume scheduling gate (Phase 8 §7)
- [x] All 17 agent classes implemented, each per its full `docs/AGENTS.md` + `docs/PHASE6-AGENT-ARCHITECTURE.md` profile
- [x] `ConcurrencyGuard` implemented with an atomic DB operation (Phase 2 §B.9, `rao-009`'s carried-forward test requirement)
- [x] Reserved Code Review Agent explicitly rejected by the Registry if scheduling is attempted (`rao-011`'s carried-forward test requirement)

**Deliverables** (created when implemented):
- [x] `lib/redmineflux_agentos/engine/agent_engine/{registry,lifecycle,runner}.rb`
- [x] `lib/redmineflux_agentos/engine/workflow_engine/state_machine.rb`
- [x] `lib/redmineflux_agentos/engine/event_bus.rb`
- [x] `lib/redmineflux_agentos/engine/dependency_engine/{graph,scheduler}.rb`
- [x] `lib/redmineflux_agentos/agents/*.rb` (17 files)
- [x] `app/jobs/redmineflux_agentos/agent_run_job.rb`

**Implemented (2026-07-03) — untested against a live Redmine instance**: every Objective above, plus `MemorySweepJob`/`CostRollupJob` (both already stubbed as "Phase 14" in their own Phase 10 comments, so completing them here rather than leaving them stubbed alongside everything else this ticket implements). 39 tests (147 assertions) were actually run — not just written — through the real Minitest+Mocha runner against a scoped ad hoc harness: **StateMachine (7), EventBus (3), DependencyEngine::Graph (5), TemplateResolver (6), ConcurrencyGuard (4), Lifecycle (8), and the 17-agent contract-conformance suite Gate 3 required (6, 90 assertions)**. All passed. **Status remains `specification`, not `done`** — no live Redmine instance/real database in this environment, so `AgentEngine::Runner`'s full Provider+MCP integration, the literal simultaneous-thread concurrency race, and `DependencyEngine::Scheduler`'s priority-ordering/pause-gate behavior against real Issue records are not exercised here; the harness intentionally scoped to what's testable without them (see the Test Cases section's verification note).

Several genuine gaps and one significant cross-phase integration bug were found and fixed, all logged transparently as a Gate 1 revision below:

1. **The AgentOS System user could never have passed Layer 1 for any MCP tool** — `rao-015`'s `SystemUserProvisioner::ROLE_PERMISSIONS` only granted AgentOS's own UI-level permissions, none of the Redmine *core* permissions (`:add_issues`, `:edit_project`, etc.) the six tool files' `authorize:` procs (`rao-018`) actually check. Every agent-initiated MCP write would have failed permission checks on a live instance despite Layer 2 correctly allowing it. Fixed by adding exactly the core permissions those `authorize:` procs check — least-privilege, nothing beyond what a tool actually gates on.
2. **The dependency-driven auto-resume mechanism — this ticket's own headline feature — would never have fired**: `issue_tools.rb`'s `update_issue`/`bulk_close_issues` handlers (`rao-018`) change `issue.status` directly and never published anything; `DependencyEngine::Scheduler` subscribes to an `issue.status_changed` event that nothing ever emitted. Fixed by publishing that event from both handlers when status actually changes — the one real code path that changes issue status now correctly triggers the Dependency Engine.
3. **Three more modules referenced throughout the approved docs but never itemized as a file in any ticket's Code Changes table**: `ConcurrencyGuard` (Phase 2 §B.9), `MemoryStore::Repository` (Phase 2 §A.9), and `Prompts::TemplateResolver`'s actual implementation (Phase 2 §A.10, previously stubbed) — all required by this ticket's own Objectives/Runner sequence diagram to function at all. Added, scoped to exactly what §A.9/§A.10/§B.9 already specify.
4. **No ticket ever seeds actual `redmineflux_agentos_agents` or `redmineflux_agentos_prompt_templates` rows** — without them, `tools_for(agent)` (Layer 2) has no `tool_allowlist` to check and `TemplateResolver` has no template to resolve, so no agent could ever run on a fresh install. Added two idempotent rake tasks (matching the existing `provision_system_user` convention) seeding the 17 agents' tool allow-lists (from `docs/AGENTS.md`'s own per-agent MCP Tools rows) and one minimal shared prompt template per category actually used.

See the Quality Gates section for the remaining design-shape decisions (the `queued -> running` transition's atomicity requiring it to bypass the generic `StateMachine`, the ticket-status machine's distinct flat event-naming convention, and the Runner/Agent division of labor).

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
- **Acknowledged gap, not silently skipped**: Phase 2 §B.3's per-project dependency-graph cache (explicit-invalidation on insert/delete) was **not implemented** — `DependencyEngine::Graph`/`Scheduler` query the DB directly on every call. This is purely a performance layer on top of already-correct behavior (identical to why `TemplateResolver`'s own §B.3 cache was deferred, see rao-019's Planning note) — correctness does not depend on it — but it is explicitly `rao-007`'s carried-forward requirement and this ticket does not close it. Flagged here rather than left for a future reader to discover it's missing.

---

## Test Cases

### Integration Tests
| # | Test Name | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Full dependency chain | Seed a project through Tier 0-6 per `docs/AGENTS.md`'s default chain | Tickets close in dependency order; parallel tiers (4/5/6) run concurrently | not run here — needs a live Redmine instance with real Issue/Project records; the underlying mechanisms (Graph cycle-checking, Scheduler priority ordering) are unit-tested in isolation instead |
| 2 | Blocking/resuming | Manually hold a Tier 1 ticket open | Tier 2 agent run enters `waiting_on_dep`; closing the Tier 1 ticket resumes it automatically | not run here (same reason) — but the actual bug that would have silently broken this feature entirely (issue status changes never publishing an event) was found and fixed, see Planning |
| 3 | Pause/Resume | Pause a project mid-execution, then resume | No new `agent_run` scheduled while paused; queued work resumes correctly after | pass (2026-07-03, ad hoc harness) — `Lifecycle`'s pause-gate logic, both paused and resumed |
| 4 | Concurrency cap race | Fire two `queued → running` transition attempts simultaneously at the cap boundary | Exactly one succeeds, cap is never exceeded | pass (2026-07-03, ad hoc harness) for cap-enforcement *logic*; the literal simultaneous-thread race needs a real database's row-locking to prove race-free (see Gate 2's live-verification flag) |
| 5 | Reserved agent rejection | Attempt to schedule `code_review` | Explicit, clear error — not a silent no-op or crash | pass (2026-07-03, ad hoc harness) — part of the 17-agent contract-conformance suite |
| 6 | Event Bus non-blocking | A subscriber with an artificially slow handler | Publisher's own execution time stays within budget (per `rao-007`'s required test) | pass (2026-07-03, ad hoc harness) — see that test file's header comment for what this actually proves vs. what remains a subscriber-authoring discipline `ActiveSupport::Notifications`'s synchronous design cannot infrastructurally enforce |

**Verification note (2026-07-03)**: same approach as `rao-017`/`rao-018` — `test/unit/{agents,engine,prompts}/*_test.rb` were run **unmodified** (byte-for-byte copies, diffed to confirm) through the real Minitest+Mocha runner against a minimal ad hoc harness with fake in-memory stand-ins for `redmineflux_agentos_agent_runs`/`_dependencies`/`_prompt_templates`/`_configurations` and a fake `Project`. Deliberately NOT loaded: `AgentEngine::Runner`, `Mcp::*`, `Providers::*` — nothing in this batch invokes an agent's `#call` or executes a real tool call, so that stack (meaningless without Redmine core's real Issue/Project/WikiPage/TimeEntry models) is out of scope for this harness, same boundary `rao-017`/`rao-018`'s harnesses drew. Result: **39/39 tests pass, 147 assertions, 0 failures, 0 errors** (7 test files: `state_machine_test.rb` (7), `event_bus_test.rb` (3), `dependency_graph_test.rb` (5), `template_resolver_test.rb` (6), `concurrency_guard_test.rb` (4), `lifecycle_test.rb` (8), `contract_conformance_test.rb` (6, 90 assertions across all 17 agents) — satisfying Gate 3 finding #1's "one shared test suite, not 17 independent ad hoc tests" requirement).

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

**Revision pass (2026-07-03, during implementation)** — the docs already fully specify every mechanism (per this ticket's own Implementation Notes: "no new design decisions are made in this ticket"), but three implementation-*shape* questions weren't literally answered by any single passage, plus the cross-phase integration bug and permission gap described in Planning:

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 2 | HIGH | `queued -> running`'s guard (Concurrency Guard cap check) and mutation (flip to `running`) must be atomic together, but the generic `StateMachine`'s shape is guard-*then-separately*-write — routing this transition through it as just another guarded entry would reintroduce the exact check-then-act race the guard exists to prevent | §A.5, §A.6 | Resolved — `AgentEngine::Lifecycle` special-cases only this one transition, calling `ConcurrencyGuard.acquire` directly (which performs guard+mutate as one DB transaction); every other transition still goes through the generic engine |
| 3 | MEDIUM | WORKFLOW.md §15 catalogs ticket-status events as one flat name (`issue.status_changed`) regardless of target status, but the agent-run machine's own catalog entries are one-name-per-status (`agent_run.queued/.running/...`) — the generic `StateMachine` needed to support both shapes from one class | §A.6, WORKFLOW.md §15 | Resolved — `StateMachine` accepts an optional `event_name` proc overriding its default one-name-per-status behavior; the ticket-status instance overrides it, the agent-run instance uses the default |
| 4 | MEDIUM | The Runner sequence diagram (Phase 2 §A.5) shows "Runner" performing every step (memory fetch, prompt resolve, provider call) but `docs/AGENTS.md`'s own agent-class contract implies each agent's `#call` "executes this agent's turn against the active Provider" — an apparent division-of-labor ambiguity between Runner and Agent | Phase 2 §A.5 diagram vs. `agents/base_agent.rb`'s own class comment | Resolved — Runner owns the cross-cutting mechanical steps identical for every agent (memory fetch/write, tool-call execution, lifecycle transition, so Liskov Substitution actually holds); each agent's `#call` owns only what varies per role (which prompt category/variables) and calls the Provider itself, returning the raw response for the Runner to act on |

Verdict (revised): Approved. Findings #2-#4 are shape clarifications the docs already implied but didn't spell out in one place — none contradicts anything already gate-approved; findings #1 (permission gap) and the dependency-event integration bug (Planning) are logged there as the concrete bugs they are, not spec ambiguities.

### Gate 2 — Security & Performance Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | HIGH | The atomic Concurrency Guard and atomic Pause check are both concurrency-correctness requirements that are easy to implement incorrectly (naive check-then-act) under real load | Test Cases #3-#4 | Resolved — both have dedicated required test cases exercising the race condition directly, not just unit-testing the happy path |

Verdict: Approved for Phase 14 documentation scope. **Live-verification flag**: the atomic Concurrency Guard's *mechanism* (`.lock` inside one `transaction` block) is implemented and its cap-enforcement *logic* is unit-tested against a fake store, but the literal simultaneous-thread race requires a real database's row-locking semantics to prove race-free — out of this environment's reach, same category of gap as every other phase's "untested against a live instance" note.

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
