class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.references :project, null: false, foreign_key: true
      t.string :session_id, null: false
      t.string :summary
      t.string :git_branch
      t.string :cwd
      t.string :claude_version
      t.boolean :is_sidechain, default: false
      t.string :agent_id
      t.references :parent_session, foreign_key: { to_table: :sessions }
      t.datetime :started_at
      t.datetime :ended_at
      t.integer :total_input_tokens, default: 0
      t.integer :total_output_tokens, default: 0
      t.integer :total_cache_read_tokens, default: 0
      t.integer :total_cache_creation_tokens, default: 0
      t.integer :messages_count, default: 0

      t.timestamps
    end
    add_index :sessions, :session_id
    add_index :sessions, [ :project_id, :session_id ], unique: true
  end
end
