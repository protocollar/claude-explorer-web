module ClaudeData
  # Builds Message attributes from a parsed JSONL record.
  class MessageBuilder
    def initialize(record)
      @record = record
    end

    def attributes
      content = normalize_content

      {
        parent_uuid: @record["parentUuid"],
        message_type: @record["type"],
        role: @record.dig("message", "role"),
        model: @record.dig("message", "model"),
        content: content,
        is_sidechain: @record["isSidechain"] || false,
        has_thinking: has_thinking_content?(content),
        thinking_metadata: @record["thinkingMetadata"] || {},
        todos: @record["todos"] || [],
        timestamp: Time.parse(@record["timestamp"]),
        input_tokens: @record.dig("message", "usage", "input_tokens") || 0,
        output_tokens: @record.dig("message", "usage", "output_tokens") || 0,
        cache_read_tokens: @record.dig("message", "usage", "cache_read_input_tokens") || 0,
        cache_creation_tokens: @record.dig("message", "usage", "cache_creation_input_tokens") || 0
      }
    end

    private

    def normalize_content
      content = @record.dig("message", "content")

      case content
      when Array
        content
      when String
        [ { "type" => "text", "text" => content } ]
      else
        []
      end
    end

    def has_thinking_content?(content)
      content.any? { |block| block["type"] == "thinking" }
    end
  end
end
