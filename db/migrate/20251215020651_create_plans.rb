class CreatePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :plans do |t|
      t.string :slug, null: false
      t.string :title
      t.text :content
      t.references :session, null: true, foreign_key: true
      t.datetime :file_created_at

      t.timestamps
    end
    add_index :plans, :slug, unique: true
  end
end
