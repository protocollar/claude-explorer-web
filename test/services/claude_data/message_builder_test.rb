require "test_helper"

module ClaudeData
  class MessageBuilderTest < ActiveSupport::TestCase
    test "builds attributes from record with array content" do
      record = {
        "uuid" => "msg-123",
        "parentUuid" => "msg-parent",
        "type" => "assistant",
        "timestamp" => "2024-01-15T10:30:00Z",
        "message" => {
          "role" => "assistant",
          "model" => "claude-3-opus",
          "content" => [ { "type" => "text", "text" => "Hello" } ],
          "usage" => {
            "input_tokens" => 100,
            "output_tokens" => 50
          }
        }
      }

      attrs = MessageBuilder.new(record).attributes

      assert_equal "msg-parent", attrs[:parent_uuid]
      assert_equal "assistant", attrs[:message_type]
      assert_equal "assistant", attrs[:role]
      assert_equal "claude-3-opus", attrs[:model]
      assert_equal [ { "type" => "text", "text" => "Hello" } ], attrs[:content]
      assert_equal 100, attrs[:input_tokens]
      assert_equal 50, attrs[:output_tokens]
    end

    test "normalizes string content to array format" do
      record = {
        "uuid" => "msg-123",
        "type" => "user",
        "timestamp" => "2024-01-15T10:30:00Z",
        "message" => {
          "role" => "user",
          "content" => "Simple string message"
        }
      }

      attrs = MessageBuilder.new(record).attributes

      assert_equal [ { "type" => "text", "text" => "Simple string message" } ], attrs[:content]
    end

    test "normalizes nil content to empty array" do
      record = {
        "uuid" => "msg-123",
        "type" => "user",
        "timestamp" => "2024-01-15T10:30:00Z",
        "message" => {
          "role" => "user",
          "content" => nil
        }
      }

      attrs = MessageBuilder.new(record).attributes

      assert_equal [], attrs[:content]
    end

    test "detects thinking content" do
      record = {
        "uuid" => "msg-123",
        "type" => "assistant",
        "timestamp" => "2024-01-15T10:30:00Z",
        "message" => {
          "role" => "assistant",
          "content" => [
            { "type" => "thinking", "thinking" => "Let me think..." },
            { "type" => "text", "text" => "Here's my answer" }
          ]
        }
      }

      attrs = MessageBuilder.new(record).attributes

      assert attrs[:has_thinking]
    end

    test "defaults missing tokens to zero" do
      record = {
        "uuid" => "msg-123",
        "type" => "user",
        "timestamp" => "2024-01-15T10:30:00Z",
        "message" => {
          "role" => "user",
          "content" => "Hello"
        }
      }

      attrs = MessageBuilder.new(record).attributes

      assert_equal 0, attrs[:input_tokens]
      assert_equal 0, attrs[:output_tokens]
      assert_equal 0, attrs[:cache_read_tokens]
      assert_equal 0, attrs[:cache_creation_tokens]
    end

    test "extracts cache tokens from usage" do
      record = {
        "uuid" => "msg-123",
        "type" => "assistant",
        "timestamp" => "2024-01-15T10:30:00Z",
        "message" => {
          "role" => "assistant",
          "content" => [],
          "usage" => {
            "input_tokens" => 100,
            "output_tokens" => 50,
            "cache_read_input_tokens" => 25,
            "cache_creation_input_tokens" => 10
          }
        }
      }

      attrs = MessageBuilder.new(record).attributes

      assert_equal 25, attrs[:cache_read_tokens]
      assert_equal 10, attrs[:cache_creation_tokens]
    end

    test "includes optional metadata fields" do
      record = {
        "uuid" => "msg-123",
        "type" => "assistant",
        "timestamp" => "2024-01-15T10:30:00Z",
        "isSidechain" => true,
        "thinkingMetadata" => { "budget" => 1000 },
        "todos" => [ { "task" => "Do something" } ],
        "message" => {
          "role" => "assistant",
          "content" => []
        }
      }

      attrs = MessageBuilder.new(record).attributes

      assert attrs[:is_sidechain]
      assert_equal({ "budget" => 1000 }, attrs[:thinking_metadata])
      assert_equal [ { "task" => "Do something" } ], attrs[:todos]
    end
  end
end
