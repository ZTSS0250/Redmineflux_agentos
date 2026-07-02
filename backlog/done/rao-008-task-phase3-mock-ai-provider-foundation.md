## Metadata
- **Task ID**: rao-008-task-phase3-mock-ai-provider-foundation
- **Title**: ROADMAP.md Phase 3 — Mock AI Provider Foundation
- **Type**: task
- **Status**: done
- **Complexity**: HIGH
- **Created**: 2026-07-02
- **Author**: Sheetal Sharma
- **Quality Gates**: Gate 1: approved (docs-scope) | Gate 2: approved (docs-scope) | Gate 3: approved (docs-scope)

---

## Planning

**Description**: [ROADMAP.md](../../ROADMAP.md) Phase 3 (Mock AI Provider Foundation) is the first fully un-spec'd phase in the roadmap and the foundational contract every later phase — Agent Engine implementation, real LLM providers (v2, `docs/PRODUCT-ROADMAP.md`), and every dashboard — is written against. The objective is explicit: complete the AI provider architecture before any implementation; no real LLM integration in v1; the architecture must be completely provider-agnostic; the entire system communicates only through the Provider Interface defined here.

**Goal**: A Provider Interface (request/response/error/capability/configuration models) that a future real provider can implement without any change to Conversation Flow, Agent Execution Flow, or Prompt Management — proven by a Mock implementation of that same interface, deterministic and fixture-based, with zero external data egress.

**Objectives**:
- [x] Design the Mock AI Provider's internal architecture (responsibilities, request/response lifecycle, extension points)
- [x] Design the Provider Interface (standard request/response/error/capability models, tool-calling support, streaming compatibility, configuration contract)
- [x] Design the full Provider Lifecycle (init through cleanup)
- [x] Add Provider-specific detail to Conversation Flow and Agent Execution Flow, without duplicating the already-approved operational/architectural design in `WORKFLOW.md` and `docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md`
- [x] Design Prompt Management (content/process layer) and the 11-category Prompt Template Library
- [x] Design the Mock Response Strategy (12 scenarios) and the deterministic generation rules for fake requirement analysis, ticket generation, dependency mapping, and agent collaboration
- [x] Design Token Usage Simulation and Cost Simulation as deterministic, fixture-declared (not runtime-computed) values
- [x] Extend the Logging and Error Handling strategies with Provider-specific detail
- [x] Design the Configuration System's Provider-specific keys
- [x] Specify the Future Migration Plan's mechanics (not just the vendor list, which already existed)
- [x] Perform the required Documentation Updates review and conclude with reviewed/modified/proposed/rationale

**Deliverables**:
- [x] `docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md` (new)

---

## Specification

**Complexity**: HIGH — this is the second genuine architectural-design task (after `rao-007`), and arguably the higher-stakes one: every future provider (v2+) and every agent-execution path is written against the interface defined here. An interface mistake here is the most expensive kind to fix later, because it would require changing every caller, not just one module.

**Reason**: Same class of risk as `rao-007` — the Event Bus and Concurrency Guard decisions there set precedent for the Agent Engine; the Standard Request/Response Model and the "fixture-declared, not computed" token-simulation decision here set precedent for the entire Provider layer and everything built on top of it through v3.

### Code Changes

None — this task produces documentation only.

### Implementation Notes

