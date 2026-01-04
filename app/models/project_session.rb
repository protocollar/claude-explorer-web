class ProjectSession < ApplicationRecord
  belongs_to :project
  belongs_to :parent_project_session, class_name: "ProjectSession", optional: true
  has_many :child_sessions, class_name: "ProjectSession", foreign_key: :parent_project_session_id, dependent: :nullify
  has_one :session_plan, dependent: :nullify
  has_many :messages, dependent: :destroy
  has_many :tool_uses, through: :messages

  scope :main_sessions, -> { where(is_sidechain: false) }
  scope :sidechains, -> { where(is_sidechain: true) }
  scope :ordered, -> { order(started_at: :desc) }
  scope :recent, -> { ordered.limit(10) }

  def duration
    return nil unless started_at && ended_at
    ended_at - started_at
  end

  def duration_in_words
    return nil unless duration
    ActiveSupport::Duration.build(duration).inspect
  end

  def total_tokens
    total_input_tokens + total_output_tokens
  end

  def display_name
    summary.presence || "Session #{session_id[0..7]}"
  end
end
