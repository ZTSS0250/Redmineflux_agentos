# Security & Compliance Overview — redmineflux_agentos

**Purpose**: state AgentOS's security posture and compliance stance at a product level, for stakeholders and reviewers evaluating the system before any code exists. This is a *product-level* document; it is distinct from — and feeds into — two other, more granular artifacts:

- The **Gate 2 security checklist** in the global `CLAUDE.md`, applied per controller/MCP tool once code exists.
- `documents/security-rules.md`, the running `SEC-{NNN}` findings log populated once implementation begins finding concrete issues.

---

## 1. Security Principles

| Principle | How AgentOS applies it |
|---|---|
| **Least privilege** | Every agent role carries an explicit MCP tool allow-list (`config_json.tool_allowlist`); an agent can only call tools it has been granted, even though the full tool registry exists. E.g. the Documentation Agent has no access to `delete_issue` or `bulk_close_issues`. |
| **Defense in depth** | Three independent layers gate every Redmine state change: (1) Redmine's own `authorize`/role permission checks, (2) AgentOS's own permission set layered on top ([docs/PHASE1-SPECIFICATION.md](PHASE1-SPECIFICATION.md) §5), (3) the MCP confirmation gate for irreversible actions. |
| **Human-in-the-loop for irreversible actions** | `bulk_close_issues`, `delete_issue`, and bulk `update_timesheet` never execute without an explicit human approval via the Pending Approvals queue (AD-5). Full autonomy on destructive actions is never in scope, in any version. |
| **Auditability by construction** | Every MCP tool call is logged before execution and updated after (`redmineflux_agentos_mcp_tool_calls`); every user-visible or irreversible action is additionally written to an immutable `redmineflux_agentos_audit_logs` table with no update/delete path exposed in the app layer. |
| **Explicit user context, never a superuser bypass** | `User.current` is set explicitly on every agent-originated call — including internal, in-process agent execution — so Redmine's own visibility/authorization rules apply identically regardless of whether a human or an agent triggered the action. |
| **Secure-by-default configuration** | No provider API keys, tokens, or credentials appear in views, logs, or JSON responses; secrets are encrypted at rest and redacted from `mcp_tool_calls.params_json` before persistence. |
| **Minimized blast radius by scope, not just by permission** | No autonomous code-writing or code-committing agent exists in v1 or v2 (AD-2) — this removes an entire class of risk (unauthorized SCM/CI access) rather than relying solely on permission checks to contain it. |

---

## 2. Data Handled by AgentOS

| Data | Where it lives | Sensitivity notes |
|---|---|---|
| User-submitted idea text, clarification answers, SRS content | `redmineflux_agentos_conversations` / `_messages` / `_project_plans` | May incidentally contain business-sensitive information (the idea itself); AgentOS does not ask for or expect PII/payment data as part of *its own* function |
| Generated ticket content (titles, descriptions, acceptance criteria) | `redmineflux_agentos_ai_tasks`, Redmine `issues` | Same sensitivity class as any Redmine ticket content today |
| Token/cost telemetry | `redmineflux_agentos_token_usages`, `_cost_trackings` | Operational metadata, not user content |
| Prompt templates | `redmineflux_agentos_prompt_templates` | System configuration, not user data |
| Provider credentials (from v2 onward) | Encrypted configuration store | Highest sensitivity — never logged, never rendered |

**Important distinction**: if the *product being planned* (e.g. an Employee Management System) will itself handle PII, payroll, or other regulated data, that is the generated project's own security concern to design for (the Security Agent flags this at spec time — see [AGENTS.md](AGENTS.md) #12) — it is not data AgentOS itself stores or processes beyond describing it in ticket text.

---

## 3. Compliance Stance

### v1 (Mock AI Provider) — zero external data egress

This is a load-bearing, verifiable claim, not marketing language: per [ROADMAP.md](../ROADMAP.md) Phase 3, "the first version must not integrate with any real LLM provider." Because the Mock AI Provider is fixture-based and runs entirely in-process, **no request or response in v1 ever leaves the host Redmine installation.** AgentOS in v1 therefore inherits whatever data-residency and compliance posture the host Redmine deployment already has — it introduces no new third-party data flow. This invariant must hold through Phase 12 (Mock AI Provider Implementation); any implementation that makes an outbound network call from the Mock Provider is a defect against this document, not a feature.

### v2 (real LLM provider) — new data flow, new review required

Once a real provider (OpenAI, Anthropic, Gemini, Ollama, Azure OpenAI, or AWS Bedrock — see [PRODUCT-ROADMAP.md](PRODUCT-ROADMAP.md)) is wired in behind the Provider Interface, prompts containing SRS/ticket content will be transmitted to that vendor. This is a new data flow that did not exist in v1 and **requires its own data-processing/vendor review (and, where applicable, a DPA) before it ships** — it is not automatically covered by this document's v1 compliance claim. This requirement is carried forward as an explicit v1→v2 promotion gate in [PRODUCT-ROADMAP.md](PRODUCT-ROADMAP.md).

### No independent certification claims

This document does not claim SOC 2, ISO 27001, HIPAA, or any other independent certification on AgentOS's own behalf. AgentOS's compliance posture is "inherits and does not weaken the host Redmine installation's existing posture" — a narrower, verifiable claim rather than an aspirational one.

---

## 4. Threat Model Summary

| Threat | Mitigation | Owning control |
|---|---|---|
| Agent bypasses Redmine authorization via direct model access | All Redmine state changes routed through the MCP Integration Layer with explicit `User.current` scoping (AD-3) | MCP Tool Registry |
| Agent executes an irreversible action autonomously | `requires_confirmation` flag + Pending Approvals queue (AD-5) | MCP confirmation gate |
| Secrets leak via logs or tool-call params | Redaction before persistence, encryption at rest | `mcp_tool_calls` write path |
| Cross-project data leakage on dashboard queries | Explicit `where(project_id: ...)` scoping required on every project-scoped table, enforced per Gate 2 on each future task | Dashboard read-models |
| Prompt-injection via user-submitted idea text | Provider Interface treats all conversation input as untrusted data, never as instructions to agents outside their declared tool allow-list; the tool allow-list is the actual security boundary, not prompt-level trust | Agent tool allow-lists |
| Malformed SRS creates a circular ticket dependency, deadlocking execution | Application-level cycle check at insert time on `redmineflux_agentos_dependencies` | Dependency Engine |
| A future real-provider integration (v2) ships without vendor/data review | Explicit gate in [PRODUCT-ROADMAP.md](PRODUCT-ROADMAP.md) blocking v1→v2 promotion until reviewed | Product Roadmap gate table |
| Code-writing agent capability expands blast radius to SCM/CI | Explicitly deferred (AD-2) until its own dedicated security spec exists — see v2→v3 gate in [PRODUCT-ROADMAP.md](PRODUCT-ROADMAP.md) | Product Roadmap gate table |

---

## 5. Relationship to Other Security Artifacts

- **Security Agent** ([AGENTS.md](AGENTS.md) #12) is the runtime enforcer of the Gate 2 checklist categories against generated architecture/tickets, at spec time, per project.
- **`documents/security-rules.md`** (created once the first concrete `SEC-001` finding exists) is the append-only institutional record of specific vulnerabilities found and fixed during implementation — this document is the "why we care", that file is the "what we found."
- **Gate 2 review** (global `CLAUDE.md`) is the per-task, code-level enforcement mechanism (authorize present, strong params, no raw SQL, etc.) applied starting at Phase 10 (plugin skeleton) once controllers/models exist.
