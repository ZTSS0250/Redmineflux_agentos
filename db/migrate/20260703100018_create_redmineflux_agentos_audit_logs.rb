# frozen_string_literal: true

class CreateRedminefluxAgentosAuditLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :redmineflux_agentos_audit_logs do |t|
      t.bigint :user_id
      t.references :agent, foreign_key: { to_table: :redmineflux_agentos_agents }
      t.string :action, null: false
      t.string :target_type, null: false
      t.bigint :target_id, null: false
      t.text :before_json
      t.text :after_json

      t.datetime :created_at, null: false
    end

    add_index :redmineflux_agentos_audit_logs, %i[target_type target_id], name: 'idx_agentos_audit_target'
    add_index :redmineflux_agentos_audit_logs, :user_id

    add_foreign_key :redmineflux_agentos_audit_logs, :users, column: :user_id
  end
end
