# frozen_string_literal: true

class RedminefluxAgentosMcpToolCall < ActiveRecord::Base
  STATUSES = %w[pending_confirmation executed rejected failed].freeze

  belongs_to :agent_run, class_name: 'RedminefluxAgentosAgentRun', foreign_key: 'agent_run_id', optional: true
  belongs_to :user, optional: true
  belongs_to :confirmed_by, class_name: 'User', foreign_key: 'confirmed_by_id', optional: true

  validates :tool_name, presence: true
  validates :status, inclusion: { in: STATUSES }

  # redmineflux_agentos_audit_logs is the immutable record
  # (docs/PHASE4-DATABASE-DESIGN.md §9) — this table is intentionally
  # mutable (status transitions pending_confirmation -> executed/rejected),
  # so no readonly guard here.
end
