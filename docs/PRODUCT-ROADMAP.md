# Product Roadmap (v1 → v2 → v3) — redmineflux_agentos

> **Do not confuse this document with [../ROADMAP.md](../ROADMAP.md).** `ROADMAP.md` is the internal, 16-phase **build process** used to specify and implement this plugin (documentation phases 1-9, implementation phases 10-16). **This document** is the **product capability roadmap** — what an adopting team can actually *do* with AgentOS in each version. A single build-process phase (e.g. Phase 3, Mock AI Provider Foundation) is what makes v1 of the *product* possible; they are related but answer different questions.

---

## v1 — Planning & Governance Foundation (current target)

Everything in [VISION.md](../VISION.md) "Project Scope" is v1. In one line: **AgentOS plans and structures Redmine projects end-to-end, but writes no application code and calls no external AI service.**

| Capability | Notes |
|---|---|
| Conversational requirement intake + bounded clarification loop | Ends in a human-approved SRS (FR-01–FR-03) |
| Automatic project/release/sprint/epic/ticket scaffolding via MCP | FR-04–FR-06 |
| Dependency-aware multi-agent execution | Planning/spec/documentation/ticket-status level only — no code-writing agents (AD-2) |
| Agent, Dependency, Release, Token Usage, Cost dashboards; execution history | [docs/UI-WIREFRAMES.md](UI-WIREFRAMES.md) |
| Exactly one AI provider: the deterministic **Mock AI Provider** | Zero external data egress — see [SECURITY-COMPLIANCE-OVERVIEW.md](SECURITY-COMPLIANCE-OVERVIEW.md) §3 |
| Single Redmine instance, no multi-tenancy | |

---

## v2 — Real Intelligence, Expanded Visibility (candidate scope — not yet gate-approved)

v2 replaces the Mock AI Provider with a real LLM and fills in the dashboard/reporting breadth the Phase 1 wireframes didn't cover, without changing any of v1's governance guarantees.

| Capability | Depends on |
|---|---|
| Real LLM provider integration (OpenAI, Anthropic, Gemini, Ollama, Azure OpenAI, or AWS Bedrock) behind the same Provider Interface | [ROADMAP.md](../ROADMAP.md) Phase 3 spec + Phase 12 implementation; vendor choice is Open Question #1 in [docs/PHASE1-SPECIFICATION.md](PHASE1-SPECIFICATION.md) §7 |
| Real (non-simulated) token/cost tracking | Same Provider Interface swap — WORKFLOW.md §19, §27 |
| Expanded dashboards: Sprint, Risk, Workload, Timesheet, Project | [ROADMAP.md](../ROADMAP.md) Phase 9 expansion (flagged as a gap in that roadmap's status table) |
| External MCP server exposure for outside agent clients (Claude Desktop, IDEs) | Open Question #3 in [docs/PHASE1-SPECIFICATION.md](PHASE1-SPECIFICATION.md) §7 |
| Notification integrations (Slack, Microsoft Teams) | [Readme.md](../Readme.md) §11 Future Roadmap |

**Gate — v1 → v2 promotion requires all of**:
- [ ] LLM provider decision made and budget/contract approved (resolves Open Question #1)
- [ ] Vendor data-processing/DPA review completed for the chosen provider (per [SECURITY-COMPLIANCE-OVERVIEW.md](SECURITY-COMPLIANCE-OVERVIEW.md) §3 — this is a hard requirement, not optional hardening)
- [ ] ROADMAP.md Phase 3 spec fully implemented (Phase 12) and passing its own test plan
- [ ] Background job backend and MCP transport model decided (Open Questions #2, #3)

---

## v3 — Autonomous Code Contribution (explicitly deferred)

v3 is the only version that changes AgentOS's fundamental blast radius: agents gain the ability to write and propose code, not just plan it. Per [VISION.md](../VISION.md) "What AgentOS Is Not" and AD-2 in [docs/PHASE1-SPECIFICATION.md](PHASE1-SPECIFICATION.md), **this is not a scheduling decision — it is a hard gate that does not open until its own dedicated security and review design exists**, independent of and in addition to everything in [SECURITY-COMPLIANCE-OVERVIEW.md](SECURITY-COMPLIANCE-OVERVIEW.md).

| Capability | Notes |
|---|---|
| Code-writing/committing Backend, Frontend, DevOps agents | Currently these agents produce tickets/specs only (v1, v2) |
| Active Code Review Agent | Currently a reserved role — see [AGENTS.md](AGENTS.md) #15 |
| Automated pull request creation | Requires SCM write access — new credential/permission surface |
| Deeper CI/CD automation via `redmineflux_devops` integration | Builds on the DevOps Agent's v1/v2 ticket-generation role |
| Possible multi-tenant / SaaS delivery model | Out of scope for v1/v2's single-instance assumption |

**Gate — v2 → v3 promotion requires all of**:
- [ ] A dedicated code-writing-agent security and review specification exists and has passed all three quality gates (this document's existence is not that specification)
- [ ] Explicit human/developer approval of the expanded blast radius (SCM/CI credential access)
- [ ] `redmineflux_devops` integration points for PR creation and CI triggering are themselves specified and reviewed
- [ ] AgentOS has operated in v2 (real-provider) production use long enough to establish trust in its planning/dependency accuracy — v3 compounds risk on top of v2, it does not replace the need for v2 to be proven first

---

## Why this ordering

Planning and governance (v1) is intentionally the foundation, not a stepping stone to rush past: an AI system that can create/close tickets and touch project structure but cannot write code has a small, well-understood blast radius and is fully auditable via MCP (§[SECURITY-COMPLIANCE-OVERVIEW.md](SECURITY-COMPLIANCE-OVERVIEW.md)). Only once that foundation is trusted in production (v1, then v2 with a real provider) does it make sense to consider the substantially larger blast radius of code-writing agents (v3).
