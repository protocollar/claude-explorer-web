# Kamal Configuration Reference

Full reference for `config/deploy.yml` options.

## Table of Contents

- [Core Settings](#core-settings)
- [Servers](#servers)
- [Registry](#registry)
- [Environment Variables](#environment-variables)
- [Proxy](#proxy)
- [Builder](#builder)
- [Accessories](#accessories)
- [SSH](#ssh)
- [Boot](#boot)
- [Aliases](#aliases)
- [Advanced Options](#advanced-options)

## Core Settings

```yaml
# Required
service: myapp              # Container name prefix
image: myuser/myapp         # Docker image name

# Optional
labels:
  my-label: my-value        # Additional container labels

volumes:
  - "/host/path:/container/path:ro"  # Mount volumes (:ro for read-only)

asset_path: /rails/public/assets     # Bridge assets between deploys

hooks_path: .kamal/hooks             # Custom hooks location (default)
secrets_path: .kamal/secrets         # Secrets file location (default)
error_pages_path: public             # Directory for 4xx/5xx error pages

primary_role: web                    # Primary role (default: web)
retain_containers: 5                 # Old containers to keep (default: 5)
readiness_delay: 7                   # Seconds to wait for container boot (default: 7)
deploy_timeout: 30                   # Max deploy time in seconds (default: 30)
drain_timeout: 30                    # Graceful shutdown time (default: 30)
run_directory: .kamal                # Runtime files directory (default: .kamal)

require_destination: false           # Require -d flag for deploys
allow_empty_roles: false             # Allow roles with no servers
minimum_version: 2.0.0               # Required Kamal version
```

## Servers

### Simple List

```yaml
servers:
  web:
    - 192.168.0.1
    - 192.168.0.2
```

### With Roles and Options

```yaml
servers:
  web:
    hosts:
      - web-1
      - web-2
    labels:
      role: web
    options:
      memory: 2g
      cpus: 2
  jobs:
    hosts:
      - jobs-1
    cmd: bin/jobs              # Custom command for this role
    proxy: false               # Disable proxy for this role
```

### Host-Specific Tags

```yaml
servers:
  web:
    hosts:
      - 192.168.0.1
      - host: 192.168.0.2
        tags:
          - monitoring
```

Use tags with `env.tags` for host-specific environment variables.

## Registry

```yaml
registry:
  server: ghcr.io                    # Registry server (default: Docker Hub)
  username: myuser
  password:
    - KAMAL_REGISTRY_PASSWORD        # From .kamal/secrets
```

### Common Registries

```yaml
# Docker Hub (default)
registry:
  username: myuser
  password:
    - KAMAL_REGISTRY_PASSWORD

# GitHub Container Registry
registry:
  server: ghcr.io
  username: myuser
  password:
    - GITHUB_TOKEN

# AWS ECR
registry:
  server: 123456789.dkr.ecr.us-east-1.amazonaws.com
  username: AWS
  password:
    - AWS_ECR_PASSWORD

# DigitalOcean
registry:
  server: registry.digitalocean.com
  username: mytoken
  password:
    - DO_REGISTRY_TOKEN
```

## Environment Variables

```yaml
env:
  # Plain text variables
  clear:
    DATABASE_HOST: db.example.com
    RAILS_ENV: production
    SOLID_QUEUE_IN_PUMA: true

  # Secrets (from .kamal/secrets, stored in env file on host)
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_PASSWORD
    - DB_PASSWORD:MAIN_DB_PASSWORD   # Alias: env name:secret name

  # Tag-specific variables (for tagged hosts)
  tags:
    monitoring:
      MYSQL_USER: monitoring
    replica:
      clear:
        MYSQL_USER: readonly
      secret:
        - READONLY_PASSWORD
```

## Proxy

kamal-proxy provides zero-downtime deployments and automatic SSL.

```yaml
proxy:
  # Host routing
  host: app.example.com              # Single host
  hosts:                             # Multiple hosts
    - app.example.com
    - www.example.com

  app_port: 3000                     # Container port (default: 80)

  # SSL via Let's Encrypt
  ssl: true                          # Auto SSL (single server only)
  ssl_redirect: true                 # Redirect HTTP to HTTPS (default: true)

  # Custom SSL certificate
  ssl:
    certificate_pem: CERTIFICATE_PEM    # Secret name
    private_key_pem: PRIVATE_KEY_PEM    # Secret name

  forward_headers: true              # Forward X-Forwarded-* headers

  response_timeout: 30               # Request timeout seconds (default: 30)

  # Path-based routing
  path_prefix: "/api"                # Mount under path
  path_prefixes:
    - "/api"
    - "/oauth_callback"
  strip_path_prefix: true            # Remove prefix before forwarding (default: true)

  # Health check
  healthcheck:
    path: /up                        # Health endpoint (default: /up)
    interval: 1                      # Check interval seconds (default: 1)
    timeout: 5                       # Check timeout seconds (default: 5)

  # Request/response buffering
  buffering:
    requests: true
    responses: true
    max_request_body: 1_000_000_000  # 1GB default
    max_response_body: 0             # Unlimited default
    memory: 1_000_000                # 1MB memory buffer default

  # Logging
  logging:
    request_headers:
      - Cache-Control
      - X-Forwarded-Proto
    response_headers:
      - X-Request-ID

  # Proxy container settings
  run:
    http_port: 80                    # Default: 80
    https_port: 443                  # Default: 443
    metrics_port: 9090               # Prometheus metrics (optional)
    debug: false
    log_max_size: "10m"
    publish: true                    # Publish ports to host
    bind_ips:
      - 0.0.0.0
    version: v0.8.0                  # kamal-proxy version
```

## Builder

```yaml
builder:
  arch: amd64                        # Architecture (amd64, arm64, or both)
  # arch:
  #   - amd64
  #   - arm64

  dockerfile: Dockerfile             # Dockerfile path (default: Dockerfile)
  context: .                         # Build context (default: git clone)
  target: production                 # Multi-stage target

  # Remote builder (for cross-architecture builds)
  remote: ssh://docker@builder-host
  local: true                        # Use local for matching arch (default: true)

  # Build arguments
  args:
    RUBY_VERSION: 3.3.0
    NODE_VERSION: 20

  # Build secrets (from .kamal/secrets)
  secrets:
    - GITHUB_TOKEN
    - BUNDLE_GEMS__EXAMPLE__COM

  # SSH forwarding for private repos
  ssh: default=$SSH_AUTH_SOCK

  # Build cache
  cache:
    type: registry                   # registry or gha
    image: myapp-build-cache
    options: mode=max

  # Cloud Native Buildpacks
  pack:
    builder: heroku/builder:24
    buildpacks:
      - heroku/ruby
      - heroku/procfile

  # Driver
  driver: docker-container           # Default
  # driver: cloud org-name/builder   # Docker Build Cloud

  # Attestations
  provenance: mode=max               # Provenance attestations
  sbom: true                         # Software Bill of Materials
```

## Accessories

Additional services (databases, caches) managed separately from main app.

```yaml
accessories:
  db:
    image: postgres:16
    host: 192.168.0.2                # Single host
    # hosts:                         # Multiple hosts
    #   - db-1
    #   - db-2
    # role: database                 # Or by role
    # tag: primary                   # Or by tag

    service: myapp-db                # Service name (default: <service>-<accessory>)
    cmd: "postgres -c max_connections=200"  # Custom command
    port: "127.0.0.1:5432:5432"      # Port mapping (local:host:container)

    env:
      clear:
        POSTGRES_DB: myapp_production
      secret:
        - POSTGRES_PASSWORD

    # Mount files (copied to host)
    files:
      - config/postgres.conf:/etc/postgresql/postgresql.conf
      - config/pg_hba.conf.erb:/etc/postgresql/pg_hba.conf  # ERB evaluated

    # Mount directories (created on host)
    directories:
      - data:/var/lib/postgresql/data

    # Additional volumes
    volumes:
      - /mnt/backups:/backups

    labels:
      app: myapp
      service: database

    options:
      restart: always
      memory: 4g
      cpus: 2

    network: kamal                   # Docker network (default: kamal)

  redis:
    image: valkey/valkey:8
    host: 192.168.0.2
    port: 6379
    directories:
      - data:/data
```

## SSH

```yaml
ssh:
  user: deploy                       # SSH user (default: root)
  port: 22                           # SSH port (default: 22)
  proxy: ssh://jump@bastion.example.com  # Jump host
  proxy_command: "ssh -W %h:%p bastion"  # Custom proxy command
  keys:
    - ~/.ssh/id_rsa                  # SSH key paths
  keys_only: true                    # Only use specified keys
  log_level: :debug                  # SSH debug level
```

## Boot

Control rolling deploys.

```yaml
boot:
  limit: 10                          # Max containers to boot at once
  # limit: "25%"                     # Or as percentage
  wait: 2                            # Seconds between batches
```

## Aliases

Command shortcuts triggered with `kamal <alias>`.

```yaml
aliases:
  console: app exec --interactive --reuse "bin/rails console"
  shell: app exec --interactive --reuse "bash"
  logs: app logs -f
  dbc: app exec --interactive --reuse "bin/rails dbconsole --include-password"
  migrate: app exec "bin/rails db:migrate"
```

With environment variables:

```yaml
aliases:
  console: app exec -i --reuse -e CONSOLE_USER:<%= ENV["USER"] %> "bin/rails console"
```

## Advanced Options

### YAML Extensions

Use `x-` prefix for YAML anchors (Kamal ignores these):

```yaml
x-common-env: &common-env
  RAILS_ENV: production
  RAILS_LOG_TO_STDOUT: true

env:
  clear:
    <<: *common-env
    SERVICE_NAME: web

servers:
  web:
    hosts:
      - web-1
    env:
      clear:
        <<: *common-env
        SERVICE_NAME: web
```

### ERB in Configuration

```yaml
builder:
  args:
    RUBY_VERSION: <%= ENV["RBENV_VERSION"] || "3.3.0" %>

aliases:
  console: app exec -i -e USER:<%= ENV["USER"] %> "bin/rails console"
```

### SSHKit Options

```yaml
sshkit:
  max_concurrent_starts: 30          # Parallel connections
  pool_idle_timeout: 300             # Connection pool timeout
```

### Logging

```yaml
logging:
  driver: json-file
  options:
    max-size: "100m"
    max-file: "5"
```
