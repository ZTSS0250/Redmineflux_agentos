# Phase 5 — Folder Structure & Plugin Organization — redmineflux_agentos

**Status**: Specification only. No files are created by this document — it defines where every class/module designed in Phases 2–4 will live once Phase 10 (Plugin Skeleton) generates them.
**Relationship to other docs**: this is the file-system realization of [docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md](PHASE2-CORE-TECHNICAL-ARCHITECTURE.md) (module responsibilities, service convention), [docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md](PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md) (Provider Interface/Mock), and [docs/AGENTS.md](AGENTS.md) (17 agent classes) — every path below traces back to a class or responsibility already named in one of those documents; nothing here introduces a new module that wasn't already designed.

---

## 1. Plugin Directory Layout

```
redmineflux_agentos/
├── app/
│   ├── controllers/redmineflux_agentos/
│   ├── models/redmineflux_agentos/
│   ├── views/redmineflux_agentos/
│   ├── helpers/redmineflux_agentos/
│   ├── jobs/redmineflux_agentos/
│   └── serializers/redmineflux_agentos/
├── assets/
│   ├── javascripts/redmineflux_agentos/
│   └── stylesheets/redmineflux_agentos/
├── config/
│   ├── locales/
│   │   └── en.yml
│   └── routes.rb
├── db/
│   └── migrate/
├── docs/                                    (this specification set)
├── lib/
│   └── redmineflux_agentos/
│       ├── agents/
│       ├── services/
│       ├── providers/
│       ├── mcp/
│       ├── engine/
│       ├── prompts/
│       └── hooks/
├── test/
│   ├── unit/
│   ├── functional/
│   ├── integration/
│   └── fixtures/
├── backlog/{planning,specification,done}/
├── documents/security-rules.md
├── init.rb
├── TODO.md
├── ROADMAP.md
├── RELEASE_NOTES.md
├── VISION.md
├── WORKFLOW.md
└── CLAUDE.md
```

This matches the top-level shape already committed to in `CLAUDE.md`'s "Directory Structure" section — this document only adds the depth CLAUDE.md deliberately left as a summary.

---

## 2. Application Layer Organization

`app/` holds everything that's a Rails MVC concern — controllers, ActiveRecord models, views, jobs. Everything namespaced under `RedminefluxAgentos::` (models) or served from `redmineflux_agentos/` view/controller paths, per CLAUDE.md's `RedminefluxAgentos*` naming convention.

| Path | Contents | Traces back to |
|---|---|---|
| `app/models/redmineflux_agentos/` | One AR model per table in [docs/DATABASE-SCHEMA.md](DATABASE-SCHEMA.md) — `agent.rb`, `agent_run.rb`, `agent_memory.rb`, `conversation.rb`, `message.rb`, `project_plan.rb`, `release.rb`, `sprint.rb`, `ai_task.rb`, `dependency.rb`, `prompt_template.rb`, `knowledge_base_entry.rb`, `execution_log.rb`, `mcp_tool_call.rb`, `token_usage.rb`, `cost_tracking.rb`, `configuration.rb`, `audit_log.rb` | `docs/DATABASE-SCHEMA.md` |
| `app/controllers/redmineflux_agentos/` | Chat/wizard, requirement review, dashboards (agent/dependency/release/token/cost/execution), admin (agents/prompts/MCP tools/config), REST API controllers | `docs/UI-WIREFRAMES.md`, `docs/PHASE1-SPECIFICATION.md` §4-§5 |
| `app/views/redmineflux_agentos/` | ERB templates, one directory per controller | `docs/UI-WIREFRAMES.md` |
| `app/helpers/redmineflux_agentos/` | View helpers (dashboard formatting, status badges) | — |
| `app/jobs/redmineflux_agentos/` | `agent_run_job.rb`, `memory_sweep_job.rb`, `cost_rollup_job.rb`, `log_retention_job.rb` | Phase 2 §B.1, Phase 4 §12 |
| `app/serializers/redmineflux_agentos/` | JSON shaping for dashboard/API responses | Phase 2 §2.2 module table (Dashboard) |

---

## 3. Service Layer Structure

`lib/redmineflux_agentos/services/` (not `app/services/` — Redmine plugins conventionally keep non-Rails-autoloaded business logic under `lib/`, consistent with where `redmineflux_devops` places its own service objects), organized by noun, one file per service per Phase 2 §A.2's `.call` convention:

