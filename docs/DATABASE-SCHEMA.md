# Database Schema — redmineflux_agentos

All tables prefixed `redmineflux_agentos_`. Foreign keys to Redmine core tables (`projects`, `issues`, `users`, `versions`) reference existing Redmine models — this plugin adds no columns to core tables.

Migrations themselves are a Phase 3 deliverable; this is the normalized design Phase 1 needs sign-off on.

---

## Core agent tables

### `redmineflux_agentos_agents`
Registry of agent roles (the 17 in [AGENTS.md](AGENTS.md)).

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| key | string, unique | e.g. `project_manager`, `database_agent` |
| name | string | display name |
| role_description | text | |
| status | string | `enabled` / `disabled` |
| config_json | text/json | per-agent config (model override, temperature, tool allow-list) |
| created_at / updated_at | datetime | |

### `redmineflux_agentos_agent_runs`
One row per agent execution.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| agent_id | bigint FK -> agents | |
| project_id | bigint FK -> projects | |
| issue_id | bigint FK -> issues, nullable | ticket this run is acting on, if any |
| conversation_id | bigint FK -> conversations, nullable | |
| status | string | `queued/running/waiting_on_dep/completed/failed/dead/cancelled` (§6 lifecycle) |
| blocking_issue_id | bigint FK -> issues, nullable | set when status = `waiting_on_dep` |
| attempts | integer, default 0 | |
| max_attempts | integer, default 3 | |
| input_json | text/json | |
| output_json | text/json | |
| error_message | text, nullable | |
| started_at / finished_at | datetime, nullable | |
| created_at / updated_at | datetime | |

Indexes: `(status)`, `(agent_id, status)`, `(project_id, status)`, `(blocking_issue_id)`.

### `redmineflux_agentos_agent_memories`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| agent_id | bigint FK -> agents | |
| project_id | bigint FK -> projects, nullable | null = cross-project memory |
| scope | string | `short_term` / `long_term` |
| key | string | |
| value_json | text/json | |
| expires_at | datetime, nullable | short-term entries expire |
| created_at / updated_at | datetime | |

Unique index: `(agent_id, project_id, scope, key)`.

---

## Conversation / requirement tables

### `redmineflux_agentos_conversations`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| project_id | bigint FK -> projects, nullable | null until project is created |
| user_id | bigint FK -> users | |
| title | string | |
| status | string | `active/awaiting_user/srs_review/approved/closed` |
| created_at / updated_at | datetime | |

### `redmineflux_agentos_messages`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| conversation_id | bigint FK -> conversations | |
| role | string | `user/agent/system` |
| agent_id | bigint FK -> agents, nullable | set when role = `agent` |
| content | text | |
| tokens_used | integer, nullable | |
| created_at | datetime | |

### `redmineflux_agentos_project_plans`
The SRS + derived plan, versioned.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| project_id | bigint FK -> projects, nullable | |
| conversation_id | bigint FK -> conversations | |
| version | integer | increments on revision |
| srs_markdown | text | |
| srs_json | text/json | structured form used by Planning Engine |
| status | string | `draft/pending_approval/approved/superseded` |
| approved_by_id | bigint FK -> users, nullable | |
| approved_at | datetime, nullable | |
| created_at / updated_at | datetime | |

---

## Planning tables

### `redmineflux_agentos_releases`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| project_plan_id | bigint FK -> project_plans | |
| version_id | bigint FK -> Redmine `versions`, nullable | linked once created via MCP |
| name | string | |
| sequence | integer | |
| status | string | `planned/in_progress/released` |
| created_at / updated_at | datetime | |

### `redmineflux_agentos_sprints`
Plugin-owned concept (see AD-1 in the spec — Redmine has no native sprint).

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| release_id | bigint FK -> releases | |
| name | string | |
| start_date / end_date | date | |
| status | string | `planned/active/completed` |
| created_at / updated_at | datetime | |

### `redmineflux_agentos_ai_tasks`
The plugin's own record of a generated unit of work, linked 1:1 to a Redmine issue once created via MCP. Carries fields Redmine issues don't natively have (story points, agent owner).

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| project_id | bigint FK -> projects | |
| issue_id | bigint FK -> issues, nullable | set once the MCP tool creates the Redmine issue |
| sprint_id | bigint FK -> sprints, nullable | |
| agent_id | bigint FK -> agents | owning agent |
| suggested_reviewer_id | bigint FK -> users, nullable | |
| task_type | string | `epic/story/task/subtask` |
| title | string | |
| description | text | |
| acceptance_criteria | text | |
| priority | string | |
| story_points | integer, nullable | |
| estimated_hours | decimal, nullable | |
| labels | string | comma-separated or use a join table if tagging needs grow |
| status | string | mirrors linked issue status, denormalized for fast dashboard reads |
| created_at / updated_at | datetime | |

