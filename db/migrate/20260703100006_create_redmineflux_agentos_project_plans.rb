# frozen_string_literal: true

class CreateRedminefluxAgentosProjectPlans < ActiveRecord::Migration[6.1]
  def change
    create_table :redmineflux_agentos_project_plans do |t|
      t.bigint :project_id
      t.references :conversation, null: false, foreign_key: { to_table: :redmineflux_agentos_conversations }
      t.integer :version, null: false
      t.text :srs_markdown
      t.text :srs_json
      t.string :status, null: false, default: 'draft'
      t.bigint :approved_by_id
      t.datetime :approved_at

      t.timestamps null: false
    end

    add_index :redmineflux_agentos_project_plans, %i[project_id status], name: 'idx_agentos_plans_project_status'

    add_foreign_key :redmineflux_agentos_project_plans, :projects, column: :project_id
    add_foreign_key :redmineflux_agentos_project_plans, :users, column: :approved_by_id
  end
end
