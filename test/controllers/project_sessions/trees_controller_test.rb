require "test_helper"

class ProjectSessions::TreesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project_session = project_sessions(:main_session)
  end

  test "show returns success" do
    get project_session_tree_path(@project_session)
    assert_response :success
  end

  test "show displays message tree" do
    get project_session_tree_path(@project_session)
    assert_select ".message-tree"
  end

  test "show returns not found for invalid session" do
    get project_session_tree_path(project_session_id: 99999)
    assert_response :not_found
  end
end
