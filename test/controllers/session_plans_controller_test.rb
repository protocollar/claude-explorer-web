require "test_helper"

class SessionPlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @session_plan = session_plans(:mvp_plan)
  end

  # Index action
  test "index returns success" do
    get session_plans_path
    assert_response :success
  end

  test "index displays plans" do
    get session_plans_path
    assert_select ".plan-card", minimum: 2
  end

  test "index shows plan titles" do
    get session_plans_path
    assert_select ".plan-card__title", text: /Claude Explorer MVP Plan/
  end

  test "index shows plan count in header" do
    get session_plans_path
    assert_select ".page-header__subtitle", text: /#{SessionPlan.count} plans/
  end

  test "index orders plans by file_created_at desc" do
    get session_plans_path
    assert_response :success
    # Most recent plan should appear first
    assert_select ".plan-card:first-child .plan-card__title", text: /Simple Walking Cloud/i
  end

  # Show action
  test "show returns success" do
    get session_plan_path(@session_plan)
    assert_response :success
  end

  test "show displays plan title" do
    get session_plan_path(@session_plan)
    assert_select "h1", text: /Claude Explorer MVP Plan/
  end

  test "show displays plan content" do
    get session_plan_path(@session_plan)
    assert_select ".plan-content"
  end

  test "show displays plan slug" do
    get session_plan_path(@session_plan)
    assert_match @session_plan.slug, response.body
  end

  test "show displays linked session" do
    get session_plan_path(@session_plan)
    assert_select "a[href='#{project_session_path(@session_plan.project_session)}']"
  end

  test "show works for unlinked plans" do
    unlinked = session_plans(:unlinked_plan)
    get session_plan_path(unlinked)
    assert_response :success
  end

  test "show returns not found for invalid id" do
    get session_plan_path(id: 99999)
    assert_response :not_found
  end

  # Navigation
  test "plans link appears in navigation" do
    get session_plans_path
    assert_select ".nav__links a[href='#{session_plans_path}']", text: "Plans"
  end
end
