# frozen_string_literal: true

class RedminefluxAgentosPromptTemplate < ActiveRecord::Base
  belongs_to :agent, class_name: 'RedminefluxAgentosAgent', foreign_key: 'agent_id', optional: true
  belongs_to :created_by, class_name: 'User', foreign_key: 'created_by_id'

  validates :key, presence: true
  validates :version, presence: true
  validates :content, presence: true

  # "One active version per key" is enforced at the application layer (a
  # service callback), not a DB constraint — docs/PHASE4-DATABASE-DESIGN.md
  # §5 (MySQL doesn't portably support the partial unique index that would
  # enforce this at the DB level). Not enforced by this model.
end
