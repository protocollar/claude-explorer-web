# Kamal Commands Reference

## Table of Contents

- [Global Options](#global-options)
- [Main Commands](#main-commands)
- [App Commands](#app-commands)
- [Build Commands](#build-commands)
- [Proxy Commands](#proxy-commands)
- [Accessory Commands](#accessory-commands)
- [Server Commands](#server-commands)
- [Registry Commands](#registry-commands)
- [Lock Commands](#lock-commands)
- [Secrets Commands](#secrets-commands)

## Global Options

Apply to any command:

```bash
-v, --verbose              # Detailed logging
-q, --quiet                # Minimal logging
--version=VERSION          # Run against specific app version
-p, --primary              # Run only on primary host
-h, --hosts=HOSTS          # Run on specific hosts (comma-separated, wildcards OK)
-r, --roles=ROLES          # Run on specific roles (comma-separated, wildcards OK)
-c, --config-file=FILE     # Config file path (default: config/deploy.yml)
-d, --destination=DEST     # Deployment destination
-H, --skip-hooks           # Skip hooks
```

## Main Commands

### kamal init

Create configuration files.

```bash
kamal init                           # Create config/deploy.yml and .kamal/secrets
kamal init --bundle                  # Also add to Gemfile
```

### kamal setup

First-time deployment setup.

```bash
kamal setup                          # Bootstrap servers and deploy
kamal setup -d staging               # Setup for staging destination
```

### kamal deploy

Deploy application.

```bash
kamal deploy                         # Deploy new version
kamal deploy -d production           # Deploy to production
kamal deploy --skip-hooks            # Skip pre/post hooks
kamal deploy -h "web-*"              # Deploy to matching hosts only
kamal deploy -r web                  # Deploy web role only
```

### kamal redeploy

Deploy without bootstrapping.

```bash
kamal redeploy                       # Skip bootstrap, proxy setup, registry login
```

### kamal rollback

Revert to previous version.

```bash
kamal rollback                       # Roll back to previous version
kamal rollback abc123def             # Roll back to specific version
```

### kamal remove

Remove everything.

```bash
kamal remove                         # Remove proxy, app, accessories, registry session
kamal remove --confirmed             # Skip confirmation
```

### kamal config

Show resolved configuration.

```bash
kamal config                         # Show full config (includes secrets!)
kamal config -d staging              # Show staging config
```

### kamal details

Show container details.

```bash
kamal details                        # Show all container details
```

### kamal audit

Show deployment audit log.

```bash
kamal audit                          # Show audit log from servers
```

### kamal version

Show Kamal version.

```bash
kamal version                        # Show version
```

### kamal docs

Show configuration documentation.

```bash
kamal docs                           # List all docs
kamal docs proxy                     # Show proxy configuration docs
kamal docs builder                   # Show builder configuration docs
```

### kamal upgrade

Upgrade from Kamal 1.x.

```bash
kamal upgrade                        # Upgrade to Kamal 2.0
```

## App Commands

### kamal app boot

Boot app containers.

```bash
kamal app boot                       # Boot app on all servers
kamal app boot -h web-1              # Boot on specific host
```

### kamal app start

Start stopped containers.

```bash
kamal app start                      # Start app containers
```

### kamal app stop

Stop running containers.

```bash
kamal app stop                       # Stop app containers
```

### kamal app exec

Execute command in container.

```bash
kamal app exec "bin/rails runner 'puts User.count'"  # Run command
kamal app exec -i "bin/rails console"                # Interactive
kamal app exec -i --reuse "bash"                     # Reuse container
kamal app exec -r jobs "bin/rails runner 'Job.count'"  # On jobs role
```

Options:

```bash
-i, --interactive          # Interactive mode (allocate TTY)
--reuse                    # Reuse existing container
-e, --env=KEY:VALUE        # Set environment variable
```

### kamal app logs

View application logs.

```bash
kamal app logs                       # Show recent logs
kamal app logs -f                    # Follow logs
kamal app logs -n 100                # Last 100 lines
kamal app logs --since 1h            # Logs from last hour
kamal app logs -h web-1              # Logs from specific host
kamal app logs -r jobs               # Logs from jobs role
```

### kamal app containers

List app containers.

```bash
kamal app containers                 # List all app containers
```

### kamal app images

List app images.

```bash
kamal app images                     # List all app images
```

### kamal app version

Show running version.

```bash
kamal app version                    # Show running app version
```

### kamal app remove

Remove app containers.

```bash
kamal app remove                     # Remove app containers
kamal app remove --confirmed         # Skip confirmation
```

## Build Commands

### kamal build push

Build and push image.

```bash
kamal build push                     # Build and push to registry
```

### kamal build pull

Pull image from registry.

```bash
kamal build pull                     # Pull image to all servers
```

### kamal build create

Create build environment.

```bash
kamal build create                   # Create buildx builder
```

### kamal build remove

Remove build environment.

```bash
kamal build remove                   # Remove buildx builder
```

### kamal build details

Show build details.

```bash
kamal build details                  # Show builder details
```

## Proxy Commands

### kamal proxy boot

Start kamal-proxy.

```bash
kamal proxy boot                     # Boot proxy on all servers
kamal proxy boot -h web-1            # Boot on specific host
```

### kamal proxy reboot

Restart kamal-proxy.

```bash
kamal proxy reboot                   # Restart proxy
kamal proxy reboot --rolling         # Rolling restart
```

### kamal proxy start

Start stopped proxy.

```bash
kamal proxy start                    # Start proxy containers
```

### kamal proxy stop

Stop proxy.

```bash
kamal proxy stop                     # Stop proxy containers
```

### kamal proxy logs

View proxy logs.

```bash
kamal proxy logs                     # Show proxy logs
kamal proxy logs -f                  # Follow proxy logs
```

### kamal proxy details

Show proxy details.

```bash
kamal proxy details                  # Show proxy configuration
```

### kamal proxy remove

Remove proxy.

```bash
kamal proxy remove                   # Remove proxy containers
kamal proxy remove --confirmed       # Skip confirmation
```

## Accessory Commands

### kamal accessory boot

Boot accessory.

```bash
kamal accessory boot all             # Boot all accessories
kamal accessory boot db              # Boot specific accessory
```

### kamal accessory start

Start stopped accessory.

```bash
kamal accessory start db             # Start db accessory
```

### kamal accessory stop

Stop accessory.

```bash
kamal accessory stop db              # Stop db accessory
```

### kamal accessory reboot

Restart accessory.

```bash
kamal accessory reboot db            # Restart db accessory
```

### kamal accessory exec

Execute command in accessory.

```bash
kamal accessory exec db "psql -U postgres"  # Run command
kamal accessory exec -i db "bash"           # Interactive
```

### kamal accessory logs

View accessory logs.

```bash
kamal accessory logs db              # Show db logs
kamal accessory logs -f db           # Follow db logs
```

### kamal accessory details

Show accessory details.

```bash
kamal accessory details db           # Show db details
```

### kamal accessory remove

Remove accessory.

```bash
kamal accessory remove db            # Remove db accessory
kamal accessory remove db --confirmed  # Skip confirmation
```

## Server Commands

### kamal server bootstrap

Bootstrap servers with Docker.

```bash
kamal server bootstrap               # Install Docker on servers
```

### kamal server exec

Execute command on host.

```bash
kamal server exec "df -h"            # Run on all servers
kamal server exec -h web-1 "uptime"  # Run on specific host
```

## Registry Commands

### kamal registry login

Login to registry.

```bash
kamal registry login                 # Login to configured registry
```

### kamal registry logout

Logout from registry.

```bash
kamal registry logout                # Logout from registry
```

## Lock Commands

Prevent concurrent deployments.

### kamal lock status

Check lock status.

```bash
kamal lock status                    # Show lock status
```

### kamal lock acquire

Acquire deployment lock.

```bash
kamal lock acquire                   # Acquire lock
kamal lock acquire -m "Deploying v1.2"  # With message
```

### kamal lock release

Release deployment lock.

```bash
kamal lock release                   # Release lock
```

## Secrets Commands

### kamal secrets fetch

Fetch secrets from password manager.

```bash
# 1Password
kamal secrets fetch --adapter 1password --account myaccount \
  --from Vault/Item SECRET1 SECRET2

# Bitwarden
kamal secrets fetch --adapter bitwarden \
  --from folder/item SECRET1 SECRET2

# LastPass
kamal secrets fetch --adapter last_pass \
  --from folder SECRET1 SECRET2

# AWS Secrets Manager
kamal secrets fetch --adapter aws_secrets_manager \
  --from secret-name SECRET1 SECRET2

# GCP Secret Manager
kamal secrets fetch --adapter gcp_secret_manager \
  --from project-id SECRET1 SECRET2

# Doppler
kamal secrets fetch --adapter doppler \
  --from project/config SECRET1 SECRET2
```

### kamal secrets extract

Extract single secret from fetched secrets.

```bash
SECRETS=$(kamal secrets fetch ...)
kamal secrets extract SECRET_NAME $SECRETS
```

## Prune Commands

Clean up old containers and images.

### kamal prune all

Prune containers and images.

```bash
kamal prune all                      # Prune everything
```

### kamal prune containers

Prune old containers.

```bash
kamal prune containers               # Remove old app containers
```

### kamal prune images

Prune old images.

```bash
kamal prune images                   # Remove old app images
```
