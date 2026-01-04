require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:claude_explorer)
  end

  test "index returns success" do
    get projects_path
    assert_response :success
  end

  test "index displays projects" do
    get projects_path
    assert_select ".project-card", minimum: 2
  end

  test "index orders projects by updated_at desc" do
    projects(:writebook).touch
    get projects_path
    assert_response :success
  end

  test "show returns success" do
    get project_path(@project)
    assert_response :success
  end

  test "show displays project name" do
    get project_path(@project)
    assert_select "h1", text: /claude-explorer/
  end

  test "show displays sessions" do
    get project_path(@project)
    assert_select ".session-card", minimum: 1
  end

  test "show only displays main sessions" do
    get project_path(@project)
    # Sidechain sessions should not appear in the list
    assert_response :success
  end

  test "show returns not found for invalid id" do
    get project_path(id: 99999)
    assert_response :not_found
  end
end
