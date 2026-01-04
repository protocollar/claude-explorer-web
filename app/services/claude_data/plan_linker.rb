module ClaudeData
  # Links SessionPlan records to their corresponding ProjectSession.
  class PlanLinker
    PROJECTS_BASE_PATH = File.expand_path("~/.claude/projects")

    def link_all
      SessionPlan.unlinked.find_each do |session_plan|
        project_session = find_project_session_for_slug(session_plan.slug)
        session_plan.update!(project_session: project_session) if project_session
      rescue => error
        Rails.logger.warn "Failed to link session_plan #{session_plan.slug}: #{error.message}"
      end
    end

    private

    def find_project_session_for_slug(slug)
      # Search all JSONL files for the slug
      # The slug appears in message records when plan mode is used
      Dir.glob("#{PROJECTS_BASE_PATH}/*/*.jsonl").each do |file|
        session_id = find_slug_in_file(file, slug)
        if session_id
          # Find the project_session by its filename (session_id in our DB)
          project_session = ProjectSession.find_by(session_id: session_id)
          return project_session if project_session
        end
      end

      nil
    end

    def find_slug_in_file(file_path, slug)
      File.foreach(file_path) do |line|
        record = JSON.parse(line)
        if record["slug"] == slug
          # Return the session ID (filename without extension)
          return File.basename(file_path, ".jsonl")
        end
      rescue JSON::ParserError
        next
      end

      nil
    end
  end
end
