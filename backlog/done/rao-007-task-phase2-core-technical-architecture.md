## Metadata
- **Task ID**: rao-007-task-phase2-core-technical-architecture
- **Title**: ROADMAP.md Phase 2 — Core Technical Architecture
- **Type**: task
- **Status**: done
- **Complexity**: HIGH
- **Created**: 2026-07-02
- **Author**: Sheetal Sharma
- **Quality Gates**: Gate 1: approved (docs-scope) | Gate 2: approved (docs-scope) | Gate 3: approved (docs-scope)

---

## Planning

**Description**: [ROADMAP.md](../../ROADMAP.md) Phase 2 (Core Technical Architecture) was flagged as only *partially* covered by `rao-001` — that task gave a layered view and a module responsibility table, but stopped short of the deeper design ROADMAP.md's Phase 2 deliverable list asks for: Agent Engine internals, Workflow Engine internals, an Event Bus (previously flagged "forward-looking" in `WORKFLOW.md` §15), Conversation/Memory/Prompt architecture, and the ten cross-cutting engineering strategies (background jobs, queueing, caching, retries, logging, configuration, error handling, security, performance, scalability). This task closes that gap.

**Goal**: Every Phase 2 deliverable is designed to a depth a future implementation task (Phase 10+) can be scoped directly from — concrete class names, public interfaces, and decisions (not just "this will need a strategy").

**Objectives**:
- [x] Deepen Plugin Architecture with an explicit cross-layer dependency-direction rule
- [x] Define the Service-Oriented Architecture convention every service object in this plugin follows
- [x] Document how each SOLID principle applies, with a concrete reference into this codebase's own design
- [x] Expand the Module Responsibility table with public interfaces and dependencies for the most central modules
- [x] Design Agent Engine internals (Registry, Lifecycle, Runner) including a concurrency model
- [x] Design the Workflow Engine as one generic, configurable state machine shared by agent-run and ticket-status workflows
- [x] Design a concrete Event Bus (resolves the `WORKFLOW.md` §15 forward-looking flag)
- [x] Design Conversation, Memory, and Prompt architecture with clear ownership boundaries
- [x] Write all ten cross-cutting strategies (Background Job, Queue, Cache, Retry, Logging, Configuration, Error Handling, Security, Performance, Scalability)

**Deliverables**:
- [x] `docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md` (new — Part A: Architecture, Part B: Cross-Cutting Strategies)

---

## Specification

**Complexity**: HIGH — this is genuine architectural design work, not citation/organization of already-approved content (unlike most of the Phase 1 breakdown tickets). Every downstream implementation phase (10 through 16) is written against the decisions made here, particularly the Event Bus design and the Agent Engine's concurrency model.

**Reason**: Getting the Event Bus's synchronous-in-process decision, the service object convention, or the concurrency guard's semantics wrong here would cascade into every agent-engine-touching implementation task, the same way `rao-001`'s AD-1 through AD-5 set precedent for everything after it.

### Code Changes

None — this task produces documentation only.

### Implementation Notes

