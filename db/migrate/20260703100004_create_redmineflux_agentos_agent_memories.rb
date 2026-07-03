# frozen_string_literal: true

class CreateRedminefluxAgentosAgentMemories < ActiveRecord::Migration[6.1]
  def change
    create_table :redmineflux_agentos_agent_memories do |t|
      t.references :agent, null: false, index: false, foreign_key: { to_table: :redmineflux_agentos_agents }
      t.bigint :project_id
      t.string :scope, null: false
      t.string :key, null: false
      t.text :value_json
      t.datetime :expires_at

      t.timestamps null: false
    end

    add_index :redmineflux_agentos_agent_memories, %i[agent_id project_id scope key],
              unique: true, name: 'idx_agentos_memories_unique_key'

    add_foreign_key :redmineflux_agentos_agent_memories, :projects, column: :project_id
  end
end
