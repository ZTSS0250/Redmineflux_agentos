# frozen_string_literal: true

class RedminefluxAgentosConversation < ActiveRecord::Base
  STATUSES = %w[active awaiting_user srs_review approved closed].freeze

  belongs_to :project, optional: true
  belongs_to :user

  has_many :redmineflux_agentos_messages, class_name: 'RedminefluxAgentosMessage',
                                           foreign_key: 'conversation_id', dependent: :destroy
  has_many :redmineflux_agentos_project_plans, class_name: 'RedminefluxAgentosProjectPlan',
                                                foreign_key: 'conversation_id', dependent: :destroy

  validates :status, inclusion: { in: STATUSES }
end