- **Event Bus decision**: built on `ActiveSupport::Notifications` (already in Rails/Redmine's dependency graph) rather than a new message-queue dependency — keeps the "zero external data egress in v1" invariant ([docs/SECURITY-COMPLIANCE-OVERVIEW.md](../../docs/SECURITY-COMPLIANCE-OVERVIEW.md)) untouched and avoids new infrastructure for Phase 10+ to stand up. Synchronous, in-process dispatch by design — see Gate 2 finding #1 below for the constraint this creates.
- **Background Job Strategy decision**: plain `ApplicationJob`/`ActiveJob::Base`, adapter-agnostic — directly informed by the sibling `redmineflux_devops` plugin's already-implemented, tested pattern (`app/jobs/devops_webhook_job.rb`: `ApplicationJob` subclass, `retry_on` with an explicit exponential-backoff proc for Rails 6.1/7.x compatibility, `discard_on ActiveRecord::RecordNotFound`). This resolves Open Question #2 in `docs/PHASE1-SPECIFICATION.md` §7 by precedent rather than by guessing.
- **Service object convention**: one canonical shape (`.call` entry point, Result object for expected failures, constructor-injected dependencies) so Gate 1 review has one concrete pattern to check every future service against, rather than each task inventing its own shape.
- **Two state machines, one engine**: agent-run status and ticket-status workflow are configured instances of one `WorkflowEngine::StateMachine` class (transition table + guards), not two separate implementations — this was an explicit design choice to avoid the drift risk of two hand-rolled state machines evolving inconsistently.
- **Security Strategy (Part B.8) is the code-level enforcement mapping for `docs/SECURITY-COMPLIANCE-OVERVIEW.md`'s principles** — each principle in that product-level document now has a specific "enforced where" answer (e.g. least privilege → a named guard clause in `Mcp::Executor.call`), closing the gap between "we have a security posture" and "here is exactly where in the code that's true."

---

## Test Cases

Not applicable — no executable code in this task.

### QA Test Plan

**Scope**: `docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md` in full, plus consistency against `docs/PHASE1-SPECIFICATION.md` §2, `WORKFLOW.md` (especially §8, §14, §15), and `docs/SECURITY-COMPLIANCE-OVERVIEW.md`.

**Pre-conditions**: None.

**QA Steps**:
1. Confirm every deliverable named in `ROADMAP.md`'s Phase 2 list has a corresponding section in the new document (Plugin Architecture, SOA, SOLID, Module Responsibilities, Agent Engine, Workflow Engine, Event Bus, Conversation/Memory/Prompt Architecture, and all ten cross-cutting strategies) — nothing was silently dropped.
2. Confirm the Event Bus design explicitly resolves (rather than re-flags) the "forward-looking" note in `WORKFLOW.md` §15.
3. Confirm the agent-run state machine described here is identical to `WORKFLOW.md` §8's canonical version — this document must not introduce a second, conflicting definition.
4. Confirm the Security Strategy table's "enforced where" column maps to a real principle in `docs/SECURITY-COMPLIANCE-OVERVIEW.md` §1 — no invented principle, no dropped one.
5. Confirm the Background Job Strategy's `ApplicationJob` pattern is consistent with the cited `redmineflux_devops` precedent (retry/discard semantics).

**Expected Outcomes**: Developer confirms the architectural decisions (especially the Event Bus's synchronous-in-process choice and the service object convention) match their intent before Phase 10+ implementation begins, and approves.

**Out of Scope**: Any actual class/module implementation (Phase 10+); Folder Structure (Phase 5, not yet spec'd); per-agent detail beyond what's already in `docs/AGENTS.md` (Phase 6 expansion, not yet spec'd).

---

## Quality Gates

### Gate 1 — Senior Developer Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | MEDIUM | Sharing one generic `WorkflowEngine::StateMachine` class across two different state machines risks becoming an over-generic abstraction if agent-run and ticket-status semantics diverge further later | docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §A.6 | Resolved by keeping the shared class deliberately minimal (transition table + guards only) — flagged as a Gate 1 watch item for whoever implements it, not solved by adding speculative flexibility now |
| 2 | LOW | Service object convention doesn't specify how a service reports partial success within a batch operation (e.g. ticket generation creating 9 of 10 tickets before a failure) | docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §A.2 | Resolved — the Result object's `errors` collection is explicitly documented as able to carry partial-success detail, not just a boolean |

Verdict: Approved for Phase 2 documentation scope.

### Gate 2 — Security & Performance Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | HIGH | The Event Bus's synchronous, in-process dispatch means a slow or faulty subscriber blocks the publisher's own thread (a job or, worse, a request) | docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §A.7 | Resolved by documenting an explicit implementation-time hard rule: subscribers must be fast and non-blocking (enqueue a job for any real work rather than doing it inline) — carried forward as a required Gate 3 check on whichever future task implements the first Event Bus subscriber |
| 2 | MEDIUM | A naive check-then-act `ConcurrencyGuard` implementation would race under concurrent job pickup, allowing the configured cap to be exceeded | docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §B.9 | Resolved by specifying the guard must use an atomic DB operation (row lock or conditional update), not an application-level read-then-write — carried forward as a required test case for the future implementation task |
| 3 | MEDIUM | Explicit-invalidation caching (§B.3) is only as correct as its invalidation hook coverage — a missed hook (e.g. invalidating on insert but not on delete) silently serves stale data | docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §B.3 | Accepted as a known risk of the explicit-invalidation approach (already required by the existing NFR); carried forward as a Gate 3 predicted bug below rather than solved by switching to a different caching strategy this document doesn't have the implementation context to fully specify |

Verdict: Approved for Phase 2 documentation scope. Findings #1 and #2 are carried forward as mandatory implementation-time requirements (not just documented intent) for the tasks that build the Event Bus's first subscriber and the Concurrency Guard respectively.

### Gate 3 — Pre-Development Sweep
Date: 2026-07-02 | Status: approved (docs-scope)

**Part A — Gate 1 & 2 resolution confirmed**: Confirmed — all four resolutions above are present in the current text of `docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md` (§A.6, §A.2, §A.7, §B.9, §B.3 respectively).

**Part B — Predicted implementation bugs**:
| # | Pattern | Predicted Bug | Edge Case Added? |
|---|---------|--------------|-----------------|
| 1 | Event Bus subscriber does synchronous heavy work | A future subscriber (e.g. a naive Notification Center implementation) does a slow synchronous call inline, silently degrading whatever job/request published the event | Logged as a required test case for the future Event Bus implementation task: assert publishing an event does not block beyond a small time budget even if a subscriber is slow |
| 2 | ConcurrencyGuard race condition | Two `agent_run`s transition `queued → running` in the same instant, both reading the counter before either writes, exceeding the configured cap | Logged as a required concurrency test case (parallel transition attempts) for the future Agent Engine implementation task |
| 3 | Cache invalidation hook coverage gap | The per-project dependency graph cache (§B.3) is invalidated on `dependencies` insert but a future edit misses invalidating on delete (e.g. `create_issue_relation`'s inverse), serving a stale graph to the Dependency Dashboard | Logged as a required test case pair (insert *and* delete invalidation) for the future Dependency Engine implementation task |

Verdict: Approved. No unresolved HIGH/CRITICAL findings in spec text; all three predicted bugs are carried forward as explicit requirements/test cases for their respective future implementation tasks, not blockers to this documentation task.

---

## Done

- **PR**: N/A — documentation-only task, committed directly to `main` per developer instruction (no application code, no PR review required)
- **Merged**: 2026-07-02
- **Release Notes entry**: `RELEASE_NOTES.md` updated
- **Deliverable verification**: `docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md` confirmed present at close-out, with both Part A (Architecture) and Part B (Cross-Cutting Strategies) fully populated
- **Carried-forward requirements** (not closed by this ticket — mandatory for future implementation tasks, per Gate 2/3 findings): Event Bus subscribers must be non-blocking (enqueue a job for real work); the Concurrency Guard must use an atomic DB operation, not check-then-act; the per-project dependency-graph cache needs invalidation test coverage on both insert and delete paths
- **Note**: the 5 open questions in `docs/PHASE1-SPECIFICATION.md` §7 remain unresolved (though B.1's Background Job Strategy decision effectively answers Open Question #2 by precedent) and still block Phase 10 — closing this ticket does not close those questions
