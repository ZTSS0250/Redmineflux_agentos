# frozen_string_literal: true

namespace :redmineflux_agentos do
  desc 'Provision the AgentOS System user and role (rao-015) — safe to run repeatedly'
  task provision_system_user: :environment do
    user = RedminefluxAgentos::SystemUserProvisioner.user
    puts "AgentOS System user ready: #{user.login} (id: #{user.id})"
  end

  desc 'Ensure the AgentOS System user is a member of every project with the :agentos module enabled'
  task sync_system_user_memberships: :environment do
    EnabledModule.where(name: 'agentos').find_each do |mod|
      RedminefluxAgentos::SystemUserProvisioner.ensure_membership!(mod.project)
    end
    puts 'AgentOS System user membership synced.'
  end

  # Added during rao-019 (Phase 14) implementation: no ticket seeds actual
  # `redmineflux_agentos_agents` rows anywhere — without them,
  # `Mcp::ToolRegistry.tools_for(agent)` (Layer 2) has no `tool_allowlist`
  # to check, so no agent could ever call any MCP tool on a fresh
  # install. Idempotent, matching this file's existing convention.
  desc 'Seed the 17 redmineflux_agentos_agents rows (idempotent) — required before any agent can call an MCP tool'
  task seed_agents: :environment do
    # docs/AGENTS.md's own per-agent "MCP Tools" rows, bare action names
    # here, prefixed to match Mcp::ToolRegistry's actual keys (rao-018)
    # below.
    tool_allowlists = {
      'project_manager' => %w[create_project update_project create_version create_issue update_issue
                               assign_issue add_comment create_issue_relation read_project search_issues],
      'requirement_analyst' => %w[create_wiki_page],
      'business_analyst' => %w[create_issue read_project search_issues],
      'scrum_master' => %w[update_issue add_comment search_issues read_comments],
      'solution_architect' => %w[create_wiki_page update_wiki read_project],
      'database_agent' => %w[create_issue update_issue add_comment create_wiki_page],
      'backend' => %w[create_issue update_issue add_comment create_issue_relation],
      'api' => %w[create_issue create_wiki_page update_wiki],
      'frontend' => %w[create_issue update_issue add_comment],
      'ui_ux' => %w[update_issue add_comment upload_file],
      'qa' => %w[create_issue create_issue_relation add_comment search_issues],
      'security' => %w[create_issue add_comment read_project],
      'devops' => %w[create_issue update_issue read_project],
      'deployment' => %w[update_issue add_comment search_issues],
      'code_review' => %w[add_comment read_comments search_issues],
      'documentation' => %w[create_wiki_page update_wiki search_wiki],
      'reporting' => %w[read_project search_issues read_comments generate_report]
    }

    tool_allowlists.each do |key, tools|
      agent = RedminefluxAgentosAgent.find_or_initialize_by(key: key)
      agent.name ||= key.tr('_', ' ').split.map(&:capitalize).join(' ')
      agent.status = 'enabled' if agent.status.blank?
      agent.config_json = { tool_allowlist: tools.map { |t| "redmineflux_agentos_#{t}" } }.to_json
      agent.save!
    end

    puts "Seeded #{tool_allowlists.size} agents."
  end

  # Added during rao-019 (Phase 14) implementation: no ticket seeds actual
  # `redmineflux_agentos_prompt_templates` rows either — `TemplateResolver`
  # (rao-019) raises a clear error rather than silently rendering blank
  # when no active template exists for a key, so without this seed no
  # agent could ever produce a prompt at all. Minimal, permissive content
  # (no declared required variables) — a real prompt library is an
  # ongoing content-authoring task, not a one-time migration; this just
  # makes the system bootable.
  desc 'Seed minimal shared prompt_templates rows (idempotent) — required before any agent can run'
  task seed_prompt_templates: :environment do
    categories = %w[project_planning requirement_analysis sprint_planning dependency_analysis
                     ticket_generation risk_analysis documentation reporting]
    system_user = RedminefluxAgentos::SystemUserProvisioner.user

    categories.each do |category|
      key = "#{category}.default"
      next if RedminefluxAgentosPromptTemplate.exists?(key: key, is_active: true)

      RedminefluxAgentosPromptTemplate.create!(
        key: key,
        agent_id: nil,
        version: 1,
        content: "You are acting as the #{category.tr('_', ' ')} step. {{memory}}",
        variables_json: [].to_json,
        is_active: true,
        created_by_id: system_user.id
      )
    end

    puts "Seeded prompt templates for: #{categories.join(', ')}"
  end
end
