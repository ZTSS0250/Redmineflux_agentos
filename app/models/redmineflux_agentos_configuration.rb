# frozen_string_literal: true

class RedminefluxAgentosConfiguration < ActiveRecord::Base
  belongs_to :project, optional: true
  belongs_to :updated_by, class_name: 'User', foreign_key: 'updated_by_id'

  validates :key, presence: true
  validates :project_id, uniqueness: { scope: :key }
end
