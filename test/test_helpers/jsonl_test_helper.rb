module JsonlTestHelper
  def create_jsonl_file(records, filename: "test_session.jsonl")
    dir = Dir.mktmpdir
    file = File.join(dir, filename)
    File.write(file, records.map(&:to_json).join("\n"))
    file
  end

  def create_raw_jsonl_file(lines, filename: "test_session.jsonl")
    dir = Dir.mktmpdir
    file = File.join(dir, filename)
    File.write(file, lines.join("\n"))
    file
  end

  def user_message(uuid:, parent_uuid: nil, content: "Test message", timestamp: "2024-01-15T10:00:00Z", **opts)
    content_value = content.is_a?(Array) ? content : [ { "type" => "text", "text" => content } ]
    {
      "type" => "user",
      "uuid" => uuid,
      "parentUuid" => parent_uuid,
      "timestamp" => timestamp,
      "gitBranch" => opts[:git_branch] || "main",
      "cwd" => opts[:cwd] || "/test/project",
      "version" => opts[:version] || "1.0.0",
      "message" => {
        "role" => "user",
        "content" => content_value,
        "usage" => {
          "input_tokens" => opts[:input_tokens] || 10,
          "output_tokens" => opts[:output_tokens] || 0,
          "cache_read_input_tokens" => opts[:cache_read_tokens] || 0,
          "cache_creation_input_tokens" => opts[:cache_creation_tokens] || 0
        }
      }
    }
  end

  def assistant_message(uuid:, parent_uuid: nil, content: nil, timestamp: "2024-01-15T10:00:01Z", **opts)
    content ||= [ { "type" => "text", "text" => "Assistant response" } ]
    content_value = content.is_a?(Array) ? content : [ { "type" => "text", "text" => content } ]
    {
      "type" => "assistant",
      "uuid" => uuid,
      "parentUuid" => parent_uuid,
      "timestamp" => timestamp,
      "message" => {
        "role" => "assistant",
        "model" => opts[:model] || "claude-3-opus-20240229",
        "content" => content_value,
        "usage" => {
          "input_tokens" => opts[:input_tokens] || 20,
          "output_tokens" => opts[:output_tokens] || 100,
          "cache_read_input_tokens" => opts[:cache_read_tokens] || 0,
          "cache_creation_input_tokens" => opts[:cache_creation_tokens] || 0
        }
      }
    }
  end

  def summary_record(text)
    { "type" => "summary", "summary" => text }
  end
end
