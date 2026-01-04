require "test_helper"

class ToolUseTest < ActiveSupport::TestCase
  setup do
    @read_tool = tool_uses(:read_model)
    @bash_tool = tool_uses(:bash_short)
    @grep_tool = tool_uses(:grep_with_path)
  end

  # Associations
  test "belongs to message" do
    assert_equal messages(:assistant_with_tool), @read_tool.message
  end

  test "has one project_session through message" do
    assert_equal project_sessions(:main_session), @read_tool.project_session
  end

  test "has one project through project_session" do
    assert_equal projects(:claude_explorer), @read_tool.project
  end

  # Scopes
  test "ordered returns tool uses by created_at desc" do
    ordered = ToolUse.ordered
    timestamps = ordered.pluck(:created_at)
    assert_equal timestamps.sort.reverse, timestamps
  end

  test "by_tool filters by tool_name" do
    reads = ToolUse.by_tool("Read")
    reads.each do |tool_use|
      assert_equal "Read", tool_use.tool_name
    end
  end

  test "successful returns only success true" do
    ToolUse.successful.each do |tool_use|
      assert tool_use.success
    end
  end

  test "failed returns only success false" do
    ToolUse.failed.each do |tool_use|
      assert_not tool_use.success
    end
  end

  # usage_counts class method
  test "usage_counts returns array of tool name counts" do
    counts = ToolUse.usage_counts
    assert counts.is_a?(Array)
  end

  test "usage_counts is sorted by count descending" do
    counts = ToolUse.usage_counts
    values = counts.map(&:last)
    assert_equal values.sort.reverse, values
  end

  # display_input - Read tool
  test "display_input for Read returns file_path" do
    assert_equal "/app/models/user.rb", @read_tool.display_input
  end

  # display_input - Write tool
  test "display_input for Write returns file_path" do
    assert_equal "/app/models/post.rb", tool_uses(:write_model).display_input
  end

  # display_input - Edit tool
  test "display_input for Edit returns file_path" do
    assert_equal "/app/controllers/users_controller.rb", tool_uses(:edit_controller).display_input
  end

  # display_input - Bash tool
  test "display_input for Bash returns command" do
    assert_equal "bin/rails test", @bash_tool.display_input
  end

  test "display_input for Bash truncates long commands" do
    long_tool = tool_uses(:bash_long)
    result = long_tool.display_input
    assert result.length <= 100
  end

  # display_input - Grep tool
  test "display_input for Grep includes pattern and path" do
    assert_equal "validates in /app/models", @grep_tool.display_input
  end

  test "display_input for Grep uses dot when path is nil" do
    assert_equal "def create in .", tool_uses(:grep_no_path).display_input
  end

  # display_input - Glob tool
  test "display_input for Glob returns pattern" do
    assert_equal "**/*.rb", tool_uses(:glob_pattern).display_input
  end

  # display_input - Unknown tool
  test "display_input for unknown tool returns truncated JSON" do
    unknown = tool_uses(:unknown_tool)
    result = unknown.display_input
    assert result.length <= 100
    assert_match(/"complex"/, result)
  end
end
