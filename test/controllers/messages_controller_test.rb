require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project_session = project_sessions(:main_session)
    @message = messages(:user_question)
  end

  test "show returns success" do
    get project_session_message_path(@project_session, @message)
    assert_response :success
  end

  test "show displays message content" do
    get project_session_message_path(@project_session, @message)
    assert_match "create a model", response.body
  end

  test "show scopes message to session" do
    other_session = project_sessions(:recent_session)
    # Message belongs to main_session, not recent_session
    get project_session_message_path(other_session, @message)
    assert_response :not_found
  end

  test "show returns not found for invalid message" do
    get project_session_message_path(@project_session, id: 99999)
    assert_response :not_found
  end
end
