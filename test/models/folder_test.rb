require "test_helper"

class FolderTest < ActiveSupport::TestCase
  test "validates canonical_path presence" do
    folder = Folder.new(canonical_path: nil)
    assert_not folder.valid?
    assert_includes folder.errors[:canonical_path], "can't be blank"
  end

  test "validates canonical_path uniqueness" do
    existing = folders(:documents_folder)
    folder = Folder.new(canonical_path: existing.canonical_path)
    assert_not folder.valid?
    assert_includes folder.errors[:canonical_path], "has already been taken"
  end

  test "display_name returns folder basename" do
    folder = Folder.new(canonical_path: "/Users/dev/Documents/my-project")
    assert_equal "my-project", folder.display_name
  end

  test "has_one project_group through Sourceable" do
    folder = folders(:documents_folder)
    assert_respond_to folder, :project_group
  end
end
