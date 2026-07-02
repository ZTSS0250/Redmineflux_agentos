## Metadata
- **Task ID**: rao-009-task-phase4-database-design
- **Title**: ROADMAP.md Phase 4 — Database Design
- **Type**: task
- **Status**: done
- **Complexity**: HIGH
- **Created**: 2026-07-02
- **Author**: Sheetal Sharma
- **Quality Gates**: Gate 1: approved (docs-scope) | Gate 2: approved (docs-scope) | Gate 3: approved (docs-scope)

---

## Planning

**Description**: [ROADMAP.md](../../ROADMAP.md) listed Phase 4 (Database Design) as "✅ Retroactively covered" by `rao-001`, but that status only reflects Table Specifications/Column Definitions/Relationships/Foreign Keys (`docs/DATABASE-SCHEMA.md`). ROADMAP.md's actual Phase 4 deliverable list asks for six more things that did not exist anywhere: a real Entity Relationship Diagram, a consolidated Indexing Strategy, Constraints, Enumerations, JSON Field Usage, State Machines, a Soft Delete Strategy, a Versioning Strategy, and Performance Considerations. This task closes that gap, the same way `rao-007` closed the analogous Phase 2 gap.

**Goal**: Every Phase 4 deliverable is designed to a depth Phase 11 (Database Migrations) can be scoped directly from — including two decisions that did not exist in any form before this task: a Soft Delete Strategy (none needed, with one concrete exception) and cross-database-portable Constraints (no reliance on a feature only one supported DB engine has).

**Objectives**:
- [x] Produce a real Mermaid Entity Relationship Diagram
- [x] Write a Database Architecture Overview
- [x] Consolidate an Indexing Strategy covering every table, filling in indexes `docs/DATABASE-SCHEMA.md` didn't specify
- [x] Consolidate Constraints, including a cross-database-portability decision for "one active prompt version per key"
- [x] Catalog every Enumeration column, its values, and its enforcement mechanism
- [x] Catalog every JSON field, why it's JSON, and a query-portability rule
- [x] Catalog which tables/columns are governed by the Phase 2 Workflow Engine's state machine
- [x] Deepen the Audit Tables immutability requirement into a defense-in-depth mechanism, not just a policy statement
- [x] Decide a Soft Delete Strategy (including the one real case that needs one: a deleted linked issue) and a Referential Integrity approach for Redmine-core-to-plugin associations
- [x] Consolidate a Versioning Strategy pattern and state which tables do/don't need it
- [x] Add Performance Considerations covering unbounded table growth and retention

**Deliverables**:
- [x] `docs/PHASE4-DATABASE-DESIGN.md` (new)

---

## Specification

**Complexity**: HIGH — same class of task as `rao-007`: this makes real, previously-undecided design calls (Soft Delete Strategy, the cross-database uniqueness-constraint tradeoff, the `to_prepare`-based Redmine-core association pattern) that Phase 11's migrations are written against, not just organization of already-approved content.

**Reason**: A wrong call here — e.g. relying on a partial unique index that doesn't work on MySQL, or soft-deleting everything by default — would surface as a production bug or a maintenance burden long after Phase 11 ships, exactly the kind of mistake the SDD process's Gate 2/3 review exists to catch before any migration is written.

### Code Changes

None — this task produces documentation only.

### Implementation Notes

