# frozen_string_literal: true

class CreateRedminefluxAgentosDependencies < ActiveRecord::Migration[6.1]
  def change
    create_table :redmineflux_agentos_dependencies do |t|
      t.references :ai_task, null: false, index: false, foreign_key: { to_table: :redmineflux_agentos_ai_tasks }
      t.references :depends_on_ai_task, null: false, foreign_key: { to_table: :redmineflux_agentos_ai_tasks }
      t.string :dependency_type, null: false

      t.datetime :created_at, null: false
    end

    add_index :redmineflux_agentos_dependencies, %i[ai_task_id depends_on_ai_task_id],
              unique: true, name: 'idx_agentos_deps_task_prereq'
  end
end
