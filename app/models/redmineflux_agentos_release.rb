# frozen_string_literal: true

class RedminefluxAgentosRelease < ActiveRecord::Base
  STATUSES = %w[planned in_progress released].freeze

  belongs_to :project_plan, class_name: 'RedminefluxAgentosProjectPlan', foreign_key: 'project_plan_id'
  belongs_to :version, optional: true

  has_many :redmineflux_agentos_sprints, class_name: 'RedminefluxAgentosSprint',
                                          foreign_key: 'release_id', dependent: :destroy

  validates :status, inclusion: { in: STATUSES }
  validates :name, presence: true
end
