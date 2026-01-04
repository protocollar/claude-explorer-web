require "test_helper"

class ImportsControllerTest < ActionDispatch::IntegrationTest
  test "create enqueues import job and redirects" do
    assert_enqueued_with(job: ImportJob) do
      post import_path
    end

    assert_redirected_to root_path
  end

  test "create sets flash notice" do
    post import_path
    follow_redirect!

    assert_equal "Import started in background", flash[:notice]
  end
end
