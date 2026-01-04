class ImportsController < ApplicationController
  def create
    ImportJob.perform_later
    redirect_to root_path, notice: "Import started in background"
  end
end
