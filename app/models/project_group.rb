class ProjectGroup < ApplicationRecord
  delegated_type :sourceable, types: Sourceable::TYPES, dependent: :destroy

  has_many :projects, dependent: :nullify

  scope :repositories, -> { where(sourceable_type: "Repository") }
  scope :folders, -> { where(sourceable_type: "Folder") }
  scope :with_sessions, -> { joins(projects: :project_sessions).distinct }

  delegate :display_name, to: :sourceable
end
