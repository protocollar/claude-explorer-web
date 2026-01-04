# Common Kamal Patterns

Production-ready deployment patterns for Rails applications.

## Single-Container Pattern

Deploy apps in a single container with jobs running in the Puma process.

```yaml
service: myapp
image: myapp

servers:
  web:
    - 192.168.0.1

registry:
  server: ghcr.io
  username: myuser
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  secret:
    - RAILS_MASTER_KEY
  clear:
    SOLID_QUEUE_IN_PUMA: true    # Jobs in Puma process

volumes:
  - "myapp_storage:/rails/storage"

asset_path: /rails/public/assets

aliases:
  console: app exec --interactive --reuse "bin/rails console"
  shell: app exec --interactive --reuse "bash"
  logs: app logs -f
  dbc: app exec --interactive --reuse "bin/rails dbconsole --include-password"
```

### Key Points

- `SOLID_QUEUE_IN_PUMA: true` runs Solid Queue in the web process
- Single container simplifies deployment and reduces infrastructure
- SQLite database in persistent volume (`/rails/storage`)
- Asset bridging prevents 404s during deploys

## Multi-Environment Pattern

For applications with multiple environments and servers:

```yaml
# config/deploy.yml (base)
service: myapp
image: myuser/myapp
asset_path: /rails/public/assets

servers:
  jobs:
    cmd: bin/jobs

volumes:
  - myapp:/rails/storage

proxy:
  ssl: true

registry:
  server: ghcr.io
  username: myuser
  password:
    - KAMAL_REGISTRY_PASSWORD

builder:
  arch: amd64
  remote: ssh://app@docker-builder
  local: <%= ENV.fetch("KAMAL_BUILDER_LOCAL", "true") %>
  secrets:
    - GITHUB_TOKEN

aliases:
  console: app exec -i --reuse -e CONSOLE_USER:<%= ENV["USER"] %> "bin/rails console"
  ssh: app exec -i --reuse -e CONSOLE_USER:<%= ENV["USER"] %> /bin/bash
```

```yaml
# config/deploy.production.yml
servers:
  web:
    hosts:
      - web-1
      - web-2
      - web-3
      - web-4
  jobs:
    hosts:
      - jobs-1
      - jobs-2
```

### Key Points

- Base config in `deploy.yml`, environment-specific in `deploy.<dest>.yml`
- Separate web and jobs roles
- Remote builder for consistent builds
- ERB for dynamic configuration

## Secrets Management with 1Password

```shell
# .kamal/secrets.production
SECRETS=$(kamal secrets fetch --adapter 1password --account myaccount \
  --from Vault/App \
  KAMAL_REGISTRY_PASSWORD \
  RAILS_MASTER_KEY \
  DATABASE_PASSWORD \
  SECRET_KEY_BASE)

GITHUB_TOKEN=$(gh config get -h github.com oauth_token)
KAMAL_REGISTRY_PASSWORD=$(kamal secrets extract KAMAL_REGISTRY_PASSWORD $SECRETS)
RAILS_MASTER_KEY=$(kamal secrets extract RAILS_MASTER_KEY $SECRETS)
DATABASE_PASSWORD=$(kamal secrets extract DATABASE_PASSWORD $SECRETS)
# ... more secrets
```

### Key Points

- Batch fetch secrets in single 1Password call
- Use `kamal secrets extract` to parse
- GitHub token from `gh` CLI
- Separate secrets files per destination

## Pre-Connect Hook: Network Validation

```bash
#!/usr/bin/env bash

# Check VPN/Tailscale connection
if ! tailscale status --json 2>/dev/null | jq -e '.Self.Online' >/dev/null; then
  echo "ERROR: Connect to VPN/Tailscale to deploy" >&2
  exit 1
fi

# Verify SSH access
TEST_HOST="web-1"
SSH_OUTPUT=$(ssh -o ConnectTimeout=5 "deploy@$TEST_HOST" true 2>&1)

if echo "$SSH_OUTPUT" | grep -q "Permission denied"; then
  echo "ERROR: SSH authentication failed" >&2
  echo "Verify your SSH key is configured correctly" >&2
  exit 1
fi

echo "Network access verified"
```

## Post-Deploy Hook: Notifications

```bash
#!/usr/bin/env bash

MESSAGE="$KAMAL_PERFORMER deployed $KAMAL_SERVICE_VERSION to $KAMAL_DESTINATION in $KAMAL_RUNTIME seconds"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Post to Slack
curl -X POST -H 'Content-type: application/json' \
  --data "{\"text\":\"$MESSAGE\"}" \
  "$SLACK_WEBHOOK_URL"

# Create GitHub release for production main branch
if [[ $CURRENT_BRANCH == "main" && $KAMAL_DESTINATION == "production" ]]; then
  gh release create $KAMAL_SERVICE_VERSION --target $KAMAL_VERSION --generate-notes 2>/dev/null || true

  RELEASE_URL=$(gh release view $KAMAL_SERVICE_VERSION --json url --jq .url)
  echo "Release created: $RELEASE_URL"
fi
```

## Dockerfile Pattern

Multi-stage build with jemalloc and Thruster:

```dockerfile
ARG RUBY_VERSION=3.4.7
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Install runtime dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl libjemalloc2 libvips sqlite3 libssl-dev && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 \
      /usr/local/lib/libjemalloc.so

# Enable jemalloc for reduced memory
ENV LD_PRELOAD="/usr/local/lib/libjemalloc.so"

# === Build Stage ===
FROM base AS build

RUN apt-get install --no-install-recommends -y \
      build-essential git libyaml-dev pkg-config

COPY Gemfile Gemfile.lock vendor ./
RUN bundle install && \
    bundle exec bootsnap precompile --gemfile

COPY . .
RUN bundle exec bootsnap precompile app/ lib/
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# === Final Stage ===
FROM base

# Non-root user
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000

USER 1000:1000

COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /rails /rails

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
```

### Key Points

- **jemalloc**: Reduces Ruby memory usage
- **bootsnap precompile**: Faster boot times
- **SECRET_KEY_BASE_DUMMY**: Asset precompile without real secrets
- **Non-root user**: Security best practice
- **Thruster**: HTTP/2 proxy in front of Puma (replaces nginx)
- **Multi-stage**: Smaller final image (no build tools)

## Health Check Endpoint

```ruby
# config/routes.rb
get "up" => "rails/health#show"
```

Kamal checks `/up` to verify container health before routing traffic.

## Summary

Common patterns:

1. **Single container** for simple deployments (jobs in Puma)
2. **Multi-container** for scale (separate web/jobs)
3. **SQLite with Solid** adapters (Queue, Cache, Cable)
4. **1Password** for secrets management
5. **Thruster** instead of nginx
6. **jemalloc** for memory optimization
7. **Asset bridging** for zero-downtime
8. **Hooks** for CI checks and notifications
9. **VPN/Tailscale** for secure network access
