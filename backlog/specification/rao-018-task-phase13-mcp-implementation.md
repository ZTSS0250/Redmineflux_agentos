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
- [ ] `Mcp::ToolRegistry` implemented, boot-registered with every tool's `params_schema` (Phase 7 §2, §7's carried-forward requirement: no tool registered without one)
- [ ] `Mcp::Executor.call` implements the full flow: Permission Model → confirmation gate → handler → logging (Phase 7 §1, §3)
- [ ] All 6 tool category handler files implemented (Phase 5 §6)
- [ ] Idempotency-key handling implemented, including the multi-call suffixing rule (Phase 3 §2.1/§2.5)
- [ ] Secrets redaction implemented for `params_json`/`result_json` before persistence (Phase 2 §B.8, `docs/SECURITY-COMPLIANCE-OVERVIEW.md`)

**Deliverables** (created when implemented):
- [ ] `lib/redmineflux_agentos/mcp/{tool_registry,executor}.rb`
- [ ] `lib/redmineflux_agentos/mcp/tools/{project,issue,wiki,file,time,reporting}_tools.rb`
- [ ] `test/unit/mcp/*.rb`, `test/integration/mcp_*.rb`

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
| 1 | Permission layer 1 denies | Call a tool as a user without the Redmine-level permission | `PermissionDeniedError`, no state change | pending |
| 2 | Permission layer 2 denies | Call a tool not in the calling agent's `tool_allowlist` | `PermissionDeniedError`, no state change | pending |
| 3 | Confirmation gate | Call `delete_issue` | Row written as `pending_confirmation`, issue not yet deleted | pending |
| 4 | Idempotent retry | Retry the same `agent_run`'s tool call | No duplicate Redmine record created | pending |
| 5 | Secrets redaction | Inspect a persisted `mcp_tool_calls.params_json` row after a call with sensitive params | No secret value present in the stored JSON | pending |

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

---

## Done

*(Not applicable until this ticket is actually implemented and tested against a running Redmine instance)*
