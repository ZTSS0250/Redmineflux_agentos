# MCP Tool Catalog — redmineflux_agentos

Every tool is named `redmineflux_agentos_{action}` (see [CLAUDE.md](../CLAUDE.md) conventions). Agents never call Redmine models directly — every state change goes through this layer, which enforces: permission check → schema validation → confirmation gate (if flagged) → execution → audit/log write.

`requires_confirmation = true` means a human must approve before the tool executes (see AD-5 in the spec). Defaults are conservative; the exact list is tunable in the admin "MCP Tools" screen (`:manage_mcp_tools`).

## Project & planning

| Tool | Purpose | Maps to | Confirmation |
|---|---|---|---|
| `redmineflux_agentos_create_project` | Create a Redmine project | `Project.create` | No |
| `redmineflux_agentos_update_project` | Update project attributes/modules | `Project#update` | No |
| `redmineflux_agentos_create_version` | Create a release/milestone (`Version`) | `Version.create` | No |
| `redmineflux_agentos_read_project` | Read project metadata | `Project.find` | n/a (read) |

## Issues

| Tool | Purpose | Maps to | Confirmation |
|---|---|---|---|
| `redmineflux_agentos_create_issue` | Create an issue (epic/story/task/subtask) | `Issue.create` | No |
| `redmineflux_agentos_update_issue` | Update fields/status/custom fields | `Issue#update` | No, except status → closed on bulk (see below) |
| `redmineflux_agentos_assign_issue` | Assign to user/agent-mapped account | `Issue#assigned_to=` | No |
| `redmineflux_agentos_add_comment` | Add a note/journal entry | `Journal.create` | No |
| `redmineflux_agentos_create_issue_relation` | Link issues (blocks/relates/duplicates) | `IssueRelation.create` | No |
| `redmineflux_agentos_bulk_close_issues` | Close many issues at once | `Issue#update` (batch) | **Yes** |
| `redmineflux_agentos_delete_issue` | Delete an issue | `Issue#destroy` | **Yes** |
| `redmineflux_agentos_search_issues` | Query issues by filter | `IssueQuery` | n/a (read) |
| `redmineflux_agentos_read_ticket` | Read full issue detail | `Issue.find` | n/a (read) |
| `redmineflux_agentos_read_comments` | Read journal history | `Issue#journals` | n/a (read) |

## Wiki

| Tool | Purpose | Maps to | Confirmation |
|---|---|---|---|
| `redmineflux_agentos_create_wiki_page` | Create a wiki page | `WikiPage.create` | No |
| `redmineflux_agentos_update_wiki` | Update a wiki page (new version) | `WikiContent#update` | No |
| `redmineflux_agentos_search_wiki` | Search wiki content | full-text search | n/a (read) |

## Files

| Tool | Purpose | Maps to | Confirmation |
|---|---|---|---|
| `redmineflux_agentos_upload_file` | Attach a file to an issue/wiki/project | `Attachment.create` | No |

## Time & workload

| Tool | Purpose | Maps to | Confirmation |
|---|---|---|---|
| `redmineflux_agentos_create_time_entry` | Log time against an issue | `TimeEntry.create` | No |
| `redmineflux_agentos_update_timesheet` | Bulk-adjust logged time | `TimeEntry#update` (batch) | **Yes** |
| `redmineflux_agentos_update_workload` | Update workload allocation records | plugin's own workload read-model (or `redmineflux_workload` integration where installed) | No |

## Reporting

| Tool | Purpose | Purpose | Confirmation |
|---|---|---|---|
| `redmineflux_agentos_generate_report` | Produce a status/progress/risk report | Reporting System | n/a |

## Permission model for tool access

- Every tool call carries the acting agent's (or user's) Redmine `User` context — `User.current` is set explicitly per call, never left as a default/system superuser, so Redmine's own permission checks (`authorize`, `visible?` scopes) apply identically to agent-originated calls.
- An agent's `config_json.tool_allowlist` (see `redmineflux_agentos_agents`) further restricts which of the above tools that specific agent role may invoke — e.g. the Documentation Agent has no access to `bulk_close_issues` or `delete_issue` even though the tool exists in the registry.
- `requires_confirmation` tools write a `redmineflux_agentos_mcp_tool_calls` row with `status: pending_confirmation` and surface it in the "Pending Approvals" queue (see open question #4 in the spec) — they do not execute until a human with the relevant permission confirms.

## Execution guarantees

- Every call is logged to `redmineflux_agentos_mcp_tool_calls` before execution (`pending_confirmation` or immediately `executed`) and updated with `result_json`/`status` after — so a crashed worker never leaves an untraceable action.
- Read-only tools (`search_*`, `read_*`) are not audit-logged in `redmineflux_agentos_audit_logs` (too high volume) but are captured in `redmineflux_agentos_execution_logs` at `debug` level for troubleshooting.
- Write tools are idempotency-checked where feasible (e.g. `create_issue` includes a caller-supplied idempotency key derived from `ai_task_id` so a retried agent run doesn't create duplicate issues).
