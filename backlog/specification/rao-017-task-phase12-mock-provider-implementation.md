## Metadata
- **Task ID**: rao-017-task-phase12-mock-provider-implementation
- **Title**: ROADMAP.md Phase 12 — Mock AI Provider Implementation
- **Type**: task
- **Status**: specification
- **Complexity**: HIGH
- **Created**: 2026-07-02
- **Author**: Sheetal Sharma
- **Quality Gates**: Gate 1: approved (docs-scope) | Gate 2: approved (docs-scope) | Gate 3: approved (docs-scope)

---

## Planning

**Description**: Implements the Provider Interface and Mock AI Provider fully designed in [docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md](../../docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md). No external AI services. This ticket specifies the implementation; it does not write it.

**Goal**: A working, fully deterministic Mock Provider that satisfies every invariant `docs/SECURITY-COMPLIANCE-OVERVIEW.md` §3 depends on (zero outbound network calls) and every correctness fix from `rao-008`'s revision pass (idempotency-key suffixing, `memory_updates`, round-aware fixture selection, fixed `latency_ms`).

**Objectives**:
- [x] `ProviderInterface` module/contract implemented per `docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md` §2
- [x] `MockProvider` implements Fixture Selector → Loader → Renderer per §1.2
- [x] Fixture files authored for all 12 Mock Response Strategy scenarios (§7) plus fake requirement/ticket/dependency/collaboration generation rules (§7.1-§7.4)
- [x] Token/cost simulation reads fixture-declared values only, never computes at runtime (§9-§10)
- [x] Error handling implements all five conditions in §8

**Deliverables** (created when implemented):
- [x] `lib/redmineflux_agentos/providers/provider_interface.rb`, `registry.rb`
- [x] `lib/redmineflux_agentos/providers/mock/{mock_provider,fixture_selector,fixture_loader,fixture_renderer}.rb`
- [x] `config/agentos/fixtures/mock_provider/**/*.yml`
- [x] `test/unit/providers/*.rb`

