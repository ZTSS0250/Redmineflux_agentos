## Metadata
- **Task ID**: rao-015-task-phase10-plugin-skeleton
- **Title**: ROADMAP.md Phase 10 — Plugin Skeleton
- **Type**: task
- **Status**: specification
- **Complexity**: HIGH
- **Created**: 2026-07-02
- **Author**: Sheetal Sharma
- **Quality Gates**: Gate 1: approved (docs-scope) | Gate 2: approved (docs-scope) | Gate 3: approved (docs-scope)

---

## Planning

**Description**: First implementation phase — generates the plugin skeleton per [docs/PHASE5-FOLDER-STRUCTURE.md](../../docs/PHASE5-FOLDER-STRUCTURE.md), with no business logic. This ticket specifies exactly what Phase 10 will create; it does not create it. **This ticket cannot move to `done` until code is written, tested against a running Redmine instance, and the developer confirms — none of which is possible in this environment.**

**Goal**: A gate-approved Code Changes table detailed enough that "implement rao-015" is an unambiguous instruction whenever the developer is ready to begin actual coding.

**Objectives**:
- [ ] `init.rb` registers the plugin, declares `project_module :agentos`, all permissions (`docs/PHASE1-SPECIFICATION.md` §5), and both menu trees (§4)
- [ ] `config/routes.rb` declares all routes (HTML + `.json`/`.api`) for every controller in `docs/PHASE9-UI-UX-SPECIFICATION.md`'s 13 pages
- [ ] Every directory in `docs/PHASE5-FOLDER-STRUCTURE.md` §1 exists, with skeleton (near-empty) files
- [ ] Controllers/models/services/jobs exist with class definitions and associations only — no business logic
- [ ] Initializer (`docs/PHASE5-FOLDER-STRUCTURE.md` §9) exists with `to_prepare` blocks, registration bodies stubbed (raise `NotImplementedError` or no-op, filled in by Phases 11-14)

**Deliverables** (to be created when this ticket is implemented, not by this specification task):
- [ ] `init.rb`, `config/routes.rb`, `config/locales/en.yml`
- [ ] `app/{controllers,models,views,helpers,jobs,serializers}/redmineflux_agentos/` (skeletons)
- [ ] `lib/redmineflux_agentos/{agents,services,providers,mcp,engine,prompts,hooks}/` (empty module namespaces)
- [ ] `config/initializers/redmineflux_agentos.rb`
- [ ] `assets/{javascripts,stylesheets}/redmineflux_agentos/` (empty)

---

## Specification

**Complexity**: HIGH — not because the skeleton itself is complex, but because it's the first code this plugin will ever contain, and every naming/registration mistake here (permission keys, route names, menu hook points) would ripple through every later phase.

**Reason**: Matches CLAUDE.md's own Phase Roadmap table (`docs/PHASE1-SPECIFICATION.md` §8): Phase 10 is explicitly gated on the 5 open questions in §7 being answered first.

### Code Changes

| File | Action | Description |
|---|---|---|
| `init.rb` | create | Plugin registration, `project_module :agentos`, permission declarations, menu items |
| `config/routes.rb` | create | Routes for all controllers, scoped under `/agentos/...` per CLAUDE.md's API route convention |
| `app/controllers/redmineflux_agentos/*.rb` | create | One per page in `docs/PHASE9-UI-UX-SPECIFICATION.md` — empty actions, `before_action :require_login`, `accept_api_auth` |
| `app/models/redmineflux_agentos/*.rb` | create | One per table in `docs/DATABASE-SCHEMA.md` — associations and validations only, no business methods |
| `lib/redmineflux_agentos/**/*.rb` | create | Namespace/class shells per `docs/PHASE5-FOLDER-STRUCTURE.md` §3-§7 |
| `config/initializers/redmineflux_agentos.rb` | create | `to_prepare` block, registration bodies stubbed |

### Implementation Notes

- **Blocked, not just sequenced, on the 5 open questions** (`docs/PHASE1-SPECIFICATION.md` §7): LLM provider choice affects nothing at skeleton stage (Mock only, per `docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md`), but background job backend, MCP transport, and confirmation UX all affect route/initializer shape and must be answered before this ticket is actually implemented, not just specified.
- **No business logic is a hard rule, not a suggestion**: every method body in this phase is either absent, a association/validation declaration, or a stub — Gate 1 review of the actual implementation must reject any real logic sneaking into "skeleton" work.

---

## Test Cases

### Functional Tests
| # | Test Name | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Plugin loads without error | Start Redmine with the plugin installed | No boot errors; plugin appears in Administration > Plugins | pending |
| 2 | Permissions registered | Check Redmine role permission matrix | All permission keys from `docs/PHASE1-SPECIFICATION.md` §5 appear | pending |
| 3 | Menus render, permission-gated | Log in as a user without `create_ai_project` | "AI Chat" menu item is absent, not just disabled | pending |

### QA Test Plan

**Scope**: Plugin boots cleanly, no business logic present, all routes/permissions/menus registered correctly.

**Pre-conditions**: A running Redmine 5.x/6.x instance; the 5 open questions in `docs/PHASE1-SPECIFICATION.md` §7 answered.

**QA Steps**: 1. Install plugin. 2. Run migrations (none exist yet at this phase — `rao-016` follows). 3. Confirm boot, permissions, menus, empty pages render without 500s.

**Expected Outcomes**: A working, empty shell — every page reachable and renders (even if blank), no business logic anywhere.

**Out of Scope**: Any actual functionality (all subsequent phases).

---

## Quality Gates

### Gate 1 — Senior Developer Review
Date: 2026-07-02 | Status: approved (docs-scope, code-level Gate 1 deferred to implementation)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | HIGH | This ticket lists implementation actions but cannot itself be executed while the 5 open questions remain unanswered | Planning | Resolved by stating explicitly: this ticket is gate-approved *as a specification*; its `[ ]` (unchecked) objectives reflect that implementation has not started, unlike doc-only tickets whose objectives were checked at authoring time |

Verdict: Approved as a specification, pending developer answers to the 5 open questions before implementation begins.

### Gate 2 — Security & Performance Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | MEDIUM | Skeleton controllers must have `before_action :require_login` and `accept_api_auth` from the very first commit, not added later "once real logic exists" | Code Changes | Resolved — stated as a Code Changes requirement for every controller file, not deferred |

Verdict: Approved for Phase 10 documentation scope.

### Gate 3 — Pre-Development Sweep
Date: 2026-07-02 | Status: approved (docs-scope)

**Part A**: Confirmed both resolutions are present in spec text.

**Part B — Predicted implementation bugs**:
| # | Pattern | Predicted Bug | Edge Case Added? |
|---|---------|--------------|-----------------|
| 1 | "Skeleton, no business logic" is easy to violate incrementally | A developer adds "just a little" real logic to make a skeleton page look functional during a demo, and it never gets refactored back out before Phase 11-16 build on top of it | Logged as a required Gate 1 check specifically for this ticket's implementation PR: reviewer must reject any method body beyond associations/validations/stubs |

Verdict: Approved. No unresolved HIGH/CRITICAL findings in spec text.

---

## Done

*(Not applicable until this ticket is actually implemented, tested against a running Redmine instance, and the developer confirms — per the Golden Rule, this stays in `backlog/specification/` until then)*
