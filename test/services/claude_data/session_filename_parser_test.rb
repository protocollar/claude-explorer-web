require "test_helper"

module ClaudeData
  class SessionFilenameParserTest < ActiveSupport::TestCase
    test "session_id returns filename without extension" do
      parser = SessionFilenameParser.new("/path/to/abc123-def456.jsonl")

      assert_equal "abc123-def456", parser.session_id
    end

    test "agent? returns true for agent files" do
      parser = SessionFilenameParser.new("/path/to/agent-abc123.jsonl")

      assert parser.agent?
    end

    test "agent? returns false for regular session files" do
      parser = SessionFilenameParser.new("/path/to/abc123-def456.jsonl")

      assert_not parser.agent?
    end

    test "agent_id returns id for agent files" do
      parser = SessionFilenameParser.new("/path/to/agent-abc123.jsonl")

      assert_equal "abc123", parser.agent_id
    end

    test "agent_id returns nil for regular session files" do
      parser = SessionFilenameParser.new("/path/to/abc123-def456.jsonl")

      assert_nil parser.agent_id
    end
  end
end
