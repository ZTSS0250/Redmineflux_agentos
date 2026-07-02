# frozen_string_literal: true

class RedminefluxAgentosKnowledgeBaseEntry < ActiveRecord::Base
  SOURCE_TYPES = %w[srs wiki decision manual].freeze

  belongs_to :project, optional: true

  validates :title, presence: true
  validates :source_type, inclusion: { in: SOURCE_TYPES }
end
