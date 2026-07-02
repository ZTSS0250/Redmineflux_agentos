# TODO.md — redmineflux_agentos Task Index

**Project Key**: `rao`
**Next Task Number**: See `backlog/.counter` (current: 9)
**Status**: See [ROADMAP.md](ROADMAP.md) for the full 16-phase roadmap and per-phase status. Phases 1, 2, and 3 are fully specified and closed (8 tickets). Next up: Phase 5 — Folder Structure & Plugin Organization (`rao-009`).

---

## Roadmap

The full phase-by-phase roadmap (architecture-first: functional spec → architecture → mock AI provider foundation → DB design → folder structure → agent architecture → MCP architecture → workflow engine → UI/UX spec → implementation phases 10-16) now lives in [ROADMAP.md](ROADMAP.md). This file tracks task-level status against it. **Do not confuse `ROADMAP.md` (build-process phases) with [docs/PRODUCT-ROADMAP.md](docs/PRODUCT-ROADMAP.md) (v1 → v2 → v3 product capability roadmap, authored under `rao-006`).**

## Current: Phase 1 — Product Functional Specification (fully covered AND closed, 6 tickets)

| ID | Title | Status | Complexity |
|----|-------|--------|------------|
| rao-001 | Phase 1 — Foundation Specification (bundled baseline) | `backlog/done/` ✅ | HIGH |
| rao-002 | Phase 1a — Product Vision, Business Goals, Project Scope, Success Criteria & Assumptions | `backlog/done/` ✅ | EASY |
| rao-003 | Phase 1b — Functional/Non-Functional Requirements, User Roles & Personas, User Stories | `backlog/done/` ✅ | EASY |
| rao-004 | Phase 1c — AI-Assisted Development Workflow & Multi-Agent Collaboration Overview | `backlog/done/` ✅ | EASY |
| rao-005 | Phase 1d — MCP Vision & Security/Compliance Overview | `backlog/done/` ✅ | MEDIUM |
| rao-006 | Phase 1e — High-Level Architecture & Product Roadmap (v1 → v2 → v3) | `backlog/done/` ✅ | MEDIUM |

`backlog/specification/` is now empty of Phase 1 tickets — every one has been verified deliverable-complete and moved to `backlog/done/`.

## Current: Phase 2 — Core Technical Architecture (fully covered AND closed)

| ID | Title | Status | Complexity |
|----|-------|--------|------------|
| rao-007 | Phase 2 — Core Technical Architecture (SOA, SOLID, Agent Engine, Workflow Engine, Event Bus, Conversation/Memory/Prompt architecture, 10 cross-cutting strategies) | `backlog/done/` ✅ | HIGH |

Deliverable: [docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md](docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md). This closes the Phase 2 gap `rao-001` left open — see `ROADMAP.md`'s "Phase 2 completion" note. Three findings were carried forward as **mandatory** requirements for future implementation tasks (not just documented intent): (1) Event Bus subscribers must be fast/non-blocking — enqueue a job for real work, don't do it inline; (2) the Concurrency Guard must use an atomic DB operation, not check-then-act; (3) the per-project dependency-graph cache needs invalidation tests on both insert *and* delete paths.

Read in this order: [VISION.md](VISION.md) → [docs/PHASE1-SPECIFICATION.md](docs/PHASE1-SPECIFICATION.md) → [docs/USER-ROLES-AND-STORIES.md](docs/USER-ROLES-AND-STORIES.md) → [docs/SECURITY-COMPLIANCE-OVERVIEW.md](docs/SECURITY-COMPLIANCE-OVERVIEW.md) → [docs/PRODUCT-ROADMAP.md](docs/PRODUCT-ROADMAP.md) → [docs/AGENTS.md](docs/AGENTS.md) → [docs/DATABASE-SCHEMA.md](docs/DATABASE-SCHEMA.md) → [docs/MCP-TOOLS.md](docs/MCP-TOOLS.md) → [docs/UI-WIREFRAMES.md](docs/UI-WIREFRAMES.md) → [WORKFLOW.md](WORKFLOW.md).

