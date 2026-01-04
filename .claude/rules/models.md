---
paths: app/models/**/*.rb
---

# Model Conventions

## Structure Order

1. Concerns (alphabetized)
2. Associations
3. Validations
4. Scopes
5. Enums
6. Callbacks
7. Public methods
8. Private methods (indented 2 spaces)

## Concerns

- **Namespace model concerns**: `Card::Assignable` in `app/models/card/assignable.rb`
- **Shared concerns**: `app/models/concerns/` for cross-model behavior
- Extract features into focused modules rather than fat models

```ruby
# app/models/card/closeable.rb
module Card::Closeable
  extend ActiveSupport::Concern

  included do
    scope :open, -> { where(closed_at: nil) }
  end

  def close!
    update!(closed_at: Time.current)
  end
end
```

## Current Class

Use `Current` for request-scoped context:

```ruby
belongs_to :creator, class_name: "User", default: -> { Current.user }
```

## Key Patterns

- **Scopes over class methods** for chainable queries
- **Touch parent records** for cache invalidation: `belongs_to :book, touch: true`
- **Conditional callbacks**: Always use `:if`/`:unless`
- **Lambdas for simple callbacks**: `before_create -> { self.token = SecureRandom.hex }`
- **`to_param` for friendly URLs**: Override to use slugs or numbers
- **`store_accessor` for JSON columns**: Structured access to flexible data
- **Enums with explicit mapping**: `enum :status, %w[drafted published].index_by(&:itself)`
