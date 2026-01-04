class SessionPlansController < ApplicationController
  def index
    set_page_and_extract_portion_from SessionPlan.includes(:project_session).ordered
  end

  def show
    @session_plan = SessionPlan.find(params[:id])
  end
end
