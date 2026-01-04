require "test_helper"

class ProjectGroupTest < ActiveSupport::TestCase
  test "delegates display_name to sourceable" do
    repo_group = project_groups(:claude_explorer_group)
    assert_equal repo_group.sourceable.display_name, repo_group.display_name
  end

  test "repositories scope returns only repository-backed groups" do
    repo_groups = ProjectGroup.repositories
    assert repo_groups.all? { |g| g.sourceable_type == "Repository" }
    assert_includes repo_groups, project_groups(:claude_explorer_group)
    assert_not_includes repo_groups, project_groups(:documents_group)
  end

  test "folders scope returns only folder-backed groups" do
    folder_groups = ProjectGroup.folders
    assert folder_groups.all? { |g| g.sourceable_type == "Folder" }
    assert_includes folder_groups, project_groups(:documents_group)
    assert_not_includes folder_groups, project_groups(:claude_explorer_group)
  end

  test "sourceable association works with Repository" do
    group = project_groups(:claude_explorer_group)
    assert_instance_of Repository, group.sourceable
    assert group.repository?
  end

  test "sourceable association works with Folder" do
    group = project_groups(:documents_group)
    assert_instance_of Folder, group.sourceable
    assert group.folder?
  end
end
