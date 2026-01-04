require "test_helper"

module ClaudeData
  class PlanLinkerTest < ActiveSupport::TestCase
    setup do
      @linker = PlanLinker.new
      @project = projects(:claude_explorer)
    end

    test "links unlinked plan to session when slug found in JSONL" do
      plan = session_plans(:unlinked_plan)
      session = project_sessions(:main_session)

      # Stub find_project_session_for_slug to return the session for this plan's slug
      @linker.stubs(:find_project_session_for_slug).with(plan.slug).returns(session)

      @linker.link_all

      assert_equal session, plan.reload.project_session
    end

    test "does not modify already linked plans" do
      plan = session_plans(:mvp_plan)
      original_session = plan.project_session

      # Stub any calls for unlinked plans
      @linker.stubs(:find_project_session_for_slug).returns(nil)

      @linker.link_all

      # Linked plan should still have original session
      assert_equal original_session, plan.reload.project_session
    end

    test "leaves plan unlinked when no session found" do
      plan = session_plans(:unlinked_plan)

      @linker.stubs(:find_project_session_for_slug).returns(nil)

      @linker.link_all

      assert_nil plan.reload.project_session
    end

    test "handles errors gracefully and continues processing" do
      unlinked_plan = session_plans(:unlinked_plan)

      # Make find_project_session_for_slug raise an error
      @linker.stubs(:find_project_session_for_slug).raises(StandardError.new("Test error"))

      # Should not raise
      assert_nothing_raised do
        @linker.link_all
      end

      # Plan should remain unlinked
      assert_nil unlinked_plan.reload.project_session
    end

    test "only processes unlinked plans" do
      linked_plan = session_plans(:mvp_plan)
      unlinked_plan = session_plans(:unlinked_plan)

      # Verify starting state
      assert_not_nil linked_plan.project_session
      assert_nil unlinked_plan.project_session

      # Expect find_project_session_for_slug only for unlinked plan
      @linker.expects(:find_project_session_for_slug).with(unlinked_plan.slug).returns(nil)
      @linker.expects(:find_project_session_for_slug).with(linked_plan.slug).never

      @linker.link_all
    end

    # Integration test for find_project_session_for_slug private method
    test "find_project_session_for_slug searches JSONL files for slug" do
      plan = session_plans(:unlinked_plan)
      session = project_sessions(:main_session)

      Dir.mktmpdir do |dir|
        project_dir = File.join(dir, @project.encoded_path)
        FileUtils.mkdir_p(project_dir)

        jsonl_path = File.join(project_dir, "#{session.session_id}.jsonl")
        File.write(jsonl_path, { "slug" => plan.slug, "type" => "assistant" }.to_json)

        Dir.stubs(:glob).with("#{PlanLinker::PROJECTS_BASE_PATH}/*/*.jsonl").returns([ jsonl_path ])

        result = @linker.send(:find_project_session_for_slug, plan.slug)

        assert_equal session, result
      end
    end

    test "find_project_session_for_slug handles malformed JSON" do
      plan = session_plans(:unlinked_plan)
      session = project_sessions(:main_session)

      Dir.mktmpdir do |dir|
        jsonl_path = File.join(dir, "#{session.session_id}.jsonl")
        File.write(jsonl_path, "invalid json\n" + { "slug" => plan.slug }.to_json)

        Dir.stubs(:glob).returns([ jsonl_path ])

        # Should not raise and should still find the slug on second line
        result = @linker.send(:find_project_session_for_slug, plan.slug)
        assert_equal session, result
      end
    end

    test "find_project_session_for_slug returns nil when slug not found" do
      Dir.stubs(:glob).returns([])

      result = @linker.send(:find_project_session_for_slug, "nonexistent-slug")
      assert_nil result
    end
  end
end
