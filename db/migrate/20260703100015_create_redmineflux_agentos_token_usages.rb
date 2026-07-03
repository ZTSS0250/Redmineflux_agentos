# frozen_string_literal: true

class CreateRedminefluxAgentosTokenUsages < ActiveRecord::Migration[6.1]
  def change
    create_table :redmineflux_agentos_token_usages do |t|
      t.references :agent_run, null: false, foreign_key: { to_table: :redmineflux_agentos_agent_runs }
      t.bigint :project_id, null: false
      t.string :provider, null: false
      t.string :model
      t.integer :prompt_tokens, null: false
      t.integer :completion_tokens, null: false
      t.integer :total_tokens, null: false

      t.datetime :created_at, null: false
    end

    add_index :redmineflux_agentos_token_usages, %i[project_id created_at], name: 'idx_agentos_tok_usages_proj_created'

    add_foreign_key :redmineflux_agentos_token_usages, :projects, column: :project_id
  end
end
