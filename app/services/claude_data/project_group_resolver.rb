module ClaudeData
  # Determines the ProjectGroup for a project path based on git repository or folder.
  class ProjectGroupResolver
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def resolve
      if git_repository?
        resolve_repository
      else
        resolve_folder
      end
    end

    private

    def git_repository?
      Dir.exist?(File.join(path, ".git"))
    end

    def resolve_repository
      repository = Repository.find_or_initialize_by(git_common_dir: git_common_dir)

      if repository.new_record?
        repository.remote_url = remote_url
        repository.normalized_url = normalize_url(remote_url)
        repository.provider = detect_provider(remote_url)
        repository.save!
      end

      repository.project_group || repository.create_project_group!
    end

    def resolve_folder
      folder = Folder.find_or_create_by!(canonical_path: path)
      folder.project_group || folder.create_project_group!
    end

    def git_common_dir
      @git_common_dir ||= begin
        result = `git -C #{Shellwords.escape(path)} rev-parse --git-common-dir 2>/dev/null`.strip
        result.presence && File.expand_path(result, path)
      end || File.join(path, ".git")
    end

    def remote_url
      @remote_url ||= `git -C #{Shellwords.escape(path)} config --get remote.origin.url 2>/dev/null`.strip.presence
    end

    def normalize_url(url)
      return nil if url.blank?

      # Convert SSH URLs to normalized format: github.com/user/repo
      url = url.gsub(/\.git$/, "")
      url = url.gsub(/^git@([^:]+):/, '\1/')
      url = url.gsub(%r{^https?://}, "")
      url
    end

    def detect_provider(url)
      return nil if url.blank?

      case url
      when /github\.com/i then "github"
      when /gitlab\.com/i then "gitlab"
      when /bitbucket\.org/i then "bitbucket"
      end
    end
  end
end
