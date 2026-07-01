# Agent Roster — redmineflux_agentos

17 agent roles. Each is a distinct class under `lib/redmineflux_agentos/agents/`, registered in `redmineflux_agentos_agents` (see [DATABASE-SCHEMA.md](DATABASE-SCHEMA.md)), and driven by the Agent Engine's lifecycle state machine (see [PHASE1-SPECIFICATION.md](PHASE1-SPECIFICATION.md) §6).

**Common contract every agent implements:**

- `input` — a typed payload (conversation turn, ticket, or upstream agent message)
- `output` — a typed payload (SRS fragment, ticket set, status update, wiki page, report) plus zero or more MCP tool calls
- `memory` — reads/writes `redmineflux_agentos_agent_memories` scoped to `(agent, project)`; short-term (current run) and long-term (persists across runs)
- `tools` — an explicit allow-list of MCP tools (least privilege — an agent can only call tools it's been granted)
- `communication` — messages routed through the Workflow Engine's inter-agent channel, always addressed to a specific agent or the Project Manager Agent (no broadcast)
- `workflow` — which ticket statuses/events trigger this agent, and what status/event it produces on completion

---

## 1. Project Manager Agent

| | |
|---|---|
| Responsibility | Owns the overall plan: creates project/release/sprint/epic structure, prioritizes and re-prioritizes work, resolves cross-agent blocking |
| Goals | Keep the dependency graph moving; escalate to human when SLA/risk thresholds are hit |
| Input | Approved SRS; blocking messages from any agent; ticket status change events |
| Output | Project/version/sprint creation calls; re-assignment/re-priority instructions to other agents; risk register updates |
| Memory | Long-term: project plan, risk register, decisions log |
| MCP Tools | `create_project`, `update_project`, `create_version`, `create_issue`, `update_issue`, `assign_issue`, `add_comment`, `create_issue_relation`, `read_project`, `search_issues` |
| Communication | Receives blocking messages from all agents; issues directives to any agent |
| Workflow | Triggered on SRS approval, on any ticket blocking event, and on a periodic health-check tick |

## 2. Requirement Analyst Agent

| | |
|---|---|
| Responsibility | Understands the raw idea, detects missing information, asks clarification questions, produces the SRS |
| Goals | Never let ticket generation start on an ambiguous or incomplete requirement set |
| Input | Free-text idea; user answers to clarification questions |
| Output | Clarification question batches; structured SRS (Markdown + JSON) |
| Memory | Short-term: conversation state; long-term: prior SRS versions for this project |
| MCP Tools | none required to produce the SRS itself; `create_wiki_page` to publish the approved SRS |
| Communication | Talks to the user via Conversation Manager; hands off approved SRS to Project Manager Agent |
| Workflow | Triggered on new conversation start; loops until gap-detection confidence threshold is met or user forces completion |

## 3. Business Analyst Agent

| | |
|---|---|
| Responsibility | Translates SRS business goals into epics/features with business value framing, validates ticket scope against original business intent |
| Goals | Prevent scope drift between SRS and generated tickets |
| Input | Approved SRS |
| Output | Epic/feature list with business justification, acceptance criteria drafts |
| Memory | Long-term: business goals, success metrics |
| MCP Tools | `create_issue` (epics), `read_project`, `search_issues` |
| Communication | Feeds Planning Engine output to Scrum Master Agent and Ticket Generator |
| Workflow | Triggered after SRS approval, before Sprint Planner runs |

## 4. Scrum Master Agent

| | |
|---|---|
| Responsibility | Runs the sprint mechanics: sprint composition, velocity assumptions, standup-style status rollups, blocker surfacing |
| Goals | Keep sprints realistically scoped; surface blockers before they age |
| Input | Epics/stories with estimates; current ticket status |
| Output | Sprint assignments; status rollup reports; blocker escalations to Project Manager Agent |
| Memory | Long-term: historical velocity per project |
| MCP Tools | `update_issue`, `add_comment`, `search_issues`, `read_comments` |
| Communication | Escalates aging blockers to Project Manager Agent |
| Workflow | Triggered on sprint boundary events and on a daily tick |

## 5. Solution Architect Agent

| | |
|---|---|
| Responsibility | Defines technical architecture from the SRS: system boundaries, tech stack rationale, module breakdown, dependency ordering seed (DB → Backend → API → Frontend → UI → Testing → Deployment) |
| Goals | Produce a technical plan other agents can decompose into tickets without re-litigating architecture |
| Input | Approved SRS |
| Output | Architecture document (wiki page); module/dependency seed for Dependency Engine |
| Memory | Long-term: architecture decisions log |
| MCP Tools | `create_wiki_page`, `update_wiki`, `read_project` |
| Communication | Hands off to Database/Backend/API/Frontend/UI-UX agents |
| Workflow | Triggered once per project, after SRS approval, before ticket generation |

## 6. Database Agent

| | |
|---|---|
| Responsibility | Designs schema/entities implied by the SRS; produces DB-layer tickets (first in the dependency chain) |
| Goals | Unblock Backend Agent as early as possible |
| Input | Architecture document; SRS data requirements |
| Output | Schema design doc; DB tickets with acceptance criteria |
| Memory | Long-term: schema decisions |
| MCP Tools | `create_issue`, `update_issue`, `add_comment`, `create_wiki_page` |
| Communication | Notifies Backend Agent (via Project Manager Agent) when schema tickets close |
| Workflow | First executable tier in the Dependency Engine's default chain |

## 7. Backend Agent

| | |
|---|---|
| Responsibility | Produces backend/service-layer tickets (business logic, service objects, background jobs) |
| Goals | Do not start until Database tier tickets are closed |
| Input | Schema design; architecture doc |
| Output | Backend tickets with acceptance criteria and dependencies on DB tickets |
| Memory | Long-term: service boundaries decided |
| MCP Tools | `create_issue`, `update_issue`, `add_comment`, `create_issue_relation` |
| Communication | Blocks on Database Agent; unblocks API Agent |
| Workflow | Second tier; `waiting_on_dep` until DB tickets close |

## 8. API Agent

| | |
|---|---|
| Responsibility | Defines API contracts (REST/GraphQL as applicable) and generates API-layer tickets |
| Goals | Contracts must be stable before Frontend Agent starts |
| Input | Backend service definitions |
| Output | API spec (wiki page), API tickets |
| Memory | Long-term: API contract versions |
| MCP Tools | `create_issue`, `create_wiki_page`, `update_wiki` |
| Communication | Blocks on Backend Agent; unblocks Frontend Agent |
| Workflow | Third tier |

## 9. Frontend Agent

| | |
|---|---|
| Responsibility | Generates frontend implementation tickets against the API contract |
| Goals | Do not start until API contracts are marked stable |
| Input | API spec |
| Output | Frontend tickets |
| Memory | Long-term: component inventory |
| MCP Tools | `create_issue`, `update_issue`, `add_comment` |
| Communication | Blocks on API Agent; coordinates with UI/UX Agent |
| Workflow | Fourth tier |

## 10. UI/UX Agent

| | |
|---|---|
| Responsibility | Defines UX flows, wireframe-level tickets, accessibility/usability acceptance criteria |
| Goals | Ensure Frontend tickets carry concrete UX acceptance criteria, not just "build the page" |
| Input | SRS target users; Frontend ticket list |
| Output | UX tickets/checklists attached to Frontend tickets |
| Memory | Long-term: design system decisions |
| MCP Tools | `update_issue`, `add_comment`, `upload_file` (wireframe attachments) |
| Communication | Works alongside Frontend Agent, same tier |
| Workflow | Runs in parallel with Frontend Agent |

## 11. QA Agent

| | |
|---|---|
| Responsibility | Generates test plans and test tickets per feature; verifies acceptance criteria are testable |
| Goals | Every story has at least one linked QA ticket before it can move to "Ready for Release" |
| Input | Story/task tickets with acceptance criteria |
| Output | Test-case tickets, edge-case checklists |
| Memory | Long-term: test coverage history |
| MCP Tools | `create_issue`, `create_issue_relation`, `add_comment`, `search_issues` |
| Communication | Blocks release sign-off via Project Manager Agent if coverage is missing |
| Workflow | Fifth tier — triggered once upstream implementation tickets exist |

## 12. Security Agent

| | |
|---|---|
| Responsibility | Reviews generated tickets/architecture for the Gate 2 security checklist categories (auth, cross-user data access, injection, mass assignment, CSRF, data leakage) and files findings |
| Goals | Catch security gaps at spec time, not after implementation |
| Input | Architecture doc; ticket set |
| Output | Security findings filed as tickets/comments; entries into `documents/security-rules.md`-style log |
| Memory | Long-term: known findings per project |
| MCP Tools | `create_issue`, `add_comment`, `read_project` |
| Communication | Can block release sign-off via Project Manager Agent on CRITICAL/HIGH findings |
| Workflow | Runs after Solution Architect Agent and again before each release |

## 13. DevOps Agent

| | |
|---|---|
| Responsibility | Generates CI/CD, environment, and infrastructure tickets; integrates with `redmineflux_devops` where installed |
| Goals | Ensure deployment tickets exist before a release is marked ready |
| Input | Architecture doc; release plan |
| Output | Infra/CI tickets |
| Memory | Long-term: environment inventory |
| MCP Tools | `create_issue`, `update_issue`, `read_project` |
| Communication | Coordinates with Deployment Agent |
| Workflow | Sixth tier, parallel with QA Agent |

## 14. Deployment Agent

| | |
|---|---|
| Responsibility | Tracks release readiness and generates deployment-tier tickets/checklists |
| Goals | No deployment ticket marked ready until QA and Security sign-off tickets are closed |
| Input | Release plan; QA/Security ticket status |
| Output | Deployment checklist tickets |
| Memory | Long-term: deployment history |
| MCP Tools | `update_issue`, `add_comment`, `search_issues` |
| Communication | Blocks on QA Agent and Security Agent |
| Workflow | Final tier in the default dependency chain |

## 15. Code Review Agent

| | |
|---|---|
| Responsibility | In phases where code-writing agents exist (post-Phase 1, see AD-2 in the spec), reviews diffs/PRs for the Gate 1 checklist and files review comments |
| Goals | Enforce the same senior-developer checklist a human reviewer would |
| Input | PR/diff metadata (via `redmineflux_devops` integration) |
| Output | Review comments, approve/request-changes signal |
| Memory | Long-term: recurring findings per project |
| MCP Tools | `add_comment`, `read_comments`, `search_issues` |
| Communication | Reports to Project Manager Agent |
| Workflow | Out of scope until code-writing agents ship; reserved role in the roster now |

## 16. Documentation Agent

| | |
|---|---|
| Responsibility | Maintains wiki documentation as tickets close — architecture doc, API docs, user guides |
| Goals | Documentation never drifts more than one release behind implementation |
| Input | Closed tickets; architecture/API docs |
| Output | Wiki pages, created/updated |
| Memory | Long-term: doc structure/table of contents |
| MCP Tools | `create_wiki_page`, `update_wiki`, `search_wiki` |
| Communication | Passive — triggered by ticket close events, not by other agents |
| Workflow | Triggered on ticket status -> closed |

## 17. Reporting Agent

| | |
|---|---|
| Responsibility | Generates on-demand and scheduled status/progress/risk reports |
| Goals | Give the human a truthful, current picture without them having to assemble it manually |
| Input | Dashboard read-models (project, agent, release, dependency, token, cost) |
| Output | Report documents (wiki page, PDF/export, or dashboard summary) |
| Memory | Short-term only — reports are derived, not remembered |
| MCP Tools | `read_project`, `search_issues`, `read_comments`, `generate_report` |
| Communication | Passive — responds to schedule or explicit request |
| Workflow | Triggered by Reporting System schedule or user request |

---

## Agent-to-tier mapping (Dependency Engine default chain)

```
Tier 0 (once, project setup):     Project Manager, Requirement Analyst,
                                   Business Analyst, Solution Architect
Tier 1:                            Database Agent
Tier 2:                            Backend Agent
Tier 3:                            API Agent
Tier 4:                            Frontend Agent + UI/UX Agent (parallel)
Tier 5:                            QA Agent + Security Agent (parallel)
Tier 6:                            DevOps Agent + Deployment Agent (parallel)
Continuous (not tiered):           Scrum Master, Documentation, Reporting Agent,
                                   Code Review Agent (reserved)
```

This is the *default* chain seeded by the Solution Architect Agent; the Dependency Engine ultimately operates on explicit ticket-level dependency edges (see [DATABASE-SCHEMA.md](DATABASE-SCHEMA.md) `redmineflux_agentos_dependencies`), so a project can deviate from this default where the SRS implies a different order.
