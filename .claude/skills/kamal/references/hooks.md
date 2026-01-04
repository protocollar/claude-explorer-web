# Kamal Hooks Reference

Hooks execute custom scripts at deployment stages. Place scripts in `.kamal/hooks/` with no file extension.

## Available Hooks

| Hook | Trigger | Use Case |
|------|---------|----------|
| `docker-setup` | After Docker installation | Custom Docker configuration |
| `pre-connect` | Before SSH connections | Validate VPN/network access |
| `pre-build` | Before Docker build | Validate branch, run tests |
| `pre-deploy` | Before deployment | Check CI status, notify team |
| `post-deploy` | After successful deployment | Notify Slack, create release |
| `pre-app-boot` | Before container starts | Database migrations |
| `post-app-boot` | After container starts | Warm caches |
| `pre-proxy-reboot` | Before proxy restart | Notify load balancer |
| `post-proxy-reboot` | After proxy restart | Verify routing |

## Environment Variables

Available in all hooks:

```bash
KAMAL_RECORDED_AT    # ISO 8601 timestamp
KAMAL_PERFORMER      # User running command (e.g., "deploy@hostname")
KAMAL_SERVICE        # Service name from deploy.yml
KAMAL_SERVICE_VERSION # Version being deployed
KAMAL_VERSION        # Git SHA or tag
KAMAL_HOSTS          # Comma-separated host list
KAMAL_COMMAND        # Command being run (deploy, rollback, etc.)
```

Optional (when applicable):

```bash
KAMAL_SUBCOMMAND     # Subcommand if any
KAMAL_DESTINATION    # Destination if specified (-d flag)
KAMAL_ROLE           # Role if specified
KAMAL_RUNTIME        # Deployment runtime in seconds (post-deploy only)
```

## Hook Examples

### pre-connect: Validate Network Access

```bash
#!/usr/bin/env bash

# Verify Tailscale connection
if ! tailscale status --json 2>/dev/null | jq -e '.Self.Online' >/dev/null; then
  echo "ERROR: Not connected to Tailscale" >&2
  exit 1
fi

# Test SSH access
TEST_HOST="web-1"
if ! ssh -o ConnectTimeout=5 "app@$TEST_HOST" true 2>&1; then
  echo "ERROR: Cannot SSH to $TEST_HOST" >&2
  exit 1
fi

echo "Network access verified"
exit 0
```

### pre-build: Validate Git State

```bash
#!/usr/bin/env bash

# Ensure clean working directory
if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: Working directory not clean" >&2
  exit 1
fi

# Ensure on main branch for production
if [ "$KAMAL_DESTINATION" = "production" ]; then
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [ "$BRANCH" != "main" ]; then
    echo "ERROR: Production deploys must be from main branch" >&2
    exit 1
  fi
fi

exit 0
```

### pre-deploy: Check CI Status

```bash
#!/usr/bin/env ruby

# Skip for rollbacks and non-production
exit 0 if ENV["KAMAL_COMMAND"] == "rollback"
exit 0 if ENV["KAMAL_DESTINATION"] != "production"

require "bundler/inline"

gemfile(true, quiet: true) do
  source "https://rubygems.org"
  gem "octokit"
  gem "faraday-retry"
end

MAX_ATTEMPTS = 72
ATTEMPTS_GAP = 10

def exit_with_error(message)
  $stderr.puts message
  exit 1
end

# Get repo from git remote
remote = `git config --get remote.origin.url`.strip
  .delete_suffix(".git")
  .sub(/^https:\/\/github\.com\//, "")
  .sub(/^git@github\.com:/, "")

sha = `git rev-parse HEAD`.strip
client = Octokit::Client.new(access_token: ENV["GITHUB_TOKEN"])

puts "Checking CI status for #{sha}..."

MAX_ATTEMPTS.times do |attempt|
  status = client.combined_status(remote, sha)

  case status[:state]
  when "success"
    puts "CI passed!"
    exit 0
  when "failure"
    exit_with_error "CI failed: #{status[:statuses].first[:target_url]}"
  when "pending"
    puts "CI pending (#{status[:statuses].count { |s| s[:state] != 'pending' }}/#{status[:statuses].count})..."
    sleep ATTEMPTS_GAP
  end
end

exit_with_error "CI still pending after #{MAX_ATTEMPTS * ATTEMPTS_GAP} seconds"
```

### post-deploy: Notify Slack

```bash
#!/usr/bin/env bash

MESSAGE="$KAMAL_PERFORMER deployed $KAMAL_SERVICE_VERSION to $KAMAL_DESTINATION in $KAMAL_RUNTIME seconds"

# Post to Slack webhook
curl -X POST -H 'Content-type: application/json' \
  --data "{\"text\":\"$MESSAGE\"}" \
  "$SLACK_WEBHOOK_URL"

# Create GitHub release for production
if [ "$KAMAL_DESTINATION" = "production" ]; then
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [ "$BRANCH" = "main" ]; then
    gh release create "$KAMAL_SERVICE_VERSION" \
      --target "$KAMAL_VERSION" \
      --generate-notes 2>/dev/null || true
  fi
fi

exit 0
```

### post-deploy: Notify with Release Notes

```bash
#!/usr/bin/env bash

MESSAGE="$KAMAL_PERFORMER deployed $KAMAL_SERVICE_VERSION to $KAMAL_DESTINATION in $KAMAL_RUNTIME seconds"
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Notify dashboard
bin/notify_deployment "$MESSAGE" "$KAMAL_VERSION" "$KAMAL_PERFORMER" "$BRANCH" "$KAMAL_DESTINATION" "$KAMAL_RUNTIME"

# Create release and broadcast for production main branch
if [[ $BRANCH == "main" && $KAMAL_DESTINATION == "production" ]]; then
  gh release create "$KAMAL_SERVICE_VERSION" --target "$KAMAL_VERSION" --generate-notes 2>/dev/null || true

  RELEASE_URL=$(gh release view "$KAMAL_SERVICE_VERSION" --json url --jq .url)
  RELEASE_BODY=$(gh release view "$KAMAL_SERVICE_VERSION" --json body --jq .body)

  bin/broadcast "$MESSAGE"$'\n'"$RELEASE_URL"$'\n'"$RELEASE_BODY"
else
  bin/broadcast "$MESSAGE"
fi
```

### pre-app-boot: Run Migrations

```bash
#!/usr/bin/env bash

# Run migrations before booting new containers
kamal app exec "bin/rails db:migrate"
```

## Hook Behavior

- **Non-zero exit**: Hook failure stops the operation
- **Skip hooks**: Use `--skip-hooks` flag
- **Custom path**: Set `hooks_path` in deploy.yml

## Configuration

```yaml
# deploy.yml
hooks_path: .kamal/hooks              # Default location

# Or from gem
hooks_path: <%= File.join(Gem::Specification.find_by_name("myapp").gem_dir, ".kamal", "hooks") %>
```

## Testing Hooks

```bash
# Test hook manually with environment variables
KAMAL_DESTINATION=production KAMAL_COMMAND=deploy .kamal/hooks/pre-deploy
```