```
lib/redmineflux_agentos/services/
├── requirements/
│   ├── analyze_idea_service.rb
│   ├── generate_clarification_questions_service.rb
│   └── generate_srs_service.rb
├── planning/
│   ├── seed_project_service.rb
│   ├── plan_releases_service.rb
│   └── plan_sprints_service.rb
├── tickets/
│   └── generate_tickets_service.rb
├── dependencies/
│   ├── build_graph_service.rb
│   └── clear_blocker_service.rb
├── mcp/
│   └── execute_tool_service.rb
└── reporting/
    └── generate_report_service.rb
```

---

## 4. Agent Modules

```
lib/redmineflux_agentos/agents/
├── project_manager_agent.rb
├── requirement_analyst_agent.rb
├── business_analyst_agent.rb
├── scrum_master_agent.rb
├── solution_architect_agent.rb
├── database_agent.rb
├── backend_agent.rb
├── api_agent.rb
├── frontend_agent.rb
├── ui_ux_agent.rb
├── qa_agent.rb
├── security_agent.rb
├── devops_agent.rb
├── deployment_agent.rb
├── code_review_agent.rb          # reserved, per docs/AGENTS.md #15
├── documentation_agent.rb
└── reporting_agent.rb
```

17 files, one per role in [docs/AGENTS.md](AGENTS.md), each implementing the common agent contract (input/output/memory/tools/communication/workflow). The Agent Engine itself (not a specific agent) lives alongside, not inside, this directory:

```
lib/redmineflux_agentos/engine/agent_engine/
├── registry.rb        # AgentEngine::Registry, Phase 2 §A.5
├── lifecycle.rb        # AgentEngine::Lifecycle, Phase 2 §A.5
└── runner.rb           # AgentEngine::Runner, Phase 2 §A.5
```

---

## 5. AI Provider Modules

```
lib/redmineflux_agentos/providers/
├── provider_interface.rb        # Phase 3 §2 — the contract every provider implements
├── registry.rb                  # Provider::Registry, Phase 3 §3.1
└── mock/
    ├── mock_provider.rb         # Phase 3 §1
    ├── fixture_selector.rb      # Phase 3 §1.2
    ├── fixture_loader.rb
    └── fixture_renderer.rb
```

Fixture *data* files (not code) live outside `lib/`, under `config/agentos/fixtures/mock_provider/` — matching Phase 3 §12's `fixture_directory` configuration key default. A future real provider (v2+, `docs/PRODUCT-ROADMAP.md`) adds a sibling directory (`lib/redmineflux_agentos/providers/openai/`, etc.) without touching `mock/` or `provider_interface.rb`.

---

## 6. MCP Modules

```
lib/redmineflux_agentos/mcp/
├── tool_registry.rb              # Mcp::ToolRegistry, docs/MCP-TOOLS.md
├── executor.rb                    # Mcp::Executor — the single write path, Phase 2 §B.8
└── tools/
    ├── project_tools.rb           # create_project, update_project, read_project, create_version
    ├── issue_tools.rb             # create_issue, update_issue, assign_issue, add_comment, create_issue_relation, bulk_close_issues, delete_issue, search_issues, read_ticket, read_comments
    ├── wiki_tools.rb               # create_wiki_page, update_wiki, search_wiki
    ├── file_tools.rb               # upload_file
    ├── time_tools.rb               # create_time_entry, update_timesheet, update_workload
    └── reporting_tools.rb          # generate_report
```

One file per [docs/MCP-TOOLS.md](MCP-TOOLS.md) category, not one file per tool — matching that document's own category grouping.

---

## 7. Workflow Modules

```
lib/redmineflux_agentos/engine/
├── workflow_engine/
│   └── state_machine.rb           # WorkflowEngine::StateMachine, Phase 2 §A.6 — one class, two configured instances
├── dependency_engine/
│   ├── graph.rb                    # DependencyEngine::Graph
│   └── scheduler.rb                 # DependencyEngine::Scheduler
└── event_bus.rb                    # RedminefluxAgentos::EventBus, Phase 2 §A.7
```

---

## 8. Background Jobs

Already listed under §2 (`app/jobs/redmineflux_agentos/`) — restated here for ROADMAP.md's deliverable checklist:

