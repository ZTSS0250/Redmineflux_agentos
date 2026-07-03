# frozen_string_literal: true

class CreateRedminefluxAgentosExecutionLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :redmineflux_agentos_execution_logs do |t|
      t.references :agent_run, null: false, foreign_key: { to_table: :redmineflux_agentos_agent_runs }
      t.string :level, null: false
      t.text :message, null: false
      t.text :metadata_json

      t.datetime :created_at, null: false
    end
  end
end
