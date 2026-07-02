# Phase 1 Specification — redmineflux_agentos

**Status**: Draft, awaiting developer approval. No code exists yet.
**Companion docs**: [AGENTS.md](AGENTS.md) · [DATABASE-SCHEMA.md](DATABASE-SCHEMA.md) · [MCP-TOOLS.md](MCP-TOOLS.md) · [UI-WIREFRAMES.md](UI-WIREFRAMES.md) · [USER-ROLES-AND-STORIES.md](USER-ROLES-AND-STORIES.md) · [SECURITY-COMPLIANCE-OVERVIEW.md](SECURITY-COMPLIANCE-OVERVIEW.md) · [PRODUCT-ROADMAP.md](PRODUCT-ROADMAP.md) · [PHASE2-CORE-TECHNICAL-ARCHITECTURE.md](PHASE2-CORE-TECHNICAL-ARCHITECTURE.md) · [PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md](PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md) · [PHASE4-DATABASE-DESIGN.md](PHASE4-DATABASE-DESIGN.md) · [PHASE5-FOLDER-STRUCTURE.md](PHASE5-FOLDER-STRUCTURE.md) · [PHASE6-AGENT-ARCHITECTURE.md](PHASE6-AGENT-ARCHITECTURE.md) · [PHASE7-MCP-ARCHITECTURE.md](PHASE7-MCP-ARCHITECTURE.md) · [PHASE8-WORKFLOW-ENGINE-ORCHESTRATION.md](PHASE8-WORKFLOW-ENGINE-ORCHESTRATION.md) · [PHASE9-UI-UX-SPECIFICATION.md](PHASE9-UI-UX-SPECIFICATION.md) · [../ROADMAP.md](../ROADMAP.md) · [../WORKFLOW.md](../WORKFLOW.md)

**Deepening map**: `DATABASE-SCHEMA.md` → deepened by `PHASE4-DATABASE-DESIGN.md`; `AGENTS.md` → expanded by `PHASE6-AGENT-ARCHITECTURE.md`; `MCP-TOOLS.md` → deepened by `PHASE7-MCP-ARCHITECTURE.md`; `UI-WIREFRAMES.md` → expanded by `PHASE9-UI-UX-SPECIFICATION.md`. Each baseline document remains the source for what it already covers; its companion phase document adds only what ROADMAP.md's fuller deliverable list asked for and the baseline didn't yet have.

**§2 (Architecture) is deepened by** [PHASE2-CORE-TECHNICAL-ARCHITECTURE.md](PHASE2-CORE-TECHNICAL-ARCHITECTURE.md) — that document adds Agent Engine internals, the Event Bus, and the ten cross-cutting engineering strategies; this document's §2.1/§2.2/§2.3 remain the baseline layered view, module table, and architectural decisions.

---

## 1. Functional Specification

### 1.1 End-to-end user flow

```
1. User opens "AI Chat" / "New AI Project Wizard"
2. User describes idea in natural language
3. Requirement Analyst Agent:
     - parses idea
     - detects missing information against a checklist
       (business goals, users, auth, tech stack, integrations,
        deployment, security, reports, notifications, i18n,
        platforms, mobile, payments, 3rd-party APIs,
        performance expectations, timeline, budget)
     - asks clarification questions (one batch, not a 20-question wall)
4. User answers (may loop 1-3 rounds until confidence threshold met)
5. Requirement Analyst Agent generates a structured SRS (Markdown + structured JSON)
6. User reviews SRS in "Requirement Review" screen -> Approve / Request changes
7. On approval:
     - Project Manager Agent creates: Project, Modules, Releases, Milestones,
       Sprints, Epics/Features, Stories, Tasks, Subtasks, Dependencies,
       Risk Register, Timeline/Roadmap  (all via MCP tools -> Redmine)
     - Ticket Generator produces structured issues per story/task
       (title, description, acceptance criteria, priority, story points,
        estimate, labels, component, release, sprint, dependencies,
        related issues, checklist, agent owner, suggested reviewer)
     - Dependency Engine orders execution (DB -> Backend -> API ->
       Frontend -> UI -> Testing -> Deployment, plus explicit ticket-level deps)
8. Agent Manager assigns tickets to specialized agents in dependency order
9. Agents execute within their scope (Phase 1: planning/spec/documentation-level
   output; code-writing agents are a later-phase capability - see VISION.md).
   Each agent, per assigned ticket:
     - updates issue status via MCP
     - adds progress notes / comments
     - creates wiki documentation where applicable
     - logs time entries
     - updates workload
     - raises a blocking message to the Project Manager Agent if it cannot proceed
10. Project Manager Agent monitors dependency graph; unblocks/re-prioritizes
    agents automatically as prerequisite tickets close
11. User watches live progress on Agent / Release / Sprint / Dependency dashboards
12. Reporting Agent generates status reports on demand or on a schedule
```

