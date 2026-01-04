require "test_helper"

module ClaudeData
  class ProjectGroupResolverTest < ActiveSupport::TestCase
    test "resolve creates repository and project group for git directory" do
      path = "/tmp/git-project"
      Dir.stubs(:exist?).with("#{path}/.git").returns(true)

      resolver = ProjectGroupResolver.new(path)
      resolver.stubs(:git_common_dir).returns("#{path}/.git")
      resolver.stubs(:remote_url).returns("git@github.com:user/repo.git")

      assert_difference -> { Repository.count }, 1 do
        assert_difference -> { ProjectGroup.count }, 1 do
          group = resolver.resolve

          assert_instance_of ProjectGroup, group
          assert_equal "Repository", group.sourceable_type
          assert_equal "#{path}/.git", group.sourceable.git_common_dir
          assert_equal "git@github.com:user/repo.git", group.sourceable.remote_url
        end
      end
    end

    test "resolve reuses existing repository by git_common_dir" do
      repo = repositories(:claude_explorer_repo)
      path = File.dirname(repo.git_common_dir)

      Dir.stubs(:exist?).with("#{path}/.git").returns(true)

      resolver = ProjectGroupResolver.new(path)
      resolver.stubs(:git_common_dir).returns(repo.git_common_dir)
      resolver.stubs(:remote_url).returns(repo.remote_url)

      assert_no_difference -> { Repository.count } do
        group = resolver.resolve

        assert_equal repo.project_group, group
      end
    end

    test "resolve creates folder and project group for non-git directory" do
      path = "/tmp/plain-folder"
      Dir.stubs(:exist?).with("#{path}/.git").returns(false)

      resolver = ProjectGroupResolver.new(path)

      assert_difference -> { Folder.count }, 1 do
        assert_difference -> { ProjectGroup.count }, 1 do
          group = resolver.resolve

          assert_instance_of ProjectGroup, group
          assert_equal "Folder", group.sourceable_type
          assert_equal path, group.sourceable.canonical_path
        end
      end
    end

    test "resolve reuses existing folder by canonical_path" do
      folder = folders(:documents_folder)
      path = folder.canonical_path

      Dir.stubs(:exist?).with("#{path}/.git").returns(false)

      resolver = ProjectGroupResolver.new(path)

      assert_no_difference -> { Folder.count } do
        group = resolver.resolve

        assert_equal folder.project_group, group
      end
    end

    test "normalize_url removes .git suffix" do
      resolver = ProjectGroupResolver.new("/tmp")
      result = resolver.send(:normalize_url, "https://github.com/user/repo.git")

      assert_equal "github.com/user/repo", result
    end

    test "normalize_url converts SSH URL format" do
      resolver = ProjectGroupResolver.new("/tmp")
      result = resolver.send(:normalize_url, "git@github.com:user/repo.git")

      assert_equal "github.com/user/repo", result
    end

    test "normalize_url removes https protocol" do
      resolver = ProjectGroupResolver.new("/tmp")
      result = resolver.send(:normalize_url, "https://github.com/user/repo")

      assert_equal "github.com/user/repo", result
    end

    test "normalize_url returns nil for blank input" do
      resolver = ProjectGroupResolver.new("/tmp")

      assert_nil resolver.send(:normalize_url, nil)
      assert_nil resolver.send(:normalize_url, "")
    end

    test "detect_provider identifies github" do
      resolver = ProjectGroupResolver.new("/tmp")

      assert_equal "github", resolver.send(:detect_provider, "git@github.com:user/repo.git")
      assert_equal "github", resolver.send(:detect_provider, "https://github.com/user/repo")
    end

    test "detect_provider identifies gitlab" do
      resolver = ProjectGroupResolver.new("/tmp")

      assert_equal "gitlab", resolver.send(:detect_provider, "git@gitlab.com:user/repo.git")
    end

    test "detect_provider identifies bitbucket" do
      resolver = ProjectGroupResolver.new("/tmp")

      assert_equal "bitbucket", resolver.send(:detect_provider, "git@bitbucket.org:user/repo.git")
    end

    test "detect_provider returns nil for unknown providers" do
      resolver = ProjectGroupResolver.new("/tmp")

      assert_nil resolver.send(:detect_provider, "git@custom.server:user/repo.git")
    end

    test "detect_provider returns nil for blank input" do
      resolver = ProjectGroupResolver.new("/tmp")

      assert_nil resolver.send(:detect_provider, nil)
      assert_nil resolver.send(:detect_provider, "")
    end
  end
end
