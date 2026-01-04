class CreateToolUses < ActiveRecord::Migration[8.1]
  def change
    create_table :tool_uses do |t|
      t.references :message, null: false, foreign_key: true
      t.string :tool_use_id, null: false
      t.string :tool_name, null: false
      t.json :input, default: {}
      t.json :result
      t.boolean :success

      t.timestamps
    end
    add_index :tool_uses, :tool_use_id, unique: true
    add_index :tool_uses, :tool_name
  end
end
