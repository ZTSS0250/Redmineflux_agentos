# Deployment Guide — redmineflux_agentos

**Status**: Operational runbook, not a design document — unlike every other file in `docs/`, this describes how to install and run what Phases 1–16 already specified/implemented, not what to build. Proposed and approved as part of `rao-021` (Phase 16, Enterprise Readiness) per the Documentation Updates process (`rao-008` §14): a production deployment needs installation/first-boot steps that don't belong in any pre-implementation specification document.
**Audience**: whoever installs this plugin into a real Redmine instance — a Zehntech DevOps engineer or a client's own Redmine administrator.

---

## 1. Prerequisites

- Redmine 5.0.0 or higher (`init.rb`'s `requires_redmine version_or_higher: '5.0.0'`) — 5.x or 6.x, per [CLAUDE.md](../CLAUDE.md)'s compatibility table.
- A background job runtime already configured for the host Redmine instance. AgentOS makes no assumption about which one (Sidekiq, Resque, Delayed Job, or Rails' default async adapter) — see [docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md](PHASE2-CORE-TECHNICAL-ARCHITECTURE.md) §B.1. If the host runs the default async adapter, note that queued jobs do not survive a process restart — acceptable for a demo/single-node install, not for production throughput.
- Outbound SMTP already configured in Redmine's own `config/configuration.yml` (`Setting.mail_from` and the standard Redmine mail delivery settings) — required for `NotificationCenter` (§6 below) to actually deliver anything.

## 2. Installation

```bash
cd redmine/plugins
git clone <this repository> redmineflux_agentos
cd ../..
bundle install
bin/rails redmine:plugins:migrate RAILS_ENV=production
sudo systemctl restart redmine   # or however this host's Redmine process is managed
```

No new gem dependencies are introduced beyond what a stock Redmine 5.x/6.x install already bundles (`ActiveJob`, `ActionMailer`, `Rails.cache` are all part of Rails itself, not plugin-added gems).

## 3. First-boot configuration

1. **Enable the module per project**: Project Settings → Modules → check "AgentOS" for every project that should use it (`project_module :agentos`, [init.rb](../init.rb)). No project has it enabled by default.
2. **Assign permissions to roles**: Administration → Roles and permissions → grant the relevant `docs/PHASE1-SPECIFICATION.md` §5 permissions (`create_ai_project`, `run_ai_tasks`, `view_token_usage`, `view_cost_dashboard`, `view_agent_logs`) to whichever roles should use each feature. The four/five administration-only permissions (`manage_agentos`, `manage_ai_agents`, `manage_mcp_tools`, `manage_prompt_templates`, `manage_ai_configuration`) are `require: :admin` — only Redmine Administrators ever see those regardless of role assignment.
3. **Review AgentOS Settings**: Administration → AgentOS → Settings. Every key in `RedminefluxAgentos::Configuration::Store::DEFAULTS` has a safe out-of-the-box default (`active_provider` starts as `mock` — v1 has no real LLM provider yet, see §7) — nothing here needs to change before first use, but concurrency caps (`global_concurrency_cap`, `project_concurrency_cap`) should be reviewed against this host's actual job worker capacity before enabling AgentOS on a busy instance.

## 4. Scheduling background jobs

Per [docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md](PHASE2-CORE-TECHNICAL-ARCHITECTURE.md) §B.1, AgentOS's jobs are plain `ActiveJob`/`ApplicationJob` classes with no bundled recurring-job scheduler (adapter-agnostic by design — the host's job runtime owns scheduling policy, AgentOS code never assumes one). Three jobs need to run on a recurring schedule; how you schedule them depends on what this host already uses for that (`whenever`, `sidekiq-cron`, or plain `cron` + `rails runner`). A plain-cron example, assuming Redmine is installed at `/opt/redmine`:

```cron
# /etc/cron.d/redmineflux_agentos
0 3 * * * redmine cd /opt/redmine && bin/rails runner "RedminefluxAgentos::LogRetentionJob.perform_later" RAILS_ENV=production
*/15 * * * * redmine cd /opt/redmine && bin/rails runner "RedminefluxAgentos::MemorySweepJob.perform_later" RAILS_ENV=production
5 0 * * * redmine cd /opt/redmine && bin/rails runner "RedminefluxAgentos::CostRollupJob.perform_later" RAILS_ENV=production
```

None of these three block a web request if they're skipped for a cycle — a missed `LogRetentionJob` run just means `execution_logs` grows a little more before the next window; a missed `CostRollupJob` run means the Cost Dashboard is a day behind until the next one runs. Neither is an outage.

## 5. Health check and ops metrics

Two unauthenticated JSON endpoints exist specifically for infrastructure tooling that cannot log in as a Redmine user (load balancers, uptime monitors, orchestration liveness/readiness probes, metrics scrapers) — see `app/controllers/redmineflux_agentos/health_controller.rb`:

| Endpoint | Purpose |
|---|---|
| `GET /agentos/health.json` | `{status: "healthy"/"unhealthy", checks: {...}}` — boot-state checks (agent registry, provider registry, Event Bus subscriptions all populated). Returns HTTP 503 when unhealthy, never a false-positive 200. |
| `GET /agentos/metrics.json` | Cross-project aggregate counts only (agent run throughput by status, 7-day cost/token trend, dependency edge counts) — never per-project or per-user data. |

Both are deliberately **not** behind Redmine login (every other AgentOS route requires it — this is the one documented exception, `HealthController`'s own class comment explains why). Because of that, **restrict network access to these two paths at the reverse proxy/firewall level** to whatever network segment your monitoring tooling actually runs in — they are not intended to be reachable from the open internet, even though they require no Redmine credentials.

## 6. Notifications

`NotificationCenter` ([docs/](../WORKFLOW.md) §23) sends real email through a small plugin-owned `ActionMailer` (`RedminefluxAgentos::NotificationMailer`), using Redmine's own configured mail delivery method (`Setting.mail_from` and whatever `config/configuration.yml` already has Redmine sending through) — no additional AgentOS-specific mail configuration exists or is needed. If Redmine's own outgoing mail is not configured, AgentOS notifications will silently fail exactly the way any other Redmine mail notification would.

## 7. Known v1 limitations to set expectations on

- **Mock Provider only** — `active_provider` cannot yet resolve to a real LLM vendor; all agent responses are fixture-driven simulations (`docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md`). Token/cost figures are real arithmetic on simulated inputs, not real vendor billing.
- **No external MCP HTTP API yet** — `config/routes.rb`'s `/agentos` JSON scope only carries `health`/`metrics` as of this release; the external MCP server integration point named in that file's own comment is routed and reserved but not yet implemented. Agent-triggered tool calls work today because they run in-process (`Mcp::Executor.call` as a direct Ruby call from `AgentEngine::Runner`), not over HTTP.
- **Two admin screens are still skeleton stubs**: `Admin::AgentsController#update` and the `Admin::McpToolsController` actions render but do not yet persist changes — logged as a known gap in `rao-021`'s Gate 1 revision, not something this release fixes.
