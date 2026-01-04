class CreateFolders < ActiveRecord::Migration[8.1]
  def change
    create_table :folders do |t|
      t.string :canonical_path, null: false

      t.timestamps
    end

    add_index :folders, :canonical_path, unique: true
  end
end
