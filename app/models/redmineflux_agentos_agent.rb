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
end
