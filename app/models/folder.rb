class Folder < ApplicationRecord
  include Sourceable

  validates :canonical_path, presence: true, uniqueness: true

  def display_name
    File.basename(canonical_path)
  end
end
