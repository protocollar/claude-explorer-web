module ProjectSessionScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_project_session
  end

  private
    def set_project_session
      @project_session = ProjectSession.find(params[:project_session_id])
    end
end
