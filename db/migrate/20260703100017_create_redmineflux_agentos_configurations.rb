# frozen_string_literal: true

# NOTE: this table intentionally has only `updated_at`, not `created_at` —
# docs/DATABASE-SCHEMA.md defines it as a mutable "current setting" row
# (docs/PHASE4-DATABASE-DESIGN.md §11 Versioning Strategy: configuration
# values are mutated in place, not versioned, so only "last changed" has
# product value). This is a deliberate reading of the approved spec, not an
# oversight.
class CreateRedminefluxAgentosConfigurations < ActiveRecord::Migration[6.1]
  def change
    create_table :redmineflux_agentos_configurations do |t|
      t.bigint :project_id
      t.string :key, null: false
      t.text :value_json
      t.bigint :updated_by_id, null: false
      t.datetime :updated_at, null: false
    end

    add_index :redmineflux_agentos_configurations, %i[project_id key],
              unique: true, name: 'idx_agentos_config_project_key'
    add_index :redmineflux_agentos_configurations, :updated_by_id

    add_foreign_key :redmineflux_agentos_configurations, :projects, column: :project_id
    add_foreign_key :redmineflux_agentos_configurations, :users, column: :updated_by_id
  end
end
