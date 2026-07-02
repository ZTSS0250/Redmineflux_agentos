# TODO.md — redmineflux_agentos Task Index

**Project Key**: `rao`
**Next Task Number**: See `backlog/.counter` (current: 7)
**Status**: See [ROADMAP.md](ROADMAP.md) for the full 16-phase roadmap and per-phase status. Phase 1 is fully done — all 6 tickets (`rao-001`..`rao-006`) closed in `backlog/done/`. Next up: Phase 3 — Mock AI Provider Foundation (`rao-007`).

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

`backlog/specification/` is now empty — every Phase 1 ticket has been verified deliverable-complete and moved to `backlog/done/`.

Read in this order: [VISION.md](VISION.md) → [docs/PHASE1-SPECIFICATION.md](docs/PHASE1-SPECIFICATION.md) → [docs/USER-ROLES-AND-STORIES.md](docs/USER-ROLES-AND-STORIES.md) → [docs/SECURITY-COMPLIANCE-OVERVIEW.md](docs/SECURITY-COMPLIANCE-OVERVIEW.md) → [docs/PRODUCT-ROADMAP.md](docs/PRODUCT-ROADMAP.md) → [docs/AGENTS.md](docs/AGENTS.md) → [docs/DATABASE-SCHEMA.md](docs/DATABASE-SCHEMA.md) → [docs/MCP-TOOLS.md](docs/MCP-TOOLS.md) → [docs/UI-WIREFRAMES.md](docs/UI-WIREFRAMES.md) → [WORKFLOW.md](WORKFLOW.md).

`rao-001` retroactively satisfies ROADMAP.md Phases 4, 7, and 9 in full, and *partially* satisfies Phases 2 and 6 (see ROADMAP.md's coverage note). `rao-002`..`rao-006` together now fully and individually satisfy every Phase 1 deliverable — Phase 1 no longer relies on the informal "retroactively covered" label alone.

**Blocking Phase 10 (plugin skeleton)**: 5 open questions in `docs/PHASE1-SPECIFICATION.md` §7 (LLM provider, background job backend, MCP transport, confirmation UX, code-writing-agent scope reservation).

---

## Upcoming (not yet spec'd)

- **rao-007** — ROADMAP.md Phase 3: Mock AI Provider Foundation (provider interface, prompt management, fixture-based mock responses, token/cost simulation) — **next task to open**
- Phase 5 — Folder Structure & Plugin Organization (not yet spec'd)
- Phase 6 (expansion) — per-agent memory/context/prompt-binding/state-machine detail beyond what `docs/AGENTS.md` currently covers
- Phase 8 — Workflow Engine & Orchestration (not yet spec'd)
- Phase 2 (expansion) — SOLID design principles, event bus, memory/prompt architecture, retry/cache/queue strategy beyond what `docs/PHASE1-SPECIFICATION.md` currently covers
- Phase 10 — Plugin skeleton (`init.rb`, empty module structure, routes, permission registration, menu entries)
- Phase 11 — Database migrations for all tables in `docs/DATABASE-SCHEMA.md`
- Phases 12-16 — one task per phase per ROADMAP.md, each through the full three-gate review before implementation

---

## Changelog

- 2026-07-02 — Closed `rao-003`, `rao-004`, `rao-005`, `rao-006`: all four moved from `backlog/specification/` → `backlog/done/`, Status set to `done` on each, Done sections filled with deliverable verification (`docs/USER-ROLES-AND-STORIES.md`, `VISION.md` Multi-Agent Collaboration Overview, `VISION.md` MCP Vision + `docs/SECURITY-COMPLIANCE-OVERVIEW.md`, `docs/PRODUCT-ROADMAP.md` — all re-confirmed present on disk). `backlog/specification/` is now empty; all six Phase 1 tickets (`rao-001`–`rao-006`) are closed. Two carried-forward requirements are logged for future tasks, not blocking this closure: a build-time zero-outbound-network-call test for the Mock AI Provider (Phase 12) and the v1→v2 vendor/DPA review gate (tracked in `docs/PRODUCT-ROADMAP.md`).
- 2026-07-02 — Closed `rao-002`: moved `backlog/specification/rao-002-task-phase1-vision-goals-scope.md` → `backlog/done/`, Status set to `done`. `VISION.md`'s Business Goals, Project Scope, and Assumptions & Constraints sections re-verified present at close-out.
- 2026-07-02 — Closed `rao-001`: moved `backlog/specification/rao-001-task-phase1-foundation-specification.md` → `backlog/done/`, Status set to `done`, Done section filled (no PR — documentation-only task, committed directly to `main` per developer instruction). All Planning deliverables re-verified present on disk at close-out. Note: the 5 open questions in `docs/PHASE1-SPECIFICATION.md` §7 remain unresolved and still block Phase 10 — closing this ticket does not close those questions.
- 2026-07-02 — Broke Phase 1 into 5 discrete, individually-gated tickets: `rao-002` (Product Vision/Business Goals/Project Scope/Success Criteria/Assumptions & Constraints — new sections in `VISION.md`), `rao-003` (Functional/NFRs already existed; new `docs/USER-ROLES-AND-STORIES.md` for Roles & 17 user stories), `rao-004` (AI Workflow already existed; new "Multi-Agent Collaboration Overview" in `VISION.md`), `rao-005` (new "MCP Vision" section in `VISION.md`; new `docs/SECURITY-COMPLIANCE-OVERVIEW.md` — principles, data handled, v1 zero-egress compliance claim, threat model), `rao-006` (High-Level Architecture already existed; new `docs/PRODUCT-ROADMAP.md` — v1→v2→v3 product capability roadmap with explicit promotion gates, disambiguated from `ROADMAP.md`). All five passed Gates 1-3 at docs-scope. Counter advanced to 7; next task is `rao-007` for Phase 3.
- 2026-07-02 — Added [WORKFLOW.md](WORKFLOW.md): end-to-end workflow specification (28 sections — design principles, requirement collection, conversation, provider, agent lifecycle, multi-agent collaboration, MCP, dependency, workflow engine, event bus, memory, prompt, mock AI, token/cost, logging, error handling, human approval, notification, dashboard, reporting, security, future-provider evolution, and a full EMS walkthrough) with Mermaid diagrams throughout. Synthesizes `rao-001`'s approved content into one operational narrative and explicitly flags sections that reach ahead of an already-gated spec (Provider internals, Event Bus, pause/resume — all ROADMAP.md Phase 2/3/8).
- 2026-07-02 — Added [ROADMAP.md](ROADMAP.md): full 16-phase development roadmap (architecture-first, Mock AI Provider Foundation sequenced before DB/plugin work). `rao-001` retroactively mapped to Phases 1, 4, 7, 9 (full) and 2, 6 (partial — expansion needed). Renumbered former placeholders: plugin skeleton is now Phase 10, DB migrations is now Phase 11. Next task to open is `rao-002` for Phase 3 (Mock AI Provider Foundation) — **superseded by the entry above**: `rao-002` was subsequently used for the Phase 1 breakdown instead, so Phase 3 is now `rao-007`.
- 2026-07-02 — rao-001 created and moved to `backlog/specification/`: Phase 1 foundation specification (functional spec, architecture, DB schema, MCP tools, navigation, permissions, agent lifecycle, UI wireframes). All three quality gates approved at documentation scope. Awaiting developer approval to begin Phase 2.
