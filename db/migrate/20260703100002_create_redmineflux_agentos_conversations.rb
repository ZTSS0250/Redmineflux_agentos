# frozen_string_literal: true

# NOTE: created before agent_runs (rao-016's Code Changes table lists
# agent_runs 2nd and conversations 4th) — agent_runs.conversation_id is a
# nullable FK into this table, so conversations must exist first. Reordering
# this table ahead of agent_runs is the actual fix for rao-016 Gate 1
# finding #1 ("migration ordering must respect FK dependencies"), which the
# originally-approved file listing did not fully satisfy for this one edge
# case. See rao-016's Done section for the full note.
class CreateRedminefluxAgentosConversations < ActiveRecord::Migration[6.1]
  def change
    create_table :redmineflux_agentos_conversations do |t|
      t.bigint :project_id
      t.bigint :user_id, null: false
      t.string :title
      t.string :status, null: false, default: 'active'

      t.timestamps null: false
    end

    add_index :redmineflux_agentos_conversations, %i[project_id status], name: 'idx_agentos_convos_project_status'
    add_index :redmineflux_agentos_conversations, :user_id

    add_foreign_key :redmineflux_agentos_conversations, :projects, column: :project_id
    add_foreign_key :redmineflux_agentos_conversations, :users, column: :user_id
  end
end
