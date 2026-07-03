# frozen_string_literal: true

class CreateRedminefluxAgentosSprints < ActiveRecord::Migration[6.1]
  def change
    create_table :redmineflux_agentos_sprints do |t|
      t.references :release, null: false, index: false, foreign_key: { to_table: :redmineflux_agentos_releases }
      t.string :name, null: false
      t.date :start_date
      t.date :end_date
      t.string :status, null: false, default: 'planned'

      t.timestamps null: false
    end

    add_index :redmineflux_agentos_sprints, %i[release_id status], name: 'idx_agentos_sprints_release_status'
  end
end
