module ClaudeData
  # Parses Claude conversation JSONL files and imports messages into the database.
  class JsonlParser
    def initialize(project, file_path)
      @project = project
      @file_path = file_path
      @filename_parser = SessionFilenameParser.new(file_path)
      @project_session = nil
      @summary = nil
    end

    def import
      return if session_already_imported?

      File.foreach(@file_path) do |line|
        process_line(JSON.parse(line))
      rescue JSON::ParserError => error
        Rails.logger.warn "Failed to parse line in #{@file_path}: #{error.message}"
      end

      finalize_project_session
    end

    private

    def session_already_imported?
      existing = @project.project_sessions.find_by(session_id: @filename_parser.session_id)
      existing&.messages_count&.positive?
    end

    def process_line(record)
      case record["type"]
      when "summary"
        handle_summary(record)
      when "file-history-snapshot"
        # Skip for MVP - could track file modifications later
      when "user", "assistant"
        handle_message(record)
      end
    end

    def handle_summary(record)
      @summary = record["summary"]
    end

    def handle_message(record)
      ensure_project_session(record)

      message = @project_session.messages.find_or_initialize_by(uuid: record["uuid"])
      message.update!(MessageBuilder.new(record).attributes)
      message.import_tool_uses
    end

    def ensure_project_session(record)
      return if @project_session

      @project_session = @project.project_sessions.find_or_initialize_by(
        session_id: @filename_parser.session_id
      )
      @project_session.update!(
        git_branch: record["gitBranch"],
        cwd: record["cwd"],
        claude_version: record["version"],
        is_sidechain: @filename_parser.agent?,
        agent_id: @filename_parser.agent_id,
        started_at: Time.parse(record["timestamp"])
      )
    end

    def finalize_project_session
      return unless @project_session

      totals = @project_session.messages.pick(
        Arel.sql("MAX(timestamp)"),
        Arel.sql("COALESCE(SUM(input_tokens), 0)"),
        Arel.sql("COALESCE(SUM(output_tokens), 0)"),
        Arel.sql("COALESCE(SUM(cache_read_tokens), 0)"),
        Arel.sql("COALESCE(SUM(cache_creation_tokens), 0)")
      )

      @project_session.update!(
        summary: @summary,
        ended_at: totals&.first,
        total_input_tokens: totals&.second || 0,
        total_output_tokens: totals&.third || 0,
        total_cache_read_tokens: totals&.fourth || 0,
        total_cache_creation_tokens: totals&.fifth || 0
      )

      MessageThreader.new(@project_session).resolve_parent_references
    end
  end
end
