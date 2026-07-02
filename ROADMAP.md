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
| 3 | Mock AI Provider Foundation | Docs | ✅ Fully covered | `rao-008` |
| 4 | Database Design | Docs | ✅ Fully covered | `rao-001` (baseline) + `rao-009` (deepened: ERD, Indexing Strategy, Constraints, Enumerations, JSON Field Usage, State Machines, Soft Delete Strategy, Versioning Strategy, Performance Considerations) |
| 5 | Folder Structure & Plugin Organization | Docs | ✅ Fully covered | `rao-010` |
| 6 | Agent Architecture (per-agent detail) | Docs | ✅ Fully covered | `rao-001` (baseline) + `rao-011` (expansion: Context, Prompt Template binding, Produced/Consumed Events, Retry Rules, Escalation Rules for all 17 agents) |
| 7 | MCP Architecture | Docs | ✅ Fully covered | `rao-001` (baseline) + `rao-012` (deepened: Tool Registry, Permission Model, Request/Response Contracts, Error Handling) |
| 8 | Workflow Engine & Orchestration | Docs | ✅ Fully covered | `rao-013` (includes Pause/Resume Logic, previously deferred) |
| 9 | UI/UX Specification | Docs | ✅ Fully covered | `rao-001` (baseline) + `rao-014` (deepened: Information Architecture, 2 new pages, 2 drill-down pages, Dashboard Designs) |
| 10 | Plugin Skeleton | Code | 📋 Spec'd, blocked on 5 open questions (`docs/PHASE1-SPECIFICATION.md` §7) | `rao-015` (spec only — not implemented) |
| 11 | Database Migrations | Code | 📋 Spec'd | `rao-016` (spec only — not implemented) |
| 12 | Mock AI Provider Implementation | Code | 📋 Spec'd | `rao-017` (spec only — not implemented) |
| 13 | MCP Implementation | Code | 📋 Spec'd | `rao-018` (spec only — not implemented) |
| 14 | Multi-Agent Orchestration | Code | 📋 Spec'd | `rao-019` (spec only — not implemented) |
| 15 | User Interface Implementation | Code | 📋 Spec'd | `rao-020` (spec only — not implemented) |
| 16 | Enterprise Readiness | Code | 📋 Spec'd | `rao-021` (spec only — not implemented) |

**Retroactive coverage note (historical)**: `rao-001` (gate-approved, docs-scope) originally bundled what this roadmap splits into Phases 1, 2, 4, 6, 7, and 9. Every one of those gaps has since been closed by a dedicated deepening ticket — see the completion notes below. As of 2026-07-02, **all 16 phases have a specification** (Phases 1-9: fully covered and closed; Phases 10-16: fully spec'd, awaiting implementation).

**Phase 2 completion (2026-07-02)**: `rao-007` closed the Phase 2 gap flagged above — `docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md` adds Service-Oriented Architecture conventions, a SOLID-principles mapping, expanded Module Responsibilities, Agent Engine internals (Registry/Lifecycle/Runner + concurrency model), a Workflow Engine design (one state machine shared by agent-run and ticket-status workflows), a concrete Event Bus design (built on `ActiveSupport::Notifications`, resolving `WORKFLOW.md` §15's forward-looking flag), Conversation/Memory/Prompt architecture, and all ten cross-cutting strategies (Background Job, Queue, Cache, Retry, Logging, Configuration, Error Handling, Security, Performance, Scalability). Phase 2 is now fully covered.

**Phase 1 breakdown (2026-07-02)**: Phase 1's deliverable list has been broken into 5 individually-gated tickets that supersede the informal "retroactively covered" label — `rao-002` (Product Vision, Business Goals, Project Scope, Success Criteria, Assumptions & Constraints), `rao-003` (Functional/Non-Functional Requirements, User Roles & Personas, User Stories), `rao-004` (AI-Assisted Development Workflow, Multi-Agent Collaboration Overview), `rao-005` (MCP Vision, Security & Compliance Overview), `rao-006` (High-Level Architecture, Product Roadmap v1→v2→v3). Each ticket cites already-approved content where it existed and adds genuinely new documents/sections where it didn't (`docs/USER-ROLES-AND-STORIES.md`, `docs/SECURITY-COMPLIANCE-OVERVIEW.md`, `docs/PRODUCT-ROADMAP.md`, plus five new sections in `VISION.md`). All five passed their three-gate review at docs-scope and sit in `backlog/specification/`.

**Phase 3 completion (2026-07-02)**: `rao-008` fully specifies Phase 3 — `docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md` defines the Provider Interface (standard request/response/error/capability/configuration models), the Mock AI Provider's internal architecture and lifecycle, Provider-specific detail on Conversation Flow and Agent Execution Flow, Prompt Management and the 11-category Prompt Template Library, the Mock Response Strategy (12 scenarios) with deterministic fake-data generation rules, Token/Cost Simulation (fixture-declared, not runtime-computed), Provider-specific Logging/Error Handling/Configuration, and the Future Migration Plan's mechanics. Phase 3 is now fully covered.

**Phase 4 completion (2026-07-02)**: `rao-009` closed the Phase 4 gap flagged above — `docs/PHASE4-DATABASE-DESIGN.md` adds a real Mermaid ERD, a Database Architecture Overview, a consolidated Indexing Strategy (filling in every index `rao-001` didn't specify), Constraints (including a deliberate cross-database-portability tradeoff for prompt-template versioning), a full Enumerations catalog, a JSON Field Usage catalog with a query-portability rule, a State Machines catalog cross-referencing the Phase 2 Workflow Engine, a deepened Audit Tables immutability mechanism, a Soft Delete Strategy (none needed, with one concrete status-based exception), a Versioning Strategy pattern, and Performance Considerations (retention/archival policy). Phase 4 is now fully covered.

**Phases 5-9 completion (2026-07-02)**: `rao-010` (Phase 5, Folder Structure), `rao-011` (Phase 6 expansion, full per-agent Context/Prompt/Events/Retry/Escalation for all 17 agents), `rao-012` (Phase 7 deepened, Tool Registry/Permission Model/Contracts/Error Handling), `rao-013` (Phase 8, including the previously-deferred Pause/Resume Logic — implemented as a scheduling gate via the existing `configurations` table, not a new agent-run state), and `rao-014` (Phase 9 deepened, Information Architecture + 2 new pages [Prompt Library, Settings] + 2 drill-down pages [Sprint Planner, Agent Monitoring]) — all five closed in `backlog/done/`. This completes every documentation phase (1-9).

**Phases 10-16 specified, not implemented (2026-07-02)**: `rao-015` through `rao-021` give every implementation phase a full Planning/Specification (with a Code Changes table)/Test Cases/Quality-Gates ticket — but per the Golden Rule ("no code before specification... no merge before tests pass"), **none of these tickets have been implemented**. They sit gate-approved in `backlog/specification/`, ready for whenever the developer says "implement this," starting with `rao-015` (Phase 10, Plugin Skeleton) — which is itself still blocked on the 5 open questions in `docs/PHASE1-SPECIFICATION.md` §7.

**Next action**: either (a) resolve the 5 open questions so `rao-015` can actually be implemented, or (b) continue refining specifications. Counter advanced to 22.

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
