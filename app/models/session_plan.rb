class SessionPlan < ApplicationRecord
  PLANS_PATH = File.expand_path("~/.claude/plans")

  belongs_to :project_session, optional: true

  validates :slug, presence: true, uniqueness: true

  scope :ordered, -> { order(file_created_at: :desc) }
  scope :linked, -> { where.not(project_session_id: nil) }
  scope :unlinked, -> { where(project_session_id: nil) }

  def self.import_from_file(path)
    slug = File.basename(path, ".md")
    content = File.read(path)
    title = extract_title(content) || slug.titleize

    find_or_initialize_by(slug: slug).tap do |plan|
      plan.update!(
        content: content,
        title: title,
        file_created_at: File.mtime(path)
      )
    end
  end

  def self.import_all
    return unless Dir.exist?(PLANS_PATH)

    Dir.glob("#{PLANS_PATH}/*.md").each do |path|
      import_from_file(path)
    rescue StandardError => error
      Rails.logger.warn "Failed to import session_plan #{path}: #{error.message}"
    end
  end

  def self.extract_title(content)
    # Extract first H1 heading from markdown (single line only)
    content.match(/^# ([^\n]+)/)&.[](1)
  end

  def display_title
    title.presence || slug.titleize
  end

  def truncated_content(length = 500)
    content.to_s.truncate(length)
  end
end
