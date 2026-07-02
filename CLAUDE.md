# CLAUDE.md — redmineflux_agentos

The AI Operating System for Redmine and RedmineFlux — a multi-agent system that turns a natural-language product idea into a fully planned, ticketed, and continuously-executed Redmine project.
**Version:** 0.0.1 (pre-development, Phase 1 specification) | **Redmine:** 5.x / 6.x | **Branch:** `main`
**Organization:** Zehntech Technologies Inc.
**SDD Project Key**: `rao`
**Task ID format**: `rao-{3-digit-number}-{feature|bug|task}-{short-description}`

---

## What This Plugin Does

A Redmine plugin that runs a team of specialized AI agents (Project Manager, Requirement Analyst, Solution Architect, Database/Backend/API/Frontend/UI-UX, QA, Documentation, Security, DevOps, Deployment, Code Review, Reporting, Scrum Master, Business Analyst) which collaborate the way a real software company would: they interview the user about a product idea, produce an SRS, plan releases/sprints/epics, generate dependency-ordered tickets, execute and monitor work via MCP tools against Redmine's own domain model (projects, versions, issues, wiki, time entries), and keep project state continuously up to date.

**Key differentiator:** Agents *act*, not just advise — every agent decision is executed through governed MCP tools that call Redmine's real APIs, with full audit logging, token/cost tracking, and a dependency engine that blocks/resumes agents automatically based on real ticket state.

**Core features (target):** Conversational requirement intake with clarification loop, SRS generation, automatic project/release/sprint/ticket scaffolding, dependency-aware multi-agent execution, live dashboards (agent, dependency, token, cost, workload), and a governed MCP tool layer.

---

## Redmine Compatibility

| Redmine Version | Plugin Version |
|-----------------|---------------|
| 5.x | 0.0.1 (planned) |
| 6.x | 0.0.1 (planned) |

---

## Current Status

**Phase 1 — Specification only. No code has been written yet.**

See [docs/PHASE1-SPECIFICATION.md](docs/PHASE1-SPECIFICATION.md) for the functional specification, architecture, folder structure, navigation, and agent lifecycle. See [docs/DATABASE-SCHEMA.md](docs/DATABASE-SCHEMA.md), [docs/AGENTS.md](docs/AGENTS.md), [docs/MCP-TOOLS.md](docs/MCP-TOOLS.md), [docs/UI-WIREFRAMES.md](docs/UI-WIREFRAMES.md), [docs/USER-ROLES-AND-STORIES.md](docs/USER-ROLES-AND-STORIES.md), and [docs/SECURITY-COMPLIANCE-OVERVIEW.md](docs/SECURITY-COMPLIANCE-OVERVIEW.md) for the supporting detail documents. See [ROADMAP.md](ROADMAP.md) for the full 16-phase internal build-process roadmap, [docs/PRODUCT-ROADMAP.md](docs/PRODUCT-ROADMAP.md) for the v1 → v2 → v3 product capability roadmap (a different document — do not confuse the two), and [WORKFLOW.md](WORKFLOW.md) for the end-to-end workflow specification (how the system operates, agent-to-agent handoffs, MCP lifecycle, approval gates). See [docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md](docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md) for the deepened internal architecture (Agent Engine, Workflow Engine, Event Bus, cross-cutting strategies) and [docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md](docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md) for the Provider Interface and Mock AI Provider design every future LLM integration is written against.

Per the global SDD process, this plugin will not receive a single line of application code until Phase 1 is reviewed and approved by the developer, at which point Phase 2 (plugin skeleton) begins.

---

## Directory Structure (proposed — created in Phase 2)

```
redmineflux_agentos/
├── app/
│   ├── controllers/                    # Chat, wizard, dashboards, admin, REST API
│   ├── models/                         # AR models (RedminefluxAgentos* prefix)
│   ├── views/                          # ERB templates
│   ├── helpers/
│   ├── jobs/                           # ActiveJob background workers (agent runs, MCP calls)
│   └── serializers/                    # JSON shaping for dashboards/API
├── assets/
│   ├── javascripts/                    # Chat UI, dashboards, live polling
│   └── stylesheets/
├── config/
│   ├── locales/en.yml
│   └── routes.rb
├── db/migrate/
├── docs/                                # This Phase 1 documentation set
├── lib/redmineflux_agentos/
│   ├── agents/                         # One class per agent role
│   ├── engine/                         # Agent Engine, Planning Engine, Dependency Engine, Workflow Engine
│   ├── mcp/                            # MCP server + tool definitions
│   ├── prompts/                        # Prompt Manager, template resolution
│   └── hooks/                          # Redmine ViewHooks
├── backlog/                             # SDD task files (planning/specification/done)
├── documents/security-rules.md          # SEC-NNN rule log
├── init.rb
├── TODO.md
├── RELEASE_NOTES.md
└── CLAUDE.md                            # ← you are here
```

---

## Conventions

- **Registered plugin name:** `:redmineflux_agentos`
- **Model prefix:** `RedminefluxAgentos*` (e.g., `RedminefluxAgentosAgent`, `RedminefluxAgentosAgentRun`)
- **Table prefix:** `redmineflux_agentos_{entity}`
- **Agent class namespace:** `RedminefluxAgentos::Agents::{RoleName}Agent`
- **MCP tool naming:** `redmineflux_agentos_{action}` (e.g., `redmineflux_agentos_create_issue`)
- **API routes:** `/agentos/{resource}.json`
- **All controller actions require authentication**; agent-triggered internal calls run through a system service account with explicit `User.current` scoping — never as an unscoped superuser bypass
- **No raw SQL interpolation** — always use parameterized queries / scopes
- **No provider API keys in views, logs, or JSON responses** — encrypted at rest, redacted in audit logs
- **Every MCP tool call, every agent decision, every state transition is logged** to `redmineflux_agentos_execution_logs` and, for user-visible actions, `redmineflux_agentos_audit_logs`

---

## Engineering Discipline

Same non-negotiables as every Redmineflux plugin ([redmineflux_devops/CLAUDE.md](../redmineflux_devops/CLAUDE.md) is the reference):

1. Spec first — nothing ships without a Gate 1/2/3-approved spec in `backlog/specification/`
2. Three sweeps before deploy — build, verify integration points, end-to-end with real data
3. Never ship untested code
4. Read before write
5. One change at a time
6. Fix root causes, not symptoms
7. Log everything (this plugin's entire value proposition depends on this — agent actions must be auditable)
8. Backward compatibility — additive params/columns with defaults
9. Graceful degradation — every LLM call and every MCP call can fail; always have a fallback and a human-visible error state

---

## Rules

- Brand: **"Redmineflux"** (capital R, lowercase f). Company: **"Zehntech Technologies Inc."**
- Agents are additive to human workflows, never a silent replacement — every irreversible action (delete, force-push equivalents, mass ticket close) requires explicit human confirmation before an agent executes it via MCP
- Follow Redmine plugin conventions (`init.rb`, hooks, no core patches)
- REST API on every feature (for MCP server + external dashboards)
- All controller actions need `before_action :require_login` and `accept_api_auth`

## Communication Tone

Same as [redmineflux_devops/CLAUDE.md](../redmineflux_devops/CLAUDE.md): collaborative not commanding, warm not robotic, empowering not replacing, transparent not mysterious, respectful of time.
