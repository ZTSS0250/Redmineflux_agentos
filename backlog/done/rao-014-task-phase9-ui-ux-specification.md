## Metadata
- **Task ID**: rao-014-task-phase9-ui-ux-specification
- **Title**: ROADMAP.md Phase 9 — UI/UX Specification (Deepened)
- **Type**: task
- **Status**: done
- **Complexity**: MEDIUM
- **Created**: 2026-07-02
- **Author**: Sheetal Sharma
- **Quality Gates**: Gate 1: approved (docs-scope) | Gate 2: approved (docs-scope) | Gate 3: approved (docs-scope)

---

## Planning

**Description**: `docs/UI-WIREFRAMES.md` (`rao-001`) wireframed 7 combined screens; ROADMAP.md's Phase 9 list names 13 pages and asks for Information Architecture, Navigation Structure, and User Flows, none of which existed as their own sections. Two pages (Prompt Library, Settings) had no wireframe at all; two more (Sprint Planner, Agent Monitoring) were ambiguous about whether they're separate pages.

**Goal**: Every page in ROADMAP.md's Phase 9 list has an unambiguous specification — either pointing at its existing wireframe or, for the two missing ones, a new wireframe matching the existing visual convention.

**Objectives**:
- [x] Produce an Information Architecture site map covering all 13 pages plus their drill-down relationships
- [x] Add the two missing wireframes: Prompt Library, Settings
- [x] Resolve the Sprint Planner / Agent Monitoring ambiguity (drill-downs of Release Planner / Agent Dashboard, not new top-level pages)
- [x] Add the two User Flows not already covered by `WORKFLOW.md` §4 (prompt versioning flow, settings-scope flow)
- [x] Formalize Dashboard Designs — widgets and data source per dashboard

**Deliverables**:
- [x] `docs/PHASE9-UI-UX-SPECIFICATION.md` (new)

---

## Specification

**Complexity**: MEDIUM — mostly filling genuine gaps (two missing wireframes, ambiguity resolution) rather than making new architectural decisions; the one Gate-2-relevant decision is the Settings screen's credential-masking rule.

**Reason**: Lower complexity than Phases 2/4/8 because no new backend mechanism is introduced — this document specifies presentation only, consistent with everything it's built on already existing (Phase 2 §B.6 Configuration Strategy, Phase 3 §2.7 Configuration Contract).

### Code Changes

None — this task produces documentation only.

### Implementation Notes

- **Sprint Planner and Agent Monitoring are drill-downs, not new menu items** — resolves the apparent mismatch between ROADMAP.md listing 13 pages and `docs/PHASE1-SPECIFICATION.md` §4's nav tree only having entries for some of them.
- **Settings screen never renders real credential values** — explicitly stated because a real provider (v2+, `docs/PRODUCT-ROADMAP.md`) will eventually have a `credentials` field (Phase 3 §2.7) that must never round-trip to the browser once saved.

---

## Test Cases

Not applicable — no executable code in this task.

### QA Test Plan

**Scope**: `docs/PHASE9-UI-UX-SPECIFICATION.md` in full, cross-checked against `docs/UI-WIREFRAMES.md`, `docs/PHASE1-SPECIFICATION.md` §4-§5, and `docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md` §2.7.

**Pre-conditions**: None.

**QA Steps**:
1. Confirm all 13 pages named in `ROADMAP.md`'s Phase 9 list are accounted for (either an existing wireframe citation or a new one).
2. Confirm the two new wireframes (§4.1, §4.2) match the visual convention (box-drawing ASCII, breadcrumb line) of `docs/UI-WIREFRAMES.md`'s existing 7.
3. Confirm the Settings wireframe explicitly shows no credential value ever rendered in plaintext.

**Expected Outcomes**: Developer confirms the Sprint Planner / Agent Monitoring drill-down resolution matches their intent (vs. wanting them as genuinely separate top-level pages) and approves.

**Out of Scope**: Actual view/controller implementation (Phase 15); visual design/CSS (a later concern per `docs/PHASE1-SPECIFICATION.md`).

---

## Quality Gates

### Gate 1 — Senior Developer Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | LOW | Resolving Sprint Planner/Agent Monitoring as drill-downs rather than separate menu items could look like avoiding the ROADMAP.md list's implication they're distinct pages | docs/PHASE9-UI-UX-SPECIFICATION.md §5 | Resolved — explicitly justified: they are distinct *pages* (own route, own breadcrumb) without needing to be distinct *menu items*, satisfying the deliverable without adding navigational clutter |

Verdict: Approved for Phase 9 documentation scope.

### Gate 2 — Security & Performance Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | HIGH | A Settings/Configuration screen for provider credentials (relevant from v2 onward) could default to a common but insecure web-form pattern: pre-filling an input with the actual decrypted secret | docs/PHASE9-UI-UX-SPECIFICATION.md §4.2 | Resolved — explicit rule: credential fields never render a real value, only a masked indicator (`•••• configured`) and a "replace" action; carried forward as a mandatory implementation requirement for Phase 15 |

Verdict: Approved for Phase 9 documentation scope. Finding #1 is carried forward as mandatory for whichever future task implements the Settings screen.

### Gate 3 — Pre-Development Sweep
Date: 2026-07-02 | Status: approved (docs-scope)

**Part A — Gate 1 & 2 resolution confirmed**: Confirmed.

**Part B — Predicted implementation bugs**:
| # | Pattern | Predicted Bug | Edge Case Added? |
|---|---------|--------------|-----------------|
| 1 | Settings form implementation defaults to standard Rails form helpers, which pre-fill fields from the model's current attribute value | A credential field gets implemented the same way as every other config field, silently pre-filling the decrypted secret into the rendered HTML | Logged as a required test case for Phase 15: any config key flagged as sensitive (credentials) must use a dedicated form partial that never binds to the real value, verified by asserting the rendered HTML never contains the plaintext secret |

Verdict: Approved. No unresolved HIGH/CRITICAL findings in spec text; finding carried forward as a required test case for Phase 15.

---

## Done

- **PR**: N/A — documentation-only task, committed directly to `main` per developer instruction
- **Merged**: 2026-07-02
- **Release Notes entry**: `RELEASE_NOTES.md` updated
- **Deliverable verification**: `docs/PHASE9-UI-UX-SPECIFICATION.md` confirmed present at close-out, including the two new wireframes
- **Carried-forward requirement**: sensitive config fields (credentials) must never pre-fill or render the real value in HTML — required test case for Phase 15
