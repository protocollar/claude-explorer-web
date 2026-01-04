require "test_helper"

class SessionPlanTest < ActiveSupport::TestCase
  setup do
    @session_plan = session_plans(:mvp_plan)
  end

  # Associations
  test "belongs to project_session optionally" do
    assert_respond_to @session_plan, :project_session
    assert_equal project_sessions(:main_session), @session_plan.project_session
  end

  test "can exist without project_session" do
    session_plan = session_plans(:unlinked_plan)
    assert_nil session_plan.project_session
    assert session_plan.valid?
  end

  # Validations
  test "requires slug" do
    session_plan = SessionPlan.new(title: "Test", content: "Content")
    assert_not session_plan.valid?
    assert_includes session_plan.errors[:slug], "can't be blank"
  end

  test "requires unique slug" do
    session_plan = SessionPlan.new(slug: @session_plan.slug, title: "Duplicate", content: "Content")
    assert_not session_plan.valid?
    assert_includes session_plan.errors[:slug], "has already been taken"
  end

  # Scopes
  test "ordered scope sorts by file_created_at descending" do
    session_plans = SessionPlan.ordered
    assert_equal session_plans(:minimal_plan), session_plans.first
    assert_equal session_plans(:unlinked_plan), session_plans.last
  end

  test "linked scope returns session_plans with project_sessions" do
    linked = SessionPlan.linked
    assert_includes linked, session_plans(:mvp_plan)
    assert_includes linked, session_plans(:test_coverage_plan)
    assert_not_includes linked, session_plans(:unlinked_plan)
  end

  test "unlinked scope returns session_plans without project_sessions" do
    unlinked = SessionPlan.unlinked
    assert_includes unlinked, session_plans(:unlinked_plan)
    assert_not_includes unlinked, session_plans(:mvp_plan)
  end

  # Class methods
  test "extract_title extracts first H1 from markdown" do
    content = "# My Plan Title\n\nSome content here."
    assert_equal "My Plan Title", SessionPlan.extract_title(content)
  end

  test "extract_title returns nil when no H1 present" do
    content = "## Not an H1\n\nSome content."
    assert_nil SessionPlan.extract_title(content)
  end

  test "extract_title handles multiline content" do
    content = "Some intro text\n\n# The Real Title\n\nMore content"
    assert_equal "The Real Title", SessionPlan.extract_title(content)
  end

  test "import_from_file creates session_plan from markdown file" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "test-import-plan.md")
      File.write(path, "# Imported Plan\n\nPlan content here.")

      session_plan = SessionPlan.import_from_file(path)

      assert_equal "test-import-plan", session_plan.slug
      assert_equal "Imported Plan", session_plan.title
      assert_includes session_plan.content, "Plan content here"
      assert_not_nil session_plan.file_created_at
    end
  end

  test "import_from_file updates existing session_plan" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "#{@session_plan.slug}.md")
      File.write(path, "# Updated Title\n\nNew content.")

      session_plan = SessionPlan.import_from_file(path)

      assert_equal @session_plan.id, session_plan.id
      assert_equal "Updated Title", session_plan.title
      assert_includes session_plan.content, "New content"
    end
  end

  test "import_from_file uses titleized slug when no H1" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "no-heading-plan.md")
      File.write(path, "Just some plain content.")

      session_plan = SessionPlan.import_from_file(path)

      assert_equal "No Heading Plan", session_plan.title
    end
  end

  test "import_all skips when plans directory does not exist" do
    Dir.stubs(:exist?).with(SessionPlan::PLANS_PATH).returns(false)

    assert_no_difference -> { SessionPlan.count } do
      SessionPlan.import_all
    end
  end

  test "import_all calls import_from_file for each markdown file" do
    test_files = [ "/path/to/plan-one.md", "/path/to/plan-two.md" ]

    Dir.stubs(:exist?).with(SessionPlan::PLANS_PATH).returns(true)
    Dir.stubs(:glob).with("#{SessionPlan::PLANS_PATH}/*.md").returns(test_files)

    SessionPlan.expects(:import_from_file).with("/path/to/plan-one.md").once
    SessionPlan.expects(:import_from_file).with("/path/to/plan-two.md").once

    SessionPlan.import_all
  end

  # Instance methods
  test "display_title returns title when present" do
    assert_equal "Claude Explorer MVP Plan", @session_plan.display_title
  end

  test "display_title returns titleized slug when title is blank" do
    session_plan = session_plans(:minimal_plan)
    session_plan.title = nil
    assert_equal "Simple Walking Cloud", session_plan.display_title
  end

  test "truncated_content returns truncated string" do
    truncated = @session_plan.truncated_content(50)
    assert truncated.length <= 50
    assert truncated.end_with?("...")
  end

  test "truncated_content returns full content when short" do
    session_plan = SessionPlan.new(content: "Short")
    assert_equal "Short", session_plan.truncated_content(100)
  end

  test "truncated_content handles nil content" do
    session_plan = SessionPlan.new(content: nil)
    assert_equal "", session_plan.truncated_content
  end
end
