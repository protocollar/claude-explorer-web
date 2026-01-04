module Sourceable
  extend ActiveSupport::Concern

  TYPES = %w[Repository Folder]

  included do
    has_one :project_group, as: :sourceable, touch: true, dependent: :destroy
  end
end
