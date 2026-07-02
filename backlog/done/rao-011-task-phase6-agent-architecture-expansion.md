## Metadata
- **Task ID**: rao-011-task-phase6-agent-architecture-expansion
- **Title**: ROADMAP.md Phase 6 — Agent Architecture (Expansion)
- **Type**: task
- **Status**: done
- **Complexity**: MEDIUM
- **Created**: 2026-07-02
- **Author**: Sheetal Sharma
- **Quality Gates**: Gate 1: approved (docs-scope) | Gate 2: approved (docs-scope) | Gate 3: approved (docs-scope)

---

## Planning

**Description**: [ROADMAP.md](../../ROADMAP.md) flagged Phase 6 as only partially covered — `rao-001`'s `docs/AGENTS.md` defines Purpose/Responsibilities/Goals/Input/Output/Memory/MCP Tools/Communication/Workflow per agent, but not Context, Prompt Template binding, Produced/Consumed Events, State Machine, Retry Rules, or Failure Handling/Escalation Rules. This task closes that gap for all 17 agents.

**Goal**: Every agent's full attribute set (per ROADMAP.md's Phase 6 list) is defined, with shared/uniform attributes (State Machine, Retry Rules) stated once rather than artificially repeated per agent.

**Objectives**:
- [x] Add Context, Prompt Template Key(s), Produced Events, Consumed Events, and Escalation Rule per agent (17 agents)
- [x] Confirm all agents share one State Machine definition (no per-agent variant)
- [x] Confirm all agents share one Retry Rules policy (`max_attempts: 3`, no per-agent override)
- [x] Define the shared Failure Handling mechanism and the three escalation patterns that cover all 17 agents

**Deliverables**:
- [x] `docs/PHASE6-AGENT-ARCHITECTURE.md` (new)

---

## Specification

**Complexity**: MEDIUM — almost entirely derivable from `docs/AGENTS.md`'s existing "Workflow" trigger descriptions (mapped onto the `WORKFLOW.md` §15 event catalog) and `docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md` §6.1's prompt categories; the one real decision (uniform retry policy, no per-agent tuning) is a simplicity call, not a complex design.

**Reason**: Low complexity relative to Phases 2-4 because this phase's job is completing an already-well-specified roster's attribute table, not inventing new architecture.

### Code Changes

None — this task produces documentation only.

### Implementation Notes

- **Uniform Retry Rules and State Machine, by design**: per-agent variation was considered and explicitly rejected as speculative — `docs/PHASE6-AGENT-ARCHITECTURE.md` §3 states any future need for a different retry policy is a configuration change (`agents.config_json`), not a reason to design 17 different policies now.
- **Code Review Agent stays fully dormant**: no prompt category, no produced/consumed events — reflecting its reserved-until-v3 status (`docs/PRODUCT-ROADMAP.md`) rather than an oversight.
- **Deployment Agent has no dedicated prompt category** — it reuses the Reporting category for its readiness narratives, since its job (readiness gating) is inherently a reporting-shaped task, not a distinct content-generation need.

---

## Test Cases

Not applicable — no executable code in this task.

### QA Test Plan

**Scope**: `docs/PHASE6-AGENT-ARCHITECTURE.md` in full, cross-checked against `docs/AGENTS.md`, `WORKFLOW.md` §15, and `docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md` §6.1.

**Pre-conditions**: None.

**QA Steps**:
1. Confirm every agent's "Consumed Events" entry traces back to that same agent's "Workflow" trigger description in `docs/AGENTS.md` — no invented trigger.
2. Confirm every "Prompt Template Key" references a category that actually exists in `docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md` §6.1.
3. Confirm the Code Review Agent row states dormancy explicitly rather than silently having empty cells that could be mistaken for gaps.

**Expected Outcomes**: Developer confirms the escalation-pattern summary (§5 — 3 patterns covering all 17 agents) matches their expectations and approves.

**Out of Scope**: Actual agent class implementation (Phase 14).

---

## Quality Gates

### Gate 1 — Senior Developer Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | LOW | Deployment Agent lacking a dedicated prompt category could look like a gap rather than a deliberate choice | docs/PHASE6-AGENT-ARCHITECTURE.md §1 | Resolved — explicitly noted as intentional reuse of the Reporting category |

Verdict: Approved for Phase 6 documentation scope.

### Gate 2 — Security & Performance Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| — | — | No security/performance-relevant content beyond what Phase 2/3 already govern | n/a | n/a |

Verdict: Approved — not applicable.

### Gate 3 — Pre-Development Sweep
Date: 2026-07-02 | Status: approved (docs-scope)

**Part A — Gate 1 & 2 resolution confirmed**: Confirmed.

**Part B — Predicted implementation bugs**:
| # | Pattern | Predicted Bug | Edge Case Added? |
|---|---------|--------------|-----------------|
| 1 | Code Review Agent is registered in the roster (`docs/AGENTS.md`) but has no active prompt/event bindings | A future implementation mistake schedules an `agent_run` for `code_review` before v3 activation, hitting undefined behavior since no prompt category or fixture exists for it | Logged as a required test case for the future Agent Engine implementation task (Phase 14): `AgentEngine::Registry` must explicitly reject scheduling `code_review` until the role is activated in a future version, with a clear error rather than a silent failure |

Verdict: Approved. No HIGH/CRITICAL findings.

---

## Done

- **PR**: N/A — documentation-only task, committed directly to `main` per developer instruction
- **Merged**: 2026-07-02
- **Release Notes entry**: `RELEASE_NOTES.md` updated
- **Deliverable verification**: `docs/PHASE6-AGENT-ARCHITECTURE.md` confirmed present at close-out, covering all 17 agents
- **Carried-forward requirement**: `AgentEngine::Registry` must reject scheduling the reserved `code_review` agent until explicitly activated in a future version — required test case for Phase 14
