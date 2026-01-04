class ProjectGroupsController < ApplicationController
  def index
    project_groups = ProjectGroup.includes(:sourceable, :projects).order(updated_at: :desc)
    project_groups = project_groups.with_sessions unless show_empty?
    @show_empty = show_empty?
    set_page_and_extract_portion_from project_groups
  end

  def show
    @project_group = ProjectGroup.includes(:sourceable).find(params[:id])
    set_page_and_extract_portion_from @project_group.projects.ordered.includes(:project_sessions)
  end

  private
    def show_empty?
      params[:show_empty] == "true"
    end
end
