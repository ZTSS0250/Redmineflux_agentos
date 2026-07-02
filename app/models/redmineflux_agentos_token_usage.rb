# frozen_string_literal: true

class RedminefluxAgentosTokenUsage < ActiveRecord::Base
  belongs_to :agent_run, class_name: 'RedminefluxAgentosAgentRun', foreign_key: 'agent_run_id'
  belongs_to :project

  validates :provider, presence: true
  validates :prompt_tokens, :completion_tokens, :total_tokens,
            presence: true, numericality: { greater_than_or_equal_to: 0 }
end