**Implemented (2026-07-03) — untested against a live Redmine instance**: `ProviderInterface` (unchanged — already a correct contract, `MockProvider` overrides its methods directly), `Provider::Registry.active`, and the full Mock pipeline (`FixtureSelector` → `FixtureLoader` → `FixtureRenderer` → `MockProvider#request`) are implemented, plus 15 fixture files covering all 12 §7 scenarios (Clarification Questions spans 3 round-qualified files; Project Planning spans 3 named scenarios sharing one category) and a `_fallback/unhandled_scenario.yml` (§8.5). All logic was smoke-tested standalone (outside Rails) against the real fixture files, and the actual, unmodified `test/unit/providers/*.rb` files were then run through the real Minitest+Mocha runner against a minimal ad hoc harness (see the Test Cases section's verification note) — **10/10 tests passed**. **Status remains `specification`, not `done`** — this environment has no live Redmine instance/real database/Redmine core (`Project`/`Issue`/`User` as real models, permission checks), so that layer of verification is still the developer's per the Golden Rule.

Two cross-cutting gaps were found and filled, both logged as a transparent Gate 1 revision below (not silent scope creep): `RedminefluxAgentos::Error`/`PromptVariableMissingError`/`PromptTemplateInvalidError` (Phase 2 §B.7) and `RedminefluxAgentos::Configuration::Store` (Phase 2 §B.6) were referenced by name throughout the approved docs and are hard dependencies of `Provider::Registry.active` and the Error Model (§2.3, §8), but neither was ever itemized in any of the seven implementation tickets' (`rao-015`-`rao-021`) Code Changes tables. Also added, scoped tightly to what this ticket needs (not the full Phase 2 designs): only the error classes and only the `Configuration::Store.get` read path — no write path, no cache (§B.6's caching/invalidation layer is deferred to whichever future phase's Settings admin page, Phase 15/`rao-020`, first needs to *write* a configuration value). `lib/redmineflux_agentos/providers/mock/ticket_generation_rule.rb` is likewise a new file not itemized in the original Code Changes table — it implements §7.2's deterministic Ticket Generation *algorithm* (the doc is explicit this is a rule, not hand-authored fixture content, since epic x story x task combinatorics make per-epic fixtures impractical).

---

## Specification

**Complexity**: HIGH — this is the foundational contract every agent-execution path depends on; a bug here (especially in the zero-egress invariant or the determinism guarantees) affects the entire system, not one feature.

**Reason**: Matches the HIGH complexity already assigned to `rao-008`'s specification — implementing a HIGH-complexity design is itself HIGH complexity, not automatically lower once "just coding."

### Code Changes

| File | Action | Description |
|---|---|---|
| `lib/redmineflux_agentos/providers/provider_interface.rb` | create | Standard Request/Response/Error/Capability/Configuration models (§2) |
| `lib/redmineflux_agentos/providers/registry.rb` | create | `Provider::Registry`, boot-time registration (§3.1) |
| `lib/redmineflux_agentos/providers/mock/mock_provider.rb` | create | Implements `ProviderInterface`, orchestrates Selector→Loader→Renderer→Usage (§1.2) |
| `lib/redmineflux_agentos/providers/mock/fixture_selector.rb` | create | `(agent_key, prompt_category, scenario_key)` lookup, round-qualification (§7) |
| `lib/redmineflux_agentos/providers/mock/fixture_loader.rb` | create | Reads YAML from `fixture_directory` (§12 config) |
| `lib/redmineflux_agentos/providers/mock/fixture_renderer.rb` | create | `{{variable}}` interpolation (§1.2, matches Prompt Management's syntax) |
| `config/agentos/fixtures/mock_provider/**/*.yml` | create | One file per scenario × agent, per the file shape in §7 |

### Implementation Notes

- **Zero outbound network calls is a tested invariant, not a code-review-only rule**: per `rao-008`'s carried-forward Gate 3 requirement, the test suite must assert `MockProvider` makes no network call (e.g. via a test harness that fails on any attempted socket connection).
- **Idempotency-key suffixing, `memory_updates`, round-aware selection, fixed `latency_ms`**: all four `rao-008` revision-pass fixes are load-bearing requirements for this implementation, not optional refinements.
- **Story-point round-robin must be derived per-fixture-render, never from shared/global state** — `rao-008` Gate 3 finding #2's determinism requirement.
- **Fixture directory existence validated at boot** — `rao-008` Gate 3 finding #1.

---

## Test Cases

### Unit Tests
| # | Test Name | Input / Condition | Expected Result | Status |
|---|-----------|-------------------|-----------------|--------|
| 1 | Zero network calls | Any `MockProvider.request` call | Test harness asserts no socket/HTTP call was attempted | pass (2026-07-03, ad hoc harness — see note) |
| 2 | Determinism | Same fixture rendered twice, in isolation and in a batch | Byte-identical output both times (`rao-008` Gate 3 #2) | pass (2026-07-03, ad hoc harness) |
| 3 | Multi-tool-call idempotency | A turn producing 3 `tool_calls` | Each has a distinct `{idempotency_key}-{n}` | pass (2026-07-03, ad hoc harness — tested with 2 tool_calls; §2.1's rule is per-index, so 2 exercises the same suffixing logic as 3) |
| 4 | Missing fixture directory | Misconfigured `fixture_directory` | Clear boot-time warning, not a silent per-request failure | pass (2026-07-03, ad hoc harness) |
| 5 | Round-qualified fixture selection | Clarification Questions round 2 | Resolves `clarification_questions_round_2.yml`, not round 1's content | pass (2026-07-03, ad hoc harness — first run caught a real bug in this test itself, see note) |

**Verification note (2026-07-03)**: this environment has no live Redmine instance, but it does have the `mocha`/`minitest`/`activesupport` gems installed system-wide. `test/unit/providers/mock_provider_test.rb` and `fixture_loader_test.rb` were run **unmodified** (byte-for-byte copies, diffed to confirm) through the real Minitest+Mocha runner against a small standalone harness that loads the actual `lib/redmineflux_agentos/**` implementation files plus minimal Rails/Redmine stand-ins (a real `Logger`, a stubbed `Redmine::Plugin.find(...).directory` pointing at this repo, and a stubbed `RedminefluxAgentosConfiguration.find_by` returning `nil` — exercising `Configuration::Store`'s real fallback-to-`DEFAULTS` path, which is also the actual fresh-install behavior, not a fake result). **What this harness does not replicate**: real Redmine core (`Project`/`Issue`/`User` as real AR models), a real database, or permission checks — that verification is still the developer's, per the Golden Rule. Result: **10/10 tests passed, 22 assertions, 0 failures, 0 errors**.

The first run of this harness caught one genuine bug — in the *test file*, not the production code: `test_round_qualified_fixture_selection` didn't override `agent_key` from the `base_request` default (`project_manager`), so it was looking for the Clarification Questions fixtures under the wrong agent directory, silently landing on the `_fallback` fixture for both rounds and passing for the wrong reason (both rounds returned identical fallback content, which the assertion's `refute_equal` should have — and did, once fixed — catch). Fixed by adding `agent_key: 'requirement_analyst'` to that test's two requests. This is exactly the kind of bug a real test run catches that reading the code cannot.

### QA Test Plan

**Scope**: Full Mock Provider behavior against `docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md`.

**Pre-conditions**: `rao-015`, `rao-016` implemented.

**QA Steps**: Run the unit test suite above; manually trigger a full conversation + agent-execution flow against the Mock Provider and confirm deterministic, reproducible output across repeated runs.

**Expected Outcomes**: Identical output for identical input, every time, with zero external network activity.

**Out of Scope**: Real provider implementation (v2, not in this roadmap).

---

## Quality Gates

### Gate 1 — Senior Developer Review
Date: 2026-07-02 | Status: approved (docs-scope, code-level Gate 1 deferred to implementation)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | MEDIUM | All four `rao-008` revision-pass fixes must survive into the actual implementation, not just the spec | Implementation Notes | Resolved — explicitly re-stated as load-bearing requirements here, not assumed carried automatically |

Verdict: Approved as a specification.

**Revision pass (2026-07-03, during implementation)** — two genuine cross-cutting gaps surfaced while wiring `Provider::Registry.active` and the Error Model (§2.3, §8), plus one under-specified detail in the Fixture Selector's own lookup key:

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 2 | HIGH | `RedminefluxAgentos::Error` and its subclasses (Phase 2 §B.7) are required by this ticket's own §8 Error Handling Strategy but were never itemized as a file in any of the seven implementation tickets' Code Changes tables | Implementation Notes | Resolved during implementation — created only the base `Error` plus what rao-017 needs (`PromptVariableMissingError`, `PromptTemplateInvalidError`, `Providers::ProviderError`/`FixtureNotFoundError`/`TimeoutSimulatedError`, `Configuration::InvalidProviderError`); `McpToolError`/`DependencyCycleError`/`ConcurrencyLimitError` are left for whichever ticket (MCP Implementation / Multi-Agent Orchestration) actually exercises them |
| 3 | HIGH | `Configuration::Store` (Phase 2 §B.6) is required by `Provider::Registry.active` (§3 step 2 of the Provider Lifecycle) but was never itemized as a file in any ticket's Code Changes table | Implementation Notes | Resolved during implementation — a minimal `Store.get(key, project: nil)` read path was added, reading `redmineflux_agentos_configurations` with the documented project-override-then-global precedence; the write path and explicit-invalidation cache §B.6 also describes are deferred to whichever future phase's Settings admin page first needs to *write* a value |
| 4 | MEDIUM | The Standard Request Model (§2.1) has no dedicated field for "which scenario within a `prompt_category`" — needed the moment a category has more than one named scenario (e.g. Project Planning's create_project/project_plan/agent_assignment) | §7 Mock Response Strategy | Resolved during implementation — an optional `scenario_key` field was added to the request shape MockProvider accepts, defaulting to `prompt_category` itself when absent (which resolves correctly for every category with exactly one scenario); every single-scenario fixture is filed under a filename matching its category for this reason |

Verdict (revised): Approved. All three findings are mechanical fills of gaps the approved docs already implied but never assigned to a specific file — none required a new design decision beyond what Phase 2 §B.6/§B.7 already specify — so no re-review of Gates 2/3 is required.

### Gate 2 — Security & Performance Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | HIGH | The "zero data egress" claim (`docs/SECURITY-COMPLIANCE-OVERVIEW.md` §3) must be verified by an automated test, not just asserted in code review | Test Cases #1 | Resolved — a dedicated test asserting no network call is a required, not optional, test case |

Verdict: Approved for Phase 12 documentation scope. Finding #1 is a mandatory test case, not advisory.

### Gate 3 — Pre-Development Sweep
Date: 2026-07-02 | Status: approved (docs-scope)

**Part A**: Confirmed.

**Part B — Predicted implementation bugs**:
| # | Pattern | Predicted Bug | Edge Case Added? |
|---|---------|--------------|-----------------|
| 1 | Fixture YAML authored by hand at scale (12 scenarios × 17 agents where applicable) | Copy-paste fixture authoring introduces inconsistent `usage` token values that don't correlate sensibly with content length, undermining the plausibility of the Token Usage dashboard even though values are deterministic | Logged as a suggested (non-blocking) review check: fixture `usage` values should be loosely proportional to content length, even though not computed at runtime |

Verdict: Approved. No unresolved HIGH/CRITICAL findings in spec text.

---

## Done

*(Not applicable until this ticket is actually implemented and tested against a running Redmine instance)*
