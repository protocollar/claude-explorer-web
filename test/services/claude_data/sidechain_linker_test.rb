require "test_helper"

module ClaudeData
  class SidechainLinkerTest < ActiveSupport::TestCase
    setup do
      @linker = SidechainLinker.new
      @project = projects(:claude_explorer)
    end

    test "links orphan sidechain to parent session by timing" do
      orphan = project_sessions(:orphan_agent)
      main = project_sessions(:main_session)

      # Adjust timing so orphan falls within main session's window
      orphan.update!(started_at: main.started_at + 10.minutes)
      main.update!(ended_at: main.started_at + 1.hour)

      @linker.link_all

      assert_equal main, orphan.reload.parent_project_session
    end

    test "ignores sidechains without agent_id" do
      sidechain = @project.project_sessions.create!(
        session_id: "no-agent-id-sidechain",
        is_sidechain: true,
        agent_id: nil,
        started_at: 1.hour.ago
      )

      @linker.link_all

      assert_nil sidechain.reload.parent_project_session
    end

    test "ignores sidechains without started_at" do
      orphan = project_sessions(:orphan_agent)
      orphan.update!(started_at: nil)

      @linker.link_all

      assert_nil orphan.reload.parent_project_session
    end

    test "prefers most recent parent when multiple match" do
      # Create two overlapping main sessions
      older = @project.project_sessions.create!(
        session_id: "older-main-session",
        is_sidechain: false,
        started_at: 3.hours.ago,
        ended_at: nil
      )

      newer = @project.project_sessions.create!(
        session_id: "newer-main-session",
        is_sidechain: false,
        started_at: 2.hours.ago,
        ended_at: nil
      )

      agent = @project.project_sessions.create!(
        session_id: "agent-multi-parent",
        agent_id: "multiparent",
        is_sidechain: true,
        started_at: 1.5.hours.ago
      )

      @linker.link_all

      assert_equal newer, agent.reload.parent_project_session
    end

    test "finds parent when ended_at is nil" do
      main = @project.project_sessions.create!(
        session_id: "open-main-session",
        is_sidechain: false,
        started_at: 2.hours.ago,
        ended_at: nil
      )

      agent = @project.project_sessions.create!(
        session_id: "agent-open-parent",
        agent_id: "openparent",
        is_sidechain: true,
        started_at: 1.hour.ago
      )

      @linker.link_all

      assert_equal main, agent.reload.parent_project_session
    end

    test "does not link sidechain started before parent" do
      # Use empty_project to avoid interference from fixtures
      empty = projects(:empty_project)

      main = empty.project_sessions.create!(
        session_id: "later-main-session",
        is_sidechain: false,
        started_at: 1.hour.ago,
        ended_at: nil
      )

      agent = empty.project_sessions.create!(
        session_id: "agent-before-main",
        agent_id: "beforemain",
        is_sidechain: true,
        started_at: 2.hours.ago
      )

      @linker.link_all

      assert_nil agent.reload.parent_project_session
    end

    test "does not link sidechain started after parent ended" do
      main = @project.project_sessions.create!(
        session_id: "ended-main-session",
        is_sidechain: false,
        started_at: 3.hours.ago,
        ended_at: 2.hours.ago
      )

      agent = @project.project_sessions.create!(
        session_id: "agent-after-end",
        agent_id: "afterend",
        is_sidechain: true,
        started_at: 1.hour.ago
      )

      @linker.link_all

      assert_nil agent.reload.parent_project_session
    end

    test "only links sidechains in same project" do
      other_project = projects(:writebook)

      main = @project.project_sessions.create!(
        session_id: "project-a-main",
        is_sidechain: false,
        started_at: 2.hours.ago,
        ended_at: nil
      )

      agent = other_project.project_sessions.create!(
        session_id: "agent-project-b",
        agent_id: "projectb",
        is_sidechain: true,
        started_at: 1.hour.ago
      )

      @linker.link_all

      assert_nil agent.reload.parent_project_session
    end
  end
end
