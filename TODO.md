# TODO.md — redmineflux_agentos Task Index

**Project Key**: `rao`
**Next Task Number**: See `backlog/.counter` (current: 2)
**Status**: Phase 1 (foundation specification) complete, awaiting developer approval before Phase 2 (plugin skeleton).

---

## Current: Phase 1 — Foundation Specification

| ID | Title | Status | Complexity |
|----|-------|--------|------------|
| rao-001 | Phase 1 — Foundation Specification | `backlog/specification/`, gates approved (docs-scope), awaiting developer sign-off | HIGH |

Read in this order: [VISION.md](VISION.md) → [docs/PHASE1-SPECIFICATION.md](docs/PHASE1-SPECIFICATION.md) → [docs/AGENTS.md](docs/AGENTS.md) → [docs/DATABASE-SCHEMA.md](docs/DATABASE-SCHEMA.md) → [docs/MCP-TOOLS.md](docs/MCP-TOOLS.md) → [docs/UI-WIREFRAMES.md](docs/UI-WIREFRAMES.md).

**Blocking Phase 2**: 5 open questions in `docs/PHASE1-SPECIFICATION.md` §7 (LLM provider, background job backend, MCP transport, confirmation UX, code-writing-agent scope reservation).

---

## Upcoming (not yet spec'd)

- **rao-002** — Phase 2: Plugin skeleton (`init.rb`, empty module structure, routes, permission registration, menu entries)
- **rao-003** — Phase 3: Database migrations for all tables in `docs/DATABASE-SCHEMA.md`
- Phase 4+ — one task per module in `docs/PHASE1-SPECIFICATION.md` §2.2, each through the full three-gate review before implementation

---

## Changelog

- 2026-07-02 — rao-001 created and moved to `backlog/specification/`: Phase 1 foundation specification (functional spec, architecture, DB schema, MCP tools, navigation, permissions, agent lifecycle, UI wireframes). All three quality gates approved at documentation scope. Awaiting developer approval to begin Phase 2.
