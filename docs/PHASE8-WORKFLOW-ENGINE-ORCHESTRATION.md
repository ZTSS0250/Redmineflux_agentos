# Phase 8 — Workflow Engine & Orchestration — redmineflux_agentos

**Status**: Specification only. No orchestration code exists yet — Phase 14 implements it.
**Relationship to other docs**: [docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md](PHASE2-CORE-TECHNICAL-ARCHITECTURE.md) §A.6/§A.7 already designed the `WorkflowEngine::StateMachine` class and the Event Bus dispatch mechanism — this document is the **broader orchestration model** layered on top: which workflows exist, how parallel/sequential execution is governed, how scheduling prioritizes unblocked work, and — the one genuine gap this closes — **Pause/Resume Logic**, which every prior document (`WORKFLOW.md` §8's mapping table, `docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md` §A.6) explicitly deferred to "Phase 8."

---

## 1. Workflow Definitions

Named, already-fully-specified workflows — this is a catalog/index, not a re-description:

| Workflow | Fully specified in |
|---|---|
| New AI Project (idea → SRS → planning → execution) | `docs/PHASE1-SPECIFICATION.md` §1.1, `WORKFLOW.md` §3-§5 |
| Conversation turn | `WORKFLOW.md` §6 |
| Agent execution (one `agent_run`) | `docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md` §A.5, `docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md` §5 |
| Ticket generation | `WORKFLOW.md` §12 |
| Dependency resolution / blocking-resuming | `WORKFLOW.md` §9, §13 |
| MCP tool call | `docs/PHASE7-MCP-ARCHITECTURE.md` §1 |
| Release readiness | §6 below (new — see Completion Criteria) |

---

## 2. Event Bus Design

Unchanged — fully specified in [docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md](PHASE2-CORE-TECHNICAL-ARCHITECTURE.md) §A.7 (built on `ActiveSupport::Notifications`, synchronous in-process dispatch, subscribers must be non-blocking). Not repeated here.

---

## 3. Dependency Resolution

Unchanged mechanism — fully specified in [WORKFLOW.md](../WORKFLOW.md) §13 and `docs/DATABASE-SCHEMA.md`'s `dependencies` table. This document adds the tier-boundary interpretation needed for §4:

**A task's `agent_run` may transition `queued → running` only when every `dependencies` row where it is the dependent (`ai_task_id`) points to an `ai_task` whose linked issue is in a terminal ticket status** (`Completed`/`Released`, `WORKFLOW.md` §14). This was already true implicitly (each edge is specific, not tier-wide) — stated explicitly here because §4 depends on it.

---

## 4. Parallel & Sequential Execution Rules

- **Parallel**: two `ai_tasks` with no `dependencies` edge between them (directly or transitively) may execute concurrently — bounded only by the Concurrency Guard's per-project/global caps (Phase 2 §B.9), never by an artificial "wait for the whole tier" rule. Tier 4 (Frontend + UI/UX), Tier 5 (QA + Security), and Tier 6 (DevOps + Deployment) — `docs/AGENTS.md`'s default chain — are parallel *because* the default chain doesn't seed edges between them, not because of a special "parallel tier" mechanism.
- **Sequential**: a task's `agent_run` cannot start while any of its specific prerequisite edges are unresolved (§3) — this is graph-level sequencing, not tier-level. A project whose SRS implies a different order (e.g. API-first) gets different edges from the Solution Architect Agent and the same mechanism sequences it correctly without any change to the Scheduler.
- **No new mechanism was introduced for either rule** — both were already fully implied by the dependency graph design (`docs/DATABASE-SCHEMA.md`, `WORKFLOW.md` §13); this section exists because ROADMAP.md asks for them as explicit, statable rules, not because a gap existed.

---

## 5. Scheduling Strategy

When a `dependency.cleared` event (Phase 2 §A.7) unblocks more than one `ai_task` at once, they are enqueued in **`ai_tasks.priority` order** (already an existing column, `docs/DATABASE-SCHEMA.md`), then by `created_at` as a tiebreaker. This reuses an existing field rather than introducing a new scheduling-priority concept — the Ticket Generator (`WORKFLOW.md` §12) already sets `priority` from SRS signals, so scheduling naturally respects the same priority the plan itself expressed.

---

## 6. Retry Policy

Unchanged — fully specified in [docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md](PHASE2-CORE-TECHNICAL-ARCHITECTURE.md) §B.4 (three layers: agent run, background job, MCP idempotency) and restated per-agent in [docs/PHASE6-AGENT-ARCHITECTURE.md](PHASE6-AGENT-ARCHITECTURE.md) §3 (uniform `max_attempts: 3`). Not repeated here.

---

## 7. Pause/Resume Logic

**This is the one genuine gap this document closes.** `WORKFLOW.md` §8 and `docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md` §A.6 both explicitly deferred this to Phase 8 rather than inventing it prematurely — here is the design.

**Decision: pause/resume is a scheduling gate, not a new `agent_runs.status` value.** The already-approved, heavily-cross-referenced 7-state agent-run machine (`queued/running/waiting_on_dep/completed/failed/dead/cancelled`, `WORKFLOW.md` §8) is **not modified** — adding an 8th state now would be a breaking change to something every other document already treats as canonical, for a capability that doesn't actually need a new state to work correctly.

- **Storage**: pause state is a `redmineflux_agentos_configurations` row — `project_id: <id>`, `key: "execution_paused"`, `value_json: {paused: true, paused_by: <user_id>, paused_at:, reason:}` — reusing the already-approved generic configuration mechanism (`docs/PHASE4-DATABASE-DESIGN.md` §11's "mutated in place, not versioned" category) rather than adding a new column or table.
- **Enforcement point**: `DependencyEngine::Scheduler` (Phase 2 §A.4) checks this flag before (a) creating a new `agent_run` for the project, or (b) allowing a `queued → running` transition. If paused, eligible work stays `queued` — exactly the same visible state as being concurrency-capped (Phase 2 §B.9) — it is not a new status a dashboard needs to learn to render.
- **What pausing does *not* do**: it does not interrupt an `agent_run` already `running` — that run finishes normally (or fails/retries normally). Cooperative mid-run interruption is out of scope for v1; a user who needs to stop an in-flight run uses the existing `cancelled` transition (`WORKFLOW.md` §8), which already covers "stop this specific run now." Pause is specifically about **not starting new work**, matching what "pause the project" means to a human user (WORKFLOW.md's UI doesn't need a new run-level control, only a project-level toggle).
- **Resume**: clearing the flag (or setting `paused: false`) — the Scheduler's next tick picks up any `queued` work normally, including anything that became unblocked *while* paused (nothing is lost, only deferred — `dependency.cleared` events still fire and update the graph during a pause, only the *scheduling* of new runs is gated).
- **Who can pause**: any user with `run_ai_tasks` (`docs/PHASE1-SPECIFICATION.md` §5) or the Project Manager Agent itself (e.g. on detecting a requirement change mid-execution) — the same permission that already governs re-prioritization.

---

## 8. Escalation Flow

Unchanged — the three patterns already cataloged in [docs/PHASE6-AGENT-ARCHITECTURE.md](PHASE6-AGENT-ARCHITECTURE.md) §5 (escalate to Project Manager Agent; Project Manager Agent escalates to a human; no escalation path). Not repeated here.

---

## 9. Completion Criteria

**New** — when is a release considered complete, as an explicit, checkable list (previously implied across several documents but never stated as one checklist):

- [ ] Every `ai_task` in the release is in a terminal ticket status (`Completed` or `Released`, `WORKFLOW.md` §14)
- [ ] Every story has at least one linked, closed QA ticket (`docs/AGENTS.md` #11, QA Agent's gating rule)
- [ ] Security Agent has filed no unresolved CRITICAL/HIGH findings for tickets in this release (`docs/AGENTS.md` #12)
- [ ] Deployment Agent's readiness checklist ticket is closed (`docs/AGENTS.md` #14 — itself blocked on the two rows above)
- [ ] No `agent_run` tied to this release is `waiting_on_dep`, `queued`, or `running` (nothing still in flight)

When all five hold, `redmineflux_agentos_releases.status` transitions to `released` (`docs/DATABASE-SCHEMA.md`) — this is a read/aggregation check the Reporting Agent (or a dashboard) performs, not a new state machine; it is the concrete answer to "how does the system know a release is actually done" that no prior document stated as a single checklist.
