# frozen_string_literal: true

class RedminefluxAgentosCostTracking < ActiveRecord::Base
  belongs_to :project, optional: true

  validates :period, presence: true
  validates :total_cost, numericality: { greater_than_or_equal_to: 0 }
  validates :project_id, uniqueness: { scope: :period }
end
