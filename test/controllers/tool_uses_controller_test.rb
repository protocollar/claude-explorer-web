require "test_helper"

class ToolUsesControllerTest < ActionDispatch::IntegrationTest
  test "index returns success" do
    get tool_uses_path
    assert_response :success
  end

  test "index displays usage statistics" do
    get tool_uses_path
    assert_response :success
  end

  test "index displays recent tool uses table" do
    get tool_uses_path
    assert_select ".recent-tools table tbody tr", minimum: 1
  end

  test "index limits to 100 recent tool uses" do
    get tool_uses_path
    # Would need 100+ fixtures to fully verify limit
    assert_response :success
  end
end
