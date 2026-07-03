# frozen_string_literal: true

class CreateRedminefluxAgentosKnowledgeBaseEntries < ActiveRecord::Migration[6.1]
  def change
    create_table :redmineflux_agentos_knowledge_base_entries do |t|
      t.bigint :project_id
      t.string :title, null: false
      t.text :content
      t.string :source_type, null: false
      t.string :tags

      t.timestamps null: false
    end

    add_index :redmineflux_agentos_knowledge_base_entries, :project_id

    add_foreign_key :redmineflux_agentos_knowledge_base_entries, :projects, column: :project_id
  end
end