- **No soft deletes, one status-based exception**: rather than adding `deleted_at` columns broadly (a common but easy-to-misuse pattern — every query must remember to filter it), the only case needing "don't lose this data" treatment (`ai_tasks` after its linked issue is deleted) reuses the existing `status` enum with an added `deleted` value.
- **Cross-database constraint tradeoff, made explicit**: "one active prompt template version per key" is enforced at the application layer, not a DB partial unique index — because MySQL (Redmine's most common production DB) doesn't portably support partial unique indexes the way PostgreSQL/SQLite do. This is a deliberate tradeoff with a known risk (see Gate 3 finding #1) carried forward as a mandatory requirement for the future implementation task, not silently accepted.
- **Redmine-core association extension pattern**: `Project`/`Issue` gain `has_many ... dependent: :destroy` declarations toward AgentOS's own tables via a `to_prepare` block at plugin boot — standard Redmine plugin practice, not a core-file edit, and explicitly one-directional (destroying a `Project` cleans up AgentOS rows; it never reaches back to affect a different Redmine record).
- **Retention policy stated as a decision, not deferred**: `execution_logs` (debug-level) gets a 90-day window; everything else governance-related (`token_usages`, `cost_trackings`, `mcp_tool_calls`, `audit_logs`) is retained indefinitely, since those are the basis for historical cost reporting and the audit trail respectively.

---

## Test Cases

Not applicable — no executable code in this task.

### QA Test Plan

**Scope**: `docs/PHASE4-DATABASE-DESIGN.md` in full, plus consistency against `docs/DATABASE-SCHEMA.md`, `docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md` §A.6 (Workflow Engine) and §B.8 (Security Strategy redaction rule), `docs/MCP-TOOLS.md`, and `WORKFLOW.md` §8/§14.

**Pre-conditions**: None.

**QA Steps**:
1. Confirm every deliverable in `ROADMAP.md`'s Phase 4 list has a corresponding section — nothing silently dropped.
2. Confirm the ERD (§2) doesn't contradict any relationship already described in `docs/DATABASE-SCHEMA.md`'s entity relationship summary.
3. Confirm the Indexing Strategy's new indexes (§4) don't duplicate ones `docs/DATABASE-SCHEMA.md` already specified.
4. Confirm the JSON Field Usage table's redaction column matches `docs/MCP-TOOLS.md`'s and CLAUDE.md's redaction rules exactly (no field marked "No" that should be "Yes" or vice versa).
5. Confirm the Soft Delete Strategy's `to_prepare` pattern is explicitly one-directional and doesn't imply any change to core Redmine deletion behavior itself.

**Expected Outcomes**: Developer confirms the Soft Delete Strategy decision and the cross-database constraint tradeoff match their intent (these are the two genuinely new product/technical decisions in this task) before Phase 11 (Database Migrations) begins, and approves.

**Out of Scope**: Actual migration files (Phase 11); any new table or column beyond what `docs/DATABASE-SCHEMA.md` already specifies (a schema change would need its own spec + gate review, not be silently introduced here — the one addition, `ai_tasks.status: deleted`, is a new *enum value*, not a new column).

---

## Quality Gates

### Gate 1 — Senior Developer Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | MEDIUM | An ERD including every table (even ones with only a nullable `project_id` relationship) would be too cluttered to be useful | docs/PHASE4-DATABASE-DESIGN.md §2 | Resolved — `knowledge_base_entries`, `configurations`, `audit_logs` deliberately omitted from the diagram with an explicit note explaining why, rather than silently left out |
| 2 | LOW | Reusing `ai_tasks.status` for a `deleted` value could be confused with a mirrored issue status if not clearly documented as mutually exclusive | docs/PHASE4-DATABASE-DESIGN.md §6, §10 | Resolved — Enumerations catalog explicitly states `deleted` is mutually exclusive with every mirrored issue-status value |

Verdict: Approved for Phase 4 documentation scope.

### Gate 2 — Security & Performance Review
Date: 2026-07-02 | Status: approved (docs-scope)

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | HIGH | Enforcing "one active prompt version per key" only at the application layer (not a DB constraint) is inherently racy under concurrent activation requests | docs/PHASE4-DATABASE-DESIGN.md §5 | Accepted as a deliberate cross-database-portability tradeoff (no portable partial-unique-index equivalent across MySQL/PostgreSQL/SQLite); the race condition itself is carried forward as a mandatory required test case for the future implementation task (Gate 3 finding #1) rather than silently accepted risk |
| 2 | MEDIUM | Unbounded growth of `execution_logs`/`mcp_tool_calls`/`token_usages` with no stated retention policy risks eventual performance degradation and storage cost | docs/PHASE4-DATABASE-DESIGN.md §12 | Resolved — explicit retention windows decided now (90 days for debug-level execution logs; indefinite for governance-relevant tables) rather than left as a future surprise |
| 3 | MEDIUM | Extending Redmine's `Project`/`Issue` core models with new associations at boot (`to_prepare`) could, if implemented carelessly, cascade-delete something outside AgentOS's own tables | docs/PHASE4-DATABASE-DESIGN.md §10 | Resolved — explicitly documented as one-directional: the association lives on `Project`/`Issue` pointing at AgentOS's own tables only; `dependent: :destroy` never reaches back to affect a different Redmine record |

Verdict: Approved for Phase 4 documentation scope. Finding #1's race condition is carried forward as a mandatory implementation-time test case, not just documented intent.

### Gate 3 — Pre-Development Sweep
Date: 2026-07-02 | Status: approved (docs-scope)

**Part A — Gate 1 & 2 resolution confirmed**: Confirmed — all five resolutions above are present in the current text of `docs/PHASE4-DATABASE-DESIGN.md` (§2, §6/§10, §5, §12, §10 respectively).

**Part B — Predicted implementation bugs**:
| # | Pattern | Predicted Bug | Edge Case Added? |
|---|---------|--------------|-----------------|
| 1 | Application-layer-only "one active version per key" enforcement (§5) | Two concurrent "activate this prompt version" requests both pass their check before either writes, resulting in two `is_active: true` rows for the same key — an in-flight agent run could then non-deterministically resolve either one, breaking the reproducibility Phase 3's Mock AI Provider design depends on | Logged as a required test case for the future implementation task: concurrent activation attempts, asserting exactly one row ends up `is_active: true` (e.g. via a row lock or a database-level transaction with `SELECT ... FOR UPDATE` on the key during activation, even though the uniqueness itself isn't DB-enforced) |
| 2 | `to_prepare`-based core model extension not firing identically across Redmine deployment/eager-loading modes | The `dependent: :destroy` association silently doesn't engage in a production eager-loaded boot the way it did in development, leaving orphaned AgentOS rows after a project deletion in some environments but not others | Logged as a required test case for the future implementation task: verify the association fires under both eager-loaded (production-like) and lazy-loaded (development-like) boot modes |
| 3 | Retention job pruning `execution_logs` for a run that is old by `created_at` but not yet in a terminal state | A long-`waiting_on_dep` agent run's logs get pruned out from under it before it ever completes, breaking Execution History for that run once it finally resumes | Logged as a required test case for the future implementation task: the retention job's query must exclude any `agent_run` not in a terminal status (`completed/failed/dead/cancelled`), regardless of `created_at` age |

Verdict: Approved. No unresolved HIGH/CRITICAL findings in spec text; all three predicted bugs are carried forward as explicit required test cases for the future Phase 11 implementation task, not blockers to this documentation task.

---

## Done

- **PR**: N/A — documentation-only task, committed directly to `main` per developer instruction (no application code, no PR review required)
- **Merged**: 2026-07-02
- **Release Notes entry**: `RELEASE_NOTES.md` updated
- **Deliverable verification**: `docs/PHASE4-DATABASE-DESIGN.md` confirmed present at close-out, with all twelve sections populated (Architecture Overview, ERD, Table Specs pointer, Indexing Strategy, Constraints, Enumerations, JSON Field Usage, State Machines, Audit Tables, Soft Delete Strategy, Versioning Strategy, Performance Considerations)
- **Carried-forward requirements** (not closed by this ticket — mandatory for the future Phase 11 implementation task): concurrent prompt-version activation needs a row-lock/transaction test to prevent two `is_active: true` rows for the same key; the `to_prepare`-based `Project`/`Issue` association extension needs a test confirming it fires under both eager- and lazy-loaded boot modes; the log-retention job must exclude any `agent_run` not in a terminal status regardless of `created_at` age
- **Note**: the 5 open questions in `docs/PHASE1-SPECIFICATION.md` §7 remain unresolved and still block Phase 10 — closing this ticket does not close those questions
