# frozen_string_literal: true

class RedminefluxAgentosAiTask < ActiveRecord::Base
  TASK_TYPES = %w[epic story task subtask].freeze
  # `status` mirrors the linked issue's tracker status (WORKFLOW.md §14),
  # plus the AgentOS-only `deleted` value (docs/PHASE4-DATABASE-DESIGN.md
  # §6/§10) — not enumerated as a fixed list since mirrored values come from
  # each project's own Redmine workflow, not a constant set.

  belongs_to :project
  belongs_to :issue, optional: true
  belongs_to :sprint, class_name: 'RedminefluxAgentosSprint', foreign_key: 'sprint_id', optional: true
  belongs_to :agent, class_name: 'RedminefluxAgentosAgent', foreign_key: 'agent_id'
  belongs_to :suggested_reviewer, class_name: 'User', foreign_key: 'suggested_reviewer_id', optional: true

  has_many :dependencies_as_dependent, class_name: 'RedminefluxAgentosDependency',
                                        foreign_key: 'ai_task_id', dependent: :destroy
  has_many :dependencies_as_prerequisite, class_name: 'RedminefluxAgentosDependency',
                                           foreign_key: 'depends_on_ai_task_id', dependent: :destroy

  validates :task_type, inclusion: { in: TASK_TYPES }
  validates :title, presence: true
end
