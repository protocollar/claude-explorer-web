class MessagesController < ApplicationController
  include ProjectSessionScoped

  def show
    @message = @project_session.messages.find(params[:id])
  end
end
