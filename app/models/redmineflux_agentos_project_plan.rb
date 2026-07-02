# frozen_string_literal: true

class RedminefluxAgentosProjectPlan < ActiveRecord::Base
  STATUSES = %w[draft pending_approval approved superseded].freeze

  belongs_to :project, optional: true
  belongs_to :conversation, class_name: 'RedminefluxAgentosConversation', foreign_key: 'conversation_id'
  belongs_to :approved_by, class_name: 'User', foreign_key: 'approved_by_id', optional: true

  has_many :redmineflux_agentos_releases, class_name: 'RedminefluxAgentosRelease',
                                           foreign_key: 'project_plan_id', dependent: :destroy

  validates :status, inclusion: { in: STATUSES }
  validates :version, presence: true
end
