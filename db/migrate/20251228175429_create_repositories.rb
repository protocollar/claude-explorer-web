class CreateRepositories < ActiveRecord::Migration[8.1]
  def change
    create_table :repositories do |t|
      t.string :git_common_dir, null: false
      t.string :remote_url
      t.string :normalized_url
      t.string :provider

      t.timestamps
    end

    add_index :repositories, :git_common_dir, unique: true
    add_index :repositories, :normalized_url
  end
end
