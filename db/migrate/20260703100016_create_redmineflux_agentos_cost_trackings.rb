# frozen_string_literal: true

class CreateRedminefluxAgentosCostTrackings < ActiveRecord::Migration[6.1]
  def change
    create_table :redmineflux_agentos_cost_trackings do |t|
      t.bigint :project_id
      t.date :period, null: false
      t.string :provider
      t.string :model
      t.bigint :total_tokens
      t.decimal :total_cost, precision: 12, scale: 4, null: false, default: 0
      t.string :currency, null: false, default: 'USD'

      t.timestamps null: false
    end

    add_index :redmineflux_agentos_cost_trackings, %i[project_id period],
              unique: true, name: 'idx_agentos_cost_project_period'

    add_foreign_key :redmineflux_agentos_cost_trackings, :projects, column: :project_id
  end
end