`rao-001` retroactively satisfies ROADMAP.md Phases 4, 7, and 9 in full, and *partially* satisfies Phase 6 (see ROADMAP.md's coverage note — still open). `rao-002`..`rao-006` together now fully and individually satisfy every Phase 1 deliverable. `rao-007` fully satisfies Phase 2 (superseding the earlier "partial" status).

**Blocking Phase 10 (plugin skeleton)**: 5 open questions in `docs/PHASE1-SPECIFICATION.md` §7 (LLM provider, background job backend, MCP transport, confirmation UX, code-writing-agent scope reservation). Note: `rao-007`'s Background Job Strategy effectively answers question #2 by precedent (plain `ActiveJob`, adapter-agnostic), but the question is formally still open pending developer sign-off.

## Current: Phase 3 — Mock AI Provider Foundation (fully covered AND closed)

| ID | Title | Status | Complexity |
|----|-------|--------|------------|
| rao-008 | Phase 3 — Mock AI Provider Foundation (Provider Interface, Mock implementation, Prompt Template Library, deterministic fixture strategy, token/cost simulation) | `backlog/done/` ✅ | HIGH |

Deliverable: [docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md](docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md). This is the foundational contract every future real LLM provider (v2, `docs/PRODUCT-ROADMAP.md`) and every agent-execution path is written against — no real LLM integration in v1, zero external data egress. One finding was carried forward as a **mandatory** requirement for whichever future task implements the first real provider: `active_provider != "mock"` must require non-nil, validated credentials before activation (never silently inherit the Mock Provider's `credentials: nil` allowance).

---

## Upcoming (not yet spec'd)

- **rao-009** — ROADMAP.md Phase 5: Folder Structure & Plugin Organization — **next task to open**
- Phase 6 (expansion) — per-agent memory/context/prompt-binding/state-machine detail beyond what `docs/AGENTS.md` currently covers
- Phase 8 — Workflow Engine & Orchestration (not yet spec'd — note: `rao-007`'s Workflow Engine section is the internal state-machine design; Phase 8 is the broader orchestration model: parallel/sequential execution rules, scheduling, pause/resume)
- Phase 10 — Plugin skeleton (`init.rb`, empty module structure, routes, permission registration, menu entries)
- Phase 11 — Database migrations for all tables in `docs/DATABASE-SCHEMA.md`
- Phases 12-16 — one task per phase per ROADMAP.md, each through the full three-gate review before implementation

---

## Changelog

- 2026-07-02 — Closed `rao-008`: moved `backlog/specification/rao-008-task-phase3-mock-ai-provider-foundation.md` → `backlog/done/`, Status set to `done`, Done section filled. `docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md` re-verified present at close-out, including the Gate 1 revision-pass fixes. `backlog/specification/` is now empty again — all eight tickets across Phase 1, 2, and 3 are closed in `backlog/done/`.
- 2026-07-02 — Revised `rao-008` before close-out: a follow-up review of `docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md` found and fixed a genuine correctness bug (multiple `tool_calls` from one turn would collide on one shared `idempotency_key`, causing `Mcp::Executor` to silently drop all but the first — now fixed with per-call `{idempotency_key}-{n}` suffixing) plus three completeness gaps: added a `memory_updates` field to the Standard Response Model (previously nothing defined what the Runner's "write memory updates" step actually writes), made fixture selection round-aware for categories like Clarification Questions (previously contradicted the no-conditionals templating rule), and tightened `latency_ms` to a fixed, non-randomized value (previously ambiguous, risked breaking determinism). Also added a concrete fixture file shape/example to §7. Logged as a Gate 1 revision pass in `rao-008`, not a silent edit.
- 2026-07-02 — Spec'd `rao-008` (ROADMAP.md Phase 3 — Mock AI Provider Foundation): new `docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md` defines the Provider Interface (standard request/response/error/capability/configuration models), the Mock AI Provider's internal architecture and full lifecycle, Provider-specific detail on Conversation Flow and Agent Execution Flow (extending `rao-007`), Prompt Management and the 11-category Prompt Template Library, the Mock Response Strategy (12 deterministic fixture-based scenarios) with generation rules for fake requirement analysis/ticket generation/dependency mapping/agent collaboration, Token Usage & Cost Simulation (fixture-declared, never runtime-computed, to guarantee determinism), Provider-specific Logging/Error Handling/Configuration extensions, and the Future Migration Plan's concrete mechanics. Performed the required Documentation Updates review: `CLAUDE.md` and `docs/PHASE1-SPECIFICATION.md` companion-doc lists updated; `VISION.md` checked and found already consistent (no edit needed); no new documents proposed beyond the one created. All three gates approved at docs-scope, with one finding carried forward as a mandatory future-implementation requirement (real providers must require validated, non-nil credentials before activation — never inherit Mock's `credentials: nil` allowance). Counter advanced to 9; next task is `rao-009` for Phase 5 (Folder Structure & Plugin Organization). Ticket currently sits in `backlog/specification/`, awaiting close-out.
- 2026-07-02 — Closed `rao-007`: moved `backlog/specification/rao-007-task-phase2-core-technical-architecture.md` → `backlog/done/`, Status set to `done`, Done section filled. `docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md` re-verified present at close-out. `backlog/specification/` is now empty again — all seven tickets across Phase 1 and Phase 2 are closed in `backlog/done/`.
- 2026-07-02 — Spec'd `rao-007` (ROADMAP.md Phase 2 — Core Technical Architecture): new `docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md` closes the Phase 2 gap `rao-001` left partial. Part A (Architecture): Plugin Architecture dependency-direction rule, Service-Oriented Architecture convention, SOLID principles mapping, expanded Module Responsibilities, Agent Engine internals (Registry/Lifecycle/Runner + concurrency model), Workflow Engine (one state machine shared by agent-run and ticket-status workflows), a concrete Event Bus design on `ActiveSupport::Notifications` (resolving `WORKFLOW.md` §15's forward-looking flag), Conversation/Memory/Prompt architecture. Part B (Cross-Cutting Strategies): Background Job (ActiveJob, adapter-agnostic, informed by `redmineflux_devops` precedent), Queue, Cache, Retry, Logging, Configuration, Error Handling, Security (code-level enforcement mapping for `docs/SECURITY-COMPLIANCE-OVERVIEW.md`), Performance, and Scalability strategies. All three gates approved at docs-scope, with three findings carried forward as mandatory future-implementation requirements (Event Bus subscribers must be non-blocking; ConcurrencyGuard must be atomic; cache invalidation needs insert+delete test coverage). Counter advanced to 8; next task is `rao-008` for Phase 3. Ticket currently sits in `backlog/specification/`, awaiting close-out.
- 2026-07-02 — Closed `rao-003`, `rao-004`, `rao-005`, `rao-006`: all four moved from `backlog/specification/` → `backlog/done/`, Status set to `done` on each, Done sections filled with deliverable verification (`docs/USER-ROLES-AND-STORIES.md`, `VISION.md` Multi-Agent Collaboration Overview, `VISION.md` MCP Vision + `docs/SECURITY-COMPLIANCE-OVERVIEW.md`, `docs/PRODUCT-ROADMAP.md` — all re-confirmed present on disk). `backlog/specification/` is now empty; all six Phase 1 tickets (`rao-001`–`rao-006`) are closed. Two carried-forward requirements are logged for future tasks, not blocking this closure: a build-time zero-outbound-network-call test for the Mock AI Provider (Phase 12) and the v1→v2 vendor/DPA review gate (tracked in `docs/PRODUCT-ROADMAP.md`).
- 2026-07-02 — Closed `rao-002`: moved `backlog/specification/rao-002-task-phase1-vision-goals-scope.md` → `backlog/done/`, Status set to `done`. `VISION.md`'s Business Goals, Project Scope, and Assumptions & Constraints sections re-verified present at close-out.
- 2026-07-02 — Closed `rao-001`: moved `backlog/specification/rao-001-task-phase1-foundation-specification.md` → `backlog/done/`, Status set to `done`, Done section filled (no PR — documentation-only task, committed directly to `main` per developer instruction). All Planning deliverables re-verified present on disk at close-out. Note: the 5 open questions in `docs/PHASE1-SPECIFICATION.md` §7 remain unresolved and still block Phase 10 — closing this ticket does not close those questions.
- 2026-07-02 — Broke Phase 1 into 5 discrete, individually-gated tickets: `rao-002` (Product Vision/Business Goals/Project Scope/Success Criteria/Assumptions & Constraints — new sections in `VISION.md`), `rao-003` (Functional/NFRs already existed; new `docs/USER-ROLES-AND-STORIES.md` for Roles & 17 user stories), `rao-004` (AI Workflow already existed; new "Multi-Agent Collaboration Overview" in `VISION.md`), `rao-005` (new "MCP Vision" section in `VISION.md`; new `docs/SECURITY-COMPLIANCE-OVERVIEW.md` — principles, data handled, v1 zero-egress compliance claim, threat model), `rao-006` (High-Level Architecture already existed; new `docs/PRODUCT-ROADMAP.md` — v1→v2→v3 product capability roadmap with explicit promotion gates, disambiguated from `ROADMAP.md`). All five passed Gates 1-3 at docs-scope. Counter advanced to 7; next task is `rao-007` for Phase 3.
- 2026-07-02 — Added [WORKFLOW.md](WORKFLOW.md): end-to-end workflow specification (28 sections — design principles, requirement collection, conversation, provider, agent lifecycle, multi-agent collaboration, MCP, dependency, workflow engine, event bus, memory, prompt, mock AI, token/cost, logging, error handling, human approval, notification, dashboard, reporting, security, future-provider evolution, and a full EMS walkthrough) with Mermaid diagrams throughout. Synthesizes `rao-001`'s approved content into one operational narrative and explicitly flags sections that reach ahead of an already-gated spec (Provider internals, Event Bus, pause/resume — all ROADMAP.md Phase 2/3/8).
- 2026-07-02 — Added [ROADMAP.md](ROADMAP.md): full 16-phase development roadmap (architecture-first, Mock AI Provider Foundation sequenced before DB/plugin work). `rao-001` retroactively mapped to Phases 1, 4, 7, 9 (full) and 2, 6 (partial — expansion needed). Renumbered former placeholders: plugin skeleton is now Phase 10, DB migrations is now Phase 11. Next task to open is `rao-002` for Phase 3 (Mock AI Provider Foundation) — **superseded by the entry above**: `rao-002` was subsequently used for the Phase 1 breakdown instead, so Phase 3 is now `rao-007`.
- 2026-07-02 — rao-001 created and moved to `backlog/specification/`: Phase 1 foundation specification (functional spec, architecture, DB schema, MCP tools, navigation, permissions, agent lifecycle, UI wireframes). All three quality gates approved at documentation scope. Awaiting developer approval to begin Phase 2.
