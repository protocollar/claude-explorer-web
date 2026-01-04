require "test_helper"

class MessageTest < ActiveSupport::TestCase
  setup do
    @user_message = messages(:user_question)
    @assistant_message = messages(:assistant_response)
    @tool_message = messages(:assistant_with_tool)
    @thinking_message = messages(:assistant_with_thinking)
    @branch_parent = messages(:branch_parent)
  end

  # Associations
  test "belongs to project_session" do
    assert_equal project_sessions(:main_session), @user_message.project_session
  end

  test "belongs to parent_message when present" do
    assert_equal @user_message, @assistant_message.parent_message
  end

  test "parent_message is optional" do
    assert_nil @user_message.parent_message
    assert @user_message.valid?
  end

  test "has many child_messages" do
    assert_includes @user_message.child_messages, @assistant_message
  end

  test "has many tool_uses" do
    assert_includes @tool_message.tool_uses, tool_uses(:read_model)
  end

  test "destroying message destroys tool_uses" do
    assert_difference -> { ToolUse.count }, -@tool_message.tool_uses.count do
      @tool_message.destroy
    end
  end

  test "destroying message nullifies child_messages" do
    @user_message.destroy
    assert_nil @assistant_message.reload.parent_message_id
  end

  # Scopes
  test "user_messages returns only user type" do
    Message.user_messages.each do |message|
      assert_equal "user", message.message_type
    end
  end

  test "assistant_messages returns only assistant type" do
    Message.assistant_messages.each do |message|
      assert_equal "assistant", message.message_type
    end
  end

  test "ordered returns messages by timestamp asc" do
    ordered = project_sessions(:main_session).messages.ordered
    timestamps = ordered.pluck(:timestamp)
    assert_equal timestamps.sort, timestamps
  end

  test "with_tool_use returns messages that have tool uses" do
    with_tools = Message.with_tool_use
    assert_includes with_tools, @tool_message
  end

  test "with_tool_use excludes messages without tool uses" do
    with_tools = Message.with_tool_use
    assert_not_includes with_tools, @user_message
  end

  test "root_messages returns messages without parent" do
    roots = Message.root_messages
    assert_includes roots, @user_message
    assert_not_includes roots, @assistant_message
  end

  # text_content method
  test "text_content extracts text from content blocks" do
    assert_equal "How do I create a model in Rails?", @user_message.text_content
  end

  test "text_content joins multiple text blocks with newlines" do
    # assistant_with_thinking has thinking + text blocks, but text_content only extracts text type
    assert_match "I suggest adding presence validations", @thinking_message.text_content
  end

  test "text_content ignores non-text blocks" do
    assert_match "Let me read", @tool_message.text_content
    assert_no_match(/tool_use/, @tool_message.text_content)
  end

  # tool_use_blocks method
  test "tool_use_blocks returns tool_use type blocks" do
    blocks = @tool_message.tool_use_blocks
    assert_equal 1, blocks.count
    assert_equal "Read", blocks.first["name"]
  end

  test "tool_use_blocks returns empty array when none" do
    assert_empty @user_message.tool_use_blocks
  end

  # thinking_blocks method
  test "thinking_blocks returns thinking type blocks" do
    blocks = @thinking_message.thinking_blocks
    assert_equal 1, blocks.count
    assert_match "analyze", blocks.first["thinking"]
  end

  test "thinking_blocks returns empty array when none" do
    assert_empty @assistant_message.thinking_blocks
  end

  # tool_result_blocks method
  test "tool_result_blocks returns tool_result type blocks" do
    result_message = messages(:user_tool_result)
    blocks = result_message.tool_result_blocks
    assert_equal 1, blocks.count
  end

  test "tool_result_blocks returns empty array when none" do
    assert_empty @user_message.tool_result_blocks
  end

  # user? method
  test "user? returns true for user messages" do
    assert @user_message.user?
  end

  test "user? returns false for assistant messages" do
    assert_not @assistant_message.user?
  end

  # assistant? method
  test "assistant? returns true for assistant messages" do
    assert @assistant_message.assistant?
  end

  test "assistant? returns false for user messages" do
    assert_not @user_message.assistant?
  end

  # total_tokens method
  test "total_tokens sums input and output tokens" do
    expected = @user_message.input_tokens + @user_message.output_tokens
    assert_equal expected, @user_message.total_tokens
  end

  # truncated_content method
  test "truncated_content respects length parameter" do
    result = @user_message.truncated_content(length: 10)
    assert result.length <= 13  # 10 + "..."
  end

  test "truncated_content uses default length of 200" do
    long_text = "x" * 300
    @user_message.content = [ { "type" => "text", "text" => long_text } ]
    result = @user_message.truncated_content
    assert result.length <= 203
  end

  # branch_count method
  test "branch_count returns number of child messages" do
    assert_equal 2, @branch_parent.branch_count
  end

  test "branch_count returns 0 for leaf messages" do
    assert_equal 0, messages(:branch_child_one).branch_count
  end

  # has_branches? method
  test "has_branches? returns true when more than one child" do
    assert @branch_parent.has_branches?
  end

  test "has_branches? returns false when one or fewer children" do
    assert_not @user_message.has_branches?
  end
end
