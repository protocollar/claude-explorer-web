require "test_helper"

module ClaudeData
  class ImporterTest < ActiveSupport::TestCase
    setup do
      @importer = Importer.new
    end

    test "encode_path replaces slashes with dashes" do
      result = @importer.send(:encode_path, "/Users/test/project")
      assert_equal "-Users-test-project", result
    end

    test "encode_path handles root path" do
      result = @importer.send(:encode_path, "/")
      assert_equal "-", result
    end

    test "encode_path handles empty string" do
      result = @importer.send(:encode_path, "")
      assert_equal "", result
    end

    test "encode_path handles path with multiple slashes" do
      result = @importer.send(:encode_path, "/a/b/c/d/e")
      assert_equal "-a-b-c-d-e", result
    end

    test "import_project creates new project" do
      path = "/Users/test/new-project"

      assert_difference -> { Project.count }, 1 do
        @importer.import_project(path, {})
      end

      project = Project.find_by(path: path)
      assert_equal "-Users-test-new-project", project.encoded_path
      assert_equal "new-project", project.name
    end

    test "import_project updates existing project" do
      project = projects(:claude_explorer)

      assert_no_difference -> { Project.count } do
        @importer.import_project(project.path, { "lastCost" => 99.99 })
      end

      assert_equal 99.99, project.reload.last_cost.to_f
    end

    test "import_project saves lastCost from config" do
      path = "/Users/test/cost-project"
      config = { "lastCost" => 15.50 }

      project = @importer.import_project(path, config)

      assert_equal 15.50, project.last_cost.to_f
    end

    test "import_project saves lastSessionId from config" do
      path = "/Users/test/session-project"
      config = { "lastSessionId" => "session-xyz-123" }

      project = @importer.import_project(path, config)

      assert_equal "session-xyz-123", project.last_session_id
    end

    test "import_project saves lastModelUsage from config" do
      path = "/Users/test/model-project"
      config = { "lastModelUsage" => { "opus" => 50, "sonnet" => 100 } }

      project = @importer.import_project(path, config)

      assert_equal({ "opus" => 50, "sonnet" => 100 }, project.last_model_usage)
    end

    test "import_project defaults lastModelUsage to empty hash" do
      path = "/Users/test/no-usage-project"
      config = {}

      project = @importer.import_project(path, config)

      assert_equal({}, project.last_model_usage)
    end

    test "import_project returns the project" do
      path = "/Users/test/return-project"
      Dir.stubs(:exist?).returns(false)

      result = @importer.import_project(path, {})

      assert_instance_of Project, result
      assert_equal path, result.path
    end

    test "import_project assigns project to project group" do
      path = "/Users/test/grouped-project"
      Dir.stubs(:exist?).returns(false)

      project = @importer.import_project(path, {})

      assert_not_nil project.project_group
      assert_equal "Folder", project.project_group.sourceable_type
    end

    test "import_project assigns project to existing group on re-import" do
      path = "/Users/test/reimport-project"
      Dir.stubs(:exist?).returns(false)

      first_import = @importer.import_project(path, {})
      group_id = first_import.project_group_id

      second_import = @importer.import_project(path, { "lastCost" => 10 })

      assert_equal group_id, second_import.project_group_id
    end

    test "import_all returns early when claude.json does not exist" do
      File.stubs(:exist?).with(Importer::CLAUDE_JSON_PATH).returns(false)

      # Should not raise and should not call other methods
      assert_nothing_raised do
        @importer.import_all
      end
    end

    test "import_all calls SidechainLinker and PlanLinker after processing projects" do
      claude_json = { "projects" => {} }

      File.stubs(:exist?).with(Importer::CLAUDE_JSON_PATH).returns(true)
      File.stubs(:read).with(Importer::CLAUDE_JSON_PATH).returns(claude_json.to_json)
      SidechainLinker.any_instance.expects(:link_all).once
      SessionPlan.stubs(:import_all)
      PlanLinker.any_instance.expects(:link_all).once

      @importer.import_all
    end

    test "import_all skips blank and root paths" do
      claude_json = {
        "projects" => {
          "" => { "lastCost" => 1 },
          "/" => { "lastCost" => 2 },
          "/valid/path" => { "lastCost" => 3 }
        }
      }

      File.stubs(:exist?).with(Importer::CLAUDE_JSON_PATH).returns(true)
      File.stubs(:read).with(Importer::CLAUDE_JSON_PATH).returns(claude_json.to_json)
      Dir.stubs(:exist?).returns(false)  # Skip conversation imports

      # Should only create one project for /valid/path
      assert_difference -> { Project.count }, 1 do
        @importer.import_all
      end

      assert Project.find_by(path: "/valid/path")
    end

    test "import_all continues on individual project failure" do
      claude_json = {
        "projects" => {
          "/project1" => {},
          "/project2" => {}
        }
      }

      File.stubs(:exist?).with(Importer::CLAUDE_JSON_PATH).returns(true)
      File.stubs(:read).with(Importer::CLAUDE_JSON_PATH).returns(claude_json.to_json)
      Dir.stubs(:exist?).returns(false)  # Skip conversation imports

      # Make first project fail
      Project.stubs(:find_or_initialize_by).with(path: "/project1").raises(StandardError.new("Test error"))
      Project.stubs(:find_or_initialize_by).with(path: "/project2").returns(
        Project.new(path: "/project2")
      )

      # Should not raise
      assert_nothing_raised do
        @importer.import_all
      end
    end
  end
end
