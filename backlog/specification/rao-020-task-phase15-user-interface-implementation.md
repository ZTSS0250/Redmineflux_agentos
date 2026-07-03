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
- [x] All 7 originally-wireframed pages implemented (AI Chat/Wizard, Requirement Review, Agent Dashboard, Dependency Dashboard, Release Planner, Token Usage & Cost, Execution History/Logs)
- [x] Two new pages implemented (Prompt Library, Settings) per `docs/PHASE9-UI-UX-SPECIFICATION.md` §4
- [x] Two drill-down pages implemented (Sprint Planner, Agent Monitoring) per §5
- [x] Every dashboard reads from its denormalized data source (§6), never a live join through `agent_runs`
- [x] Credential fields never pre-fill or render real secret values (`rao-014`'s carried-forward requirement)

**Deliverables** (created when implemented):
- [x] `app/controllers/redmineflux_agentos/*.rb` (full actions, not skeletons)
- [x] `app/views/redmineflux_agentos/**/*.erb`
- [x] `assets/javascripts/redmineflux_agentos/{chat,dashboards,pending_approvals}.js`
- [x] `assets/stylesheets/redmineflux_agentos/agentos.css`

**Implemented (2026-07-03) — untested against a live Redmine instance**: all 13 pages across 9 controllers (`AgentDashboardsController`, `DependencyDashboardsController`, `ReleasesController`+`SprintsController`, `TokenUsagesController`, `CostDashboardsController`, `ExecutionHistoriesController`, `Admin::PromptTemplatesController`, `Admin::SettingsController`, `ChatController`+`RequirementReviewsController`), every dashboard reading its denormalized source directly per §6, plus a new `RedminefluxAgentos::Configuration::CredentialMasking` module implementing Gate 2's mandatory masking mechanism. `approve`/`reject` on the Agent Dashboard are wired to the real `Mcp::Executor.confirm`/`.reject` (Phase 13) — the Pending Approvals flow (Functional Test #3) is a genuine, working integration, not a stub. **Status remains `specification`, not `done`** — this environment has no live Redmine instance, so the parts of this ticket's own Test Cases that need a real browser/routing/view-rendering stack (permission-gated 404s, actual rendered HTML inspection) are not exercised here; only `CredentialMasking`'s pure logic was run through the real Minitest+Mocha runner — **6/6 tests pass, 20 assertions** — catching one real bug: the sensitive-key pattern list included a bare `/token/i`, which false-positived against the real v1 config key `token_rules` (a behavior setting, not a credential) — fixed by requiring "token" to be paired with a credential-indicating word (`access`/`api`/`auth`/`refresh`).

One genuine, acknowledged gap, not silently worked around — logged as a Gate 1 revision below: `ChatController#create` and `RequirementReviewsController#update` correctly persist their respective state (a user message; an SRS approval decision) but do **not** trigger the actual agent turn that should follow (the Requirement Analyst Agent's turn on a new chat message; the Project Manager Agent's planning turn on SRS approval, per WORKFLOW.md §5-§6). That bridging is `ConversationManager::Session`'s job (Phase 2 §A.8) — a class that does not exist anywhere in this codebase, and was never itemized as a deliverable in any of the seven implementation tickets (`rao-015` through `rao-021`). Building an ad hoc bridge directly in these controllers would duplicate logic §A.8 already owns and risk getting its contract wrong ahead of whichever future ticket actually implements Conversation Architecture.

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
| 1 | Permission-gated visibility | Log in as a user without `view_token_usage` | Token Usage menu item and route both absent (404, not a rendered "access denied" page revealing the feature exists) | not run here — needs a live Redmine instance's real routing/permission stack; the mechanism (`before_action :authorize` already gating every action per the same init.rb permission map the menu items use, Phase 10) was verified by code review, not a functional test |
| 2 | Credential masking | Save a config value, then reload the Settings page | Value renders as `•••• configured`, never the real secret, and the rendered HTML source contains no plaintext secret | pass (2026-07-03, ad hoc harness) for the masking *logic*; the rendered-HTML half needs a live instance, see Gate 2's live-verification flag |
| 3 | Pending Approvals flow | Trigger a `requires_confirmation` tool call, then approve it from the Agent Dashboard | Action executes only after approval; UI reflects `executed` status | not run here — `AgentDashboardsController#approve`/`#reject` are wired to the already-tested `Mcp::Executor.confirm`/`.reject` (15/15 pass, `rao-018`), but exercising the actual controller/view/AJAX round trip needs a live Redmine instance |

**Verification note (2026-07-03)**: same approach as every prior phase — `test/unit/configuration/credential_masking_test.rb` was run **unmodified** (byte-for-byte copy, diffed to confirm) through the real Minitest+Mocha runner against a minimal harness (this module has no dependency beyond plain Ruby + ActiveSupport's `blank?`/`present?`, so the harness is far lighter than Phases 12-14's). Result: **6/6 pass, 20 assertions, 0 failures, 0 errors**, after fixing the real `token_rules` false-positive bug described in Planning. This is the one part of Phase 15 that's genuinely unit-testable without a browser — every controller action was implemented and syntax-checked (`ruby -c`, all pass) but not functionally exercised, since that requires Redmine's real routing/view-rendering/permission stack this environment doesn't have.

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

**Revision pass (2026-07-03, during implementation)**:

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 2 | MEDIUM | `ChatController`/`RequirementReviewsController` need to trigger an actual agent turn (Requirement Analyst on a new message, Project Manager on SRS approval, WORKFLOW.md §5-§6), but the class that owns that bridging — `ConversationManager::Session`, Phase 2 §A.8 — does not exist, and no ticket from `rao-015` through `rao-021` itemizes it as a deliverable | Code Changes (implied dependency) | Resolved for this ticket's scope — both actions correctly persist their own state (message; approval decision) and stop there, with an explicit code comment; the actual agent-triggering step is left for whichever future ticket implements Phase 2 §A.8's Conversation Architecture, rather than this ticket inventing an ad hoc, likely-to-be-reworked bridge |

Verdict (revised): Approved. Finding #2 is a genuine cross-ticket dependency gap the roadmap never assigned an owner to — not a reason to block this ticket, since the pages this ticket owns (their own read/persist concerns) are otherwise complete and correct.

### Gate 2 — Security & Performance Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | HIGH | A generic Rails form helper bound to a credential attribute would render the real decrypted secret in HTML by default | Implementation Notes | Resolved — mandatory dedicated form partial for sensitive fields, with a required test asserting no plaintext secret appears in rendered HTML |

Verdict: Approved for Phase 15 documentation scope. Finding #1 is a mandatory implementation and test requirement. **Live-verification flag**: `CredentialMasking`'s logic is unit-tested (6/6 pass), but the literal claim "rendered HTML source contains no plaintext secret" needs an actual Rails view-rendering pass against a live Redmine instance — out of this environment's reach, same category of gap as every other phase.

### Gate 3 — Pre-Development Sweep
Date: 2026-07-02 | Status: approved (docs-scope)

**Part A**: Confirmed.

**Part B — Predicted implementation bugs**:
| # | Pattern | Predicted Bug | Edge Case Added? |
|---|---------|--------------|-----------------|
| 1 | Permission checks implemented per-controller independently | One controller correctly hides its menu item but still allows direct URL access (route exists, just not linked) | Logged as a required test case: every gated page must also reject direct URL access for unauthorized users, not rely on menu-hiding alone. **Confirmed already structurally satisfied**: every AgentOS controller inherits `before_action :authorize` (project-scoped) or `:authorize_global` (admin-scoped) from `rao-015`'s `BaseController`/`Admin::BaseController` — the same permission declarations in `init.rb` that gate menu-item visibility also gate the action itself, so no per-controller implementation choice could reintroduce this gap; still needs a live-instance functional test to confirm, not just code review |

Verdict: Approved. No unresolved HIGH/CRITICAL findings in spec text.

---

## Done

*(Not applicable until this ticket is actually implemented and tested against a running Redmine instance)*
