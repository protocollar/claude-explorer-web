class Repository < ApplicationRecord
  include Sourceable

  validates :git_common_dir, presence: true, uniqueness: true

  def display_name
    if remote_url.present?
      remote_url.split("/").last&.delete_suffix(".git")
    else
      File.basename(File.dirname(git_common_dir))
    end
  end

  def remote?
    remote_url.present?
  end

  def local_only?
    !remote?
  end
end
