class ProjectSessionsController < ApplicationController
  def index
    @project = Project.find(params[:project_id])
    set_page_and_extract_portion_from @project.project_sessions.main_sessions.ordered.includes(:child_sessions)
  end

  def show
    @project_session = ProjectSession.find(params[:id])
    set_page_and_extract_portion_from @project_session.messages.ordered.includes(:tool_uses, :parent_message, :child_messages)
  end
end
