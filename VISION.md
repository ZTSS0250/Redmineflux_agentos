# VISION.md — redmineflux_agentos

## Product Vision

AgentOS transforms Redmine from a traditional project management system into an AI-powered software development platform. Instead of a user manually creating projects, releases, tickets, documentation, workloads, and timesheets, they describe a software idea in natural language. A team of specialized AI agents collaborates — the way a real software company would — to turn that idea into a running, continuously-managed Redmine project.

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

## What AgentOS Is Not (Phase 1 scope guard)

- It is not a code-generation/deployment platform in v1 — Backend/Frontend/DevOps "agents" in early phases produce **tickets, specs, and scaffolding tasks**, not committed application code. Actual code generation and autonomous PR creation is an explicit later-phase capability, gated behind its own security and review design.
- It does not replace human approval on the SRS or on irreversible Redmine actions (deleting projects/issues, closing large batches of tickets, force-changing permissions).
- It is not a generic chatbot — every agent output that changes Redmine state goes through a governed MCP tool call, logged and attributable.

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
