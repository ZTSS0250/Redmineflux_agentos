## Metadata
- **Task ID**: rao-010-task-phase5-folder-structure
- **Title**: ROADMAP.md Phase 5 — Folder Structure & Plugin Organization
- **Type**: task
- **Status**: done
- **Complexity**: MEDIUM
- **Created**: 2026-07-02
- **Author**: Sheetal Sharma
- **Quality Gates**: Gate 1: approved (docs-scope) | Gate 2: approved (docs-scope) | Gate 3: approved (docs-scope)

---

## Planning

**Description**: [ROADMAP.md](../../ROADMAP.md) Phase 5 was entirely un-spec'd. This task defines exactly where every class/module already designed in Phases 2–4 will live on disk, so Phase 10 (Plugin Skeleton) can generate files directly from this document without re-deciding placement.

**Goal**: Every deliverable in ROADMAP.md's Phase 5 list (Plugin Directory Layout, Application/Service Layer Organization, Agent/Provider/MCP/Workflow Modules, Background Jobs, Initializers, Assets, Locales, Specs, Documentation Layout) maps to a concrete path, traceable back to the Phase 2-4 document that designed the thing living there.

**Objectives**:
- [x] Full plugin directory tree
- [x] Map every Phase 2 module (Agent Engine, Workflow Engine, Event Bus, MCP Integration) to a `lib/` path
- [x] Map every Phase 3 Provider concept to a `lib/redmineflux_agentos/providers/` path
- [x] Map all 17 agents (`docs/AGENTS.md`) to `lib/redmineflux_agentos/agents/` files
- [x] Map every Phase 2 §B.1 background job to `app/jobs/`
- [x] Define the initializer's boot-time responsibilities
- [x] Define the test directory structure, matching Redmine's `Test::Unit` convention (not RSpec) for consistency with `redmineflux_devops`
- [x] Resolve the "fixtures" naming collision between Rails test fixtures and Mock Provider response fixtures

**Deliverables**:
- [x] `docs/PHASE5-FOLDER-STRUCTURE.md` (new)

---

## Specification

**Complexity**: MEDIUM — unlike Phases 2/3/4, this task makes almost no new architectural decisions; it's placement/organization of things already designed. The one genuine decision is `lib/` vs `app/services/` for the service layer, resolved by precedent (`redmineflux_devops`'s own structure).

**Reason**: A wrong or inconsistent placement decision here would surface as autoloading confusion or merge conflicts during Phase 10, not a design defect — hence MEDIUM rather than the HIGH of the phases that made load-bearing decisions.

### Code Changes

None — this task produces documentation only. No files or directories are created by this task; Phase 10 creates them.

### Implementation Notes

- **Services live under `lib/`, not `app/services/`** — matching `redmineflux_devops`'s own plugin structure, since Redmine plugins conventionally keep plugin-namespaced business logic under `lib/` rather than relying on Rails' `app/` autoload conventions across a plugin boundary.
- **Test convention**: `test/unit/`, `test/functional/`, `test/integration/` (Minitest/`Test::Unit`), not `spec/` (RSpec) — Redmine core and `redmineflux_devops` both use this convention; deviating would be inconsistent with every other Zehntech Redmine plugin.
- **"Fixtures" naming collision resolved by directory separation**: Rails test fixtures (`test/fixtures/`) and Mock Provider response fixtures (`config/agentos/fixtures/mock_provider/`, per Phase 3 §12) are unrelated concepts that happen to share a name — kept in deliberately distant directory trees so a file path is never ambiguous about which one it is.
- **Initializer uses `to_prepare`, not a plain top-level initializer body** — so provider/agent/event-bus registration re-runs correctly under both eager-loaded (production) and lazy-loaded (development) boot, directly addressing the Gate 3 finding from `rao-009` about `to_prepare`-based core extensions needing to work in both modes.

---

## Test Cases

Not applicable — no executable code in this task.

### QA Test Plan

**Scope**: `docs/PHASE5-FOLDER-STRUCTURE.md` in full, cross-checked against every module/class name already committed to in Phases 2–4.

**Pre-conditions**: None.

**QA Steps**:
1. Confirm every path in §2-§7 corresponds to a class/module actually named in `docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md`, `docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md`, `docs/AGENTS.md`, or `docs/MCP-TOOLS.md` — no new, undesigned class is introduced by this document.
2. Confirm all 17 agents from `docs/AGENTS.md` (including the reserved Code Review Agent) appear in §4.
3. Confirm the test-directory convention matches `redmineflux_devops`'s actual structure (`test/unit/`, `test/functional/`, `test/integration/`).

**Expected Outcomes**: Developer confirms the `lib/` vs `app/services/` placement choice and approves.

**Out of Scope**: Actually generating any file or directory (Phase 10).

---

## Quality Gates

### Gate 1 — Senior Developer Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | LOW | Placing services under `lib/` instead of Rails-conventional `app/services/` could surprise a developer expecting standard autoloading | docs/PHASE5-FOLDER-STRUCTURE.md §3 | Resolved — explicitly justified by precedent (matches `redmineflux_devops`'s own structure), not an arbitrary deviation |

Verdict: Approved for Phase 5 documentation scope.

### Gate 2 — Security & Performance Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | MEDIUM | The initializer's boot-time registration (provider, agents, event bus subscribers, core-model association extension) must complete before the first `agent_run_job` executes, or a run could be picked up against an empty registry | docs/PHASE5-FOLDER-STRUCTURE.md §9 | Resolved by using `to_prepare` (runs before request/job handling begins in every boot mode), consistent with the `rao-009` Gate 3 requirement that this pattern work under both eager and lazy loading |

Verdict: Approved for Phase 5 documentation scope.

### Gate 3 — Pre-Development Sweep
Date: 2026-07-02 | Status: approved (docs-scope)

**Part A — Gate 1 & 2 resolution confirmed**: Confirmed — both resolutions are present in the current text of `docs/PHASE5-FOLDER-STRUCTURE.md`.

**Part B — Predicted implementation bugs**:
| # | Pattern | Predicted Bug | Edge Case Added? |
|---|---------|--------------|-----------------|
| 1 | Two same-named "fixtures" concepts in one plugin | A future contributor adds Mock Provider fixture files under `test/fixtures/` by habit, mixing runtime simulation data with test seed data | Logged as a required code-review check for the Phase 12 implementation task: Mock Provider fixtures must never be added under `test/fixtures/` |

Verdict: Approved. No HIGH/CRITICAL findings.

---

## Done

- **PR**: N/A — documentation-only task, committed directly to `main` per developer instruction
- **Merged**: 2026-07-02
- **Release Notes entry**: `RELEASE_NOTES.md` updated
- **Deliverable verification**: `docs/PHASE5-FOLDER-STRUCTURE.md` confirmed present at close-out, all 13 sections populated
- **Carried-forward requirement**: Mock Provider fixtures must never be placed under `test/fixtures/` — a required code-review check for Phase 12
