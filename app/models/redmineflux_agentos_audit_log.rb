# frozen_string_literal: true

class RedminefluxAgentosAuditLog < ActiveRecord::Base
  belongs_to :user, optional: true
  belongs_to :agent, class_name: 'RedminefluxAgentosAgent', foreign_key: 'agent_id', optional: true

  validates :action, presence: true
  validates :target_type, presence: true
  validates :target_id, presence: true

  # Immutability (docs/PHASE4-DATABASE-DESIGN.md §9): no update/destroy
  # route is exposed at the app layer; reinforced here at the model layer
  # so a console session or rake task can't easily mutate history either.
  def readonly?
    !new_record?
  end

  before_destroy { raise ActiveRecord::ReadOnlyRecord }
end
