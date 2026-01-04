module ClaudeData
  # Links agent sidechain sessions to their parent main session.
  class SidechainLinker
    def link_all
      ProjectSession.sidechains.where(parent_project_session: nil).find_each do |sidechain|
        link_to_parent(sidechain)
      end
    end

    private

    def link_to_parent(sidechain)
      return unless sidechain.agent_id

      # Find a main project_session in the same project that spawned this agent
      # We look for Task tool uses that might have created this agent
      # The agent_id is a short hash like "a05ff79"
      parent_project_session = find_parent_by_timing(sidechain)

      sidechain.update!(parent_project_session: parent_project_session) if parent_project_session
    end

    def find_parent_by_timing(sidechain)
      # Find main project_sessions that were active around the same time
      # and in the same project
      return nil unless sidechain.started_at

      sidechain.project.project_sessions.main_sessions
        .where("started_at <= ?", sidechain.started_at)
        .where("ended_at IS NULL OR ended_at >= ?", sidechain.started_at)
        .order(started_at: :desc)
        .first
    end
  end
end