### 1.2 Functional requirements summary

| ID | Requirement |
|----|-------------|
| FR-01 | User can start a new AI project from a single free-text idea |
| FR-02 | System detects missing requirement categories and asks targeted clarification questions |
| FR-03 | System never creates Redmine artifacts before the user approves the SRS |
| FR-04 | System generates project/release/sprint/epic/ticket hierarchy automatically from the approved SRS |
| FR-05 | Generated tickets carry acceptance criteria, priority, estimate, labels, dependencies |
| FR-06 | System computes ticket execution order from a dependency graph, not just creation order |
| FR-07 | Agents can message each other and the Project Manager Agent; blocked agents pause and resume automatically when a dependency clears |
| FR-08 | Every agent action that changes Redmine state is performed via an MCP tool call, never a direct DB write bypassing Redmine's model layer |
| FR-09 | Every agent action is logged (execution log) and user-facing actions are audit-logged |
| FR-10 | Token usage and cost are tracked per agent run, per project, and are visible before/while spend accrues |
| FR-11 | Irreversible or high-blast-radius MCP actions (delete, bulk close, permission changes) require explicit human confirmation |
| FR-12 | System exposes dashboards for project, agent, release, sprint, dependency, risk, token usage, cost, workload, timesheet, performance |
| FR-13 | All AgentOS actions are governed by a dedicated permission set, independent of (but layered on top of) Redmine's existing role/permission system |
| FR-14 | System degrades gracefully on LLM/MCP failure: retry with backoff, then surface a clear, actionable error — never a silent partial state |

### 1.3 Non-functional requirements

| Category | Requirement |
|---|---|
| Performance | Agent runs and MCP calls execute as background jobs (ActiveJob), never inline in a request cycle |
| Scalability | Multiple agents can run concurrently across multiple projects; per-project and global concurrency caps configurable |
| Reliability | Every agent run is retryable and idempotent at the MCP-tool-call level (tool calls are logged with enough context to detect "already applied") |
| Caching | Prompt templates, agent configs, and dependency graphs are cached in-process with explicit invalidation on edit |
| Observability | Structured logs for every LLM call, every MCP call, every state transition; correlated by `agent_run_id` |
| Security | See Gate 2 checklist in the global CLAUDE.md — applies to every controller/MCP tool in this plugin |

---

## 2. Architecture

### 2.1 Layered view

