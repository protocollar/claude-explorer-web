class ProjectSessions::TreesController < ApplicationController
  include ProjectSessionScoped

  def show
    @root_messages = @project_session.messages.root_messages.ordered.includes(:child_messages, :tool_uses)
  end
end
