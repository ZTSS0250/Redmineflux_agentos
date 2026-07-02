# frozen_string_literal: true

class RedminefluxAgentosDependency < ActiveRecord::Base
  DEPENDENCY_TYPES = %w[blocks relates_to].freeze

  belongs_to :ai_task, class_name: 'RedminefluxAgentosAiTask', foreign_key: 'ai_task_id'
  belongs_to :depends_on_ai_task, class_name: 'RedminefluxAgentosAiTask', foreign_key: 'depends_on_ai_task_id'

  validates :dependency_type, inclusion: { in: DEPENDENCY_TYPES }
  validates :ai_task_id, uniqueness: { scope: :depends_on_ai_task_id }

  # Cycle prevention is application-level (DependencyEngine::Graph,
  # docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §A.4), not a model
  # validation — detecting a cycle requires graph traversal beyond one row.
end
