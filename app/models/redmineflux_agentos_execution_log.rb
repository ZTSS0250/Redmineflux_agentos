# frozen_string_literal: true

class RedminefluxAgentosExecutionLog < ActiveRecord::Base
  LEVELS = %w[debug info warn error].freeze

  belongs_to :agent_run, class_name: 'RedminefluxAgentosAgentRun', foreign_key: 'agent_run_id'

  validates :level, inclusion: { in: LEVELS }
  validates :message, presence: true
end
