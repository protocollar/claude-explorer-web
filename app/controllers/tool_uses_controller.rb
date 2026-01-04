class ToolUsesController < ApplicationController
  def index
    @tool_stats = ToolUse.usage_counts
    set_page_and_extract_portion_from ToolUse.includes(message: :project_session).order(created_at: :desc)
  end
end
