class Project < ApplicationRecord
  belongs_to :project_group, optional: true

  has_many :project_sessions, dependent: :destroy
  has_many :messages, through: :project_sessions
  has_many :tool_uses, through: :messages

  validates :path, presence: true, uniqueness: true
  validates :encoded_path, presence: true

  scope :ordered, -> { order(updated_at: :desc) }
  scope :with_group, -> { where.not(project_group_id: nil) }
  scope :without_group, -> { where(project_group_id: nil) }
  scope :with_sessions, -> { joins(:project_sessions).distinct }

  def name
    super || File.basename(path)
  end

  def conversation_files_path
    File.expand_path("~/.claude/projects/#{encoded_path}")
  end

  def main_sessions
    project_sessions.main_sessions
  end

  def total_tokens
    project_sessions.sum(:total_input_tokens) + project_sessions.sum(:total_output_tokens)
  end
end
