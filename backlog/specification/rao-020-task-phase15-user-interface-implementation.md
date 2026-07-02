## Metadata
- **Task ID**: rao-020-task-phase15-user-interface-implementation
- **Title**: ROADMAP.md Phase 15 — User Interface Implementation
- **Type**: task
- **Status**: specification
- **Complexity**: HIGH
- **Created**: 2026-07-02
- **Author**: Sheetal Sharma
- **Quality Gates**: Gate 1: approved (docs-scope) | Gate 2: approved (docs-scope) | Gate 3: approved (docs-scope)

---

## Planning

**Description**: Implements all 13 pages specified in [docs/UI-WIREFRAMES.md](../../docs/UI-WIREFRAMES.md) and [docs/PHASE9-UI-UX-SPECIFICATION.md](../../docs/PHASE9-UI-UX-SPECIFICATION.md). This ticket specifies the implementation; it does not write it. Depends on `rao-019` (orchestration) for any page that shows live agent/dependency state.

**Goal**: Every wireframed page renders real data, every permission gate hides (not just disables) unauthorized menu items, and the Settings screen's credential-masking rule is implemented exactly as specified.

**Objectives**:
- [ ] All 7 originally-wireframed pages implemented (AI Chat/Wizard, Requirement Review, Agent Dashboard, Dependency Dashboard, Release Planner, Token Usage & Cost, Execution History/Logs)
- [ ] Two new pages implemented (Prompt Library, Settings) per `docs/PHASE9-UI-UX-SPECIFICATION.md` §4
- [ ] Two drill-down pages implemented (Sprint Planner, Agent Monitoring) per §5
- [ ] Every dashboard reads from its denormalized data source (§6), never a live join through `agent_runs`
- [ ] Credential fields never pre-fill or render real secret values (`rao-014`'s carried-forward requirement)

**Deliverables** (created when implemented):
- [ ] `app/controllers/redmineflux_agentos/*.rb` (full actions, not skeletons)
- [ ] `app/views/redmineflux_agentos/**/*.erb`
- [ ] `assets/javascripts/redmineflux_agentos/{chat,dashboards,pending_approvals}.js`
- [ ] `assets/stylesheets/redmineflux_agentos/agentos.css`

---

## Specification

**Complexity**: HIGH — 13 pages across project-level and admin-level surfaces, with a real security requirement (credential masking) and a real correctness requirement (permission-gated menu visibility, not just disabled controls).

**Reason**: UI implementation is where a design flaw becomes user-visible for the first time — the credential-masking and permission-hiding requirements are both things a generic Rails form/menu implementation would get wrong by default if not deliberately handled.

### Code Changes

| File | Action | Description |
|---|---|---|
| `app/controllers/redmineflux_agentos/chat_controller.rb` | create | AI Chat / New AI Project Wizard |
| `app/controllers/redmineflux_agentos/requirement_reviews_controller.rb` | create | SRS approval flow |
| `app/controllers/redmineflux_agentos/agent_dashboards_controller.rb` | create | Agent Dashboard + Agent Monitoring drill-down |
| `app/controllers/redmineflux_agentos/dependency_dashboards_controller.rb` | create | Dependency Dashboard |
| `app/controllers/redmineflux_agentos/releases_controller.rb` | create | Release Planner + Sprint Planner drill-down |
| `app/controllers/redmineflux_agentos/token_usages_controller.rb` | create | Token Usage & Cost Dashboard |
| `app/controllers/redmineflux_agentos/execution_histories_controller.rb` | create | Execution History / Logs |
| `app/controllers/redmineflux_agentos/admin/prompt_templates_controller.rb` | create | Prompt Library |
| `app/controllers/redmineflux_agentos/admin/settings_controller.rb` | create | Settings/Configuration, with masked-credential form partial |
| `app/views/redmineflux_agentos/**/*.erb` | create | One view set per controller above |

### Implementation Notes

- **Settings screen's credential fields use a dedicated form partial that never binds to the real decrypted value** — `rao-014`'s mandatory requirement; a generic Rails form helper bound directly to the model attribute would violate this by default.
- **Permission-gated menu items are hidden by the menu registration condition (`init.rb`), not CSS `display: none`** — matches the existing design principle already stated in `docs/UI-WIREFRAMES.md`'s "Design principles applied across all screens."
- **All dashboards are read-only views over already-denormalized tables** — no dashboard controller action performs a live aggregation query across `agent_runs` at request time (Phase 2 §B.9).

---

## Test Cases

### Functional Tests
| # | Test Name | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Permission-gated visibility | Log in as a user without `view_token_usage` | Token Usage menu item and route both absent (404, not a rendered "access denied" page revealing the feature exists) | pending |
| 2 | Credential masking | Save a config value, then reload the Settings page | Value renders as `•••• configured`, never the real secret, and the rendered HTML source contains no plaintext secret | pending |
| 3 | Pending Approvals flow | Trigger a `requires_confirmation` tool call, then approve it from the Agent Dashboard | Action executes only after approval; UI reflects `executed` status | pending |

### QA Test Plan

**Scope**: All 13 pages, both permission-gating and credential-masking behavior.

**Pre-conditions**: `rao-015` through `rao-019` implemented.

**QA Steps**: Manually walk every page as users with and without each relevant permission; inspect rendered HTML source for the Settings page specifically to confirm no secret leakage.

**Expected Outcomes**: Every page matches its wireframe/specification; no permission or credential-masking violation.

**Out of Scope**: Visual design/CSS polish beyond functional layout (explicitly deferred per `docs/PHASE1-SPECIFICATION.md`).

---

## Quality Gates

### Gate 1 — Senior Developer Review
Date: 2026-07-02 | Status: approved (docs-scope, code-level Gate 1 deferred to implementation)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | LOW | 13 pages implemented independently risks inconsistent breadcrumb/layout conventions | Code Changes | Resolved — all views share the `AgentOS › {Screen}` breadcrumb convention already established in `docs/UI-WIREFRAMES.md`, enforced by Gate 1 review at implementation time |

Verdict: Approved as a specification.

### Gate 2 — Security & Performance Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | HIGH | A generic Rails form helper bound to a credential attribute would render the real decrypted secret in HTML by default | Implementation Notes | Resolved — mandatory dedicated form partial for sensitive fields, with a required test asserting no plaintext secret appears in rendered HTML |

Verdict: Approved for Phase 15 documentation scope. Finding #1 is a mandatory implementation and test requirement.

### Gate 3 — Pre-Development Sweep
Date: 2026-07-02 | Status: approved (docs-scope)

**Part A**: Confirmed.

**Part B — Predicted implementation bugs**:
| # | Pattern | Predicted Bug | Edge Case Added? |
|---|---------|--------------|-----------------|
| 1 | Permission checks implemented per-controller independently | One controller correctly hides its menu item but still allows direct URL access (route exists, just not linked) | Logged as a required test case: every gated page must also reject direct URL access for unauthorized users, not rely on menu-hiding alone |

Verdict: Approved. No unresolved HIGH/CRITICAL findings in spec text.

---

## Done

*(Not applicable until this ticket is actually implemented and tested against a running Redmine instance)*
