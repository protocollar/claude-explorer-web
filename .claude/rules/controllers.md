---
paths: app/controllers/**/*.rb
---

# Controller Conventions

## Application Controller

Minimal base - only concern includes:

```ruby
class ApplicationController < ActionController::Base
  include Authentication, Authorization, CurrentRequest
end
```

## Structure

```ruby
class CardsController < ApplicationController
  include FilterScoped

  before_action :set_card, only: %i[show edit update destroy]
  before_action :ensure_permission_to_admin, only: %i[destroy]

  def index
    @cards = @filter.cards
  end

  def show  # Empty - just render
  end

  def create
    @card = Current.user.cards.create!(card_params)
    redirect_to @card
  end

  private
    def set_card
      @card = Current.user.cards.find(params[:id])
    end

    def card_params
      params.expect(card: [:title, :description])
    end
end
```

## Key Patterns

- **RESTful actions only** - Standard CRUD, no custom actions
- **Bang methods** - `create!`, `update!` raise on failure
- **Empty show/edit** - Just render, no logic
- **`params.expect`** - Strong parameters with expected structure
- **Private indent** - 2 spaces per Rails omakase
- **`Current` class** - Request-scoped context, not passed everywhere

## Scoped Concerns

Load parent resources from URL params:

```ruby
# app/controllers/concerns/card_scoped.rb
module CardScoped
  extend ActiveSupport::Concern
  included do
    before_action :set_card
  end
  private
    def set_card
      @card = Current.user.cards.find_by!(number: params[:card_id])
    end
end
```

## Nested Controllers

Namespace by parent resource: `Cards::CommentsController` in `app/controllers/cards/comments_controller.rb`

## Single-Action Controllers

For state changes: `Cards::ClosuresController` with only `create`/`destroy`

## Authorization

Simple `head :forbidden` checks - no gems:

```ruby
def ensure_permission_to_admin
  head :forbidden unless Current.user.can_administer?(@card)
end
```
