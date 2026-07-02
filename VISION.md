# VISION.md — redmineflux_agentos

## Product Vision

AgentOS transforms Redmine from a traditional project management system into an AI-powered software development platform. Instead of a user manually creating projects, releases, tickets, documentation, workloads, and timesheets, they describe a software idea in natural language. A team of specialized AI agents collaborates — the way a real software company would — to turn that idea into a running, continuously-managed Redmine project.

## Business Goals

**For Zehntech**:
- Cut the PM/BA ramp-up time on new client engagements — delivery teams start executing against a structured backlog days, not weeks, after a client signs.
- Turn governed, auditable AI action-taking (MCP-gated, human-approved) into a reusable pattern other Redmineflux plugins (`redmineflux_devops`, `redmineflux_workload`) can build on rather than each inventing their own.
- Create a concrete, demonstrable differentiator for Zehntech's Redmine consulting and plugin offering.

**For adopting teams**:
- Make Redmine (self-hosted, data-sovereign) competitive with Jira/Linear-grade structured planning without giving up self-hosting or paying for a PM/BA cycle on every new project.
- Replace inconsistent, manually-authored tickets/notes/status updates with a system that keeps them current by construction, not by discipline.

## Core Objective

A user enters something like:

> "Build an Employee Management System with Leave, Attendance, Payroll, Notifications and Reports."

AgentOS should:

1. Understand the idea
2. Ask clarification questions
3. Confirm requirements with the user
4. Generate a Software Requirement Specification (SRS)
5. Create the Redmine project
6. Create releases and milestones
7. Generate epics/features
8. Create tickets, with acceptance criteria and dependencies
9. Assign work to specialized AI agents in dependency order
10. Monitor progress and update ticket status/notes
11. Create wiki documentation
12. Log time and update workload
13. Generate reports

— without requiring manual project management for the mechanical parts of this workflow. Humans stay in the loop for judgment calls: approving the SRS, approving irreversible actions, and doing actual code review of agent-authored work in downstream phases.

## Target Users

- Zehntech delivery teams standing up new client engagements quickly
- Product owners who want to go from idea to backlog without a dedicated PM/BA cycle
- Small teams that want Jira/Linear-grade structured planning without the manual overhead

## Project Scope

**In scope for v1** (see [ROADMAP.md](ROADMAP.md) for the phase-by-phase build sequence and [docs/PRODUCT-ROADMAP.md](docs/PRODUCT-ROADMAP.md) for the v1 → v2 → v3 product capability boundary):
- Conversational requirement intake with a bounded clarification loop, ending in a human-approved SRS
- Automatic Redmine project/release/sprint/epic/ticket scaffolding, created only via governed MCP tools
- Dependency-aware multi-agent execution, at the planning/spec/documentation/ticket-status level
- Agent, Dependency, Release, Token Usage, and Cost dashboards; execution history/audit trail
- Exactly one AI provider in v1: the deterministic Mock AI Provider (no real LLM call, no external data egress — see [ROADMAP.md](ROADMAP.md) Phase 3)
- A single Redmine instance per AgentOS installation (no multi-tenancy)

**Out of scope for v1**: see "What AgentOS Is Not" immediately below.

**Boundary with Redmine core**: AgentOS is a plugin only — no Redmine core patches, no core-table schema changes (CLAUDE.md rule). Everything it creates is a normal Redmine object (`Project`, `Version`, `Issue`, `WikiPage`, `TimeEntry`) reachable and editable through Redmine's native UI, so a team can stop using AgentOS at any point without losing or locking up their data.

## What AgentOS Is Not (Phase 1 scope guard)

- It is not a code-generation/deployment platform in v1 — Backend/Frontend/DevOps "agents" in early phases produce **tickets, specs, and scaffolding tasks**, not committed application code. Actual code generation and autonomous PR creation is an explicit later-phase capability, gated behind its own security and review design.
- It does not replace human approval on the SRS or on irreversible Redmine actions (deleting projects/issues, closing large batches of tickets, force-changing permissions).
- It is not a generic chatbot — every agent output that changes Redmine state goes through a governed MCP tool call, logged and attributable.

