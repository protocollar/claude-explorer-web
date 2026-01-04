class ProjectsController < ApplicationController
  def index
    projects = Project.ordered.includes(:project_sessions)
    projects = projects.with_sessions unless show_empty?
    @show_empty = show_empty?
    set_page_and_extract_portion_from projects
  end

  def show
    @project = Project.find(params[:id])
    set_page_and_extract_portion_from @project.project_sessions.main_sessions.ordered
  end

  private
    def show_empty?
      params[:show_empty] == "true"
    end
end
