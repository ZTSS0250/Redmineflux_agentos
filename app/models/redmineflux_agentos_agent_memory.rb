# frozen_string_literal: true

class RedminefluxAgentosAgentMemory < ActiveRecord::Base
  SCOPES = %w[short_term long_term].freeze

  belongs_to :agent, class_name: 'RedminefluxAgentosAgent', foreign_key: 'agent_id'
  belongs_to :project, optional: true

  validates :scope, inclusion: { in: SCOPES }
  validates :key, presence: true
  validates :agent_id, uniqueness: { scope: %i[project_id scope key] }
end
