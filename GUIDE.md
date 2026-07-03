# AgentOS v1 — Demonstration & Validation Guide

**Audience**: whoever is running the demo (and whoever they're demoing to).
**Scope**: this document describes what the plugin **actually does today**, verified by reading the current code on 2026-07-03 — not what any specification document says it will eventually do. Where those two things differ, this guide says so explicitly, in **bold callouts** you should not skip.

**The single most important thing to know before you demo this**: AgentOS's agent-execution pipeline (the part that makes an agent actually respond via the Mock Provider) has **no UI trigger anywhere in this codebase**. Nothing a user clicks creates a `redmineflux_agentos_agent_run` row or enqueues the job that processes one — not the Chat screen, not the SRS approval screen, not the "+ New AI Project" wizard. Every one of those UI actions correctly saves its own data, but none of them hands off to the Agent Engine. The only way to see an agent actually run today is a Rails console command (Section 7 gives you the exact one). This isn't a bug you introduced or missed — it's a real, load-bearing architectural gap (`ConversationManager::Session`, Phase 2 §A.8) that no ticket from Phase 10 through Phase 16 was ever assigned to build. Plan your demo narrative around this fact, not around clicking "Send" and hoping something happens.

---

## 1. Overview

### What AgentOS is

RedmineFlux AgentOS is a Redmine plugin that runs a team of specialized AI agents — Project Manager, Requirement Analyst, Solution Architect, Database/Backend/API/Frontend/UI-UX, QA, Documentation, Security, DevOps, Deployment, Code Review, Reporting, Scrum Master, Business Analyst (17 roles total) — which are meant to interview a user about a product idea, produce an SRS, plan releases/sprints, generate dependency-ordered tickets, and execute/monitor work against Redmine's own domain model (projects, issues, wiki, time entries) through a governed tool layer.

### Purpose

Turn a natural-language product idea into a fully planned, ticketed, continuously-executed Redmine project, with every agent action going through an auditable, permission-checked tool layer rather than being a black box.

### Architecture overview

```
UI (Chat / Dashboards / Admin)
        │
        ▼
Agent Engine (Registry, Lifecycle, Runner, ConcurrencyGuard)
        │
        ▼
Provider Interface  ──►  Mock Provider (v1)  /  [real LLM — v2, not built]
        │
        ▼
MCP Layer (ToolRegistry, Executor)  ──►  Redmine core models (Issue, Project, Wiki, TimeEntry, Attachment)
        │
        ▼
Event Bus (ActiveSupport::Notifications)  ──►  Dependency Engine, Notification Center
```

Full design detail: `docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md` (architecture), `docs/PHASE7-MCP-ARCHITECTURE.md` (tool layer), `docs/AGENTS.md` (all 17 roles).

### Major components (and where they live)

| Component | Path | What it does |
|---|---|---|
| 17 Agent classes | `lib/redmineflux_agentos/agents/*.rb` | One class per role; `#call(memory:)` resolves a prompt and calls the active Provider |
| Agent Engine | `lib/redmineflux_agentos/engine/agent_engine/{registry,lifecycle,runner}.rb` | Registry (role→class map + enabled/disabled cache), Lifecycle (7-state machine), Runner (executes one run end to end) |
| Provider Interface + Mock Provider | `lib/redmineflux_agentos/providers/**` | Deterministic, fixture-driven fake LLM — see Section 4 |
| MCP layer | `lib/redmineflux_agentos/mcp/{tool_registry,executor}.rb`, `lib/redmineflux_agentos/mcp/tools/*.rb` | 22 tools across 6 files; the plugin's only write path to real Redmine data |
| Event Bus | `lib/redmineflux_agentos/engine/event_bus.rb` | Thin wrapper over `ActiveSupport::Notifications`, namespaced `agentos.*` |
| Dependency Engine | `lib/redmineflux_agentos/engine/dependency_engine/{graph,scheduler}.rb` | DAG of ticket dependencies + auto-resume on blocking-issue close |
| Notification Center | `lib/redmineflux_agentos/notification_center.rb` | Routes 4 of 6 documented event types to email |
| UI (9 controllers, 13 pages) | `app/controllers/redmineflux_agentos/**`, `app/views/redmineflux_agentos/**` | Dashboards, Chat, Admin screens |
| Health/metrics | `app/controllers/redmineflux_agentos/health_controller.rb` | Unauthenticated `/agentos/health.json`, `/agentos/metrics.json` |

### Version

`0.0.1` (`init.rb`). This is v1 per `docs/PRODUCT-ROADMAP.md`'s v1→v2→v3 plan — Mock Provider only, no real LLM.

### Current limitations (headline list — full list in Section 12)

1. **No UI path creates an `agent_run` or triggers the Agent Engine.** Console-only today.
2. Mock Provider only — zero real LLM integration.
3. `Admin::AgentsController`/`Admin::McpToolsController` render a "coming soon" placeholder — no persistence.
4. Two `test/unit/mcp/*.rb` files reference test-double classes (`FakeMcpToolCall`, `FakeUser`, `FakeAgent`, `FakeAuditLog`) that don't exist anywhere in this repo — they will fail with `NameError` if run as-is.
5. Never run against a live Redmine instance until you do it as part of this guide.

---

## 2. Prerequisites

| Requirement | Value | Why |
|---|---|---|
| Docker | Any recent version with Compose v2 (`docker compose`, not the old standalone `docker-compose`) | Runs Redmine + Postgres without installing Ruby/Rails on your host at all |
| Docker Compose | v2 syntax (`redmineflux_devops/docker/docker-compose.redmine5.yml` uses `name:` at top level, a v2-only key) | — |
| Redmine version | 5.1.x (this guide) — plugin also declares 6.x support (`requires_redmine version_or_higher: '5.0.0'`, `init.rb:21`); a `docker-compose.redmine6.yml` variant of the same stack also mounts this plugin now, if you need that path | `docker-compose.redmine5.yml` pins `redmine:5.1` |
| Ruby | Whatever the `redmine:5.1` image bundles (Ruby 3.1–3.2 depending on the exact tag) — **you do not need Ruby installed on your host** unless you want to run something outside Docker | The official image is self-contained |
| Rails | 6.1 (bundled with Redmine 5.1; confirmed by every migration's `ActiveRecord::Migration[6.1]` header, e.g. `db/migrate/20260703100014_create_redmineflux_agentos_mcp_tool_calls.rb:3`) | — |
| Database | PostgreSQL 16 (matches the existing `redmineflux_devops` compose stack this plugin now rides along on) — the plugin itself is DB-portable (no DB-specific SQL anywhere; migrations avoid MySQL's partial-unique-index limitation on purpose) | `docker-compose.redmine5.yml` |
| Plugin installation path | Mounted at `/usr/src/redmine/plugins/redmineflux_agentos` inside the container (a bind mount of this repo, not a copy) | Standard Redmine plugin convention |
| Gemfile | **None** — this plugin adds zero new gem dependencies beyond a stock Redmine install | Confirmed: no `Gemfile`/`Gemfile.local` anywhere in this repo |
| Sibling checkout | `redmineflux_devops` must be checked out as a **sibling directory** of this plugin (i.e. both directly under the same `Redmine/` parent folder) | The compose file's volume mounts are relative paths (`../../Redmineflux_agentos`) — this only resolves correctly with that layout |

---

## 3. Local Docker Setup

### Does a Docker setup already exist for this plugin?

**Yes — reused, not duplicated.** This repo has no `docker-compose.yml` of its own, and doesn't need one: the only real Docker-based Redmine development environment anywhere in this workspace is the sibling `redmineflux_devops` plugin's stack (`redmineflux_devops/docker/docker-compose.redmine5.yml` and `redmine6.yml`). `redmineflux_agentos` is now mounted directly into both files (one added `volumes:` line per service, matching the exact pattern every other Redmineflux plugin already there uses), and both files' one-shot migrate containers now also run AgentOS's two required seed rake tasks plus the system-user provisioner after `redmine:plugins:migrate`. Running a second, separate Postgres+Redmine stack just for this plugin would mean more resource usage, a second port range to remember, and a less representative environment (every real deployment of this plugin runs alongside whatever else is installed) — the shared stack is both simpler and closer to reality.

**Caveat**: these compose file edits have not been executed end-to-end in the environment this guide was written in (no Docker runtime available there). Treat first boot as the actual first test of the added mount + seed steps, and read the container logs if something doesn't come up.

### Does it need any additional containers?

| Dependency | Required? | Why |
|---|---|---|
| **Redis** | No | `Rails.cache` (used by Phase 16's caching — Section 5) works with whatever cache store Redmine is configured with; the default in-process `MemoryStore` is sufficient for a single-container demo. AgentOS's code never assumes Redis specifically. |
| **Sidekiq** | No | Every background job (`AgentRunJob`, `MemorySweepJob`, `CostRollupJob`, `LogRetentionJob`) is a plain `ApplicationJob`/`ActiveJob::Base`, adapter-agnostic by design (`docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md` §B.1). The default Redmine container runs the `:async` in-process adapter — fine for a demo, not for production throughput. |
| **Prometheus** | No | `/agentos/metrics.json` is a plain JSON endpoint (`app/controllers/redmineflux_agentos/health_controller.rb`), not a Prometheus exposition-format endpoint. No exporter exists. |
| **Ollama / OpenAI / any real LLM** | No | The only registered provider is `:mock` (`config/initializers/redmineflux_agentos.rb`); the Mock Provider makes **zero outbound network calls** — this is a directly tested invariant (`test/unit/providers/mock_provider_test.rb`'s `test_zero_network_calls`, which mocks `TCPSocket.open`/`Net::HTTP#start` and asserts they're never called), not just an absence of code. Pointing `active_provider` at anything but `mock` raises `Configuration::InvalidProviderError` immediately — there's nowhere else for it to go. |

### Environment variables required

None beyond what any Redmine container needs (`REDMINE_DB_*`, `SECRET_KEY_BASE`) — already set in `docker-compose.redmine5.yml`. AgentOS has no plugin-specific environment variable anywhere in its code (all its configuration is DB-backed, via `Admin → AgentOS → Settings`, not env vars).

### Bring the stack up

```bash
cd redmineflux_devops/docker
docker compose -f docker-compose.redmine5.yml up -d
docker compose -f docker-compose.redmine5.yml logs -f redmine5-migrate   # watch the one-shot migrate container; it exits 0 when done
```

First boot installs build tools + gems inside the containers (not baked into the image), so it takes a few minutes. `redmine5-migrate` runs, in order, as **separate** rake invocations (this matters — see the comment in the compose file):

```bash
rake db:migrate RAILS_ENV=production
rake redmine:load_default_data REDMINE_LANG=en RAILS_ENV=production
rake redmine:plugins:migrate RAILS_ENV=production
rake redmineflux_agentos:seed_agents RAILS_ENV=production
rake redmineflux_agentos:seed_prompt_templates RAILS_ENV=production
rake redmineflux_agentos:provision_system_user RAILS_ENV=production
```

The last three (added to the compose file's entrypoint alongside this plugin's own volume mount) are **not optional** — skip them and:
- `seed_agents` missing → every `RedminefluxAgentosAgent` row is absent, so `Mcp::ToolRegistry.tools_for(agent)` (Layer 2 permission check) has nothing to allow, and no agent-initiated tool call could ever pass
- `seed_prompt_templates` missing → `Prompts::TemplateResolver.resolve` raises `PromptVariableMissingError` for every category, since no active template exists
- `provision_system_user` missing → the AgentOS System user (the `User.current` identity for autonomous agent actions, `lib/redmineflux_agentos/system_user_provisioner.rb`) doesn't exist yet; it auto-creates lazily on first use, but running it explicitly up front means Section 6/8's console demos don't have to wait on it

Once `redmine5-migrate` exits successfully, `redmine5` starts serving on **http://localhost:3080** (the devops stack's existing port — unchanged, since AgentOS didn't need a new one).

### Enable the plugin on a project

Docker/migration alone does **not** turn AgentOS on for any project — enable it explicitly:
1. Log in as `admin` (default Redmine seed password: `admin` — you'll be forced to change it on first login)
2. Create or open a project → **Settings → Modules** → check **AgentOS** → Save
3. **Settings → Members** → add whichever user you'll demo as, with a role that has the AgentOS permissions you want to show (Section 9)

---

## 4. Mock AI Provider

### What it is

`RedminefluxAgentos::Providers::Mock::MockProvider` — a deterministic, YAML-fixture-driven stand-in for a real LLM. Same `ProviderInterface` contract a real provider would implement, so swapping providers later changes only the Provider implementation, nothing else in the codebase (`WORKFLOW.md` §27).

### Why it exists

v1 has no real LLM integration by design (`docs/PRODUCT-ROADMAP.md`'s v1→v2 gate requires a vendor/DPA review before any real provider ships). The Mock Provider lets every other layer — Agent Engine, MCP, dependency tracking, UI — be built and demonstrated against realistic, structured responses without waiting on that review or incurring any real API cost/network dependency.

### How it works internally

```
MockProvider#request(agent_key:, prompt_category:, scenario_key:, variables:, idempotency_key:)
        │
        ▼
FixtureSelector.resolve — builds "{agent_key}/{prompt_category}/{scenario_key}[_round_N].yml",
                           loads it, or falls back to _fallback/unhandled_scenario.yml
        │
        ▼
FixtureLoader.load — YAML.safe_load from config/agentos/fixtures/mock_provider/**
        │
        ▼
FixtureRenderer.render — {{variable}} interpolation, walked recursively through
                          content / tool_calls / memory_updates
        │
        ▼
MockProvider#build_response — assembles the Standard Response hash, suffixes each
                               tool_call's idempotency_key as "{base}-{index}"
```

Zero I/O beyond local `File.read`/`Dir.exist?` on the plugin's own fixture directory — confirmed by grepping the whole `lib/redmineflux_agentos/providers/` tree for `Net::HTTP`/`HTTParty`/`Faraday`/`open-uri`/`RestClient`/`TCPSocket`: no matches.

### How to enable it

Nothing to do — `active_provider` defaults to `'mock'` (`Configuration::Store::DEFAULTS`, `lib/redmineflux_agentos/configuration/store.rb`) and `:mock` is the only provider ever registered (`config/initializers/redmineflux_agentos.rb`).

### How to verify it is active

- **UI**: Administration → AgentOS → Settings → `active_provider` row shows `mock`
- **HTTP**: `GET http://localhost:3080/agentos/health.json` → `checks.provider_registry_populated: true`
- **Console**: `RedminefluxAgentos::Providers::Registry.active.class` → `RedminefluxAgentos::Providers::Mock::MockProvider`

### Which files implement it

`lib/redmineflux_agentos/providers/provider_interface.rb`, `registry.rb`, `mock/mock_provider.rb`, `mock/fixture_selector.rb`, `mock/fixture_loader.rb`, `mock/fixture_renderer.rb`, `mock/ticket_generation_rule.rb`.

### Fixture directory (as it actually exists on disk)

```
config/agentos/fixtures/mock_provider/
├── _fallback/unhandled_scenario.yml
├── project_manager/{project_planning,release_planning,ticket_generation}/*.yml
├── requirement_analyst/{clarification_questions,requirement_analysis}/*.yml
├── scrum_master/sprint_planning/sprint_planning.yml
├── security/risk_analysis/risk_analysis.yml
├── solution_architect/dependency_analysis/dependency_analysis.yml
└── reporting/reporting/reporting.yml
```

### How to test it manually — Rails console

```bash
cd redmineflux_devops/docker
docker compose -f docker-compose.redmine5.yml exec redmine5 rails console -e production
```

```ruby
provider = RedminefluxAgentos::Providers::Registry.active

response = provider.request(
  agent_key: 'project_manager',
  prompt_category: 'project_planning',
  scenario_key: 'create_project',
  variables: { 'project_name' => 'EMS', 'module_list' => 'Leave, Attendance' },
  idempotency_key: 'demo-turn-1'
)

pp response
```

### Example 1 — a response with `tool_calls` (real fixture, `project_manager/project_planning/create_project.yml`)

Fixture YAML (verbatim, on disk today):
```yaml
content: "Created project '{{project_name}}' with modules: {{module_list}}."
tool_calls:
  - tool_name: redmineflux_agentos_create_project
    params:
      name: "{{project_name}}"
      modules: "{{module_list}}"
usage:
  prompt_tokens: 420
  completion_tokens: 180
latency_ms: 250
finish_reason: content_and_tool_calls
memory_updates:
  - scope: long_term
    key: project_plan
    value: "{{project_name}} created with modules {{module_list}}"
```

With the console call above, expect back (shapes match; the `raw:` key echoes the fully-rendered fixture):
```ruby
{
  content: "Created project 'EMS' with modules: Leave, Attendance.",
  tool_calls: [
    { tool_name: "redmineflux_agentos_create_project",
      params: { "name" => "EMS", "modules" => "Leave, Attendance" },
      idempotency_key: "demo-turn-1-0" }
  ],
  memory_updates: [{ "scope" => "long_term", "key" => "project_plan", "value" => "EMS created with modules Leave, Attendance" }],
  usage: { prompt_tokens: 420, completion_tokens: 180, total_tokens: 600 },
  latency_ms: 250,
  finish_reason: :content_and_tool_calls,
  provider: "mock",
  model: "n/a",
  raw: { ... }
}
```

### Example 2 — plain-text response, no tool_calls (`requirement_analyst/clarification_questions/clarification_questions_round_1.yml`)

```ruby
provider.request(
  agent_key: 'requirement_analyst',
  prompt_category: 'clarification_questions',
  scenario_key: 'clarification_questions',
  variables: { 'idea_text' => 'An HR platform', 'round_number' => 1, 'gaps_detected' => 'notification channel, currency' },
  idempotency_key: 'demo-turn-2'
)
```

Note `round_number` in `variables` — that's what makes `FixtureSelector` pick the `_round_1` file, not a top-level request field. Response has `tool_calls: nil`, `memory_updates: nil`, and `content` is the rendered multi-line clarification-questions text.

### Example 3 — unknown scenario, degrades gracefully (never raises)

```ruby
provider.request(agent_key: 'qa', prompt_category: 'nonexistent_category', scenario_key: 'nonexistent', variables: {}, idempotency_key: 'demo-turn-3')
# => content: "This scenario is not yet covered by the Mock Provider's fixture set." (the fallback fixture)
```

### Example 4 — multi-tool-call idempotency suffixing

```ruby
provider.request(
  agent_key: 'project_manager', prompt_category: 'release_planning', scenario_key: 'release_planning',
  variables: { 'release_count' => 2, 'constraints' => 'HR before Payroll' }, idempotency_key: 'demo-turn-4'
)[:tool_calls].map { |c| c[:idempotency_key] }
# => ["demo-turn-4-0", "demo-turn-4-1"]  — two create_version calls, zero-based suffix per array position
```

---

## 5. Feature Demonstration Guide

Every row below states plainly whether the feature is **UI-reachable today** or **console-only**. Don't promise a manager a UI click will do something it won't.

### 5.1 AI Chat (message persistence — real; agent response — NOT real)

| | |
|---|---|
| Purpose | Start/continue a conversation about a project idea |
| UI location | Project → AgentOS → AI Chat (`agentos_chat_path`) |
| Required permission | `create_ai_project` |
| Steps | Open AI Chat, type text, click Send |
| Expected result | **Your message appears saved (page shows it after reload); no agent reply ever appears** — `chat.js`'s own code comment: *"there is no agent turn to render yet... this handler only clears the composer on a successful submit"* |
| Backend flow | `ChatController#create` finds-or-creates a `RedminefluxAgentosConversation`, creates a `RedminefluxAgentosMessage` (`role: 'user'`), returns `204 No Content` |
| DB changes | 1 row in `redmineflux_agentos_conversations` (first message only), 1 row in `redmineflux_agentos_messages` per message |
| Events fired | None |
| Logs to verify | None specific — check the DB rows directly (`RedminefluxAgentosMessage.last`) |

### 5.2 SRS Review / Approval (persistence — real; triggering planning — NOT real)

| | |
|---|---|
| Purpose | Approve or reject a generated SRS (Software Requirements Spec) |
| UI location | Project → AgentOS → Requirement Review |
| Required permission | `create_ai_project` |
| Steps | Open the page (needs an existing `RedminefluxAgentosProjectPlan` row — none is created by any UI action, see caveat below), click Approve/Reject |
| Expected result | Plan's `status` flips to `approved`/`draft` and persists; **no Project Manager Agent planning turn ever fires** |
| **Caveat** | There's no UI path that creates the first `ProjectPlan` row either — you must create one via console first: `RedminefluxAgentosProjectPlan.create!(project_id: @project.id, conversation_id: RedminefluxAgentosConversation.last.id, status: 'pending_approval', version: 1)` |
| Backend flow | `RequirementReviewsController#update` finds the latest plan, sets `status`/`approved_by_id`/`approved_at` |
| DB changes | 1 row updated in `redmineflux_agentos_project_plans` |
| Events fired | None |
| Logs to verify | None |

### 5.3 Agent Dashboard + Pending Approvals (real UI, real MCP integration)

| | |
|---|---|
| Purpose | See agent run status; approve/reject destructive MCP tool calls |
| UI location | Project → AgentOS → Agent Dashboard |
| Required permission | `view_agentos_dashboard` (view), `run_ai_tasks` (approve/reject) |
| Steps | See Section 6's confirmation-flow demo to create a `pending_confirmation` row via console first, then visit this page and click Approve/Reject |
| Expected result | This is the one place a button click drives **real** business logic: `approve`/`reject` call straight into `Mcp::Executor.confirm`/`.reject` |
| Backend flow | `AgentDashboardsController#approve` → `Mcp::Executor.confirm(id, confirmed_by: User.current)` → runs the tool's real handler → writes result |
| DB changes | `redmineflux_agentos_mcp_tool_calls.status` → `executed`/`rejected`; the tool's own model changes (e.g. an `Issue` actually gets deleted, for `delete_issue`) |
| Events fired | None on approve/reject itself (the `mcp_tool_call.pending_confirmation` event already fired when the call was first queued) |
| Logs to verify | `RedminefluxAgentosAuditLog.last` (for non-read-only tools) |

### 5.4 Dependency Dashboard (real, but needs console-seeded data)

| | |
|---|---|
| Purpose | View the DAG of ticket dependencies |
| UI location | Project → AgentOS → Dependency Dashboard |
| Required permission | `view_agentos_dashboard` |
| Steps | Need at least one edge first — console: `a = RedminefluxAgentosAiTask.create!(project_id: @project.id, agent_id: RedminefluxAgentosAgent.first.id, task_type: 'story', title: 'A'); b = RedminefluxAgentosAiTask.create!(project_id: @project.id, agent_id: RedminefluxAgentosAgent.first.id, task_type: 'story', title: 'B'); RedminefluxAgentos::Engine::DependencyEngine::Graph.add_edge(a, depends_on: b)` |
| Expected result | Table showing task A depends on task B |
| Backend flow | `DependencyDashboardsController#show` reads through `Graph.edges_for_project` (Rails.cache-backed, Phase 16) |
| DB changes | 2 rows in `redmineflux_agentos_ai_tasks`, 1 row in `redmineflux_agentos_dependencies` |
| Events fired | None |
| Cache to verify | `Rails.cache.exist?("redmineflux_agentos/dependency_graph/#{project.id}")` → `true` after first page load |

### 5.5 Release Planner (real UI, read-only over console-seeded data)

| | |
|---|---|
| Purpose | View releases/sprints under a project plan |
| UI location | Project → AgentOS → Release Planner |
| Required permission | `run_ai_tasks` |
| Steps | Needs a `RedminefluxAgentosRelease`/`RedminefluxAgentosSprint` row — none created by any UI path; seed via console |
| Expected result | Read-only list |
| Backend flow | `ReleasesController#index` joins `releases` → `project_plans` for the current project |
| DB changes | None (read-only) |

### 5.6 Token Usage / Cost Dashboard (real UI, populated by `CostRollupJob`)

| | |
|---|---|
| Purpose | Show simulated token/cost totals |
| UI location | Project → AgentOS → Token Usage; → Cost Dashboard |
| Required permission | `view_token_usage`; `view_cost_dashboard` |
| Steps | Run an agent (Section 7's console demo) to generate a `RedminefluxAgentosTokenUsage` row, then `docker compose -f docker-compose.redmine5.yml exec redmine5 rails runner "RedminefluxAgentos::CostRollupJob.new.perform(Date.current)"` |
| Expected result | Non-zero totals |
| Backend flow | `CostRollupJob` aggregates `token_usages` into `cost_trackings` by `(project_id, period)` |
| DB changes | 1 row in `redmineflux_agentos_cost_trackings` |

### 5.7 Execution History (real UI, log of console-driven runs)

| | |
|---|---|
| Purpose | Chronological agent/MCP event feed |
| UI location | Project → AgentOS → Execution History |
| Required permission | `view_agent_logs` |
| Backend flow | Reads `redmineflux_agentos_execution_logs` directly — **note**: nothing in the current codebase actually writes rows to this table (no `RedminefluxAgentosExecutionLog.create!` call exists anywhere outside tests) — this page will show empty even after running agents via console, unless you write log rows yourself |

### 5.8 Admin → Settings (real, fully wired)

| | |
|---|---|
| Purpose | View/edit every `Configuration::Store` key, global or per-project |
| UI location | Administration → AgentOS → Settings |
| Required permission | `manage_ai_configuration` (admin-only) |
| Steps | Change `notify_on_agent_started` to `true`, Save |
| Expected result | Value persists (`RedminefluxAgentosConfiguration` row written); sensitive-looking keys show `•••• configured` (`CredentialMasking`) — none of the current default keys are actually sensitive, so you won't see this triggered with stock data |
| DB changes | 1 row in `redmineflux_agentos_configurations` |

### 5.9 Admin → Prompt Library (real, only genuinely non-trivial admin screen)

| | |
|---|---|
| Purpose | View/version/activate prompt templates |
| UI location | Administration → AgentOS → Prompt Library |
| Required permission | `manage_prompt_templates` (admin-only) |
| Steps | Open a template seeded by `seed_prompt_templates`, edit content, Save (creates v2), then Activate a specific version |
| Expected result | Activating deactivates the previous version in the same transaction |
| Backend flow | `Admin::PromptTemplatesController#activate!`/`#create_new_draft!`, then calls `TemplateResolver.invalidate!(key)` (Phase 16 cache) |
| Cache to verify | Resolve the same key twice via console before/after activation — second resolve reflects the new content immediately |

### 5.10 Admin → Agents / Admin → MCP Tools (NOT implemented — "coming soon")

| | |
|---|---|
| UI location | Administration → AgentOS → Agents; → MCP Tools |
| What you'll actually see | A literal "This screen is specified but not yet implemented" message (`_coming_soon.html.erb`, rendered by both `index` actions) |
| Backend flow | `update` on both controllers is `head :no_content` — nothing is persisted regardless of what you submit |
| **Do not demo this as working** | Both are Phase 10 skeleton stubs; say so if asked |

### 5.11 Admin → Audit Logs (real, but empty on a fresh install)

| | |
|---|---|
| UI location | Administration → AgentOS → Audit Logs |
| Required permission | `manage_agentos` (admin-only) |
| Steps | Run a non-read-only MCP tool via console (Section 6) first — that's the only thing that writes rows here |
| **Recently-fixed bug worth mentioning in the demo**: this page was completely unreachable (404-equivalent for every user including admins) until Phase 16 — `init.rb` never declared a permission for it at all | |

### 5.12 Health & Metrics (real, unauthenticated, ops-facing — not a "feature page")

```bash
curl http://localhost:3080/agentos/health.json
curl http://localhost:3080/agentos/metrics.json
```
No login needed by design (`app/controllers/redmineflux_agentos/health_controller.rb`'s own class comment explains why). Good opener for a demo — proves the plugin booted correctly before you touch any UI.

---

## 6. MCP Demonstration

### Tool Registry — `lib/redmineflux_agentos/mcp/tool_registry.rb`

Boot-time lookup table. 22 tools registered across 6 files' `register!` methods, called from `config/initializers/redmineflux_agentos.rb`. `ToolRegistry.register` raises `ArgumentError` at boot if any tool's `params_schema` is blank (a real safety rail, not just documentation).

```ruby
RedminefluxAgentos::Mcp::ToolRegistry.lookup(:redmineflux_agentos_create_issue)
# => { category: "ticket_generation", handler: #<Proc>, params_schema: {...}, authorize: #<Proc>, requires_confirmation: false, read_only: false }
```

### Executor — `lib/redmineflux_agentos/mcp/executor.rb`

The single write path to Redmine for every AgentOS action. `Executor.call(tool_name:, params:, actor:, idempotency_key:, agent: nil, agent_run: nil)`.

### Tool execution — demo via console (no UI creates this path)

```ruby
project = Project.find(1)   # or your demo project
actor = User.current = User.find(1)  # admin, or any user with the right Redmine permission

result = RedminefluxAgentos::Mcp::Executor.call(
  tool_name: :redmineflux_agentos_create_issue,
  params: { project_id: project.id, tracker: 'Bug', subject: 'Created by AgentOS demo' },
  actor: actor,
  idempotency_key: 'demo-issue-1'
)
pp result
# => { status: :executed, result: { id: <new_id>, subject: "Created by AgentOS demo" }, error: nil }
Issue.find(result[:result]['id'])   # confirm it's real
```

### Permission checking — both layers

**Layer 1** (Redmine authorization) — each tool's own `authorize:` proc, e.g. `create_issue`'s checks `actor.allowed_to?(:add_issues, project)`:
```ruby
non_privileged = User.find_by(admin: false)  # a user with NO :add_issues permission on the project
RedminefluxAgentos::Mcp::Executor.call(tool_name: :redmineflux_agentos_create_issue, params: { project_id: project.id, tracker: 'Bug', subject: 'Should fail' }, actor: non_privileged, idempotency_key: 'demo-fail-1')
# => raises RedminefluxAgentos::McpToolError::PermissionDeniedError
```

**Layer 2** (agent tool_allowlist) — only relevant when `agent:` is passed:
```ruby
qa_agent = RedminefluxAgentosAgent.find_by(key: 'qa')  # seeded allowlist has no delete_issue
RedminefluxAgentos::Mcp::Executor.call(tool_name: :redmineflux_agentos_delete_issue, params: { issue_id: 1 }, actor: actor, agent: qa_agent, idempotency_key: 'demo-fail-2')
# => raises PermissionDeniedError — "redmineflux_agentos_delete_issue is not in qa's tool_allowlist"
```

Both failures write a `status: 'failed'` row to `redmineflux_agentos_mcp_tool_calls` — check `RedminefluxAgentosMcpToolCall.last.result_json`.

### Confirmation flow — 3 tools require it: `bulk_close_issues`, `delete_issue`, `update_timesheet`

```ruby
result = RedminefluxAgentos::Mcp::Executor.call(
  tool_name: :redmineflux_agentos_delete_issue, params: { issue_id: some_issue.id }, actor: actor, idempotency_key: 'demo-confirm-1'
)
# => { status: :pending_confirmation, result: nil, error: nil } — issue NOT deleted yet
```
Now go to **Agent Dashboard → Pending Approvals** and click Approve — that's the one real UI→backend path in this whole layer (Section 5.3). Or finish it from console: `RedminefluxAgentos::Mcp::Executor.confirm(RedminefluxAgentosMcpToolCall.last.id, confirmed_by: actor)`.

### Idempotency

```ruby
key = 'demo-idempotent-1'
r1 = RedminefluxAgentos::Mcp::Executor.call(tool_name: :redmineflux_agentos_create_issue, params: { project_id: project.id, tracker: 'Bug', subject: 'Once only' }, actor: actor, idempotency_key: key)
r2 = RedminefluxAgentos::Mcp::Executor.call(tool_name: :redmineflux_agentos_create_issue, params: { project_id: project.id, tracker: 'Bug', subject: 'Once only' }, actor: actor, idempotency_key: key)
r1 == r2  # true — second call replayed the stored result, no second Issue was created
Issue.where(subject: 'Once only').count  # 1
```

### Secret redaction — mechanism exists, but no *current* tool exercises it live

`Executor#redact` only masks a param when the tool's own `params_schema` marks it `sensitive: true`. **None of the 22 registered tools currently declare a sensitive param** — so there's nothing to click/call to see this live with real tools. Demonstrate it via the test suite instead (`test/unit/mcp/executor_test.rb`'s `test_secrets_redaction_is_allow_list_based`, which registers a synthetic tool with `api_key: { sensitive: true }`), or register one yourself in a console session:
```ruby
RedminefluxAgentos::Mcp::Executor::ToolRegistry rescue nil
RedminefluxAgentos::Mcp::ToolRegistry.register(:demo_sensitive_tool, category: 'test', handler: ->(p, a) { { result: { ok: true } } }, params_schema: { note: { required: true }, api_key: { required: false, sensitive: true } }, authorize: ->(a, p) { true })
RedminefluxAgentos::Mcp::Executor.call(tool_name: :demo_sensitive_tool, params: { note: 'hi', api_key: 'super-secret' }, actor: actor, idempotency_key: 'demo-redact-1')
RedminefluxAgentosMcpToolCall.last.params_json  # contains '[REDACTED]' for api_key, 'hi' in the clear for note
```

---

## 7. Chat Demonstration

### How to start a conversation

Project → AgentOS → AI Chat → type text → Send. Real, saves a `RedminefluxAgentosMessage`.

### How the Mock Provider "responds"

**It doesn't, through the UI.** To actually see a Mock Provider response tied to your chat message, drive it manually:
```ruby
conversation = RedminefluxAgentosConversation.last
message = RedminefluxAgentosMessage.last
agent_record = RedminefluxAgentosAgent.find_by(key: 'requirement_analyst')

agent_run = RedminefluxAgentosAgentRun.create!(
  agent_id: agent_record.id, project_id: conversation.project_id, conversation_id: conversation.id,
  status: 'queued', attempts: 0, max_attempts: 3
)
RedminefluxAgentos::Engine::AgentEngine::Runner.execute(agent_run)
agent_run.reload.status  # 'completed' if the seeded prompt template + a matching fixture resolve cleanly
```

### Conversation persistence

`RedminefluxAgentosConversation` (one per project+user, reused across messages — see `ChatController#latest_conversation`) and `RedminefluxAgentosMessage` (one per turn, `role: 'user'` only — nothing ever writes an `assistant`-role message, since nothing ever runs the agent from this flow).

### Session storage

There is no session/conversation-manager class. `ConversationManager::Session` (`docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md` §A.8) does not exist anywhere in this codebase. "Session state" today is just "the most recent conversation row for this project+user," recomputed on every request.

### Agent execution flow

Only reachable as shown above — `AgentEngine::Runner.execute` → `agent_class.new(agent_run).call(memory:)` → `Providers::Registry.active.request(...)` → tool calls (if any) go through `Mcp::Executor.call`.

### Expected logs

None — no code path writes to `redmineflux_agentos_execution_logs` outside the test suite (see Section 5.7).

### Known limitations

- No agent ever replies through the Chat UI itself
- No `assistant`-role messages are ever created
- SRS generation/approval → planning handoff is equally unwired (Section 5.2)

---

## 8. Tool Demonstrations

All 22 tools are individually callable via `Mcp::Executor.call` against a real Redmine instance (Section 6's pattern) — this is genuinely demonstrable now that you have a live Redmine in Docker, unlike the ad hoc test harnesses used during development. None require an external dependency beyond Redmine core itself.

| Tool | Input (key params) | Output | DB change | Verify |
|---|---|---|---|---|
| `redmineflux_agentos_create_project` | `name`, `identifier`, `description?`, `modules?` | new Project attrs | `projects` row | `Project.find_by(identifier: ...)` |
| `redmineflux_agentos_update_project` | `project_id`, `name?`, `description?` | updated attrs | `projects` row | reload project |
| `redmineflux_agentos_read_project` (read-only) | `project_id` | id/identifier/name/description/status | none | — |
| `redmineflux_agentos_create_version` | `project_id`, `name`, `description?`, `due_date?` | new Version attrs | `versions` row | `Version.last` |
| `redmineflux_agentos_create_issue` | `project_id`, `tracker`, `subject`, `description?`, `priority?` | new Issue attrs | `issues` row | `Issue.last` |
| `redmineflux_agentos_update_issue` | `issue_id`, `subject?`, `description?`, `status?`, `priority?` | updated attrs | `issues` row; publishes `issue.status_changed` if status changed | `Issue.find(id).reload` |
| `redmineflux_agentos_assign_issue` | `issue_id`, `assignee_id` | before/after assignee | `issues.assigned_to_id` | reload issue |
| `redmineflux_agentos_add_comment` | `issue_id`, `notes` | notes | `journals` row | `Issue.find(id).journals.last` |
| `redmineflux_agentos_create_issue_relation` | `issue_id`, `related_issue_id`, `relation_type?` | new relation | `issue_relations` row | `IssueRelation.last` |
| `redmineflux_agentos_bulk_close_issues` **(confirmation required)** | `issue_ids[]`, `status?` | per-item results | multiple `issues` rows | check each issue's status |
| `redmineflux_agentos_delete_issue` **(confirmation required)** | `issue_id` | before snapshot | `issues` row destroyed | `Issue.exists?(id)` → false |
| `redmineflux_agentos_search_issues` (read-only) | `project_id?`, `status?`, `assigned_to_id?`, `limit?` | matching issues | none | — |
| `redmineflux_agentos_read_ticket` (read-only) | `issue_id` | full issue detail | none | — |
| `redmineflux_agentos_read_comments` (read-only) | `issue_id` | non-blank journal notes | none | — |
| `redmineflux_agentos_create_wiki_page` | `project_id`, `title`, `text` | new page | `wiki_pages`+`wiki_contents` | `Project.find(id).wiki.find_page(title)` |
| `redmineflux_agentos_update_wiki` | `project_id`, `title`, `text`, `comments?` | updated content | `wiki_contents` row | reload page |
| `redmineflux_agentos_search_wiki` (read-only) | `project_id`, `query` | matching pages | none | — |
| `redmineflux_agentos_upload_file` | `container_type`, `container_id`, `filename`, `content`, `content_type?` | new attachment | `attachments` row | `Attachment.last` |
| `redmineflux_agentos_create_time_entry` | `issue_id`, `hours`, `activity?`, `comments?`, `spent_on?` | new entry | `time_entries` row | `TimeEntry.last` |
| `redmineflux_agentos_update_timesheet` **(confirmation required)** | `time_entry_ids[]`, `hours` | per-id results | multiple `time_entries` rows | — |
| `redmineflux_agentos_update_workload` | `project_id`, `allocation` | `acknowledged: true` | **none — no-op stub, doesn't persist anything** (no workload table exists) | N/A |
| `redmineflux_agentos_generate_report` (read-only) | `project_id`, `report_type?` | `ai_tasks` grouped by status | none | — |

**All 22 can be demonstrated** given this Docker environment — none is blocked by a missing external dependency. `update_workload` is the one worth flagging explicitly as a no-op even though it "succeeds" — don't imply it does anything real.

---

## 9. Permissions

### Layer 1 — Redmine authorization

Every controller action maps to exactly one AgentOS permission (`init.rb`), checked via `before_action :authorize` (project-scoped, `BaseController`) or `:authorize_global` (admin-scoped, `Admin::BaseController`). For MCP tools, Layer 1 is each tool's own `authorize:` proc (Section 6).

**Full permission table** (`init.rb`):

| Permission | Grants | Scope |
|---|---|---|
| `view_agentos_dashboard` | Agent Dashboard, Dependency Dashboard (view) | project |
| `create_ai_project` | Chat, Requirement Review, "+ New AI Project" | project + global |
| `run_ai_tasks` | Release Planner, Sprints, approve/reject | project |
| `view_token_usage` | Token Usage dashboard | project |
| `view_cost_dashboard` | Cost dashboard | project |
| `view_agent_logs` | Execution History | project |
| `manage_agentos` | Full admin control + Audit Logs | admin |
| `manage_ai_agents` | Admin Agents screen | admin |
| `manage_mcp_tools` | Admin MCP Tools screen | admin |
| `manage_prompt_templates` | Admin Prompt Library | admin |
| `manage_ai_configuration` | Admin Settings | admin |

### Layer 2 — Agent tool_allowlist

`RedminefluxAgentosAgent#config_json['tool_allowlist']` — only checked when an `agent:` is passed to `Mcp::Executor.call` (a human-initiated call skips it entirely). See `seed_agents`'s per-role allowlists in `lib/tasks/redmineflux_agentos.rake`.

### How to test both

- Layer 1 (UI): log in as a user with NO AgentOS permissions on a project, try to visit `/projects/:id/agentos/agent_dashboards` directly by URL → should be denied, not just hidden from the menu
- Layer 1 (MCP): Section 6's Layer 1 console example
- Layer 2 (MCP): Section 6's Layer 2 console example

### How to verify failures

- UI: Redmine's standard "You are not authorized to access this page" screen
- MCP: `RedminefluxAgentos::McpToolError::PermissionDeniedError` raised; a `status: 'failed'` row written to `mcp_tool_calls`

---

## 10. Events

Namespaced `agentos.*` over `ActiveSupport::Notifications`, dispatched synchronously in-process.

### Events that actually fire AND have a subscriber

| Event | Fires from | Subscriber effect |
|---|---|---|
| `issue.status_changed` | `issue_tools.rb` (`update_issue`, `bulk_close_issues`) | If new status is closed → `DependencyEngine::Scheduler.on_issue_closed` re-queues any `agent_run` blocked on that issue |
| `agent_run.running` | `ConcurrencyGuard.acquire` | `NotificationCenter.agent_started` — emails project members (opt-in, `notify_on_agent_started`) |
| `agent_run.completed` | `Lifecycle::MACHINE` transition | `NotificationCenter.agent_completed` — emails issue assignee/watchers |
| `agent_run.dead` | `Lifecycle::MACHINE` transition | `NotificationCenter.agent_dead` — emails users with `view_agent_logs` |
| `mcp_tool_call.pending_confirmation` | `Mcp::Executor.call` | `NotificationCenter.approval_needed` — emails users with `run_ai_tasks` |

### Events that fire but have NO subscriber (published into the void)

`agent_run.waiting_on_dep`, `agent_run.queued`, `agent_run.failed`, `agent_run.cancelled` — all real transitions in `Lifecycle::MACHINE`, none wired to anything.

### Events documented in `WORKFLOW.md` §15 that are never published anywhere in code

`conversation.srs_generated`, `conversation.srs_approved`, `project.created`, `dependency.cleared`, `mcp_tool_call.executed`/`.rejected`/`.failed`, `report.generated` — `WORKFLOW.md` itself flags these as "forward-looking."

### Dead code worth knowing about

`WorkflowEngine::TicketStatusMachine` (`lib/redmineflux_agentos/engine/workflow_engine/ticket_status_machine.rb`) is fully built (8-state transition table, always publishes `issue.status_changed`) but has **zero callers anywhere** — every real `issue.status_changed` event actually comes directly from `issue_tools.rb`, bypassing this class entirely.

### How to verify event publication

```ruby
received = []
RedminefluxAgentos::Engine::EventBus.subscribe('agent_run.completed') { |*, payload| received << payload }
# ... trigger a run via Section 7's console snippet ...
received  # non-empty if the run actually completed
```

### How to confirm subscribers executed

Check the side effect directly — e.g. for `agent_run.dead`, check `ActionMailer::Base.deliveries` in a test/dev-mail-catcher setup, or check Redmine's own mail log if `delivery_method` is `:logger`/`:file` in this container.

---

## 11. Testing

### The real command (run from the Redmine root inside the container, NOT from the plugin directory)

```bash
cd redmineflux_devops/docker
docker compose -f docker-compose.redmine5.yml exec redmine5 bash
cd /usr/src/redmine
bundle exec rake db:test:prepare RAILS_ENV=test redmine:plugins:migrate RAILS_ENV=test
bundle exec rails test plugins/redmineflux_agentos/test
```

This mirrors `redmineflux_devops`'s own `Dockerfile.test` precedent exactly (`bundle exec rails test plugins/redmineflux_devops/test`) — **`bundle exec rails test` alone, or run from inside the plugin directory, is not the correct invocation** for a Redmine plugin; plugin tests are addressed by path relative to the Redmine root.

### Run one file

```bash
bundle exec rails test plugins/redmineflux_agentos/test/unit/prompts/template_resolver_test.rb
```

### ⚠ Known issue — two files will fail as-is

`test/unit/mcp/executor_test.rb` and `test/unit/mcp/tool_registry_test.rb` reference `FakeMcpToolCall`, `FakeUser`, `FakeAgent`, `FakeAuditLog` — none of these classes are defined anywhere in this repo (confirmed by grep). They were only ever defined in throwaway ad hoc scratchpad harnesses used during development, never committed. Running these two files for real will raise `NameError: uninitialized constant`. Every other test file uses real Redmine core models/fixtures (`Project.find(1)`-style, relying on Redmine's own stock test fixtures) and should run cleanly. **This is a genuine, previously-undocumented gap** — flag it, don't paper over it in the demo.

### Full test file inventory (14 files)

| File | What it validates |
|---|---|
| `test/unit/agents/contract_conformance_test.rb` | All 17 agent classes share the same `#call` contract |
| `test/unit/configuration/credential_masking_test.rb` | Sensitive-key masking logic |
| `test/unit/engine/concurrency_guard_test.rb` | Atomic queued→running cap enforcement |
| `test/unit/engine/dependency_graph_test.rb` | Cycle detection + Phase 16 cache invalidation |
| `test/unit/engine/event_bus_test.rb` | Publish/subscribe roundtrip, boot-time subscriptions |
| `test/unit/engine/lifecycle_test.rb` | 7-state machine, pause/resume, disabled-agent guard |
| `test/unit/engine/state_machine_test.rb` | Generic `WorkflowEngine::StateMachine` |
| `test/unit/jobs/log_retention_job_test.rb` | Retention window + non-terminal-run exclusion |
| `test/unit/mcp/executor_test.rb` | ⚠ will fail (see above) |
| `test/unit/mcp/tool_registry_test.rb` | ⚠ will fail (see above) |
| `test/unit/notification_center_test.rb` | Recipient resolution for 4 event types |
| `test/unit/prompts/template_resolver_test.rb` | Prompt resolution + cache |
| `test/unit/providers/fixture_loader_test.rb` | Fixture directory validation |
| `test/unit/providers/mock_provider_test.rb` | Determinism, zero-network-calls, idempotency suffixing |
| `test/integration/mcp_multi_call_idempotency_test.rb` | Mock Provider → Executor integration |

### Expected passing output (once the two ⚠ files are excluded or fixed)

```
Finished in X.XXs
NN runs, MM assertions, 0 failures, 0 errors, 0 skips
```

---

## 12. Current Limitations

**Nothing here is hidden. If your manager asks "does X work," check this list before answering.**

1. **No UI trigger for the Agent Engine.** Nothing creates a `redmineflux_agentos_agent_run` row or enqueues `AgentRunJob` from any human action — Chat, SRS approval, and the "+ New AI Project" wizard all persist their own state and stop there. Only a Rails console call reaches the Agent Engine.
2. **`ConversationManager::Session`** (Phase 2 §A.8) doesn't exist anywhere — this is *why* #1 is true. No ticket from Phase 10 through Phase 16 was ever assigned to build it.
3. **`Admin::AgentsController#update` / `Admin::McpToolsController#update`** are `head :no_content` stubs — nothing persists. `index` actions render a "coming soon" placeholder.
4. **No external MCP HTTP API.** `config/routes.rb`'s `/agentos` JSON scope only has `health`/`metrics`. Agent-triggered tool calls work only because they're in-process Ruby calls (`Runner` → `Executor.call`), not HTTP.
5. **Real LLM integration doesn't exist.** `:mock` is the only registered provider; anything else raises `Configuration::InvalidProviderError`. This is intentional v1 scope, not a bug (`docs/PRODUCT-ROADMAP.md`).
6. **2 of `WORKFLOW.md` §23's 6 notification types are unimplemented**: "Workflow Blocked... SLA at risk" (no SLA tracking exists) and "Project Completed" (no completion-detection exists).
7. **4 `agent_run.*` events are published with no subscriber**: `waiting_on_dep`, `queued`, `failed`, `cancelled`.
8. **Several events documented in `WORKFLOW.md` are never published anywhere**: `conversation.srs_generated`, `conversation.srs_approved`, `project.created`, `dependency.cleared`, `mcp_tool_call.executed`/`.rejected`/`.failed`, `report.generated`.
9. **`WorkflowEngine::TicketStatusMachine` is dead code** — fully built, zero callers.
10. **`redmineflux_agentos_execution_logs` is never written to** by any real code path — only referenced by `LogRetentionJob` (which prunes rows) and the Execution History page (which reads them). The page will be empty even after real agent activity.
11. **`test/unit/mcp/executor_test.rb` and `tool_registry_test.rb` reference undefined test-double classes** and will fail with `NameError` if run as-is (Section 11).
12. **No planning services are wired up.** `lib/redmineflux_agentos/services/planning/{plan_releases_service,seed_project_service}.rb` exist but are never called from any controller, job, or rake task.
13. **None of this has been tested against a live Redmine instance until you do it via this guide** — every prior implementation phase's own spec says so explicitly (`backlog/specification/rao-01[5-9]*.md`, `rao-020`, `rao-021`).
14. **No sensitive MCP tool params exist today** — the redaction mechanism is real and tested, but no shipped tool currently has anything to redact (Section 6).
15. **`update_workload` MCP tool is a no-op** — no backing table, just an acknowledgment.

---

## 13. Demo Scenarios

### Scenario 1 — "Manager asks AI to create an issue"
Console (Section 6): `Mcp::Executor.call(tool_name: :redmineflux_agentos_create_issue, ...)`. Show the resulting Issue in Redmine's normal issue view immediately after. **Say explicitly**: "this simulates what an agent would do after reasoning about a request — the reasoning step itself (Mock Provider call) and the tool call are two separate, both-real pieces; only the UI glue between them is what's missing."

### Scenario 2 — "Manager updates a project"
Console: `Mcp::Executor.call(tool_name: :redmineflux_agentos_update_project, params: { project_id: p.id, description: 'Updated by AgentOS' }, ...)`. Show the change in Redmine's project settings page.

### Scenario 3 — "Manager demonstrates MCP confirmation"
Section 6's confirmation-flow demo, finishing the approval through the **real UI** (Agent Dashboard → Pending Approvals) — this is your best "look, a button does something real" moment.

### Scenario 4 — "Permission denied example"
Section 6's Layer 1 and Layer 2 examples, back to back — show the same tool call succeed for an authorized user/agent and fail for an unauthorized one, then show the `failed` row in `mcp_tool_calls`.

### Scenario 5 — "Idempotency demonstration"
Section 6's idempotency example — call the same tool twice with the same key, show `Issue.count` didn't move on the second call.

### Scenario 6 — "Mock Provider end-to-end" (recommended opener)
Section 4's console example — show a structured response come back instantly, zero network activity, deterministic (run it twice, get the identical `content`).

### Scenario 7 — "Health check"
`curl http://localhost:3080/agentos/health.json` before anything else — proves the plugin booted, all boot-time registrations succeeded, before you touch a single feature.

---

## 14. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Plugin not showing in Administration → Plugins | Volume mount path wrong (check `Redmineflux_agentos` casing matches your actual folder name on disk), or `redmine5-migrate` never completed | `docker compose -f docker-compose.redmine5.yml logs redmine5-migrate` — must exit 0 before `redmine5` starts (compose `depends_on: condition: service_completed_successfully` enforces this) |
| `NoMethodError` / `uninitialized constant Redminefluxagentos*` on boot | `bundle install` step failed inside the container (network issue mid-build) | `docker compose -f docker-compose.redmine5.yml logs redmine5` — rerun `docker compose -f docker-compose.redmine5.yml up -d --force-recreate redmine5` |
| Migration errors (`PG::UndefinedTable`, FK violations) | Migrations run out of order, or `db:migrate` run without `redmine:plugins:migrate` after it | Re-run the full sequence in Section 3, in order, as separate invocations — do not chain them |
| Mock Provider raises `FixtureNotFoundError` even for known scenarios | `fixture_directory` config points somewhere wrong, or the fixture file genuinely doesn't exist for that exact `agent_key/prompt_category/scenario_key` combination | `RedminefluxAgentos::Providers::Mock::FixtureLoader.root` in console to see the resolved path; `Dir.exist?` it |
| Mock Provider silently returns "not yet covered by fixtures" | Scenario legitimately has no fixture — this is the designed fallback behavior, not a bug | Check the fixture tree in Section 4 for what actually exists |
| Permission failures on every AgentOS page for every user | Module not enabled on the project (Section 3's last step), or role missing the permission | Project Settings → Modules → check AgentOS; Administration → Roles → grant the permission |
| Docker containers won't start / port conflict | Port 3080/5433 already in use by something else on your host | Stop whatever's using it, or edit the port mapping in `docker-compose.redmine5.yml` |
| Controller routing 404 | Route not declared, or plugin not eager-loaded | Check `config/routes.rb`; restart the container (`docker compose -f docker-compose.redmine5.yml restart redmine5`) |
| Admin menu item missing | Permission not admin-scoped correctly, or you're not logged in as an admin/role with that permission | `manage_*` permissions are `require: :admin` — only Administrators see them regardless of role assignment |
| Cache seems stale after activating a new prompt template version | `invalidate!` wasn't called — should happen automatically via `Admin::PromptTemplatesController`; if you changed the row directly in console/DB, the cache won't know | Call `RedminefluxAgentos::Prompts::TemplateResolver.invalidate!(key)` manually, or `Rails.cache.clear` |
| `NameError: uninitialized constant FakeMcpToolCall` running tests | Known gap (Section 11) | Skip those two files, or write the missing test-support classes first |

---

## 15. Demo Checklist

- [ ] `docker compose -f docker-compose.redmine5.yml up -d` completed, `redmine5-migrate` exited 0
- [ ] `curl http://localhost:3080/agentos/health.json` → `"status": "healthy"`
- [ ] Logged in as `admin`, password changed from default
- [ ] AgentOS module enabled on the demo project (Settings → Modules)
- [ ] Demo user created, added as project Member with a role granting the permissions you'll show
- [ ] `seed_agents` / `seed_prompt_templates` / `provision_system_user` rake tasks confirmed run (`RedminefluxAgentosAgent.count` → 17 in console)
- [ ] Mock Provider verified active (`Providers::Registry.active.class` → `MockProvider`)
- [ ] At least one console-driven agent run completed successfully, so the Token Usage / Execution History pages have *something* to show if you go there
- [ ] Rails console open in a visible terminal, ready for Sections 4/6/7/8's snippets
- [ ] You've decided in advance which "coming soon" pages you'll skip past quickly (Admin Agents, Admin MCP Tools) rather than clicking into cold
- [ ] You've read Section 12 once more right before presenting — know the answer to "does X work" before it's asked

---

## 16. Verification Method (how this guide was produced)

Every claim above was checked against the actual repository on 2026-07-03, not assumed from specification documents:

- Read `init.rb`, `config/routes.rb` directly for the real permission/route table
- Read every controller under `app/controllers/redmineflux_agentos/**` to determine real vs. stub implementation status
- Read `app/views/redmineflux_agentos/_coming_soon.html.erb` and its two callers to confirm exactly what a stub page renders
- Read `assets/javascripts/redmineflux_agentos/chat.js` — its own code comment independently confirms the "no agent reply" finding
- Grepped the entire `lib/`, `app/`, `config/` tree for every `EventBus.publish`/`.subscribe` call site and every `AgentRunJob`/`RedminefluxAgentosAgentRun.create` reference — this is what surfaced that nothing anywhere creates an agent run
- Read all 6 MCP tool files in full for the exact 22-tool inventory (not the "20 tools" figure quoted in earlier project history — recounted directly)
- Read the actual Mock Provider fixture YAML files verbatim for Section 4's examples, not reconstructed from memory
- Grepped `test/` for `Fake*` class references and confirmed via grep that none are defined anywhere in the committed codebase
- Rather than standing up a second, separate compose stack, added `redmineflux_agentos`'s volume mount + seed rake tasks directly into the sibling `redmineflux_devops` plugin's already-working `docker-compose.redmine5.yml`/`redmine6.yml` — the one real Docker-based Redmine setup anywhere in this workspace — following the exact mount pattern every other Redmineflux plugin already there uses

**Not verified**: the volume-mount and seed-task additions to `redmineflux_devops`'s compose files have not been run end-to-end (no Docker runtime in the environment this guide was written in). Treat first boot as the actual first test of them.
