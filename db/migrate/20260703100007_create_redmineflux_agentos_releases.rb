# frozen_string_literal: true

class CreateRedminefluxAgentosReleases < ActiveRecord::Migration[6.1]
  def change
    create_table :redmineflux_agentos_releases do |t|
      t.references :project_plan, null: false, index: false,
                                   foreign_key: { to_table: :redmineflux_agentos_project_plans }
      t.bigint :version_id
      t.string :name, null: false
      t.integer :sequence, null: false
      t.string :status, null: false, default: 'planned'

      t.timestamps null: false
    end

    add_index :redmineflux_agentos_releases, %i[project_plan_id sequence], name: 'idx_agentos_releases_plan_seq'
    add_index :redmineflux_agentos_releases, :version_id

    add_foreign_key :redmineflux_agentos_releases, :versions, column: :version_id
  end
end
