module ClaudeData
  # Extracts session metadata from JSONL filenames.
  class SessionFilenameParser
    def initialize(file_path)
      @filename = File.basename(file_path, ".jsonl")
    end

    def session_id
      @filename
    end

    def agent?
      @filename.start_with?("agent-")
    end

    def agent_id
      return unless agent?

      @filename.delete_prefix("agent-")
    end
  end
end
