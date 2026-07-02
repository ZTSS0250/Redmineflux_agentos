## Metadata
- **Task ID**: rao-001-task-phase1-foundation-specification
- **Title**: Phase 1 — Foundation Specification for redmineflux_agentos
- **Type**: task
- **Status**: done
- **Complexity**: HIGH
- **Created**: 2026-07-02
- **Author**: Sheetal Sharma
- **Quality Gates**: Gate 1: approved (docs-scope) | Gate 2: approved (docs-scope) | Gate 3: approved (docs-scope)

---

## Planning

**Description**: Design a new Redmine plugin, `redmineflux_agentos`, that acts as an AI Operating System for Redmine/RedmineFlux — a multi-agent system that turns a natural-language product idea into a fully planned, ticketed, dependency-ordered, continuously-monitored Redmine project. Full brief captured verbatim in conversation; condensed vision in [../../VISION.md](../../VISION.md).

**Goal**: Produce a Phase 1 deliverable — functional specification, architecture, folder structure, database schema, plugin navigation, permissions, agent lifecycle, and UI wireframes — that the developer can review and approve before any code (Phase 2 skeleton) is written. No application code is in scope for this task.

**Objectives**:
- [x] Functional specification of the end-to-end idea-to-execution flow
- [x] Layered architecture with module responsibility table
- [x] 17-agent roster with responsibility/goals/input/output/memory/tools/communication/workflow per agent
- [x] Normalized database schema covering agents, runs, conversations, plans, releases, sprints, tasks, dependencies, prompts, knowledge base, memory, execution logs, MCP calls, token usage, cost tracking, configuration, audit logs
- [x] MCP tool catalog mapped to Redmine actions, with confirmation-gating for irreversible operations
- [x] Plugin navigation (project menu + admin menu) and permission set
- [x] Agent lifecycle state machine and inter-agent blocking/resuming model
- [x] ASCII UI wireframes for the seven key screens (chat/wizard, requirement review, agent dashboard, dependency dashboard, release planner, token/cost dashboard, execution history)

**Deliverables**:
- [x] `redmineflux_agentos/CLAUDE.md`
- [x] `redmineflux_agentos/VISION.md`
- [x] `redmineflux_agentos/docs/PHASE1-SPECIFICATION.md`
- [x] `redmineflux_agentos/docs/AGENTS.md`
- [x] `redmineflux_agentos/docs/DATABASE-SCHEMA.md`
- [x] `redmineflux_agentos/docs/MCP-TOOLS.md`
- [x] `redmineflux_agentos/docs/UI-WIREFRAMES.md`
- [x] `redmineflux_agentos/backlog/` scaffolding (this file), `TODO.md`, `RELEASE_NOTES.md`

---

## Specification

**Complexity**: HIGH — foundational design spanning 17 agents, ~20 modules, ~20 database tables, and the full MCP tool surface. No migrations or code in this task; complexity reflects breadth of design surface, not LOC.

**Reason**: Sets architectural precedent for every future `rao-NNN` task; getting the module boundaries, dependency model, and confirmation-gating wrong here would cascade into every later phase.

### Code Changes

None — this task produces documentation only. Code Changes tables begin with `rao-002` (Phase 2: plugin skeleton).

### Implementation Notes

See [docs/PHASE1-SPECIFICATION.md](../../docs/PHASE1-SPECIFICATION.md) §2.3 "Key architectural decisions" (AD-1 through AD-5) — these are binding for all subsequent specs unless explicitly revisited with the developer.

Five open questions are logged in §7 of that document and must be answered before `rao-002` (Phase 2) can be scoped:
1. LLM provider(s) to target first
2. Background job backend assumption
3. MCP transport (in-process vs. shared external MCP server with `redmineflux_devops`)
4. Confirmation UX pattern for irreversible actions
5. Whether to reserve schema/permission space now for future code-writing agents

---

## Test Cases

Not applicable — no executable code in this task. Test case authoring begins with `rao-002` once controllers/models exist.

### QA Test Plan

**Scope**: Documentation review only.

**Pre-conditions**: None.

**QA Steps**:
1. Read `docs/PHASE1-SPECIFICATION.md`, `docs/AGENTS.md`, `docs/DATABASE-SCHEMA.md`, `docs/MCP-TOOLS.md`, `docs/UI-WIREFRAMES.md`.
2. Confirm the 5 open questions in §7 are answerable or acceptable as-is.
3. Confirm the architectural decisions (AD-1 to AD-5) match developer intent.

