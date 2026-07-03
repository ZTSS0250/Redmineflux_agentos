# frozen_string_literal: true

class CreateRedminefluxAgentosMcpToolCalls < ActiveRecord::Migration[6.1]
  def change
    create_table :redmineflux_agentos_mcp_tool_calls do |t|
      t.references :agent_run, foreign_key: { to_table: :redmineflux_agentos_agent_runs }
      t.bigint :user_id
      t.string :tool_name, null: false
      # Secrets must be redacted before being written here — see
      # docs/DATABASE-SCHEMA.md's Gate 2 design note and docs/MCP-TOOLS.md.
      t.text :params_json
      t.text :result_json
      t.string :status, null: false
      t.boolean :requires_confirmation, null: false, default: false
      t.bigint :confirmed_by_id
      t.integer :duration_ms

      t.datetime :created_at, null: false
    end

    add_index :redmineflux_agentos_mcp_tool_calls, :status

    add_foreign_key :redmineflux_agentos_mcp_tool_calls, :users, column: :user_id
    add_foreign_key :redmineflux_agentos_mcp_tool_calls, :users, column: :confirmed_by_id
  end
end
