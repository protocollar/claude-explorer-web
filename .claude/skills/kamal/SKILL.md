---
name: kamal
description: "Deploy Rails applications with Kamal (Docker + SSH). Use when: (1) Creating or modifying deploy.yml configuration, (2) Setting up new server deployments, (3) Configuring kamal-proxy, SSL, or accessories, (4) Writing deployment hooks, (5) Managing secrets with 1Password/Bitwarden/LastPass, (6) Troubleshooting deployment issues, (7) Setting up multi-server or multi-destination deployments."
---

# Kamal Deployment

Kamal deploys containerized applications via SSH. It builds Docker images, pushes to registries, and orchestrates zero-downtime deployments using kamal-proxy.

## Quick Reference

```bash
kamal init              # Create config/deploy.yml and .kamal/secrets
kamal setup             # First-time setup (bootstrap + deploy)
kamal deploy            # Deploy new version
kamal rollback VERSION  # Revert to specific version
kamal app logs -f       # Tail application logs
kamal console           # Rails console (via alias)
```

## Configuration Workflow

1. **Initialize**: `kamal init` creates `config/deploy.yml` and `.kamal/secrets`
2. **Configure**: Edit `deploy.yml` with service, servers, registry, and env
3. **Secrets**: Set up `.kamal/secrets` to fetch from password manager
4. **Deploy**: Run `kamal setup` for first deployment, `kamal deploy` thereafter

### Minimal deploy.yml

```yaml
service: myapp
image: myuser/myapp

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
    SOLID_QUEUE_IN_PUMA: true

volumes:
  - "myapp_storage:/rails/storage"

asset_path: /rails/public/assets

builder:
  arch: amd64

aliases:
  console: app exec --interactive --reuse "bin/rails console"
  shell: app exec --interactive --reuse "bash"
  logs: app logs -f
```

### Secrets File (.kamal/secrets)

```shell
# Fetch from 1Password
SECRETS=$(kamal secrets fetch --adapter 1password --account myaccount \
  --from Vault/Item KAMAL_REGISTRY_PASSWORD RAILS_MASTER_KEY)

KAMAL_REGISTRY_PASSWORD=$(kamal secrets extract KAMAL_REGISTRY_PASSWORD $SECRETS)
RAILS_MASTER_KEY=$(kamal secrets extract RAILS_MASTER_KEY $SECRETS)

# Or from environment
# KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD

# Or from file
# RAILS_MASTER_KEY=$(cat config/master.key)
```

## Key Configuration Sections

| Section | Purpose | Reference |
|---------|---------|-----------|
| `servers` | Deployment targets and roles | [configuration.md](references/configuration.md#servers) |
| `proxy` | kamal-proxy settings (SSL, hosts, healthcheck) | [configuration.md](references/configuration.md#proxy) |
| `builder` | Docker build options (arch, remote, cache) | [configuration.md](references/configuration.md#builder) |
| `env` | Environment variables (clear/secret) | [configuration.md](references/configuration.md#environment-variables) |
| `accessories` | Additional services (db, redis) | [configuration.md](references/configuration.md#accessories) |

## Destinations

Use destinations for staging/production environments:

```bash
kamal deploy -d staging     # Uses config/deploy.staging.yml
kamal deploy -d production  # Uses config/deploy.production.yml
```

Destination configs merge with base `deploy.yml`. Secrets read from `.kamal/secrets.<destination>`.

## Hooks

Place executable scripts in `.kamal/hooks/` (no extension):

| Hook | Trigger |
|------|---------|
| `pre-connect` | Before SSH connections |
| `pre-build` | Before Docker build |
| `pre-deploy` | Before deployment starts |
| `post-deploy` | After successful deployment |
| `pre-app-boot` / `post-app-boot` | Around container boot |

Available environment variables: `KAMAL_PERFORMER`, `KAMAL_VERSION`, `KAMAL_DESTINATION`, `KAMAL_RUNTIME`, `KAMAL_HOSTS`

See [hooks.md](references/hooks.md) for examples.

## Common Patterns

### Single-Server Rails

```yaml
service: myapp
image: myapp

servers:
  web:
    - 192.168.0.1

env:
  clear:
    SOLID_QUEUE_IN_PUMA: true  # Jobs in Puma process

volumes:
  - "myapp_storage:/rails/storage"

asset_path: /rails/public/assets

proxy:
  ssl: true
  host: myapp.example.com
```

### Multi-Server with Separate Jobs

```yaml
servers:
  web:
    hosts:
      - web-1
      - web-2
  jobs:
    hosts:
      - jobs-1
    cmd: bin/jobs
```

### Database Accessory

```yaml
accessories:
  db:
    image: postgres:16
    host: 192.168.0.2
    port: "127.0.0.1:5432:5432"
    env:
      secret:
        - POSTGRES_PASSWORD
    directories:
      - data:/var/lib/postgresql/data
```

## Commands Reference

See [commands.md](references/commands.md) for full CLI reference.

| Command | Purpose |
|---------|---------|
| `kamal app exec "cmd"` | Run command in container |
| `kamal app logs -f` | Tail logs |
| `kamal proxy reboot` | Restart kamal-proxy |
| `kamal rollback` | Revert to previous version |
| `kamal prune all` | Clean old containers/images |
| `kamal config` | Show resolved configuration |
| `kamal lock status` | Check deployment lock |

## Troubleshooting

- **Health check failing**: Check `/up` endpoint responds 200, verify `proxy.healthcheck.path`
- **SSL not working**: Ensure port 443 open, host DNS resolves to server
- **Build slow**: Use `builder.remote` for remote builds, or `builder.cache` for layer caching
- **Container not starting**: Check `kamal app logs`, verify environment variables
- **Permission denied**: Check SSH key, ensure user can run Docker

## Reference Files

- [configuration.md](references/configuration.md) - Full deploy.yml options
- [commands.md](references/commands.md) - CLI commands reference
- [hooks.md](references/hooks.md) - Hook system and examples
- [patterns.md](references/patterns.md) - Common production patterns