**Expected Outcomes**: Developer approves this task (moves it to `backlog/specification/` is skipped since it's already there in `specification` status; on approval it moves to `backlog/done/`) and Phase 2 (plugin skeleton) is authorized.

**Out of Scope**: Any actual Ruby/Rails code, migrations, or UI implementation.

---

## Quality Gates

### Gate 1 — Senior Developer Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | MEDIUM | Sprint concept has no native Redmine equivalent, easy to design inconsistently across future tasks | DATABASE-SCHEMA.md `sprints` | Resolved via AD-1: sprints are plugin-owned, linked to `releases`, not overloaded onto `Version` |
| 2 | MEDIUM | Risk of scope creep into autonomous code-writing without a security design | AGENTS.md Backend/Frontend/DevOps agents | Resolved via AD-2: code-writing explicitly deferred to a future dedicated spec |

Verdict: Approved for Phase 1 documentation scope. Code-level Gate 1 checks (authorize present, strong params, `dependent:` options, respond_to blocks) are N/A until `rao-002`+ introduce real controllers/models, and will be re-run per task at that point.

### Gate 2 — Security & Performance Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | HIGH | Agents could bypass Redmine's own authorization if given direct model access | PHASE1-SPECIFICATION.md §2.1 | Resolved via AD-3: all Redmine state changes routed through MCP layer with `User.current` scoping enforced per call |
| 2 | HIGH | Irreversible actions (delete, bulk close) executed autonomously would be a production risk | MCP-TOOLS.md | Resolved via AD-5 + `requires_confirmation` flag + Pending Approvals queue |
| 3 | MEDIUM | Secrets/API tokens could leak into `mcp_tool_calls.params_json` or logs | DATABASE-SCHEMA.md `mcp_tool_calls` | Resolved: design notes mandate redaction before persistence, following `redmineflux_devops` precedent |
| 4 | MEDIUM | Cross-project data leakage risk on dashboard aggregation queries | DATABASE-SCHEMA.md design notes | Resolved: explicit `where(project_id: ...)` scoping called out as a requirement, to be enforced per Gate 2 on each future task touching dashboards |

Verdict: Approved for Phase 1 documentation scope. Concrete enforcement (actual `authorize` calls, actual redaction code) is re-verified per task once implemented.

### Gate 3 — Pre-Development Sweep
Date: 2026-07-02 | Status: approved (docs-scope)

**Part A — Gate 1 & 2 resolution confirmed**: Confirmed — AD-1 through AD-5 and the four Gate 2 findings are present in the current text of `PHASE1-SPECIFICATION.md`, `DATABASE-SCHEMA.md`, and `MCP-TOOLS.md` (not just agreed verbally).

**Part B — Predicted implementation bugs** (informational for Phase 2+, not blocking Phase 1):
| # | Pattern | Predicted Bug | Edge Case Added? |
|---|---------|--------------|-----------------|
| 1 | `ai_tasks.status` denormalized from linked issue | Dashboard shows stale status if `update_issue` MCP call updates Redmine but not `ai_tasks` in the same transaction | Logged as a design note in DATABASE-SCHEMA.md; will become a Gate 3 edge case on the task that implements `update_issue` |
| 2 | Dependency cycles | A malformed SRS could produce a circular `depends_on_ai_task_id` graph, deadlocking the Dependency Engine | Logged as a requirement ("application-level check prevents cycles at insert time") in DATABASE-SCHEMA.md; will need an explicit test case in the Dependency Engine implementation task |
| 3 | Retry storms | `agent_runs` retry-on-failure could hammer the LLM provider or MCP tools on a systemic outage | Will need exponential backoff + circuit breaker as an explicit requirement in the Agent Engine implementation task |

Verdict: Approved. No HIGH/CRITICAL findings remain unresolved in spec text. Predicted bugs above are carried forward as requirements/edge cases for their respective future implementation tasks, not blockers to this documentation task.

---

## Done

- **PR**: N/A — documentation-only task, committed directly to `main` per developer instruction (no application code, no PR review required)
- **Merged**: 2026-07-02
- **Release Notes entry**: `RELEASE_NOTES.md` updated
- **Deliverable verification**: all Planning deliverables confirmed present on disk at close-out — `CLAUDE.md`, `VISION.md`, `docs/PHASE1-SPECIFICATION.md`, `docs/AGENTS.md`, `docs/DATABASE-SCHEMA.md`, `docs/MCP-TOOLS.md`, `docs/UI-WIREFRAMES.md`, `backlog/` scaffolding, `TODO.md`, `RELEASE_NOTES.md`
- **Superseded/expanded by**: `rao-002`–`rao-006` subsequently broke this task's Phase 1 content into individually-gated tickets per `ROADMAP.md`'s Phase 1 deliverable list (still in `backlog/specification/`); this file remains the original bundled baseline record
- **Note**: the 5 open questions logged in `docs/PHASE1-SPECIFICATION.md` §7 remain unresolved and still block Phase 10 (plugin skeleton) — closing this task does not close those questions
