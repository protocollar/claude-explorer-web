class RenameSessionsAndPlansTables < ActiveRecord::Migration[8.1]
  def change
    # Rename sessions table to project_sessions
    rename_table :sessions, :project_sessions

    # Rename plans table to session_plans
    rename_table :plans, :session_plans

    # Update foreign key columns to match new table names
    rename_column :messages, :session_id, :project_session_id
    rename_column :session_plans, :session_id, :project_session_id

    # Update self-referential foreign key in project_sessions
    rename_column :project_sessions, :parent_session_id, :parent_project_session_id
  end
end