```
┌──────────────────────────────────────────────────────────────────────┐
│  UI Layer (Redmine views + JS)                                       │
│  AI Chat · Wizard · Requirement Review · Dashboards · Prompt Library │
└───────────────────────────────┬────────────────────────────────────┘
                                 │ Rails controllers (REST + HTML)
┌───────────────────────────────▼────────────────────────────────────┐
│  Application Layer                                                   │
│  Conversation Manager · Requirement Analyzer · Planning Engine       │
│  Release Planner · Sprint Planner · Ticket Generator                 │
│  Dependency Engine · Workflow Engine · Notification Center           │
│  Reporting System · Permission Manager · Configuration               │
└───────────────────────────────┬────────────────────────────────────┘
                                 │
┌───────────────────────────────▼────────────────────────────────────┐
│  Agent Engine                                                        │
│  Agent Manager · Prompt Manager · Memory Store · Knowledge Base      │
│  Token Manager · Cost Tracker · one class per Agent role             │
└───────────────────────────────┬────────────────────────────────────┘
                                 │ governed tool calls only
┌───────────────────────────────▼────────────────────────────────────┐
│  MCP Integration Layer                                               │
│  Tool registry · auth/scope enforcement · confirmation gate for      │
│  irreversible actions · request/response audit logging               │
└───────────────────────────────┬────────────────────────────────────┘
                                 │
┌───────────────────────────────▼────────────────────────────────────┐
│  Redmine Core (unmodified)                                           │
│  Projects · Versions · Issues · Wiki · Time Entries · Users · Roles  │
└──────────────────────────────────────────────────────────────────────┘
```

**Rule enforced by this layering**: agents never touch ActiveRecord models directly for anything Redmine-owned. All Redmine state changes go through the MCP Integration Layer, so every action is uniformly logged, permission-checked, and confirmable — regardless of which agent or which UI surface triggered it.

### 2.2 Module responsibility table

| Module | Responsibility | Key classes (proposed) |
|---|---|---|
| Agent Engine | Owns agent lifecycle (spawn, run, pause, resume, retire) | `AgentEngine::Runner`, `AgentEngine::Lifecycle` |
| Prompt Manager | Resolves versioned prompt templates + variable interpolation per agent role | `PromptManager::TemplateResolver` |
| Conversation Manager | Threads chat turns, maintains conversation state machine | `ConversationManager::Session` |
| Requirement Analyzer | Gap-detection against requirement checklist, clarification question generation, SRS synthesis | `RequirementAnalyzer::GapDetector`, `::SrsBuilder` |
| Planning Engine | Orchestrates SRS -> project plan translation | `PlanningEngine::Orchestrator` |
| Release Planner | Derives releases/milestones from plan | `ReleasePlanner::Builder` |
| Sprint Planner | Derives sprints from releases + team velocity assumptions | `SprintPlanner::Builder` |
| Dependency Engine | Builds/validates DAG of tickets, computes execution order, blocks/unblocks agents | `DependencyEngine::Graph`, `::Scheduler` |
| Ticket Generator | Produces structured issue payloads from epics/stories/tasks | `TicketGenerator::IssueBuilder` |
| Workflow Engine | State machine for agent run + ticket status transitions | `WorkflowEngine::StateMachine` |
| Knowledge Base | Project-scoped reference material agents can retrieve (SRS, prior decisions, wiki excerpts) | `KnowledgeBase::Store` |
| Memory Store | Short/long-term agent memory (per agent, per project) | `MemoryStore::Repository` |
| Agent Manager | Registry of agent instances, assignment, concurrency limits | `AgentManager::Registry` |
| Token Manager | Tracks token consumption per call/run/project | `TokenManager::Tracker` |
| Cost Tracker | Converts token usage to cost by provider/model rate card | `CostTracker::Calculator` |
| Dashboard | Read-model aggregation for all dashboards | `Dashboards::*Presenter` |
| MCP Integration | Tool registry, execution, confirmation gate, audit hook | `Mcp::ToolRegistry`, `::Executor` |
| Notification Center | Routes agent/system events to Redmine notifications + optional external channels | `NotificationCenter::Dispatcher` |
| Reporting System | On-demand/scheduled report generation | `ReportingSystem::Generator` |
| Configuration | Global + per-project AgentOS settings | `Configuration::Store` |
| Permission Manager | AgentOS-specific permission checks layered on Redmine roles | `PermissionManager::Guard` |
| Audit Logs | Immutable record of user-visible/irreversible actions | `AuditLogs::Recorder` |
| Activity History | Feed of agent + ticket activity for the Redmine activity view | `ActivityHistory::Provider` |

### 2.3 Key architectural decisions (need developer sign-off)

