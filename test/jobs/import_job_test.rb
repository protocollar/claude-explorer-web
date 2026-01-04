require "test_helper"

class ImportJobTest < ActiveJob::TestCase
  test "perform calls importer" do
    ClaudeData::Importer.any_instance.expects(:import_all).once

    ImportJob.perform_now
  end
end