- **Determinism is the load-bearing design constraint, not a preference**: token/cost figures come from fixture-declared values, never computed at runtime; fixture selection is keyed by `(agent_key, prompt_category, scenario_key)`, never by hashing free-text input. Every other design choice in this document (no template conditionals, `{{variable}}`-only composition, a fixed Fibonacci-like story-point sequence) traces back to protecting this constraint — see Gate 3 finding #2 below for a subtle way this constraint could be silently violated during implementation.
- **Tool-calling is v1-load-bearing, not a v2 feature**: the Standard Response Model's `tool_calls` field is how *every* MCP-driven action in v1 (creating a project, a ticket, a wiki page) actually happens — it is not an aspirational capability reserved for a smarter future provider. The Mock Provider must support it fully.
- **Streaming and capability fields exist in the interface now, unused by Mock**: `stream`/`supports_streaming` are present in the Standard Request/Capability models from day one specifically so a v2 real-provider integration never needs an interface shape change — only new provider *behavior*.
- **Configuration Contract's `credentials: nil` is Mock-only**: this document is explicit that only the Mock Provider is allowed to have no credentials; see Gate 2 finding #1 for the guardrail this requires once a real provider is implemented.
- **Documentation Updates performed as part of this task** (not deferred): `CLAUDE.md` and `docs/PHASE1-SPECIFICATION.md` companion-doc lists updated; `TODO.md` updated with this ticket; `VISION.md` checked against this document's design and found already consistent (no edit needed) — full detail in `docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md` §14.
- **Revision pass before close-out**: a follow-up review found and fixed one genuine correctness bug (multi-tool-call idempotency-key collision, §2.1/§2.5) and three completeness gaps (no `memory_updates` field on the Response Model; no round-awareness in fixture selection despite banning template conditionals; `latency_ms` didn't explicitly rule out randomization) — see Gate 1's revision-pass findings #3-6 below. A concrete fixture file shape/example was also added to §7 so the design is verifiably concrete, not just described in prose.

---

## Test Cases

Not applicable — no executable code in this task.

### QA Test Plan

**Scope**: `docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md` in full, plus consistency against `WORKFLOW.md` §7/§18/§19, `docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md` (Agent Engine Runner, Prompt Manager, Configuration Strategy, Error Handling Strategy, Logging Strategy), `docs/PRODUCT-ROADMAP.md`, and `docs/SECURITY-COMPLIANCE-OVERVIEW.md`.

**Pre-conditions**: `rao-007` should be reviewed alongside this task since the Agent Execution Flow and Provider Lifecycle sections directly extend it.

**QA Steps**:
1. Confirm every deliverable in `ROADMAP.md`'s Phase 3 list has a corresponding section — nothing silently dropped.
2. Confirm the Standard Request/Response/Error/Capability/Configuration models are complete enough that a hypothetical `AnthropicProvider` could be described as "implements the same five things" without needing an interface change.
3. Confirm the zero-external-data-egress invariant from `docs/SECURITY-COMPLIANCE-OVERVIEW.md` §3 is upheld by this design — the Mock Provider's internal architecture (§1.2) makes no reference to any network call.
4. Confirm the Documentation Updates section (§14) accurately reflects what was actually reviewed/modified — spot-check that `CLAUDE.md` and `docs/PHASE1-SPECIFICATION.md` were in fact updated as claimed.
5. Confirm the Fake Ticket Generation rule (§7.2) and the round-robin story-point assignment are specified as deterministic *per epic*, not dependent on global/shared state or request order (see Gate 3 finding #2).

**Expected Outcomes**: Developer confirms the Provider Interface shape and the Mock Response Strategy's determinism guarantees match their intent before Phase 12 (Mock AI Provider Implementation) begins, and approves.

**Out of Scope**: Any actual provider class implementation (Phase 12); real provider vendor selection (Open Question #1, `docs/PHASE1-SPECIFICATION.md` §7 — still open, this document does not answer it, only ensures the architecture doesn't need to know the answer yet); fixture *content* authoring (a Phase 12 implementation-time activity, this document specifies the *rules* fixtures must follow, not their literal text).

---

## Quality Gates

### Gate 1 — Senior Developer Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | MEDIUM | The fixed "3 stories / 2 tasks per epic" default in the Fake Ticket Generation rule risks looking repetitive across many epics in a demo | docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §7.2 | Accepted — documented as a deliberate reproducibility-over-realism tradeoff for v1, explicitly overridable per fixture, not a hard cap the implementation must preserve forever |
| 2 | LOW | The "no conditionals, `{{variable}}`-only" templating decision could read as an oversight rather than an intentional simplicity choice | docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §6 | Resolved — explicitly documented as a deliberate choice protecting the determinism constraint, with a stated path to revisit only if a concrete v2+ need emerges |

**Revision pass (2026-07-02, before close-out)** — a follow-up review caught four additional issues not found on the first pass:

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 3 | HIGH | When one agent turn produces multiple `tool_calls`, reusing the turn's single `idempotency_key` across all of them would make `Mcp::Executor`'s idempotency check ([docs/MCP-TOOLS.md](../../docs/MCP-TOOLS.md)) treat calls 2..N as retries of call 1 — silently dropping tickets/records instead of creating them | docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §2.1, §2.5 | Resolved — each tool call's effective idempotency key is now specified as `{idempotency_key}-{n}` (index-suffixed), stated as a correctness requirement, not an implementation nicety |
| 4 | MEDIUM | The Standard Response Model had no field for what an agent's turn wants written to memory, despite Phase 2 §A.5's Runner diagram depending on "write memory updates" as a completion-handling step | docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §2.2, §5.6 | Resolved — added a `memory_updates` field (`{scope, key, value}` array) to the Standard Response Model; the Runner writes exactly what the Provider declares, never inferring memory content from `content` |
| 5 | MEDIUM | §6 bans template conditionals, but Clarification Questions legitimately needs different content per round (1-3) — with no conditionals and no round-awareness in the fixture selection key, this was an unresolved contradiction | docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §7 | Resolved — fixture selection now folds `variables.round_number` into a round-qualified `scenario_key` (e.g. `clarification_questions_round_1`) for any category where this applies; this is a selection-key rule, not a rendering-time branch, so determinism is preserved |
| 6 | LOW | `latency_ms` said "never zero" but didn't rule out randomization, which would break the determinism guarantee for any test asserting on timing-adjacent behavior | docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §2.2 | Resolved — specified as a fixed value (default 250ms), fixture-overridable, explicitly never randomized |

A concrete fixture file shape/example (§7) was also added, since none of the five findings above could be verified as actually resolved without one to point at.

Verdict: Approved for Phase 3 documentation scope, including the revision pass. Findings #3 and #5 are the most significant — #3 is a genuine correctness bug that would have silently dropped data if implemented as originally (under-)specified.

### Gate 2 — Security & Performance Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | HIGH | The Configuration Contract allows `credentials: nil` for the Mock Provider — if this pattern is copy-pasted carelessly, a future real-provider implementation could activate with no credentials and fail silently or (worse) authenticate as some unintended default | docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §2.7 | Resolved by explicitly stating `credentials: nil` is a Mock-Provider-only allowance; carried forward as a mandatory Gate 2 check on whichever future task implements the first real provider (`active_provider != "mock"` must require non-nil, validated credentials before activation) |
| 2 | MEDIUM | The "unknown scenario" fallback (§8.5) returns a generic content response instead of an error — if fallback usage isn't itself visible, real fixture-coverage gaps could persist indefinitely unnoticed | docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §7, §8.5 | Resolved — the Logging Strategy (§11) tags fallback responses distinctly (`scenario_key: fallback`) so coverage gaps are visible in Execution History rather than silently masked forever |

Verdict: Approved for Phase 3 documentation scope. Finding #1 is carried forward as a mandatory implementation-time requirement for the first real-provider task, not just documented intent.

### Gate 3 — Pre-Development Sweep
Date: 2026-07-02 | Status: approved (docs-scope)

**Part A — Gate 1 & 2 resolution confirmed**: Confirmed — all four resolutions above are present in the current text of `docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md` (§7.2, §6, §2.7, §7/§8.5/§11 respectively).

**Part B — Predicted implementation bugs**:
| # | Pattern | Predicted Bug | Edge Case Added? |
|---|---------|--------------|-----------------|
| 1 | Fixture directory misconfigured (wrong/missing path) | Every request fails with `Provider::FixtureNotFoundError`, and the retry layer (Phase 2 §B.4) burns through attempts before anyone notices it's a configuration problem, not a coverage gap | Logged as a required implementation-time check: validate the configured `fixture_directory` exists at plugin boot / provider selection, and log a clear one-time warning if not, rather than only failing per-request |
| 2 | Round-robin story-point assignment implemented as global/shared mutable state instead of derived per-epic | The Fake Ticket Generation rule's determinism guarantee silently breaks — the same epic fixture could produce different story points depending on what else was processed before it in the same run, violating the core "same input, same output" constraint this entire document is built on | Logged as a required test case for the future implementation task: assert that rendering the same epic fixture in isolation vs. as part of a larger batch produces byte-identical output |
| 3 | Fallback ("unknown scenario") usage not actively monitored despite being logged | Fallback responses accumulate silently in logs that nobody reviews, and fixture coverage gaps persist for months | Logged as a suggested (not blocking) future enhancement: a Dashboard or scheduled report surfacing fallback-response frequency, to be scoped when the Reporting System (`docs/AGENTS.md` #17) is actually implemented |

Verdict: Approved. No unresolved HIGH/CRITICAL findings in spec text; all three predicted bugs are carried forward as explicit requirements/test cases for the future Phase 12 implementation task, not blockers to this documentation task.

---

## Done

- **PR**: N/A — documentation-only task, committed directly to `main` per developer instruction (no application code, no PR review required)
- **Merged**: 2026-07-02
- **Release Notes entry**: `RELEASE_NOTES.md` updated
- **Deliverable verification**: `docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md` confirmed present at close-out, including the Gate 1 revision-pass fixes (idempotency-key suffixing, `memory_updates` field, round-qualified fixture selection, fixed `latency_ms`, concrete fixture example)
- **Carried-forward requirements** (not closed by this ticket — mandatory for future implementation tasks): real providers must require validated, non-nil credentials before activation (Gate 2 finding #1); fixture directory existence must be validated at boot (Gate 3 finding #1); story-point round-robin must be derived per-epic, not from shared/global state (Gate 3 finding #2); fallback ("unknown scenario") usage should eventually be surfaced in a dashboard/report (Gate 3 finding #3, non-blocking)
- **Note**: the 5 open questions in `docs/PHASE1-SPECIFICATION.md` §7 remain unresolved and still block Phase 10 — closing this ticket does not close those questions
