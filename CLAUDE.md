# CLAUDE.md

## What This Is

Claude Explorer is a Rails app that parses local Claude conversation data for exploration via web UI.

## Stack

- Rails 8.1 with Propshaft, SQLite, Solid Queue/Cache/Cable
- Hotwire (Turbo + Stimulus) - no JavaScript build
- Minitest with fixtures

## Development Workflow

```bash
bin/dev                    # Start dev server
bin/rails test             # Run tests (append path:line to run specific)
bin/ci                     # Full CI: lint, security, tests
bin/rubocop -a             # Auto-fix Ruby lint issues
bin/erb_lint -a --lint-all # Auto-fix ERB lint issues
```

Use binstubs (`bin/rails`, `bin/rake`, `bin/rubocop`, `bin/erb_lint`, `bin/brakeman`) instead of `bundle exec`.

## Rules

Rules in `.claude/rules/` auto-load. Path-specific rules apply when working with matching files:

| Rule | Paths |
|------|-------|
| `models.md` | `app/models/**/*.rb` |
| `controllers.md` | `app/controllers/**/*.rb` |
| `views.md` | `app/views/**/*.erb` |
| `turbo.md` | `app/views/**/*.erb`, `app/controllers/**/*.rb` |
| `stimulus.md` | `app/javascript/controllers/**/*.js` |
| `css.md` | `app/assets/stylesheets/**/*.css` |
| `testing.md` | `test/**/*.rb` |
| `ui-validation.md` | Global - browser validation for UI features |
| `git.md` | Git commit conventions |
| `pull-requests.md` | PR description format |

## Commands

| Command | Purpose |
|---------|---------|
| `/commit` | Create conventional commit following git rules |
| `/pr` | Create, update, or check PR status |

## Skills

| Skill | When to use |
|-------|-------------|
| `hotwire` | Turbo Drive/Frames/Streams, Stimulus controllers |
| `kamal` | Docker deployment configuration |

## Key Conventions

- **Controllers**: Nested under resources, use concerns for shared setup
- **Models**: Feature modules as concerns (e.g., `Card::Taggable`)
- **Views**: Partials prefixed `_`, Turbo Frames for partial updates
- **CSS**: One plain CSS file per feature, no frameworks

When you notice a pattern being repeated, consider whether it should become a rule or documented pattern.
