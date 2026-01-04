class ToolUse < ApplicationRecord
  belongs_to :message

  has_one :project_session, through: :message
  has_one :project, through: :project_session

  scope :ordered, -> { order(created_at: :desc) }
  scope :by_tool, ->(name) { where(tool_name: name) }
  scope :successful, -> { where(success: true) }
  scope :failed, -> { where(success: false) }

  def self.usage_counts
    group(:tool_name).count.sort_by { |_, v| -v }
  end

  def display_input
    case tool_name
    when "Read"
      input["file_path"]
    when "Write"
      input["file_path"]
    when "Edit"
      input["file_path"]
    when "Bash"
      input["command"]&.truncate(100)
    when "Grep"
      "#{input['pattern']} in #{input['path'] || '.'}"
    when "Glob"
      input["pattern"]
    else
      input.to_json.truncate(100)
    end
  end
end
