## Metadata
- **Task ID**: rao-018-task-phase13-mcp-implementation
- **Title**: ROADMAP.md Phase 13 — MCP Implementation
- **Type**: task
- **Status**: specification
- **Complexity**: HIGH
- **Created**: 2026-07-02
- **Author**: Sheetal Sharma
- **Quality Gates**: Gate 1: approved (docs-scope) | Gate 2: approved (docs-scope) | Gate 3: approved (docs-scope)

---

## Planning

**Description**: Implements the MCP tools that perform real Redmine actions, per [docs/MCP-TOOLS.md](../../docs/MCP-TOOLS.md) and [docs/PHASE7-MCP-ARCHITECTURE.md](../../docs/PHASE7-MCP-ARCHITECTURE.md). This ticket specifies the implementation; it does not write it.

**Goal**: Every tool in `docs/MCP-TOOLS.md`'s catalog is implemented through the single `Mcp::Executor` write path, with the Permission Model's two independent layers, the Request/Response Contract, and the full error hierarchy all enforced exactly as designed.

**Objectives**:
- [x] `Mcp::ToolRegistry` implemented, boot-registered with every tool's `params_schema` (Phase 7 §2, §7's carried-forward requirement: no tool registered without one)
- [x] `Mcp::Executor.call` implements the full flow: Permission Model → confirmation gate → handler → logging (Phase 7 §1, §3)
- [x] All 6 tool category handler files implemented (Phase 5 §6)
- [x] Idempotency-key handling implemented, including the multi-call suffixing rule (Phase 3 §2.1/§2.5)
- [x] Secrets redaction implemented for `params_json`/`result_json` before persistence (Phase 2 §B.8, `docs/SECURITY-COMPLIANCE-OVERVIEW.md`)

**Deliverables** (created when implemented):
- [x] `lib/redmineflux_agentos/mcp/{tool_registry,executor}.rb`
- [x] `lib/redmineflux_agentos/mcp/tools/{project,issue,wiki,file,time,reporting}_tools.rb`
- [x] `test/unit/mcp/*.rb`, `test/integration/mcp_*.rb`

**Implemented (2026-07-03) — untested against a live Redmine instance**: all 20 tools across the six category files, `Mcp::ToolRegistry`, and `Mcp::Executor` (`call`/`confirm`/`reject`). `Mcp::Executor`'s own generic mechanics (both permission layers, the confirmation gate, idempotency dedup, allow-list redaction, audit logging) were run — not just written — through the real Minitest+Mocha runner against a synthetic registered tool (real Issue/Project/WikiPage/TimeEntry/Attachment creation via the six tool files needs a live Redmine instance to verify, which is out of this environment's reach): **15/15 tests pass, 41 assertions, 0 failures, 0 errors**. Three real bugs were caught by actually running this, not by reading the code, and are fixed:

1. **`Mcp::ToolRegistry.register` never actually gained an `authorize:` keyword** — every one of the six tool files' `register!` calls passes `authorize:`, but the registry method's signature was never updated to accept it. This would have raised `ArgumentError: unknown keyword: :authorize` on the very first `to_prepare` boot, crashing plugin initialization entirely before a single tool was usable. Fixed in `lib/redmineflux_agentos/mcp/tool_registry.rb`.
2. **Inconsistent result key-typing between a fresh execution and a replayed idempotent call** — a fresh `Mcp::Executor.call` returned `result:` with whatever key types the handler happened to use (typically symbols), while a deduped replay of the same call (§4) could only reconstruct `result:` from the persisted `result_json` (necessarily string-keyed, since JSON has no symbols). A caller retrying the same call could silently get a different-shaped hash back depending on whether it executed fresh or replayed. Fixed by round-tripping the fresh-execution result through JSON too, so both paths always return the same string-keyed shape.
3. A harness-only gap (not a production bug): the AR-backed `RedminefluxAgentosMcpToolCall` model's `belongs_to :user` association reader needed a stand-in in the test double, confirming `Mcp::Executor#confirm`'s `record.user || confirmed_by` fallback path actually works.

