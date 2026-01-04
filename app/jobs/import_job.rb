class ImportJob < ApplicationJob
  queue_as :default

  def perform
    ClaudeData::Importer.new.import_all
  end
end
