class CreateProjectGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :project_groups do |t|
      t.string :sourceable_type, null: false
      t.bigint :sourceable_id, null: false
      t.timestamps
    end

    add_index :project_groups, [ :sourceable_type, :sourceable_id ], unique: true
  end
end
