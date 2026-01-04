require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  setup do
    @project = projects(:claude_explorer)
  end

  # Validations
  test "valid with all required attributes" do
    assert @project.valid?
  end

  test "requires path" do
    @project.path = nil
    assert_not @project.valid?
  end

  test "requires unique path" do
    duplicate = Project.new(path: @project.path, encoded_path: "-other-path")
    assert_not duplicate.valid?
  end

  test "requires encoded_path" do
    @project.encoded_path = nil
    assert_not @project.valid?
  end

  # Associations
  test "belongs to project_group optionally" do
    assert_equal project_groups(:claude_explorer_group), @project.project_group
  end

  test "project without group is valid" do
    project = projects(:writebook)
    assert_nil project.project_group
    assert project.valid?
  end

  test "has many project_sessions" do
    assert_includes @project.project_sessions, project_sessions(:main_session)
  end

  test "has many messages through project_sessions" do
    assert_includes @project.messages, messages(:user_question)
  end

  test "has many tool_uses through messages" do
    assert_includes @project.tool_uses, tool_uses(:read_model)
  end

  test "destroying project destroys project_sessions" do
    assert_difference -> { ProjectSession.count }, -@project.project_sessions.count do
      @project.destroy
    end
  end

  # Scopes
  test "ordered returns projects by updated_at desc" do
    projects(:writebook).touch
    assert_equal projects(:writebook), Project.ordered.first
  end

  test "with_group returns only projects with project_group" do
    with_group = Project.with_group
    assert_includes with_group, projects(:claude_explorer)
    assert_not_includes with_group, projects(:writebook)
  end

  test "without_group returns only projects without project_group" do
    without_group = Project.without_group
    assert_includes without_group, projects(:writebook)
    assert_not_includes without_group, projects(:claude_explorer)
  end

  # name method
  test "name returns stored name when present" do
    assert_equal "claude-explorer", @project.name
  end

  test "name returns path basename when name is nil" do
    project = projects(:empty_project)
    assert_equal "empty", project.name
  end

  # conversation_files_path method
  test "conversation_files_path returns expanded path with encoded_path" do
    expected = File.expand_path("~/.claude/projects/-Users-test-Code-claude-explorer")
    assert_equal expected, @project.conversation_files_path
  end

  # main_sessions method
  test "main_sessions returns only non-sidechain sessions" do
    main = @project.main_sessions
    assert_includes main, project_sessions(:main_session)
    assert_not_includes main, project_sessions(:agent_sidechain)
  end

  # total_tokens method
  test "total_tokens sums input and output tokens from all project_sessions" do
    expected = @project.project_sessions.sum(:total_input_tokens) + @project.project_sessions.sum(:total_output_tokens)
    assert_equal expected, @project.total_tokens
  end

  test "total_tokens returns 0 for project with no sessions" do
    project = projects(:empty_project)
    assert_equal 0, project.total_tokens
  end
end
