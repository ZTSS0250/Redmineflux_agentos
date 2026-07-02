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
- [ ] `ProviderInterface` module/contract implemented per `docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md` §2
- [ ] `MockProvider` implements Fixture Selector → Loader → Renderer per §1.2
- [ ] Fixture files authored for all 12 Mock Response Strategy scenarios (§7) plus fake requirement/ticket/dependency/collaboration generation rules (§7.1-§7.4)
- [ ] Token/cost simulation reads fixture-declared values only, never computes at runtime (§9-§10)
- [ ] Error handling implements all five conditions in §8

**Deliverables** (created when implemented):
- [ ] `lib/redmineflux_agentos/providers/provider_interface.rb`, `registry.rb`
- [ ] `lib/redmineflux_agentos/providers/mock/{mock_provider,fixture_selector,fixture_loader,fixture_renderer}.rb`
- [ ] `config/agentos/fixtures/mock_provider/**/*.yml`
- [ ] `test/unit/providers/*.rb`

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
| 1 | Zero network calls | Any `MockProvider.request` call | Test harness asserts no socket/HTTP call was attempted | pending |
| 2 | Determinism | Same fixture rendered twice, in isolation and in a batch | Byte-identical output both times (`rao-008` Gate 3 #2) | pending |
| 3 | Multi-tool-call idempotency | A turn producing 3 `tool_calls` | Each has a distinct `{idempotency_key}-{n}` | pending |
| 4 | Missing fixture directory | Misconfigured `fixture_directory` | Clear boot-time warning, not a silent per-request failure | pending |
| 5 | Round-qualified fixture selection | Clarification Questions round 2 | Resolves `clarification_questions_round_2.yml`, not round 1's content | pending |

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
