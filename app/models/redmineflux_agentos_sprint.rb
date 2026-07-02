# frozen_string_literal: true

class RedminefluxAgentosSprint < ActiveRecord::Base
  STATUSES = %w[planned active completed].freeze

  belongs_to :release, class_name: 'RedminefluxAgentosRelease', foreign_key: 'release_id'

  has_many :redmineflux_agentos_ai_tasks, class_name: 'RedminefluxAgentosAiTask',
                                           foreign_key: 'sprint_id', dependent: :nullify

  validates :status, inclusion: { in: STATUSES }
  validates :name, presence: true
end
