## Metadata
- **Task ID**: rao-013-task-phase8-workflow-engine-orchestration
- **Title**: ROADMAP.md Phase 8 — Workflow Engine & Orchestration
- **Type**: task
- **Status**: done
- **Complexity**: HIGH
- **Created**: 2026-07-02
- **Author**: Sheetal Sharma
- **Quality Gates**: Gate 1: approved (docs-scope) | Gate 2: approved (docs-scope) | Gate 3: approved (docs-scope)

---

## Planning

**Description**: Phase 8 was entirely un-spec'd in `ROADMAP.md`. Most of its deliverables (Event Bus, Retry Policy, Escalation Flow, Dependency Resolution) are already fully designed elsewhere and just need cataloging — but **Pause/Resume Logic** is a genuine, previously-deferred gap: `WORKFLOW.md` §8 and `docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md` §A.6 both explicitly pushed it to "Phase 8" rather than inventing it prematurely. This task designs it for real.

**Goal**: Every Phase 8 deliverable is either cataloged (pointing to its existing full design) or, for the two genuinely new pieces (Pause/Resume Logic, Completion Criteria), designed to implementation-ready depth.

**Objectives**:
- [x] Catalog existing Workflow Definitions rather than re-describing them
- [x] Confirm Event Bus Design, Retry Policy, and Escalation Flow are unchanged (cite, don't duplicate)
- [x] State the tier-boundary interpretation of Dependency Resolution needed for Parallel/Sequential Execution Rules
- [x] Formalize Parallel and Sequential Execution Rules explicitly (even though no new mechanism was needed)
- [x] Design a Scheduling Strategy for simultaneously-unblocked work (reusing the existing `ai_tasks.priority` column)
- [x] Design Pause/Resume Logic without modifying the already-approved 7-state agent-run machine
- [x] Define Completion Criteria for release readiness as one explicit checklist

**Deliverables**:
- [x] `docs/PHASE8-WORKFLOW-ENGINE-ORCHESTRATION.md` (new)

---

## Specification

**Complexity**: HIGH — same tier as `rao-007`/`rao-009`: Pause/Resume Logic is a load-bearing new decision with real race-condition risk if implemented carelessly, not just organization of existing content.

**Reason**: Getting Pause/Resume wrong — e.g. by adding a state to the already-cross-referenced agent-run machine, or by not making the pause check atomic with the scheduling transition — would either break every document that already cites the 7-state machine as canonical, or silently let paused projects keep executing.

### Code Changes

None — this task produces documentation only.

### Implementation Notes

- **Pause/Resume does not touch the agent-run state machine**: implemented as a `redmineflux_agentos_configurations` row checked by `DependencyEngine::Scheduler` before scheduling — reuses the already-approved generic configuration mechanism (Phase 4 §11) instead of a schema change or a new state.
- **Pause only gates new scheduling, never interrupts a running agent_run**: cooperative mid-run interruption is explicitly out of scope for v1 — `cancelled` (already in the state machine) covers "stop this specific run now."
- **Scheduling Strategy reuses `ai_tasks.priority`**: no new priority concept was introduced — simultaneously-unblocked work is ordered by a field the Ticket Generator already populates from the SRS.
- **Completion Criteria is a read/aggregation checklist, not a new state machine**: five checkable conditions determine when `releases.status` moves to `released` — this was previously implied across several documents but never stated as one list.

---

## Test Cases

Not applicable — no executable code in this task.

### QA Test Plan

**Scope**: `docs/PHASE8-WORKFLOW-ENGINE-ORCHESTRATION.md` in full, cross-checked against `WORKFLOW.md` §8/§13/§14, `docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md` §A.6/§A.7/§B.4/§B.9, and `docs/PHASE6-AGENT-ARCHITECTURE.md` §5.

**Pre-conditions**: None.

**QA Steps**:
1. Confirm the agent-run state machine referenced (§0 framing) is identical to `WORKFLOW.md` §8's canonical version — no 8th state introduced.
2. Confirm Pause/Resume's enforcement point (`DependencyEngine::Scheduler`) is consistent with where Phase 2 §A.4 already placed that module's responsibility.
3. Confirm the Completion Criteria checklist doesn't contradict the QA/Security/Deployment gating rules already stated in `docs/AGENTS.md` #11/#12/#14.

**Expected Outcomes**: Developer confirms the Pause/Resume design (scheduling gate, not a new state) matches their intent — this is the one genuinely new product decision in this task — and approves.

**Out of Scope**: Actual orchestration engine implementation (Phase 14).

---

## Quality Gates

### Gate 1 — Senior Developer Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | MEDIUM | Reusing the generic `configurations` table for pause state, rather than a dedicated column, could look like overloading a mechanism beyond its intent | docs/PHASE8-WORKFLOW-ENGINE-ORCHESTRATION.md §7 | Resolved — explicitly consistent with Phase 4 §11's "mutated in place, not versioned" category for exactly this kind of live operational flag, not an ad hoc reuse |

Verdict: Approved for Phase 8 documentation scope.

### Gate 2 — Security & Performance Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | HIGH | If the pause check and the `queued → running` transition aren't part of the same atomic operation, a run could "slip through" between the check and the transition, executing after the project was supposedly paused | docs/PHASE8-WORKFLOW-ENGINE-ORCHESTRATION.md §7 | Carried forward as a mandatory requirement for the Phase 14 implementation task: the pause check must be part of the same transaction/lock as the state transition it gates, not a separate earlier check (same class of requirement as `rao-009`'s Gate 3 finding #1 on atomic prompt-version activation) |

Verdict: Approved for Phase 8 documentation scope. Finding #1's atomicity requirement is carried forward as mandatory, not just documented intent.

### Gate 3 — Pre-Development Sweep
Date: 2026-07-02 | Status: approved (docs-scope)

**Part A — Gate 1 & 2 resolution confirmed**: Confirmed.

**Part B — Predicted implementation bugs**:
| # | Pattern | Predicted Bug | Edge Case Added? |
|---|---------|--------------|-----------------|
| 1 | Configuration values are cached with explicit invalidation (Phase 2 §B.3) | Pausing a project writes the `configurations` row but the Scheduler reads a stale cached value if the write path forgets to invalidate synchronously, letting scheduling continue briefly (or indefinitely) after a pause | Logged as a required test case for Phase 14: setting `execution_paused` must synchronously invalidate the config cache in the same request/service call, verified by a test that pauses and immediately asserts no new `agent_run` is scheduled |

Verdict: Approved. No unresolved HIGH/CRITICAL findings in spec text; finding carried forward as a required test case for Phase 14.

---

## Done

- **PR**: N/A — documentation-only task, committed directly to `main` per developer instruction
- **Merged**: 2026-07-02
- **Release Notes entry**: `RELEASE_NOTES.md` updated
- **Deliverable verification**: `docs/PHASE8-WORKFLOW-ENGINE-ORCHESTRATION.md` confirmed present at close-out
- **Carried-forward requirements**: pause check must be atomic with the `queued → running` transition; setting `execution_paused` must synchronously invalidate the config cache — both required for Phase 14
