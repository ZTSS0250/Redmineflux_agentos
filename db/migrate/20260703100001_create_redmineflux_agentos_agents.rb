# frozen_string_literal: true

class CreateRedminefluxAgentosAgents < ActiveRecord::Migration[6.1]
  def change
    create_table :redmineflux_agentos_agents do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.text :role_description
      t.string :status, null: false, default: 'enabled'
      t.text :config_json

      t.timestamps null: false
    end

    add_index :redmineflux_agentos_agents, :key, unique: true
  end
end
