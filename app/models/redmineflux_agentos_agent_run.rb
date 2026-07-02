# frozen_string_literal: true

class RedminefluxAgentosAgentRun < ActiveRecord::Base
  # Canonical 7-state machine — WORKFLOW.md §8. Governed by
  # WorkflowEngine::StateMachine (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md
  # §A.6), not enforced by a model-level state machine gem.
  STATUSES = %w[queued running waiting_on_dep completed failed dead cancelled].freeze

  belongs_to :agent, class_name: 'RedminefluxAgentosAgent', foreign_key: 'agent_id'
  belongs_to :project
  belongs_to :issue, optional: true
  belongs_to :conversation, class_name: 'RedminefluxAgentosConversation',
                            foreign_key: 'conversation_id', optional: true
  belongs_to :blocking_issue, class_name: 'Issue', foreign_key: 'blocking_issue_id', optional: true

  has_many :redmineflux_agentos_execution_logs, class_name: 'RedminefluxAgentosExecutionLog',
                                                 foreign_key: 'agent_run_id', dependent: :destroy
  has_many :redmineflux_agentos_mcp_tool_calls, class_name: 'RedminefluxAgentosMcpToolCall',
                                                 foreign_key: 'agent_run_id', dependent: :destroy
  has_many :redmineflux_agentos_token_usages, class_name: 'RedminefluxAgentosTokenUsage',
                                               foreign_key: 'agent_run_id', dependent: :destroy

  validates :status, inclusion: { in: STATUSES }
end
