## Metadata
- **Task ID**: rao-012-task-phase7-mcp-architecture
- **Title**: ROADMAP.md Phase 7 — MCP Architecture (Deepened)
- **Type**: task
- **Status**: done
- **Complexity**: MEDIUM
- **Created**: 2026-07-02
- **Author**: Sheetal Sharma
- **Quality Gates**: Gate 1: approved (docs-scope) | Gate 2: approved (docs-scope) | Gate 3: approved (docs-scope)

---

## Planning

**Description**: `rao-001`'s `docs/MCP-TOOLS.md` catalogs every tool and states the permission model in prose, but ROADMAP.md's Phase 7 list asks for a formal Tool Registry design, Request/Response Contracts, and consolidated Error Handling — none of which existed as their own sections. This task closes that gap, matching the same "deepen rather than duplicate" treatment already applied to Phases 2 and 4.

**Goal**: `Mcp::ToolRegistry` and `Mcp::Executor` (named but not designed in Phase 2 §A.4) have a full design a future implementation task (Phase 13) can build directly from.

**Objectives**:
- [x] Design the Tool Registry's data shape and extension pattern
- [x] Formalize the Permission Model as an explicit two-independent-layer decision flow
- [x] Define a uniform Request/Response Contract every tool handler follows
- [x] Extend the Phase 2 §B.7 error hierarchy with MCP-specific error conditions
- [x] Reconcile ROADMAP.md's finer-grained tool-category list against `docs/MCP-TOOLS.md`'s actual grouping

**Deliverables**:
- [x] `docs/PHASE7-MCP-ARCHITECTURE.md` (new)

---

## Specification

**Complexity**: MEDIUM — most of the content is formalizing decisions already implied by `docs/MCP-TOOLS.md` and Phase 2 §B.8; the one deliberate new decision is reusing the Provider Error Model's exact shape for MCP errors so callers don't need two different error-handling code paths.

**Reason**: Lower complexity than Phases 2-4 because no new security posture is introduced — this document makes existing posture (AD-3, Phase 2 §B.8) concrete and implementable, it doesn't change it.

### Code Changes

None — this task produces documentation only.

### Implementation Notes

- **Error shape reuse is deliberate**: `docs/PHASE7-MCP-ARCHITECTURE.md` §4's Response Contract error field intentionally matches Phase 3 §2.3's Provider Error Model shape (`{error_code, message, retryable}`) — a caller handling a failed agent turn and a caller handling a failed MCP call use the same error-handling code, not two parallel implementations.
- **Two permission layers are independently denial-capable**: neither Redmine's own authorization nor the agent's tool allow-list is a superset of the other — both must pass, explicitly stated as a decision flow (§3) rather than left implicit.
- **Tool category reconciliation**: ROADMAP.md's Phase 7 list names 11 categories where `docs/MCP-TOOLS.md` has 6 groups — this document explains the mapping (Release/Sprint Management fold into Project & Planning per AD-1; Search/Notifications are covered by existing read-only tools and the Notification Center module, not separate categories) rather than inventing new tool categories to match the count.

---

## Test Cases

Not applicable — no executable code in this task.

### QA Test Plan

**Scope**: `docs/PHASE7-MCP-ARCHITECTURE.md` in full, cross-checked against `docs/MCP-TOOLS.md` and `docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md` §A.4/§B.7/§B.8.

**Pre-conditions**: None.

**QA Steps**:
1. Confirm the Tool Registry's fields are sufficient to describe every tool already cataloged in `docs/MCP-TOOLS.md` without needing a tool-specific exception.
2. Confirm the Permission Model flow diagram matches Phase 2 §B.8's enforcement table exactly (no new or contradicting permission rule introduced).
3. Confirm the tool-category reconciliation doesn't imply any new MCP tool beyond what `docs/MCP-TOOLS.md` already lists.

**Expected Outcomes**: Developer confirms the error-shape reuse decision and approves.

**Out of Scope**: Actual tool handler implementation (Phase 13).

---

## Quality Gates

### Gate 1 — Senior Developer Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | LOW | ROADMAP.md's 11-category tool list vs. `docs/MCP-TOOLS.md`'s 6-group catalog could read as a contradiction if not explained | docs/PHASE7-MCP-ARCHITECTURE.md §6 | Resolved — explicit mapping/reconciliation provided, no new category invented |

Verdict: Approved for Phase 7 documentation scope.

### Gate 2 — Security & Performance Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | MEDIUM | Returning a full serialized Redmine model as a tool call `result` could leak fields never intended to be read back by an agent | docs/PHASE7-MCP-ARCHITECTURE.md §4 | Resolved — Response Contract explicitly limits `result` to key attributes only (e.g. `{id, subject}`), never a full model serialization |

Verdict: Approved for Phase 7 documentation scope.

### Gate 3 — Pre-Development Sweep
Date: 2026-07-02 | Status: approved (docs-scope)

**Part A — Gate 1 & 2 resolution confirmed**: Confirmed.

**Part B — Predicted implementation bugs**:
| # | Pattern | Predicted Bug | Edge Case Added? |
|---|---------|--------------|-----------------|
| 1 | `params_schema` validation happens before the handler runs | If a future tool handler is implemented without registering a `params_schema`, invalid params could reach Redmine's own model layer and surface as a confusing `RedmineValidationError` instead of a clear `InvalidParamsError` | Logged as a required test case for Phase 13: every registered tool must have a non-empty `params_schema`, enforced by a registry-level check at boot, not left to convention |

Verdict: Approved. No HIGH/CRITICAL findings.

---

## Done

- **PR**: N/A — documentation-only task, committed directly to `main` per developer instruction
- **Merged**: 2026-07-02
- **Release Notes entry**: `RELEASE_NOTES.md` updated
- **Deliverable verification**: `docs/PHASE7-MCP-ARCHITECTURE.md` confirmed present at close-out
- **Carried-forward requirement**: every registered MCP tool must have a non-empty `params_schema`, enforced by a registry-level boot check — required for Phase 13
