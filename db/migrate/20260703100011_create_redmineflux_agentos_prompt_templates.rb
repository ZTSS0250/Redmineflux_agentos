# frozen_string_literal: true

class CreateRedminefluxAgentosPromptTemplates < ActiveRecord::Migration[6.1]
  def change
    create_table :redmineflux_agentos_prompt_templates do |t|
      t.string :key, null: false
      t.references :agent, foreign_key: { to_table: :redmineflux_agentos_agents }
      t.integer :version, null: false
      t.text :content, null: false
      t.text :variables_json
      # "One active version per key" is intentionally NOT a DB constraint
      # here (no partial unique index) — enforced at the application layer
      # per docs/PHASE4-DATABASE-DESIGN.md §5's MySQL-portability decision.
      t.boolean :is_active, null: false, default: false
      t.bigint :created_by_id, null: false

      t.timestamps null: false
    end

    add_index :redmineflux_agentos_prompt_templates, %i[key is_active], name: 'idx_agentos_prompts_key_active'
    add_index :redmineflux_agentos_prompt_templates, :created_by_id

    add_foreign_key :redmineflux_agentos_prompt_templates, :users, column: :created_by_id
  end
end