Several interpretive decisions were required beyond what any approved doc states outright — none is a new design surprise, but each fills a genuine gap in `docs/MCP-TOOLS.md`/`docs/PHASE7-MCP-ARCHITECTURE.md`, logged transparently as a Gate 1 revision below.

---

## Specification

**Complexity**: HIGH — this is the plugin's sole write path to Redmine's real data; a defect here has the largest blast radius of any implementation phase (data corruption, permission bypass, or a missed confirmation gate on a destructive action).

**Reason**: Every principle in `docs/SECURITY-COMPLIANCE-OVERVIEW.md` that's actually enforceable in code is enforced here — this phase is where "we designed it securely" becomes "it actually is."

### Code Changes

| File | Action | Description |
|---|---|---|
| `lib/redmineflux_agentos/mcp/tool_registry.rb` | create | Registry with `params_schema` required per entry (Phase 7 §2) |
| `lib/redmineflux_agentos/mcp/executor.rb` | create | The single write path: Permission Model, confirmation gate, handler dispatch, logging (Phase 7 §1/§3/§4) |
| `lib/redmineflux_agentos/mcp/tools/project_tools.rb` | create | `create_project`, `update_project`, `read_project`, `create_version` |
| `lib/redmineflux_agentos/mcp/tools/issue_tools.rb` | create | `create_issue`, `update_issue`, `assign_issue`, `add_comment`, `create_issue_relation`, `bulk_close_issues` (`requires_confirmation`), `delete_issue` (`requires_confirmation`), `search_issues`, `read_ticket`, `read_comments` |
| `lib/redmineflux_agentos/mcp/tools/wiki_tools.rb` | create | `create_wiki_page`, `update_wiki`, `search_wiki` |
| `lib/redmineflux_agentos/mcp/tools/file_tools.rb` | create | `upload_file` |
| `lib/redmineflux_agentos/mcp/tools/time_tools.rb` | create | `create_time_entry`, `update_timesheet` (`requires_confirmation`), `update_workload` |
| `lib/redmineflux_agentos/mcp/tools/reporting_tools.rb` | create | `generate_report` |

### Implementation Notes

