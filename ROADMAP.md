# ROADMAP.md — RedmineFlux AgentOS Development Roadmap

> **This is the internal SDD build-process roadmap** (how this plugin gets specified and implemented, phases 1-16). For **what ships to end users in which version** (v1 → v2 → v3 product capability), see [docs/PRODUCT-ROADMAP.md](docs/PRODUCT-ROADMAP.md) instead — do not confuse the two.

This is the authoritative, phase-by-phase roadmap for AgentOS. It keeps an architecture-first approach: every phase produces a reviewed specification before any implementation code exists. The **Mock AI Provider Foundation** (Phase 3) is deliberately sequenced before database design, folder structure, or plugin work — it is the contract every later phase (agents, workflow engine, UI) is written against, and the contract every future real LLM provider (OpenAI, Anthropic, Gemini, Ollama, Azure OpenAI, Bedrock) must satisfy without changing the rest of the system.

See [WORKFLOW.md](WORKFLOW.md) for the end-to-end workflow narrative (how these phases' outputs operate together at runtime) — it cross-references this roadmap wherever a workflow reaches ahead of an already-gated phase.

**Rule for every phase**: no implementation code until the phase's deliverables are documented and, where the SDD process applies, gate-approved. See `CLAUDE.md` for the three-gate review process and task naming (`rao-{NNN}-{type}-{desc}`).

---

## Status Overview

| Phase | Name | Type | Status | Task(s) |
|---|---|---|---|---|
| 1 | Product Functional Specification | Docs | ✅ Fully covered — 5 discrete tickets, individually gated | `rao-001` (bundled baseline) + `rao-002`..`rao-006` (per-deliverable breakdown) |
| 2 | Core Technical Architecture | Docs | ✅ Fully covered | `rao-001` (baseline) + `rao-007` (deepened: Agent Engine, Workflow Engine, Event Bus, Conversation/Memory/Prompt architecture, 10 cross-cutting strategies) |
| 3 | Mock AI Provider Foundation | Docs | 🔜 Next up — not yet spec'd | unassigned (`rao-008`) |
| 4 | Database Design | Docs | ✅ Retroactively covered | `rao-001` |
| 5 | Folder Structure & Plugin Organization | Docs | ⏳ Not yet spec'd | unassigned |
| 6 | Agent Architecture (per-agent detail) | Docs | ⚠️ Partially covered — needs expansion | `rao-001` (partial), gap noted below |
| 7 | MCP Architecture | Docs | ✅ Retroactively covered | `rao-001` |
| 8 | Workflow Engine & Orchestration | Docs | ⏳ Not yet spec'd | unassigned |
| 9 | UI/UX Specification | Docs | ✅ Retroactively covered | `rao-001` |
| 10 | Plugin Skeleton | Code | ⏳ Blocked on Phases 2, 3, 5, 8 | unassigned (was placeholder `rao-002`) |
| 11 | Database Migrations | Code | ⏳ Blocked on Phase 4 sign-off | unassigned (was placeholder `rao-003`) |
| 12 | Mock AI Provider Implementation | Code | ⏳ Blocked on Phase 3 | unassigned |
| 13 | MCP Implementation | Code | ⏳ Blocked on Phase 7 | unassigned |
| 14 | Multi-Agent Orchestration | Code | ⏳ Blocked on Phases 6, 8 | unassigned |
| 15 | User Interface Implementation | Code | ⏳ Blocked on Phase 9 | unassigned |
| 16 | Enterprise Readiness | Code | ⏳ Blocked on all above | unassigned |

**Retroactive coverage note**: `rao-001` (gate-approved, docs-scope) bundled what this roadmap now splits into Phases 1, 2, 4, 7, and 9, via `docs/PHASE1-SPECIFICATION.md`, `docs/DATABASE-SCHEMA.md`, `docs/MCP-TOOLS.md`, `docs/AGENTS.md`, and `docs/UI-WIREFRAMES.md`. Phases 4, 7, and 9 are considered satisfied at the depth this roadmap asks for. Phase 6 is only **partially** satisfied — `rao-001` covers per-agent purpose/responsibilities, but this roadmap's Phase 6 (per-agent memory, context, prompt template binding, MCP tool binding, state machine, retry/escalation rules) goes deeper than what exists today. This gap should be closed as a follow-up specification task before Phase 10+ implementation begins, not silently treated as done.

**Phase 2 completion (2026-07-02)**: `rao-007` closed the Phase 2 gap flagged above — `docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md` adds Service-Oriented Architecture conventions, a SOLID-principles mapping, expanded Module Responsibilities, Agent Engine internals (Registry/Lifecycle/Runner + concurrency model), a Workflow Engine design (one state machine shared by agent-run and ticket-status workflows), a concrete Event Bus design (built on `ActiveSupport::Notifications`, resolving `WORKFLOW.md` §15's forward-looking flag), Conversation/Memory/Prompt architecture, and all ten cross-cutting strategies (Background Job, Queue, Cache, Retry, Logging, Configuration, Error Handling, Security, Performance, Scalability). Phase 2 is now fully covered.

**Phase 1 breakdown (2026-07-02)**: Phase 1's deliverable list has been broken into 5 individually-gated tickets that supersede the informal "retroactively covered" label — `rao-002` (Product Vision, Business Goals, Project Scope, Success Criteria, Assumptions & Constraints), `rao-003` (Functional/Non-Functional Requirements, User Roles & Personas, User Stories), `rao-004` (AI-Assisted Development Workflow, Multi-Agent Collaboration Overview), `rao-005` (MCP Vision, Security & Compliance Overview), `rao-006` (High-Level Architecture, Product Roadmap v1→v2→v3). Each ticket cites already-approved content where it existed and adds genuinely new documents/sections where it didn't (`docs/USER-ROLES-AND-STORIES.md`, `docs/SECURITY-COMPLIANCE-OVERVIEW.md`, `docs/PRODUCT-ROADMAP.md`, plus five new sections in `VISION.md`). All five passed their three-gate review at docs-scope and sit in `backlog/specification/`.

**Next action**: Phase 3 — Mock AI Provider Foundation is the first fully un-spec'd phase in sequence and should be the next backlog task opened (`rao-008` — counter advanced to 8 after `rao-007` closed the Phase 2 gap).

---

## Phase 1 — Product Functional Specification

**Objective**: Define what AgentOS is, what problems it solves, and how users interact with it. No implementation code.

**Deliverables**: Product Vision, Business Goals, Project Scope, Functional Requirements, Non-Functional Requirements, User Roles & Personas, User Stories, AI-Assisted Development Workflow, Multi-Agent Collaboration Overview, MCP Vision, Security & Compliance Overview, High-Level Architecture, Product Roadmap (v1 → v2 → v3), Success Criteria, Assumptions & Constraints.

---

## Phase 2 — Core Technical Architecture

**Objective**: Design the complete software architecture before implementation. No implementation code.

**Deliverables**: Plugin Architecture, Service-Oriented Architecture, SOLID Design Principles, Module Responsibilities, Agent Engine Architecture, Workflow Engine, Event Bus, Conversation Architecture, Memory Architecture, Prompt Architecture, Background Job Strategy, Queue Strategy, Cache Strategy, Retry Strategy, Logging Strategy, Configuration Strategy, Error Handling Strategy, Security Strategy, Performance Strategy, Scalability Strategy.

---

## Phase 3 — Mock AI Provider Foundation

**Objective**: Complete the AI provider architecture before any implementation.

- The first version must not integrate with any real LLM provider.
- The architecture must be completely provider-agnostic.
- The entire system must communicate only through the Provider Interface.
- No Ruby, Rails, migrations, controllers, models, routes, views, JavaScript, CSS, tests, or implementation code.

**Deliverables**:

- **Mock AI Provider Architecture** — provider responsibilities, internal architecture, request lifecycle, response lifecycle, extension points
- **Provider Interface Design** — standard request model, standard response model, error model, capability model, tool-calling support, streaming compatibility, configuration contract
- **Provider Lifecycle** — initialization, configuration loading, provider selection, prompt preparation, mock execution, response generation, logging, token simulation, cost simulation, cleanup
- **Conversation Flow** — conversation lifecycle, context loading, prompt composition, provider interaction, response routing, persistence
- **Agent Execution Flow** — agent invocation, context loading, prompt resolution, provider interaction, workflow continuation, completion handling
- **Prompt Management** — prompt lifecycle, prompt versioning, categories, variables, validation, composition, localization readiness
- **Prompt Template Library** — templates for Requirement Analysis, Clarification Questions, SRS Generation, Project Planning, Release Planning, Sprint Planning, Ticket Generation, Dependency Analysis, Risk Analysis, Documentation, Reporting
- **Mock Response Strategy** — deterministic fixture-based responses for: Create Project, Requirement Analysis, Clarification Questions, Requirement Summary, Project Plan, Release Plan, Sprint Plan, Ticket Creation, Dependency Detection, Agent Assignment, Risk Analysis, Progress Summary
- **Fake Requirement Analysis** — Functional Requirements, Non-functional Requirements, Business Rules, Clarification Questions, SRS Outline
- **Fake Ticket Generation** — deterministic Epics, Features, Stories, Tasks, Subtasks, Acceptance Criteria, Estimates, Story Points, Labels
- **Fake Dependency Mapping** — e.g. Database → Backend → API → Frontend → QA → Deployment
- **Fake Agent Collaboration** — e.g. Backend Agent waits for Database Agent; Project Manager reprioritizes work; QA requests fixes; Documentation Agent updates wiki
- **Token Usage Simulation** — Prompt Tokens, Completion Tokens, Total Tokens, Agent Totals, Conversation Totals, Project Totals
- **Cost Simulation** — Request Cost, Token Cost, Agent Cost, Project Cost, Monthly Cost
- **Logging Strategy** — Requests, Responses, Prompt Versions, Agent Events, Workflow Events, Simulated Tokens, Simulated Costs, Errors, Retries
- **Error Handling Strategy** — missing fixtures, invalid templates, timeout simulation, configuration errors, unknown scenarios, recovery strategy
- **Configuration System** — Active Provider, Fixture Directory, Logging, Prompt Version, Simulation Mode, Cost Rules, Token Rules
- **Future Migration Plan** — migration path to Mock Provider → OpenAI → Anthropic → Gemini → Ollama → Azure OpenAI → AWS Bedrock providers
- **Documentation Updates** — review and update `VISION.md`, `CLAUDE.md`, `TODO.md`, backlog specifications, task specifications; propose additional specification documents if necessary. Each documentation phase must conclude with: Documents reviewed, Documents modified, New documents proposed, Rationale for each change.

---

## Phase 4 — Database Design

**Objective**: Design a normalized, scalable database model before writing migrations. No implementation code.

**Deliverables**: Entity Relationship Diagram (ERD), Database Architecture Overview, Table Specifications, Column Definitions, Relationships, Foreign Keys, Indexing Strategy, Constraints, Enumerations, JSON Field Usage, State Machines, Audit Tables, Soft Delete Strategy, Versioning Strategy, Performance Considerations.

**Tables include**: Agents, Agent Runs, Conversations, Messages, Prompt Templates, Knowledge Base, Agent Memory, Project Plans, Releases, Sprints, AI Tasks, Execution Logs, Token Usage, Cost Tracking, Configurations, Audit Logs.

---

## Phase 5 — Folder Structure & Plugin Organization

**Objective**: Define the complete plugin structure before generating files.

**Deliverables**: Plugin Directory Layout, Application Layer Organization, Service Layer Structure, Agent Modules, AI Provider Modules, MCP Modules, Workflow Modules, Background Jobs, Initializers, Assets, Locales, Specs, Documentation Layout.

---

## Phase 6 — Agent Architecture

**Objective**: Design every AI agent in detail.

**For each agent define**: Purpose, Responsibilities, Goals, Inputs, Outputs, Memory, Context, Prompt Template, MCP Tools, Produced Events, Consumed Events, State Machine, Retry Rules, Failure Handling, Escalation Rules.

**Agents**: Project Manager, Requirement Analyst, Business Analyst, Scrum Master, Solution Architect, Database, Backend, API, Frontend, UI/UX, QA, Documentation, Security, DevOps, Deployment, Code Review, Reporting.

---

## Phase 7 — MCP Architecture

**Objective**: Design how agents interact with Redmine through MCP tools.

**Deliverables**: MCP Architecture, Tool Registry, Permission Model, Request/Response Contracts, Error Handling.

**Tool categories**: Project Management, Issue Management, Release Management, Sprint Management, Wiki Management, File Management, Time Tracking, Workload, Reporting, Search, Notifications.

---

## Phase 8 — Workflow Engine & Orchestration

**Objective**: Define the orchestration model for multi-agent execution.

**Deliverables**: Workflow Definitions, Event Bus Design, Dependency Resolution, Parallel Execution Rules, Sequential Execution Rules, Scheduling Strategy, Retry Policy, Pause/Resume Logic, Escalation Flow, Completion Criteria.

---

## Phase 9 — UI/UX Specification

**Objective**: Design the complete user experience before implementation.

**Deliverables**: Information Architecture, Navigation Structure, User Flows, Wireframes, Page Specifications, Dashboard Designs.

**Pages include**: Agent Dashboard, AI Chat, New AI Project Wizard, Requirement Review, Release Planner, Sprint Planner, Agent Monitoring, Execution History, Logs, Prompt Library, Token Usage, Cost Dashboard, Settings.

---

## Phase 10 — Plugin Skeleton

**Objective**: Generate the initial Rails plugin structure. First implementation phase.

**Deliverables**: Plugin registration (`init.rb`), directory structure, routes, hooks, permissions, menus, controllers (skeleton), models (skeleton), services (skeleton), jobs (skeleton), helpers, initializers, configuration placeholders.

No business logic.

---

## Phase 11 — Database Migrations

Implement the database schema defined in Phase 4.

---

## Phase 12 — Mock AI Provider Implementation

Implement the deterministic Mock AI Provider according to the Phase 3 specification: Provider Interface implementation, fixture loading, prompt resolution, deterministic response generation, token simulation, cost simulation, logging, error handling. No external AI services.

---

## Phase 13 — MCP Implementation

Implement MCP tools that perform real Redmine actions: create/update projects, create/update issues, manage versions & sprints, update wiki, log time, update workload, generate reports, search Redmine data.

---

## Phase 14 — Multi-Agent Orchestration

Implement the Agent Engine with: Agent Scheduler, Workflow Engine, Dependency Resolution, Inter-Agent Communication, Event Bus, Parallel Execution, Retry & Recovery.

---

## Phase 15 — User Interface Implementation

Implement all specified UI pages, dashboards, monitoring views, and configuration screens.

---

## Phase 16 — Enterprise Readiness

Prepare the plugin for production use with: Caching, Background Processing, Performance Optimization, Audit Logging, RBAC, Notifications, Metrics, Health Checks, Monitoring, Scalability Enhancements, Documentation Finalization, Deployment & Upgrade Guides.

---

This sequence ensures every architectural decision is documented and reviewed before a single line of implementation code is written, while making the Mock AI Provider the foundational contract that future real LLM providers can plug into seamlessly.