| Job | Purpose | Traces back to |
|---|---|---|
| `agent_run_job.rb` | Executes one `agent_run` via `AgentEngine::Runner` | Phase 2 §B.1 |
| `memory_sweep_job.rb` | Expires `short_term` agent memory | Phase 2 §A.9 |
| `cost_rollup_job.rb` | Daily `cost_trackings` aggregation | Phase 2 §B.1, §10 |
| `log_retention_job.rb` | Prunes `execution_logs` past the retention window, excluding non-terminal `agent_run`s | Phase 4 §12 |

---

## 9. Initializers

```
config/initializers/redmineflux_agentos.rb
```

Boot-time responsibilities (all deferred via `Rails.application.config.to_prepare`, per Redmine plugin convention, so they re-run correctly under both eager and lazy class loading — see Phase 4 §10's Gate 3 finding #2 on why this matters):

1. Register the Mock Provider into `Provider::Registry` (Phase 3 §3.1)
2. Register every agent into `AgentEngine::Registry` (Phase 2 §A.5)
3. Subscribe Event Bus listeners — the Dependency Engine's `agentos.issue_status_changed` subscriber (Phase 2 §A.7)
4. Extend `Project`/`Issue` with `has_many ... dependent: :destroy` associations toward AgentOS's own tables (Phase 4 §10)

---

## 10. Assets

```
assets/javascripts/redmineflux_agentos/
├── chat.js               # AI Chat / New AI Project Wizard
├── dashboards.js          # live-polling dashboard updates
└── pending_approvals.js   # Agent Dashboard confirmation queue

assets/stylesheets/redmineflux_agentos/
└── agentos.css
```

Per `docs/PHASE1-SPECIFICATION.md`, visual design/CSS depth is a later concern — this section only fixes *where* assets live, not their content.

---

## 11. Locales

```
config/locales/en.yml
```

One file in v1 — English only. This is consistent with, not a resolution of, the localization gap flagged in Phase 3 §6 (`prompt_templates` has no `locale` column): Redmine's own i18n mechanism (`config/locales/*.yml`) covers UI strings, but prompt *content* localization is the separate, still-open gap Phase 3 already documented. Adding `fr.yml`/etc. later covers UI chrome; it does not by itself localize agent-generated prompt content.

---

## 12. Specs (Tests)

Redmine plugins use Rails' `Test::Unit`/Minitest convention, under `test/`, not RSpec's `spec/` — matching `redmineflux_devops`'s own structure (`test/unit/`, `test/functional/`, `test/integration/`) for consistency across Zehntech's Redmine plugins:

```
test/
├── unit/
│   ├── models/           # one test per app/models/redmineflux_agentos/*.rb
│   ├── services/         # one test per lib/redmineflux_agentos/services/**/*.rb
│   ├── agents/           # one test per lib/redmineflux_agentos/agents/*.rb
│   ├── providers/        # Mock Provider fixture/lifecycle tests
│   └── jobs/
├── functional/            # one test per app/controllers/redmineflux_agentos/*.rb
├── integration/           # end-to-end flows (e.g. the WORKFLOW.md §28 EMS walkthrough, as an integration test)
└── fixtures/              # Rails test fixtures (YAML) — distinct from Mock Provider's own fixture files (§5), which are runtime data, not test data
```

**Naming collision to watch for**: "fixtures" means two different things in this plugin — Rails test fixtures (`test/fixtures/`, seed data for tests) and Mock Provider response fixtures (`config/agentos/fixtures/mock_provider/`, runtime simulation data). They are stored in deliberately different directory trees specifically to avoid this ambiguity ever showing up in a file path.

---

## 13. Documentation Layout

`docs/` — already established and populated (this document is itself part of it): `PHASE1-SPECIFICATION.md`, `AGENTS.md`, `DATABASE-SCHEMA.md`, `MCP-TOOLS.md`, `UI-WIREFRAMES.md`, `USER-ROLES-AND-STORIES.md`, `SECURITY-COMPLIANCE-OVERVIEW.md`, `PRODUCT-ROADMAP.md`, `PHASE2-CORE-TECHNICAL-ARCHITECTURE.md`, `PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md`, `PHASE4-DATABASE-DESIGN.md`, `PHASE5-FOLDER-STRUCTURE.md` (this file). Root-level docs (`VISION.md`, `WORKFLOW.md`, `ROADMAP.md`, `CLAUDE.md`, `TODO.md`, `RELEASE_NOTES.md`) stay at the repository root per existing convention — `docs/` is reserved for the detailed specification set, not project-level narrative documents.
