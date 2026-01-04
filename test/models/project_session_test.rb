require "test_helper"

class ProjectSessionTest < ActiveSupport::TestCase
  setup do
    @project_session = project_sessions(:main_session)
    @agent = project_sessions(:agent_sidechain)
  end

  # Associations
  test "belongs to project" do
    assert_equal projects(:claude_explorer), @project_session.project
  end

  test "belongs to parent_project_session when present" do
    assert_equal @project_session, @agent.parent_project_session
  end

  test "parent_project_session is optional" do
    assert_nil @project_session.parent_project_session
    assert @project_session.valid?
  end

  test "has many child_sessions" do
    assert_includes @project_session.child_sessions, @agent
  end

  test "has many messages" do
    assert_includes @project_session.messages, messages(:user_question)
  end

  test "has many tool_uses through messages" do
    assert_includes @project_session.tool_uses, tool_uses(:read_model)
  end

  test "destroying project_session destroys messages" do
    assert_difference -> { Message.count }, -@project_session.messages.count do
      @project_session.destroy
    end
  end

  test "destroying project_session nullifies child_sessions" do
    @project_session.destroy
    assert_nil @agent.reload.parent_project_session_id
  end

  # Scopes
  test "main_sessions returns only non-sidechain sessions" do
    main = ProjectSession.main_sessions
    assert_includes main, @project_session
    assert_not_includes main, @agent
  end

  test "sidechains returns only sidechain sessions" do
    chains = ProjectSession.sidechains
    assert_includes chains, @agent
    assert_not_includes chains, @project_session
  end

  test "ordered returns sessions by started_at desc" do
    ordered = ProjectSession.ordered
    timestamps = ordered.pluck(:started_at).compact
    assert_equal timestamps.sort.reverse, timestamps
  end

  test "recent returns maximum 10 sessions" do
    assert ProjectSession.recent.count <= 10
  end

  # duration method
  test "duration returns nil when started_at is nil" do
    @project_session.started_at = nil
    assert_nil @project_session.duration
  end

  test "duration returns nil when ended_at is nil" do
    @project_session.ended_at = nil
    assert_nil @project_session.duration
  end

  test "duration returns difference in seconds" do
    expected = @project_session.ended_at - @project_session.started_at
    assert_equal expected, @project_session.duration
  end

  # duration_in_words method
  test "duration_in_words returns nil when duration is nil" do
    @project_session.ended_at = nil
    assert_nil @project_session.duration_in_words
  end

  test "duration_in_words returns human readable string" do
    assert_not_nil @project_session.duration_in_words
    assert @project_session.duration_in_words.is_a?(String)
  end

  # total_tokens method
  test "total_tokens sums input and output tokens" do
    expected = @project_session.total_input_tokens + @project_session.total_output_tokens
    assert_equal expected, @project_session.total_tokens
  end

  # display_name method
  test "display_name returns summary when present" do
    assert_equal "Built the data import feature", @project_session.display_name
  end

  test "display_name returns truncated session_id when summary is nil" do
    project_session = project_sessions(:recent_session)
    assert_equal "Session recent-j", project_session.display_name
  end
end