## Multi-Agent Collaboration Overview

AgentOS decomposes delivery across 17 specialized agent roles (Project Manager, Requirement Analyst, Business Analyst, Scrum Master, Solution Architect, Database, Backend, API, Frontend, UI/UX, QA, Security, DevOps, Deployment, Code Review *(reserved)*, Documentation, Reporting) rather than one monolithic "AI." Agents are organized into dependency tiers seeded by the Solution Architect Agent (Database → Backend → API → Frontend/UI-UX → QA/Security → DevOps/Deployment), communicate through the Workflow Engine's inter-agent channel, and block/resume automatically as prerequisite tickets close — no human has to notice a dependency cleared and manually unblock the next agent. Full per-agent responsibilities live in [docs/AGENTS.md](docs/AGENTS.md); the runtime mechanics (states, blocking/resuming, tiering) are detailed in [WORKFLOW.md](WORKFLOW.md) §8-9.

## MCP Vision

Every action an agent takes against Redmine — creating a project, closing an issue, logging time — goes through a governed **Model Context Protocol (MCP)** tool call, never a direct model write. This is what makes AgentOS auditable and safe to leave partially autonomous: each tool call is permission-checked against the acting user's real Redmine role, checked against the calling agent's own least-privilege tool allow-list, gated behind a human confirmation step if it's irreversible, and logged before and after execution. The result is that "the AI did something to my project" is never an unanswerable question — see [Readme.md](Readme.md) §8 for the tool catalog overview and [docs/MCP-TOOLS.md](docs/MCP-TOOLS.md) for the full architecture.

## Differentiation

| Alternative | Limitation AgentOS Solves |
|---|---|
| Manually using Redmine | Requires a trained PM to structure projects/releases/tickets/dependencies |
| Generic AI chat (ChatGPT etc.) alongside Redmine | No memory of project state, no ability to act on Redmine, no audit trail |
| Existing Redmine AI plugins (single-shot ticket generators) | No multi-agent collaboration, no dependency awareness, no continuous monitoring, no cost/token governance |

## Success Criteria for v1

- A user can go from a one-paragraph idea to an approved SRS plus a fully structured, dependency-ordered backlog (project → releases → sprints → epics → tickets) without touching Redmine's native UI.
- Every agent action is visible in an Agent Dashboard and reconstructable from audit logs.
- Token/cost usage per project is visible before it becomes a surprise.
- The system degrades gracefully: if the LLM or an MCP call fails, the user sees a clear error and can retry — nothing silently corrupts project state.

## Assumptions & Constraints

**Assumptions**:
- The target install is Redmine 5.x or 6.x with plugin support enabled and a background job runtime available (exact backend — Sidekiq/Resque/Delayed Job vs. plain ActiveJob async — is Open Question #2 in [docs/PHASE1-SPECIFICATION.md](docs/PHASE1-SPECIFICATION.md) §7).
- A deterministic Mock AI Provider is an acceptable v1 deliverable — no real LLM contract, budget, or vendor decision is required to ship v1.
- Users already have Redmine accounts and roles; AgentOS layers its own permission set on top of Redmine's, it does not replace Redmine's authentication/authorization.
- One AgentOS installation serves one Redmine instance; no cross-instance or multi-tenant data sharing is assumed.

**Constraints**:
- No Redmine core modifications — plugin conventions only (`init.rb`, hooks, no core patches).
- Every irreversible or high-blast-radius MCP action requires explicit human confirmation before execution (AD-5) — full autonomy on destructive actions is out of scope permanently, not just for v1.
- No autonomous code-writing or code-committing agent ships until it has its own dedicated security and review design (AD-2) — this is a hard gate, not a scheduling preference.
- The final choice of LLM provider, background job backend, and MCP transport model are still open (5 open questions logged in [docs/PHASE1-SPECIFICATION.md](docs/PHASE1-SPECIFICATION.md) §7) and must be resolved before Phase 10 (plugin skeleton) implementation begins.
- This document should be revisited whenever an open question above is answered, so assumptions never silently go stale relative to actual decisions made.