- **`params_schema` is mandatory, enforced at registry boot** (Phase 7 §7's carried-forward requirement) — a tool registered without one must fail plugin boot, not silently accept unvalidated params.
- **`User.current` is always explicit** — every `Mcp::Executor.call` requires an `actor:` keyword argument with no default (Phase 2 §B.8).
- **Result payloads never serialize a full Redmine model** — only the key attributes declared in the Response Contract (Phase 7 §4).

---

## Test Cases

### Functional Tests
| # | Test Name | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Permission layer 1 denies | Call a tool as a user without the Redmine-level permission | `PermissionDeniedError`, no state change | pass (2026-07-03, ad hoc harness — synthetic tool, real Redmine permission checks need a live instance) |
| 2 | Permission layer 2 denies | Call a tool not in the calling agent's `tool_allowlist` | `PermissionDeniedError`, no state change | pass (2026-07-03, ad hoc harness) |
| 3 | Confirmation gate | Call `delete_issue` | Row written as `pending_confirmation`, issue not yet deleted | pass (2026-07-03, ad hoc harness — tested against a synthetic `requires_confirmation` tool, plus the full confirm/reject cycle; `delete_issue` itself needs a live Issue to verify) |
| 4 | Idempotent retry | Retry the same `agent_run`'s tool call | No duplicate Redmine record created | pass (2026-07-03, ad hoc harness — caught and fixed a real key-typing inconsistency between a fresh execution and a replayed call, see Planning) |
| 5 | Secrets redaction | Inspect a persisted `mcp_tool_calls.params_json` row after a call with sensitive params | No secret value present in the stored JSON | pass (2026-07-03, ad hoc harness) |

**Verification note (2026-07-03)**: same approach as `rao-017` — `test/unit/mcp/*.rb` and `test/integration/mcp_*.rb` were run **unmodified** (byte-for-byte copies, diffed to confirm) through the real Minitest+Mocha runner against a minimal harness that loads the actual `lib/redmineflux_agentos/**` files with fake `User`/`Agent` actors and in-memory stand-ins for the `mcp_tool_calls`/`audit_logs` tables (no real database in this environment). This validates `Mcp::Executor`'s own generic mechanics exhaustively. It does **not** validate the six tool files' actual Redmine-model interactions (creating a real `Issue`/`Project`/`WikiPage`/`TimeEntry`/`Attachment`) — that requires a live Redmine instance with a real database, which this environment doesn't have. Result: **15/15 pass, 41 assertions, 0 failures, 0 errors**, after fixing the two real bugs described in Planning (the missing `authorize:` keyword on `ToolRegistry.register`, and the result key-typing inconsistency).

### QA Test Plan

**Scope**: Every tool in the catalog, both permission layers, the confirmation gate, and redaction.

**Pre-conditions**: `rao-015`, `rao-016` implemented.

**QA Steps**: Exercise every tool as both an authorized and unauthorized actor; exercise every `requires_confirmation` tool through the full pending → approved/rejected cycle.

**Expected Outcomes**: No tool ever bypasses either permission layer or the confirmation gate; every call is logged before and after execution.

**Out of Scope**: Agent-side logic deciding *when* to call a tool (Phase 14).

---

## Quality Gates

### Gate 1 — Senior Developer Review
Date: 2026-07-02 | Status: approved (docs-scope, code-level Gate 1 deferred to implementation)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | MEDIUM | Six tool files could drift in code style/error handling if implemented independently over time | Code Changes | Resolved — all six must share the same handler shape (registered via one `Mcp::ToolRegistry` entry format, Phase 7 §2), enforced by Gate 1 review at implementation time |

Verdict: Approved as a specification.

**Revision pass (2026-07-03, during implementation)** — `docs/MCP-TOOLS.md`/`docs/PHASE7-MCP-ARCHITECTURE.md` describe the Permission Model and Request/Response Contract at the design level but leave several implementation-shape questions genuinely open. Each below is a mechanical fill within the spirit of the approved design, not a new architectural direction:

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 2 | HIGH | Layer 1 ("Redmine authorize?") has no generic implementation anywhere — only a specific tool handler knows how to resolve its own target Project/Issue from `params` to check the right permission against | §3 Permission Model | Resolved — each tool's `Mcp::ToolRegistry` entry carries its own `authorize:` proc (`->(actor, params) { ... }`), checked by `Mcp::Executor` generically before dispatch. Keeps `Mcp::Executor` itself tool-agnostic (Open/Closed) — adding a tool is a new registry entry, never an Executor change |
| 3 | MEDIUM | Layer 2 (agent `tool_allowlist`) cannot be checked without knowing which agent is calling, but the originally-stubbed `Mcp::Executor.call` signature (Phase 10) has no field for it | §3 Permission Model, Phase 10 stub | Resolved — added an optional `agent:` keyword (`nil` for human-initiated calls, e.g. a Pending Approvals confirmation or an SRS approval); Layer 2 is skipped, not denied, when `agent` is nil, since it doesn't apply to a call with no agent behind it |
| 4 | MEDIUM | No document enumerates which specific stock Redmine permission (`:add_issues`, `:edit_project`, etc.) each of the 20 tools' Layer 1 check should use | §3, `docs/MCP-TOOLS.md` catalog | Resolved — each tool file's `authorize:` proc uses the nearest stock Redmine permission for its action (documented inline per tool); two tools without an obvious stock-permission fit are called out separately (findings #5-#6) |
| 5 | LOW | `update_workload` is hedged in `docs/MCP-TOOLS.md` as "the plugin's own workload read-model (or `redmineflux_workload` integration where installed)" — neither exists as a real table/integration in this schema | `docs/MCP-TOOLS.md` "Time & workload" | Resolved for v1 scope — gated on the existing `:run_ai_tasks` AgentOS permission (project-scoped); the handler acknowledges the request without a real backing read-model rather than raising `NotImplementedError` for a tool the registry advertises as callable. A real `redmineflux_workload` integration replaces the handler body later, not the registration |
| 6 | LOW | `upload_file`'s target can be an Issue, WikiPage, or Project (`docs/MCP-TOOLS.md`), each needing a different Layer-1 permission | `docs/MCP-TOOLS.md` "Files" | Resolved — `container_type` is restricted to exactly those three strings (also closes an unrestricted-`constantize` risk); each maps to its natural permission (`:edit_issues`/`:edit_wiki_pages`/`:manage_files`) |
| 7 | MEDIUM | The QA Test Plan requires exercising `requires_confirmation` tools "through the full pending → approved/rejected cycle," but no confirm/reject mechanism was itemized as a specific deliverable beyond `executor.rb` itself | Test Cases, QA Test Plan | Resolved — `Mcp::Executor.confirm`/`.reject` are implemented as public methods on the same `Executor` module (still just `executor.rb`, no new file). `confirm` does not re-run Layer 1/2 (already satisfied when the call was first queued) — only re-executes the handler and finalizes the row; whether the *confirming* human is authorized to approve is left as a controller-level `authorize` concern for the Pending Approvals queue (Phase 15) |
| 8 | HIGH | `docs/DATABASE-SCHEMA.md`'s `mcp_tool_calls` table has no column to persist an idempotency key, but rao-018's own Objectives require implementing idempotency-key handling, and `docs/MCP-TOOLS.md`'s "Execution guarantees" require it too | `docs/DATABASE-SCHEMA.md`, Objectives | Resolved — one additive migration (`db/migrate/20260703110001_...`) adds a nullable, uniquely-indexed `idempotency_key` column, per CLAUDE.md's "additive params/columns with defaults" rule. Without it, Test Case #4 ("no duplicate Redmine record created" on retry) would have nothing to actually check against |

Verdict (revised): Approved. All findings are mechanical fills of gaps the approved docs already implied but never assigned a concrete shape to — none required abandoning or contradicting anything already gate-approved.

### Gate 2 — Security & Performance Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | HIGH | This phase is the plugin's entire write surface against real Redmine data — any gap in either permission layer is a direct data-integrity/security incident, not a degraded feature | Test Cases #1-#2 | Resolved — both permission layers get dedicated, mandatory test coverage, not just manual review |
| 2 | HIGH | Secrets redaction must be allow-list based (only known-safe keys logged), not deny-list based, per `docs/PHASE4-DATABASE-DESIGN.md` §7's stated rule | Implementation Notes | Resolved — restated here as a mandatory requirement, not assumed carried from the DB design doc automatically |

Verdict: Approved for Phase 13 documentation scope. Both findings are mandatory test/implementation requirements.

### Gate 3 — Pre-Development Sweep
Date: 2026-07-02 | Status: approved (docs-scope)

**Part A**: Confirmed.

**Part B — Predicted implementation bugs**:
| # | Pattern | Predicted Bug | Edge Case Added? |
|---|---------|--------------|-----------------|
| 1 | `bulk_close_issues` operates on a batch | A partial failure mid-batch (issue 3 of 10 fails validation) leaves an ambiguous state — some closed, some not, with an unclear `mcp_tool_calls` result | Logged as a required test case: batch tool calls must either wrap the batch in a transaction (all-or-nothing) or explicitly report per-item success/failure in `result_json` — this ticket does not decide which, but requires the implementation to pick one deliberately, not leave it undefined |

Verdict: Approved. No unresolved HIGH/CRITICAL findings in spec text; finding #1 requires an explicit implementation-time decision, logged so it isn't accidentally left ambiguous.

**Decision recorded (2026-07-03, implementation)**: `bulk_close_issues` (and `update_timesheet`, the same batch shape) use **per-item reporting, not an all-or-nothing transaction**. A batch can span issues in different projects/workflows; wrapping it in one transaction would mean one issue's workflow-validation failure silently undoes N-1 otherwise-valid closures, which is more surprising than a partial result, not less. `result_json` reports `{closed:, failed: [{id:, error:}, ...]}` (or `updated:`/`failed:` for the timesheet tool) instead.

---

## Done

*(Not applicable until this ticket is actually implemented and tested against a running Redmine instance)*
