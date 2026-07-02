# frozen_string_literal: true

class RedminefluxAgentosMessage < ActiveRecord::Base
  ROLES = %w[user agent system].freeze

  belongs_to :conversation, class_name: 'RedminefluxAgentosConversation', foreign_key: 'conversation_id'
  belongs_to :agent, class_name: 'RedminefluxAgentosAgent', foreign_key: 'agent_id', optional: true

  validates :role, inclusion: { in: ROLES }
  validates :content, presence: true
end
