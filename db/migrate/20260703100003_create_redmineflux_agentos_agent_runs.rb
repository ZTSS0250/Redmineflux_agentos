# frozen_string_literal: true

class CreateRedminefluxAgentosAgentRuns < ActiveRecord::Migration[6.1]
  def change
    create_table :redmineflux_agentos_agent_runs do |t|
      t.references :agent, null: false, index: false, foreign_key: { to_table: :redmineflux_agentos_agents }
      t.bigint :project_id, null: false
      t.bigint :issue_id
      t.references :conversation, foreign_key: { to_table: :redmineflux_agentos_conversations }
      t.string :status, null: false
      t.bigint :blocking_issue_id
      t.integer :attempts, null: false, default: 0
      t.integer :max_attempts, null: false, default: 3
      t.text :input_json
      t.text :output_json
      t.text :error_message
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps null: false
    end

    add_index :redmineflux_agentos_agent_runs, :status
    add_index :redmineflux_agentos_agent_runs, %i[agent_id status], name: 'idx_agentos_runs_agent_status'
    add_index :redmineflux_agentos_agent_runs, %i[project_id status], name: 'idx_agentos_runs_project_status'
    add_index :redmineflux_agentos_agent_runs, :issue_id
    add_index :redmineflux_agentos_agent_runs, :blocking_issue_id

    add_foreign_key :redmineflux_agentos_agent_runs, :projects, column: :project_id
    add_foreign_key :redmineflux_agentos_agent_runs, :issues, column: :issue_id
    add_foreign_key :redmineflux_agentos_agent_runs, :issues, column: :blocking_issue_id
  end
end
