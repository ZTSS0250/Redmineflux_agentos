# User Roles, Personas & User Stories — redmineflux_agentos

**Scope note**: these are the roles of people who *operate* AgentOS itself (Redmine users interacting with the plugin), not the personas of an example generated project. For a worked example of end-product personas (e.g. HR Admin, Manager, Employee inside a generated "Employee Management System"), see [../Readme.md](../Readme.md) §13.2.

---

## 1. Roles & Personas

| Role | Who they typically are | Primary goal when using AgentOS | Key permissions ([PHASE1-SPECIFICATION.md](PHASE1-SPECIFICATION.md) §5) |
|---|---|---|---|
| **AgentOS Administrator** | Redmine system administrator | Configure agents, MCP tool scopes, prompt templates, and global defaults; keep the system safe to leave partially autonomous | `manage_agentos`, `manage_mcp_tools`, `manage_prompt_templates`, `manage_ai_configuration` |
| **Project Owner / Product Manager** | The person who has the idea and owns the delivery outcome | Turn a one-paragraph idea into an approved SRS and a structured backlog with minimal manual PM work | `create_ai_project` |
| **Delivery Lead / Human Scrum Master** | Team lead overseeing execution | Monitor agent/dependency/release state, approve pending irreversible actions, re-prioritize when something's blocked | `run_ai_tasks`, `view_agentos_dashboard` |
| **Developer / Team Member** | Engineer assigned a generated ticket | Work tickets that read like normal, well-formed Redmine issues — acceptance criteria, priority, dependencies already filled in | No AgentOS-specific permission required; ticket assignment uses Redmine's native issue model |
| **QA / Security Reviewer** | Quality or security-focused team member | Confirm generated test coverage and security findings are real and complete before release sign-off | `run_ai_tasks` (to act on findings), `view_agent_logs` |
| **Finance / Leadership Stakeholder** | Budget owner, engagement lead | See AI spend (simulated in v1, real from v2) before it becomes a surprise | `view_token_usage`, `view_cost_dashboard` |

---

## 2. User Stories

Each story references the Functional Requirement(s) it satisfies from [PHASE1-SPECIFICATION.md](PHASE1-SPECIFICATION.md) §1.2 where applicable.

### Project Owner / Product Manager

| # | Story | Related FR |
|---|---|---|
| US-01 | As a Project Owner, I want to describe my product idea in one free-text paragraph, so that I don't have to manually structure a project before AgentOS can act. | FR-01 |
| US-02 | As a Project Owner, I want AgentOS to ask me only the clarification questions it actually needs, in small batches, so that I'm not filling out a wall of 20 questions at once. | FR-02 |
| US-03 | As a Project Owner, I want to review the generated SRS and explicitly approve it before anything is created in Redmine, so that no project artifacts exist based on a misunderstood requirement. | FR-03 |
| US-04 | As a Project Owner, I want to request changes to a draft SRS and receive a new version rather than an in-place edit, so that I keep a clear history of what changed and why. | FR-03 |
| US-05 | As a Project Owner, I want the generated ticket hierarchy (epics → stories → tasks) to carry acceptance criteria, priority, and estimates automatically, so that I don't have to write them by hand. | FR-04, FR-05 |

### Delivery Lead / Human Scrum Master

| # | Story | Related FR |
|---|---|---|
| US-06 | As a Delivery Lead, I want to see every agent's current status and active ticket on one dashboard, so that I know what's happening without asking each agent individually. | FR-12 |
| US-07 | As a Delivery Lead, I want a blocked agent to resume automatically once its dependency ticket closes, so that I never have to manually notice and unblock work. | FR-06, FR-07 |
| US-08 | As a Delivery Lead, I want to approve or reject any irreversible action (bulk close, delete) before it executes, so that AgentOS can't cause unrecoverable damage while I'm not watching. | FR-11 |
| US-09 | As a Delivery Lead, I want a dependency dashboard showing the current Database → Backend → API → Frontend → QA → Deployment chain, so that I can see the critical path and current blockers at a glance. | FR-06, FR-12 |
| US-10 | As a Delivery Lead, I want a clear, actionable error — not a silent failure — when an LLM or MCP call fails, so that I know whether to retry, wait, or escalate. | FR-14 |

### AgentOS Administrator

| # | Story | Related FR |
|---|---|---|
| US-11 | As an AgentOS Administrator, I want to enable/disable individual agents and edit their MCP tool allow-lists, so that I can control each agent's blast radius independently. | FR-13 |
| US-12 | As an AgentOS Administrator, I want prompt templates to be versioned with only one active version per key, so that an in-flight agent run never resolves a half-edited template. | — (Prompt Workflow, see [WORKFLOW.md](../WORKFLOW.md) §17) |
| US-13 | As an AgentOS Administrator, I want every MCP tool call logged with who/what/when/result, so that I can reconstruct any Redmine state change after the fact. | FR-08, FR-09 |

### Developer / Team Member

| # | Story | Related FR |
|---|---|---|
| US-14 | As a Developer, I want AgentOS-generated tickets to look and behave like normal Redmine issues, so that I can work them in the tools I already use without learning a new system. | FR-04, FR-05 |

### QA / Security Reviewer

| # | Story | Related FR |
|---|---|---|
| US-15 | As a QA Reviewer, I want every story to have at least one linked test ticket before it can be marked release-ready, so that untested work can't slip through. | — (QA Agent, [AGENTS.md](AGENTS.md) #11) |
| US-16 | As a Security Reviewer, I want architecture and ticket sets reviewed against a security checklist before release sign-off, so that security gaps are caught at spec time, not after implementation. | — (Security Agent, [AGENTS.md](AGENTS.md) #12) |

### Finance / Leadership Stakeholder

| # | Story | Related FR |
|---|---|---|
| US-17 | As a Finance Stakeholder, I want to see token usage and estimated cost broken down by project and by agent, so that AI spend doesn't become a surprise at the end of the month. | FR-10 |

---

## Coverage note

This story set covers every Functional Requirement in [PHASE1-SPECIFICATION.md](PHASE1-SPECIFICATION.md) §1.2 except FR-13 (AgentOS permission set, covered indirectly by every role's permission column in §1) — no story was written purely to pad the count. New stories should be added here, with an FR cross-reference, whenever a new capability is scoped rather than left implicit in a future task's spec.