| # | Decision | Rationale | Alternative considered |
|---|---|---|---|
| AD-1 | Sprints are a plugin-owned concept (`redmineflux_agentos_sprints`), not native Redmine, since Redmine only has `Version` (used for both releases and milestones) | Redmine has no sprint primitive; releases map to `Version` | Overload `Version` with a custom field for sprint — rejected, conflates two lifecycles |
| AD-2 | Phase 1-3 agents produce planning/spec/documentation artifacts and ticket state changes only; no autonomous code-writing/committing agent ships until its own dedicated security review | Code-writing agents are a much larger blast radius (SCM write access) and need a separate spec | Ship code-writing Backend/Frontend agents now — rejected for Phase 1 scope |
| AD-3 | All agent-to-Redmine actions go through MCP tools, even for in-process agent execution (no ActiveRecord shortcut) | Uniform audit trail, permission checks, and confirmation gating regardless of call path | Direct model calls for "trusted" internal agents — rejected, breaks the audit guarantee |
| AD-4 | Background execution via ActiveJob (adapter left to host Redmine's existing queue config) | Agent runs and MCP calls must never block a web request | Inline synchronous execution — rejected, unacceptable latency and no retry story |
| AD-5 | Irreversible/high-blast-radius MCP tools require an explicit human confirmation step before execution | Matches global engineering discipline: agents assist, humans approve destructive actions | Full autonomy — rejected per product vision guardrail |

---

## 3. Folder Structure

See [CLAUDE.md](../CLAUDE.md) "Directory Structure" section — reproduced here for Phase 1 reviewers:

```
redmineflux_agentos/
├── app/{controllers,models,views,helpers,jobs,serializers}/
├── assets/{javascripts,stylesheets}/
├── config/{locales,routes.rb}
├── db/migrate/
├── docs/
├── lib/redmineflux_agentos/{agents,engine,mcp,prompts,hooks}/
├── backlog/{planning,specification,done}/
├── documents/security-rules.md
├── init.rb
├── TODO.md
├── RELEASE_NOTES.md
└── CLAUDE.md
```

No `app/` or `lib/` code is created in Phase 1 — this structure is proposed for Phase 2 (plugin skeleton).

---

## 4. Plugin Navigation

### 4.1 Project-level menu (visible inside a project, permission-gated)

```
Project
 └── AgentOS                              (:view_agentos_dashboard)
      ├── AI Chat                         (:create_ai_project or :run_ai_tasks)
      ├── Requirement Review              (:create_ai_project)
      ├── Release Planner                 (:run_ai_tasks)
      ├── Agent Dashboard                 (:view_agentos_dashboard)
      ├── Dependency Dashboard            (:view_agentos_dashboard)
      ├── Token Usage                     (:view_token_usage)
      ├── Cost Dashboard                  (:view_cost_dashboard)
      └── Execution History / Logs        (:view_agent_logs)
```

### 4.2 Global / Administration menu

```
Administration
 └── AgentOS
      ├── Agents                          (manage roster, enable/disable)  (:manage_ai_agents)
      ├── Prompt Library                  (:manage_prompt_templates)
      ├── MCP Tools                       (enable/disable, scopes)         (:manage_mcp_tools)
      ├── Configuration                   (global defaults, rate cards)    (:manage_ai_configuration)
      └── Audit Logs                      (:view_agent_logs)
```

### 4.3 New AI Project entry point

A top-level "+ New AI Project" action (project list page) launches the wizard described in [UI-WIREFRAMES.md](UI-WIREFRAMES.md), gated by `:create_ai_project`.

---

## 5. Permissions (Phase 1 set)

| Permission key | Grants |
|---|---|
| `manage_agentos` | Full administrative control (superset; typically Admin-only) |
| `create_ai_project` | Start the wizard, submit ideas, approve/reject SRS |
| `manage_ai_agents` | Enable/disable agents, edit agent configuration |
| `run_ai_tasks` | Trigger agent runs on existing tickets, approve ticket generation |
| `view_token_usage` | View Token Usage dashboard |
| `view_cost_dashboard` | View Cost dashboard |
| `manage_mcp_tools` | Enable/disable MCP tools, edit tool scopes |
| `manage_prompt_templates` | Create/edit/version prompt templates |
| `view_agent_logs` | View execution logs, audit logs, agent activity history |
| `manage_ai_configuration` | Edit global/per-project AgentOS configuration |

All permissions are declared per-project (`init.rb` `project_module :agentos`) except the four administration-only ones (`manage_agentos`, `manage_mcp_tools`, `manage_prompt_templates`, `manage_ai_configuration`), which are also exposed at the global Administration level. Every controller action maps to exactly one permission — enforced in Gate 1/2 review of each future task spec.

---

## 6. Agent Lifecycle

### 6.1 State machine (per `redmineflux_agentos_agent_runs` row)

```
                ┌─────────┐
      create    │ queued  │◄────────────────┐
     ─────────► └────┬────┘                 │ retry (attempts < max)
                     │ picked up by worker    │
                     ▼                        │
                ┌─────────┐   dependency   ┌──┴──────────────┐
                │ running │ ─────not met──►│ waiting_on_dep   │
                └────┬────┘                └──────┬───────────┘
                     │                             │ dependency cleared
        success      │      failure                │ (Dependency Engine event)
    ┌────────────────┼─────────────────┐          │
    ▼                                  ▼           │
┌───────────┐                    ┌───────────┐     │
│ completed │                    │  failed   │◄────┘
└───────────┘                    └─────┬─────┘
                                        │ attempts >= max
                                        ▼
                                  ┌───────────┐
                                  │ dead       │  (surfaced to Agent Dashboard
                                  └───────────┘   for human intervention)

  Any non-terminal state ──user/PM-agent cancels──► cancelled
```

### 6.2 Transition rules

| From | To | Trigger |
|---|---|---|
| `queued` | `running` | Worker picks up job, dependency check passes |
| `queued` / `running` | `waiting_on_dep` | Dependency Engine reports an unmet prerequisite ticket/agent-run |
| `waiting_on_dep` | `queued` | Dependency Engine emits "cleared" event for the blocking ticket |
| `running` | `completed` | Agent finishes, all MCP calls in the run succeeded |
| `running` | `failed` | Unhandled error, LLM error, or MCP tool call rejected |
| `failed` | `queued` | Automatic retry (bounded, exponential backoff) if attempts < configured max |
| `failed` | `dead` | Attempts exhausted — requires human action from Agent Dashboard |
| any non-terminal | `cancelled` | User or Project Manager Agent cancels (e.g. requirement changed) |

### 6.3 Inter-agent communication (blocking/resuming example)

```
Backend Agent (run #482, ticket rao-proj-014):
  "Cannot continue — ticket rao-proj-009 (DB schema) is not closed."
  -> agent_run transitions to waiting_on_dep, records blocking ticket id

Project Manager Agent:
  receives blocking event -> re-prioritizes Database Agent's queue
  -> optionally notifies human via Notification Center if SLA at risk

Database Agent:
  completes ticket rao-proj-009 -> closes issue via MCP
  -> Dependency Engine detects closure -> emits "cleared" event

Backend Agent run #482:
  waiting_on_dep -> queued -> running (resumes automatically, no human step)
```

This is implemented by the Dependency Engine subscribing to ticket-status-change MCP events and re-queuing any `agent_runs` row whose recorded blocking ticket just closed.

---

## 7. Open Questions for Developer — RESOLVED (2026-07-02)

All five questions below are now resolved. Nothing here required reopening any already-approved spec — each resolution is either already implemented in an existing gate-approved document (Q2, Q4) or is now recorded here for the first time (Q1, Q3, Q5). **This closes the item that was blocking Phase 10 (`rao-015`) implementation.**

1. **LLM provider(s)** — ✅ RESOLVED, and not actually a Phase 10 blocker. v1 uses the Mock AI Provider exclusively (`docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md`) — no real provider is called anywhere in Phases 10-16. The question only matters for v2 (`docs/PRODUCT-ROADMAP.md`). **Default direction recorded now**: Anthropic Claude, per the global CLAUDE.md guidance to default to the latest Claude models — but this is a *recommendation*, not a final vendor commitment, and remains subject to the v1→v2 promotion gate's vendor/DPA review (`docs/SECURITY-COMPLIANCE-OVERVIEW.md` §3, `docs/PRODUCT-ROADMAP.md`) before it ships. If the developer wants a different vendor for v2, that review happens then — it does not block any work in this roadmap today.
2. **Background job backend** — ✅ RESOLVED by `rao-007`: plain `ApplicationJob`/`ActiveJob::Base`, adapter-agnostic (no assumption of Sidekiq/Resque/Delayed Job) — directly modeled on the sibling `redmineflux_devops` plugin's own already-implemented, tested pattern (`retry_on` with an explicit exponential-backoff proc, `discard_on` for expected non-retryable errors). See `docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md` §B.1.
3. **MCP transport** — ✅ RESOLVED, informed by the same `redmineflux_devops` precedent: that plugin does **not** run its own standalone MCP protocol server — it exposes a REST/JSON API (`/devops/...`) that an external, shared "Redmineflux MCP server" calls into (per `redmineflux_devops/API.md`: *"the contract between the DevOps plugin and the Redmineflux MCP server"*). **AgentOS follows the identical pattern**: `Mcp::Executor`'s in-process call path (`docs/PHASE7-MCP-ARCHITECTURE.md`) handles agent-internal tool calls; the same tool functionality is additionally exposed as a REST API under `/agentos/...` (`docs/PHASE5-FOLDER-STRUCTURE.md`, `rao-015`'s routing spec — `defaults: { format: 'json' }`), which the same shared external MCP server registers AgentOS's tools into. **AgentOS does not stand up a second, competing MCP server.**
4. **Confirmation UX for irreversible actions (AD-5)** — ✅ RESOLVED, already implemented consistently across every UI/workflow document since `rao-001`: a **Pending Approvals queue embedded in the Agent Dashboard** (`docs/UI-WIREFRAMES.md` §3, `WORKFLOW.md` §22, `docs/PHASE9-UI-UX-SPECIFICATION.md`) — not a separate modal or a dedicated standalone page. This was de facto decided from the first UI wireframe; this entry formally closes the question rather than leaving it nominally "open" against already-built consensus.
5. **Code-writing agents (AD-2)** — ✅ RESOLVED: **confirmed out of scope**; Phase 1 does **not** reserve schema or permission space now for a future `manage_agent_code_writes` permission. Rationale: reserving space for a hypothetical future capability before its own dedicated security design exists is speculative scope creep, not preparation — the same principle already applied throughout this project (e.g. not over-generalizing the Workflow Engine's state machine, `docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md` §A.6 Gate 1 finding #1). `docs/PRODUCT-ROADMAP.md`'s v2→v3 gate already requires a fully gate-reviewed, dedicated security spec to exist before any code-writing capability ships — that future task adds its own schema/permissions when it's actually scoped, not before.

---

## 8. Phase Roadmap — superseded by ROADMAP.md

This section's original 4-phase sketch (Phase 1 spec → Phase 2 plugin skeleton → Phase 3 migrations → Phase 4+ modules) has been fully superseded by the 16-phase roadmap in [../ROADMAP.md](../ROADMAP.md), which is now the single authoritative phase tracker for this project — see that document for current status. As of 2026-07-02: Phases 1-9 (documentation) are complete and closed; Phases 10-16 (implementation) are fully specified in `backlog/specification/` (`rao-015`-`rao-021`) but not yet implemented. The 5 open questions in §7 above, which blocked this old Phase 2 (now ROADMAP.md's Phase 10, "Plugin Skeleton"), are now resolved.
