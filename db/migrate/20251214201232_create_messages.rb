class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :session, null: false, foreign_key: true
      t.string :uuid, null: false
      t.string :parent_uuid
      t.references :parent_message, foreign_key: { to_table: :messages }
      t.string :message_type, null: false
      t.string :role
      t.string :model
      t.json :content, default: []
      t.integer :input_tokens, default: 0
      t.integer :output_tokens, default: 0
      t.integer :cache_read_tokens, default: 0
      t.integer :cache_creation_tokens, default: 0
      t.boolean :is_sidechain, default: false
      t.boolean :has_thinking, default: false
      t.json :thinking_metadata, default: {}
      t.json :todos, default: []
      t.datetime :timestamp, null: false

      t.timestamps
    end
    add_index :messages, :uuid, unique: true
    add_index :messages, :parent_uuid
    add_index :messages, :message_type
    add_index :messages, [ :session_id, :timestamp ]
  end
end
