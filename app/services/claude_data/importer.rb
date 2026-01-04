module ClaudeData
  # Orchestrates importing Claude data from ~/.claude into the database.
  class Importer
    CLAUDE_JSON_PATH = File.expand_path("~/.claude.json")
    PROJECTS_BASE_PATH = File.expand_path("~/.claude/projects")

    def import_all
      return unless File.exist?(CLAUDE_JSON_PATH)

      projects_config = JSON.parse(File.read(CLAUDE_JSON_PATH))

      projects_config["projects"]&.each do |path, config|
        next if path.blank? || path == "/"
        import_project(path, config)
      rescue => error
        Rails.logger.warn "Failed to import project #{path}: #{error.message}"
      end

      # Second pass: link sidechains to parent sessions
      SidechainLinker.new.link_all

      # Third pass: import session_plans and link to project_sessions
      SessionPlan.import_all
      PlanLinker.new.link_all
    end

    def import_project(path, config = {})
      encoded_path = encode_path(path)
      project = Project.find_or_initialize_by(path: path)
      project_group = ProjectGroupResolver.new(path).resolve

      project.update!(
        encoded_path: encoded_path,
        name: File.basename(path),
        last_cost: config["lastCost"],
        last_session_id: config["lastSessionId"],
        last_model_usage: config["lastModelUsage"] || {},
        project_group: project_group
      )

      import_conversations(project)
      project
    end

    private

    def encode_path(path)
      # Claude encodes paths by replacing / with -
      # The leading - is kept (e.g., /Users/thomascarr -> -Users-thomascarr)
      path.to_s.gsub("/", "-")
    end

    def import_conversations(project)
      conversation_path = project.conversation_files_path
      return unless Dir.exist?(conversation_path)

      Dir.glob("#{conversation_path}/*.jsonl").each do |file|
        JsonlParser.new(project, file).import
      end
    end
  end
end
