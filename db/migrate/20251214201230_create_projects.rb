class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :path, null: false
      t.string :name
      t.string :encoded_path, null: false
      t.decimal :last_cost, precision: 10, scale: 2
      t.string :last_session_id
      t.json :last_model_usage, default: {}

      t.timestamps
    end
    add_index :projects, :path, unique: true
  end
end
