require "test_helper"

class ProjectSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:claude_explorer)
    @project_session = project_sessions(:main_session)
  end

  test "index returns success" do
    get project_project_sessions_path(@project)
    assert_response :success
  end

  test "index displays sessions" do
    get project_project_sessions_path(@project)
    assert_select ".session-card", minimum: 1
  end

  test "show returns success with project scope" do
    get project_project_session_path(@project, @project_session)
    assert_response :success
  end

  test "show returns success with standalone route" do
    get project_session_path(@project_session)
    assert_response :success
  end

  test "show displays messages" do
    get project_session_path(@project_session)
    assert_select ".message", minimum: 1
  end

  test "show returns not found for invalid session" do
    get project_session_path(id: 99999)
    assert_response :not_found
  end
end
