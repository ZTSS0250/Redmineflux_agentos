# frozen_string_literal: true

class RedminefluxAgentosAgent < ActiveRecord::Base
  STATUSES = %w[enabled disabled].freeze

  has_many :redmineflux_agentos_agent_runs, class_name: 'RedminefluxAgentosAgentRun',
                                             foreign_key: 'agent_id', dependent: :restrict_with_error
  has_many :redmineflux_agentos_agent_memories, class_name: 'RedminefluxAgentosAgentMemory',
                                                 foreign_key: 'agent_id', dependent: :destroy
  has_many :redmineflux_agentos_prompt_templates, class_name: 'RedminefluxAgentosPromptTemplate',
                                                   foreign_key: 'agent_id', dependent: :nullify
  has_many :redmineflux_agentos_ai_tasks, class_name: 'RedminefluxAgentosAiTask',
                                           foreign_key: 'agent_id', dependent: :restrict_with_error

  validates :key, presence: true, uniqueness: true
  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }

  # The agent's MCP tool allow-list (docs/AGENTS.md, "tools" — an explicit
  # allow-list of MCP tools) — one of the "model override, temperature,
  # tool allow-list" fields docs/DATABASE-SCHEMA.md already documents
  # `config_json` as carrying. Least-privilege default: an agent with no
  # `config_json`, or no `tool_allowlist` key within it, may call no
  # tools at all — never treated as "unrestricted."
  def tool_allowlist
    return [] if config_json.blank?

    parsed = JSON.parse(config_json)
    Array(parsed['tool_allowlist'])
  rescue JSON::ParserError
    []
  end
end
