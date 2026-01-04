require "test_helper"

class ProjectGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project_group = project_groups(:claude_explorer_group)
  end

  test "index returns success" do
    get project_groups_path
    assert_response :success
  end

  test "index displays project groups" do
    get project_groups_path
    assert_select ".project-group-card", minimum: 1
  end

  test "show returns success" do
    get project_group_path(@project_group)
    assert_response :success
  end

  test "show displays group name" do
    get project_group_path(@project_group)
    assert_select "h1", text: /claude-explorer-web/
  end

  test "show displays projects" do
    get project_group_path(@project_group)
    assert_select ".project-card", minimum: 1
  end

  test "show returns not found for invalid id" do
    get project_group_path(id: 99999)
    assert_response :not_found
  end
end
