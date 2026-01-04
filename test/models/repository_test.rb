require "test_helper"

class RepositoryTest < ActiveSupport::TestCase
  test "validates git_common_dir presence" do
    repo = Repository.new(git_common_dir: nil)
    assert_not repo.valid?
    assert_includes repo.errors[:git_common_dir], "can't be blank"
  end

  test "validates git_common_dir uniqueness" do
    existing = repositories(:claude_explorer_repo)
    repo = Repository.new(git_common_dir: existing.git_common_dir)
    assert_not repo.valid?
    assert_includes repo.errors[:git_common_dir], "has already been taken"
  end

  test "display_name uses repo name from remote_url" do
    repo = Repository.new(
      git_common_dir: "/path/to/.git",
      remote_url: "git@github.com:user/my-project.git"
    )
    assert_equal "my-project", repo.display_name
  end

  test "display_name falls back to project directory name without remote" do
    repo = Repository.new(git_common_dir: "/Users/dev/my-local-project/.git")
    assert_equal "my-local-project", repo.display_name
  end

  test "remote? returns true when remote_url present" do
    repo = Repository.new(remote_url: "git@github.com:user/repo.git")
    assert repo.remote?
  end

  test "remote? returns false when remote_url blank" do
    repo = Repository.new(remote_url: nil)
    assert_not repo.remote?
  end

  test "local_only? is opposite of remote?" do
    remote_repo = Repository.new(remote_url: "git@github.com:user/repo.git")
    local_repo = Repository.new(remote_url: nil)

    assert_not remote_repo.local_only?
    assert local_repo.local_only?
  end

  test "has_one project_group through Sourceable" do
    repo = repositories(:claude_explorer_repo)
    assert_respond_to repo, :project_group
  end
end
