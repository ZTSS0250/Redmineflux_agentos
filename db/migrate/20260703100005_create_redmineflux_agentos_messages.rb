# frozen_string_literal: true

class CreateRedminefluxAgentosMessages < ActiveRecord::Migration[6.1]
  def change
    create_table :redmineflux_agentos_messages do |t|
      t.references :conversation, null: false, index: false,
                                   foreign_key: { to_table: :redmineflux_agentos_conversations }
      t.string :role, null: false
      t.references :agent, foreign_key: { to_table: :redmineflux_agentos_agents }
      t.text :content, null: false
      t.integer :tokens_used

      t.datetime :created_at, null: false
    end

    add_index :redmineflux_agentos_messages, %i[conversation_id created_at], name: 'idx_agentos_messages_convo_created'
  end
end
