# Phase 6 — Agent Architecture (Expansion) — redmineflux_agentos

**Status**: Specification only. No agent classes exist yet — Phase 10+ implements them.
**Relationship to other docs**: [docs/AGENTS.md](AGENTS.md) (`rao-001`) already defines, per agent, Responsibility, Goals, Input, Output, Memory, MCP Tools, Communication, and Workflow (trigger conditions) — this document does not repeat any of that. It adds the six attributes ROADMAP.md's Phase 6 asks for that weren't covered: **Context**, **Prompt Template Key(s)**, **Produced Events**, **Consumed Events**, **Retry Rules**, **Failure Handling & Escalation Rules**. **State Machine** is intentionally *not* repeated per-agent — see §2, every agent shares one definition.

---

## 1. Per-Agent Expansion Table

`Consumed Events` are derived directly from each agent's existing `docs/AGENTS.md` "Workflow" trigger description, mapped onto the formal event catalog in [WORKFLOW.md](../WORKFLOW.md) §15. `Prompt Template Key(s)` map onto the categories in [docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md](PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md) §6.1.

| Agent | Context (beyond direct input) | Prompt Template Key(s) | Produced Events | Consumed Events (trigger) | Escalation Rule |
|---|---|---|---|---|---|
| Project Manager | Full dependency graph state, risk register, every agent's current status | `project_planning.*`, `risk_analysis.*` | `project.created`, `agent_run.completed`/`.failed` | `conversation.srs_approved`, `agent_run.waiting_on_dep` (blocking event), periodic health-check tick | Escalates to the **human** via Notification Center if an SLA/risk threshold is hit — the only agent whose escalation target is a person, not another agent |
| Requirement Analyst | Prior SRS versions for this project (long-term memory) | `requirement_analysis.*`, `clarification_questions.*`, `srs_generation.*` | `conversation.srs_generated`, `conversation.srs_approved` (on user action) | `conversation.created` (new conversation start) | Escalates to Project Manager Agent if confidence threshold can't be met after the bounded clarification loop |
| Business Analyst | Approved SRS, prior business goals (long-term memory) | `project_planning.*` (epic/business-value framing) | `issue.created` (epics) | `conversation.srs_approved` | Escalates to Project Manager Agent on scope-drift detection |
| Scrum Master | Historical velocity (long-term memory), current ticket status | `sprint_planning.*` | `issue.status_changed` (via `update_issue`) | Sprint boundary events, daily tick | Escalates aging blockers to Project Manager Agent |
| Solution Architect | SRS, prior architecture decisions (long-term memory) | `dependency_analysis.*` | `dependency.cleared`-seeding via `create_issue_relation`, `project.created` follow-on wiki creation | `conversation.srs_approved` (once, per project) | Escalates to Project Manager Agent if the SRS implies conflicting non-functional requirements |
| Database | Architecture document, SRS data requirements | `ticket_generation.*` | `issue.created` (DB tickets) | Tier 0 completion (Solution Architect Agent's architecture doc ready) | Notifies Backend Agent (via Project Manager Agent) when schema tickets close |
| Backend | Schema design, architecture doc | `ticket_generation.*` | `issue.created` (backend tickets) | `dependency.cleared` (DB tier closed) | Blocks on Database Agent; escalates to Project Manager Agent if blocked past an aging threshold |
| API | Backend service definitions | `ticket_generation.*` | `issue.created` (API tickets) | `dependency.cleared` (Backend tier closed) | Same pattern as Backend Agent, one tier up |
| Frontend | API spec | `ticket_generation.*` | `issue.created` (frontend tickets) | `dependency.cleared` (API tier closed) | Same pattern, blocks on API Agent |
| UI/UX | SRS target users, Frontend ticket list | `ticket_generation.*` (UX acceptance criteria) | `issue.status_changed` (attaches UX checklists) | Same tier as Frontend Agent (parallel) | Coordinates with Frontend Agent directly, no separate escalation path |
| QA | Story/task tickets with acceptance criteria | `ticket_generation.*` (test-case framing) | `issue.created` (test tickets), `issue.created_relation` (linking) | Upstream implementation tickets existing (Tier 4 output) | Blocks release sign-off via Project Manager Agent if coverage is missing |
| Security | Architecture doc, ticket set | `risk_analysis.*` | `issue.created`/`add_comment` (findings) | Runs after Solution Architect Agent, and again before each release | Can block release sign-off via Project Manager Agent on CRITICAL/HIGH findings |
| DevOps | Architecture doc, release plan | `ticket_generation.*` (infra framing) | `issue.created` (infra/CI tickets) | Parallel with QA Agent (Tier 5→6 boundary) | Coordinates with Deployment Agent directly |
| Deployment | Release plan, QA/Security ticket status | `progress_summary`-adjacent (no dedicated category — reuses Reporting's `reporting.*` for readiness narratives) | `mcp_tool_call.pending_confirmation` (its own `bulk_close_issues` requests) | QA + Security tickets both closed | Blocked on QA Agent and Security Agent; escalates via Pending Approvals queue for irreversible actions |
| Code Review *(reserved)* | PR/diff metadata (via `redmineflux_devops` integration) | none defined in v1 — no prompt category exists yet since this role is inactive until code-writing agents ship (v3, `docs/PRODUCT-ROADMAP.md`) | none | none (dormant) | Reports to Project Manager Agent once activated — not applicable in v1/v2 |
| Documentation | Closed tickets, architecture/API docs | `documentation.*` | none beyond standard wiki-page creation logging | `issue.status_changed` → closed (passive, ticket-close-triggered) | No escalation path — purely reactive, never blocks anything |
| Reporting | Dashboard read-models (project, agent, release, dependency, token, cost) | `reporting.*` | `report.generated` | Reporting System schedule or explicit user request | No escalation path — reports are informational, never gating |

---

## 2. State Machine

**All 17 agents share exactly one state machine** — the `agent_runs.status` machine fully defined in [WORKFLOW.md](../WORKFLOW.md) §8 and implemented by `AgentEngine::Lifecycle` (Phase 2 §A.5/§A.6). This document does not define a per-agent variant, and Phase 10+ implementation must not create one — a second, agent-specific state machine would violate the "one engine, configured instances" design decision made in Phase 2 §A.6. The **Code Review Agent** is the only role that never actually enters this state machine in v1/v2 (reserved, no agent runs are ever scheduled for it) — this is a scope statement, not a different state machine.

---

## 3. Retry Rules

**Uniform across every agent**: `max_attempts: 3` (the `redmineflux_agentos_agent_runs` schema default, per [docs/DATABASE-SCHEMA.md](DATABASE-SCHEMA.md)), exponential backoff (Phase 2 §B.4). No agent overrides this default. This is a deliberate simplicity decision: per-agent retry tuning would be a speculative optimization with no concrete v1 requirement driving it — if a specific agent's failure pattern in production later justifies a different value, that's a configuration change (`docs/PHASE4-DATABASE-DESIGN.md` §6, `agents.config_json` could carry an override), not a reason to design 17 different policies now.

---

## 4. Failure Handling

Also uniform: `AgentEngine::Runner` catches every failure the same way regardless of agent role (Phase 2 §B.7's exception hierarchy, Phase 3 §8's Mock-specific subclasses) — transitions to `failed`, retries per §3 above, and lands on `dead` (surfaced on the Agent Dashboard) if attempts are exhausted. **What varies per agent is not failure *handling*, it's failure *consequence*** — captured in the Escalation Rule column of §1: some agents' failure blocks a release (QA, Security), some just delay a tier (Backend, API, Frontend), and some have no downstream consequence at all (Documentation, Reporting).

---

## 5. Escalation Rules — summary pattern

Three patterns, not 17 unique ones (see §1's Escalation Rule column for the specific target per agent):

1. **Escalates to Project Manager Agent** (most agents) — the PM Agent is the single aggregation point for cross-agent blocking, matching its role as the only agent with a human escalation path.
2. **Escalates to the human directly via Notification Center** — Project Manager Agent only, when an SLA/risk threshold is hit ([docs/AGENTS.md](AGENTS.md) #1).
3. **No escalation path** — Documentation and Reporting Agents, whose work is never gating and never blocks another agent's progress.
