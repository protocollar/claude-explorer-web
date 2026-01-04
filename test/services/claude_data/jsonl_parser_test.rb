require "test_helper"

module ClaudeData
  class JsonlParserTest < ActiveSupport::TestCase
    setup do
      @project = projects(:empty_project)
    end

    test "creates session from first message" do
      file = create_jsonl_file([
        user_message(uuid: "parser-msg-1", git_branch: "feature/test")
      ])

      assert_difference -> { @project.project_sessions.count }, 1 do
        JsonlParser.new(@project, file).import
      end

      project_session = @project.project_sessions.last
      assert_equal "feature/test", project_session.git_branch
    end

    test "creates messages from records" do
      file = create_jsonl_file([
        user_message(uuid: "parser-msg-1"),
        assistant_message(uuid: "parser-msg-2", parent_uuid: "parser-msg-1")
      ])

      JsonlParser.new(@project, file).import

      assert_equal 2, @project.project_sessions.last.messages.count
    end

    test "normalizes string content to array" do
      file = create_jsonl_file([
        user_message(uuid: "parser-string-msg", content: "Plain string content")
      ])

      JsonlParser.new(@project, file).import

      message = @project.messages.last
      assert message.content.is_a?(Array)
      assert_equal "text", message.content.first["type"]
      assert_equal "Plain string content", message.content.first["text"]
    end

    test "preserves array content" do
      content = [ { "type" => "text", "text" => "Already array" } ]
      file = create_jsonl_file([
        user_message(uuid: "parser-array-msg", content: content)
      ])

      JsonlParser.new(@project, file).import

      message = @project.messages.last
      assert_equal content, message.content
    end

    test "extracts tool uses from assistant messages" do
      tool_content = [
        { "type" => "text", "text" => "Let me check" },
        { "type" => "tool_use", "id" => "parser-tool-1", "name" => "Read", "input" => { "file_path" => "/test.rb" } }
      ]
      file = create_jsonl_file([
        assistant_message(uuid: "parser-tool-msg", content: tool_content)
      ])

      JsonlParser.new(@project, file).import

      message = @project.messages.last
      assert_equal 1, message.tool_uses.count
      assert_equal "Read", message.tool_uses.first.tool_name
    end

    test "links tool results to tool uses" do
      file = create_jsonl_file([
        assistant_message(uuid: "parser-tool-msg-2", content: [
          { "type" => "tool_use", "id" => "parser-tool-2", "name" => "Read", "input" => {} }
        ]),
        user_message(uuid: "parser-result-msg", parent_uuid: "parser-tool-msg-2", content: [
          { "type" => "tool_result", "tool_use_id" => "parser-tool-2", "content" => "file contents", "is_error" => false }
        ])
      ])

      JsonlParser.new(@project, file).import

      tool_use = ToolUse.find_by(tool_use_id: "parser-tool-2")
      assert_equal "file contents", tool_use.result
      assert tool_use.success
    end

    test "marks tool result as failed when is_error true" do
      file = create_jsonl_file([
        assistant_message(uuid: "parser-error-tool-msg", content: [
          { "type" => "tool_use", "id" => "parser-error-tool", "name" => "Bash", "input" => {} }
        ]),
        user_message(uuid: "parser-error-result", parent_uuid: "parser-error-tool-msg", content: [
          { "type" => "tool_result", "tool_use_id" => "parser-error-tool", "content" => "command failed", "is_error" => true }
        ])
      ])

      JsonlParser.new(@project, file).import

      tool_use = ToolUse.find_by(tool_use_id: "parser-error-tool")
      assert_not tool_use.success
    end

    test "stores summary from summary record" do
      file = create_jsonl_file([
        summary_record("Test session summary"),
        user_message(uuid: "parser-summary-msg")
      ])

      JsonlParser.new(@project, file).import

      assert_equal "Test session summary", @project.project_sessions.last.summary
    end

    test "detects sidechain from agent filename" do
      file = create_jsonl_file(
        [ user_message(uuid: "agent-msg-1") ],
        filename: "agent-abc123.jsonl"
      )

      JsonlParser.new(@project, file).import

      project_session = @project.project_sessions.last
      assert project_session.is_sidechain
      assert_equal "abc123", project_session.agent_id
    end

    test "skips already imported sessions" do
      # First import
      file = create_jsonl_file(
        [ user_message(uuid: "skip-msg-1") ],
        filename: "skip-session.jsonl"
      )
      JsonlParser.new(@project, file).import
      initial_count = Message.count

      # Second import with same file should be skipped
      JsonlParser.new(@project, file).import

      assert_equal initial_count, Message.count
    end

    test "handles malformed JSON lines gracefully" do
      file = create_raw_jsonl_file([
        user_message(uuid: "malformed-msg-1").to_json,
        "not valid json {{{",
        assistant_message(uuid: "malformed-msg-2", parent_uuid: "malformed-msg-1").to_json
      ])

      assert_nothing_raised do
        JsonlParser.new(@project, file).import
      end

      # Should still have imported the valid messages
      assert_equal 2, @project.project_sessions.last.messages.count
    end

    test "detects has_thinking from content blocks" do
      thinking_content = [
        { "type" => "thinking", "thinking" => "Let me consider..." },
        { "type" => "text", "text" => "Answer" }
      ]
      file = create_jsonl_file([
        assistant_message(uuid: "thinking-msg", content: thinking_content)
      ])

      JsonlParser.new(@project, file).import

      message = @project.messages.last
      assert message.has_thinking
    end

    test "calculates session token totals on finalize" do
      file = create_jsonl_file([
        user_message(uuid: "tokens-msg-1", input_tokens: 100, output_tokens: 0),
        assistant_message(uuid: "tokens-msg-2", input_tokens: 50, output_tokens: 200)
      ])

      JsonlParser.new(@project, file).import

      project_session = @project.project_sessions.last
      assert_equal 150, project_session.total_input_tokens
      assert_equal 200, project_session.total_output_tokens
    end

    test "sets session ended_at to latest message timestamp" do
      file = create_jsonl_file([
        user_message(uuid: "time-msg-1", timestamp: "2024-01-15T10:00:00Z"),
        assistant_message(uuid: "time-msg-2", timestamp: "2024-01-15T10:05:00Z")
      ])

      JsonlParser.new(@project, file).import

      project_session = @project.project_sessions.last
      assert_equal Time.parse("2024-01-15T10:05:00Z"), project_session.ended_at
    end

    test "resolves parent message references after import" do
      file = create_jsonl_file([
        user_message(uuid: "parent-ref-1"),
        assistant_message(uuid: "parent-ref-2", parent_uuid: "parent-ref-1")
      ])

      JsonlParser.new(@project, file).import

      child = @project.messages.find_by(uuid: "parent-ref-2")
      parent = @project.messages.find_by(uuid: "parent-ref-1")
      assert_equal parent, child.parent_message
    end
  end
end