### `redmineflux_agentos_dependencies`
Explicit ticket-level dependency edges (the Dependency Engine's DAG).

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| ai_task_id | bigint FK -> ai_tasks | the dependent task |
| depends_on_ai_task_id | bigint FK -> ai_tasks | the prerequisite task |
| dependency_type | string | `blocks/relates_to` |
| created_at | datetime | |

Unique index: `(ai_task_id, depends_on_ai_task_id)`. Application-level check prevents cycles at insert time.

---

## Prompt / knowledge tables

### `redmineflux_agentos_prompt_templates`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| key | string | e.g. `requirement_analyst.clarify_questions` |
| agent_id | bigint FK -> agents, nullable | null = shared/system template |
| version | integer | |
| content | text | |
| variables_json | text/json | declared interpolation variables |
| is_active | boolean | only one active version per key |
| created_by_id | bigint FK -> users | |
| created_at / updated_at | datetime | |

### `redmineflux_agentos_knowledge_base_entries`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| project_id | bigint FK -> projects, nullable | |
| title | string | |
| content | text | |
| source_type | string | `srs/wiki/decision/manual` |
| tags | string | |
| created_at / updated_at | datetime | |

---

## Governance / operations tables

### `redmineflux_agentos_execution_logs`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| agent_run_id | bigint FK -> agent_runs | |
| level | string | `debug/info/warn/error` |
| message | text | |
| metadata_json | text/json | |
| created_at | datetime | |

### `redmineflux_agentos_mcp_tool_calls`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| agent_run_id | bigint FK -> agent_runs, nullable | null for user-triggered direct calls |
| user_id | bigint FK -> users, nullable | set for human-confirmed calls |
| tool_name | string | |
| params_json | text/json | secrets redacted before storage |
| result_json | text/json | |
| status | string | `pending_confirmation/executed/rejected/failed` |
| requires_confirmation | boolean | |
| confirmed_by_id | bigint FK -> users, nullable | |
| duration_ms | integer, nullable | |
| created_at | datetime | |

### `redmineflux_agentos_token_usages`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| agent_run_id | bigint FK -> agent_runs | |
| project_id | bigint FK -> projects | denormalized for dashboard queries |
| provider | string | |
| model | string | |
| prompt_tokens | integer | |
| completion_tokens | integer | |
| total_tokens | integer | |
| created_at | datetime | |

### `redmineflux_agentos_cost_trackings`
Aggregated rollup (populated from `token_usages` via rate card, on a schedule or on write).

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| project_id | bigint FK -> projects, nullable | null = org-wide rollup |
| period | date | day granularity |
| provider | string | |
| model | string | |
| total_tokens | bigint | |
| total_cost | decimal(12,4) | |
| currency | string | default `USD` |
| created_at / updated_at | datetime | |

### `redmineflux_agentos_configurations`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| project_id | bigint FK -> projects, nullable | null = global default |
| key | string | |
| value_json | text/json | |
| updated_by_id | bigint FK -> users | |
| updated_at | datetime | |

Unique index: `(project_id, key)`.

### `redmineflux_agentos_audit_logs`
Immutable — no update/delete path exposed in the app layer.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| user_id | bigint FK -> users, nullable | null if system/agent-initiated with no human confirmer |
| agent_id | bigint FK -> agents, nullable | |
| action | string | e.g. `project.created`, `issue.bulk_closed` |
| target_type | string | |
| target_id | bigint | |
| before_json | text/json, nullable | |
| after_json | text/json, nullable | |
| created_at | datetime | |

---

## Entity relationship summary

```
projects (Redmine) 1──* project_plans 1──* releases 1──* sprints
                                       └──────────────┬──* ai_tasks ──1 issues (Redmine)
                                                        │
                                        ai_tasks *──* ai_tasks   (via dependencies)
                                                        │
agents 1──* agent_runs ──* execution_logs
       1──* agent_memories
       1──* prompt_templates
agent_runs 1──* mcp_tool_calls
agent_runs 1──* token_usages ──(rollup)──> cost_trackings
conversations 1──* messages
conversations 1──1 project_plans (per version)
```

## Design notes for Gate 2 review (flagged in advance)

- `mcp_tool_calls.params_json` and any stored credentials must never retain raw secrets — redact before persisting (see `redmineflux_devops` precedent: encrypted token storage, never in logs).
- All `project_id`-scoped tables must be queried with an explicit `where(project_id: ...)` — no cross-project leakage, especially on dashboard aggregation queries.
- `ai_tasks.status` is a denormalized cache of the linked issue's status; every MCP `update_issue` call must update this column in the same transaction, or dashboards will show stale state.
