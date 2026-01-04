class Message < ApplicationRecord
  belongs_to :project_session, counter_cache: true
  belongs_to :parent_message, class_name: "Message", optional: true
  has_many :child_messages, class_name: "Message", foreign_key: :parent_message_id, dependent: :nullify
  has_many :tool_uses, dependent: :destroy

  scope :user_messages, -> { where(message_type: "user") }
  scope :assistant_messages, -> { where(message_type: "assistant") }
  scope :ordered, -> { order(timestamp: :asc) }
  scope :with_tool_use, -> { joins(:tool_uses).distinct }
  scope :root_messages, -> { where(parent_message: nil) }

  def text_content
    content.filter_map { |block| block["text"] if block["type"] == "text" }.join("\n")
  end

  def tool_use_blocks
    content.select { |block| block["type"] == "tool_use" }
  end

  def thinking_blocks
    content.select { |block| block["type"] == "thinking" }
  end

  def tool_result_blocks
    content.select { |block| block["type"] == "tool_result" }
  end

  def user?
    message_type == "user"
  end

  def assistant?
    message_type == "assistant"
  end

  def total_tokens
    input_tokens + output_tokens
  end

  def truncated_content(length: 200)
    text_content.truncate(length)
  end

  def branch_count
    child_messages.count
  end

  def has_branches?
    branch_count > 1
  end

  def import_tool_uses
    tool_use_blocks.each do |block|
      tool_use = tool_uses.find_or_initialize_by(tool_use_id: block["id"])
      tool_use.update!(
        tool_name: block["name"],
        input: block["input"] || {}
      )
    end

    import_tool_results if user?
  end

  private
    def import_tool_results
      tool_result_blocks.each do |block|
        tool_use = ToolUse.find_by(tool_use_id: block["tool_use_id"])
        next unless tool_use

        tool_use.update!(
          result: block["content"],
          success: !block["is_error"]
        )
      end
    end
end
