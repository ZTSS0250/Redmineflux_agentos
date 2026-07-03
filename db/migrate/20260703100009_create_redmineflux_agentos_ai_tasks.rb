# frozen_string_literal: true

class CreateRedminefluxAgentosAiTasks < ActiveRecord::Migration[6.1]
  def change
    create_table :redmineflux_agentos_ai_tasks do |t|
      t.bigint :project_id, null: false
      t.bigint :issue_id
      t.references :sprint, foreign_key: { to_table: :redmineflux_agentos_sprints }
      t.references :agent, null: false, foreign_key: { to_table: :redmineflux_agentos_agents }
      t.bigint :suggested_reviewer_id
      t.string :task_type, null: false
      t.string :title, null: false
      t.text :description
      t.text :acceptance_criteria
      t.string :priority
      t.integer :story_points
      t.decimal :estimated_hours
      t.string :labels
      t.string :status, null: false

      t.timestamps null: false
    end

    add_index :redmineflux_agentos_ai_tasks, %i[project_id status], name: 'idx_agentos_tasks_project_status'
    add_index :redmineflux_agentos_ai_tasks, :issue_id

    add_foreign_key :redmineflux_agentos_ai_tasks, :projects, column: :project_id
    add_foreign_key :redmineflux_agentos_ai_tasks, :issues, column: :issue_id
    add_foreign_key :redmineflux_agentos_ai_tasks, :users, column: :suggested_reviewer_id
  end
end
