# Rails Integration

## Table of Contents
- [Installation](#installation)
- [Turbo Rails Helpers](#turbo-rails-helpers)
- [Stimulus Rails](#stimulus-rails)
- [Testing](#testing)
- [Action Cable](#action-cable)

## Installation

Rails 7+ includes Hotwire by default. For Rails 6:

```ruby
# Gemfile
gem "turbo-rails"
gem "stimulus-rails"
```

```bash
./bin/bundle install
./bin/rails turbo:install
./bin/rails stimulus:install
```

## Turbo Rails Helpers

### turbo_frame_tag

```erb
<%# Basic - uses dom_id(@model) %>
<%= turbo_frame_tag @model do %>
  content
<% end %>

<%# With suffix %>
<%= turbo_frame_tag @model, :edit do %>  <!-- id="model_123_edit" -->

<%# Custom ID %>
<%= turbo_frame_tag "custom_id" do %>

<%# With src (eager load) %>
<%= turbo_frame_tag "sidebar", src: sidebar_path %>

<%# Lazy load %>
<%= turbo_frame_tag "comments", src: comments_path, loading: "lazy" %>

<%# With target %>
<%= turbo_frame_tag "nav", target: "_top" do %>

<%# With morphing %>
<%= turbo_frame_tag @model, refresh: "morph" %>

<%# With data attributes %>
<%= turbo_frame_tag @model, data: { turbo_action: "advance" } %>
```

### turbo_stream Helpers

**In .turbo_stream.erb templates:**
```erb
<%= turbo_stream.append :target, @model %>
<%= turbo_stream.append :target, partial: "item", locals: { item: @item } %>
<%= turbo_stream.prepend :items, @item %>
<%= turbo_stream.replace @model %>
<%= turbo_stream.update :counter, "42" %>
<%= turbo_stream.update :form do %>
  <%= render "form" %>
<% end %>
<%= turbo_stream.remove @model %>
<%= turbo_stream.before @model, partial: "divider" %>
<%= turbo_stream.after @model, partial: "footer" %>
```

**Inline in controller:**
```ruby
def create
  @item = Item.create!(item_params)

  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: [
        turbo_stream.append(:items, @item),
        turbo_stream.update(:count, Item.count.to_s)
      ]
    end
    format.html { redirect_to items_path }
  end
end
```

### turbo_stream_from

Subscribe to broadcasts:
```erb
<%= turbo_stream_from @room %>
<%= turbo_stream_from @room, :messages %>
<%= turbo_stream_from current_user, :notifications %>
```

### Drive Helpers

```erb
<%# Disable turbo %>
<%= link_to "Regular", path, data: { turbo: false } %>

<%# Confirm dialog %>
<%= button_to "Delete", path, method: :delete,
      data: { turbo_confirm: "Are you sure?" } %>

<%# Custom method %>
<%= link_to "Archive", path, data: { turbo_method: :patch } %>

<%# Frame targeting %>
<%= link_to "Edit", edit_path, data: { turbo_frame: "modal" } %>
<%= link_to "Full page", path, data: { turbo_frame: "_top" } %>
```

### Controller Helpers

```ruby
class ItemsController < ApplicationController
  def create
    @item = Item.create!(item_params)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @item, notice: "Created!" }
    end
  end

  def update
    @item.update!(item_params)

    # Redirect with flash works with Turbo
    redirect_to @item, notice: "Updated!"
  end

  def destroy
    @item.destroy!

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@item) }
      format.html { redirect_to items_path, notice: "Deleted!" }
    end
  end
end
```

### Request Detection

```ruby
# Check if turbo frame request
if turbo_frame_request?
  # Respond with just the frame content
end

# Get the requesting frame ID
turbo_frame_request_id  # => "item_123"
```

### Custom Layouts for Frames

```ruby
class ApplicationController < ActionController::Base
  layout :determine_layout

  private

  def determine_layout
    turbo_frame_request? ? "turbo_rails/frame" : "application"
  end
end
```

## Stimulus Rails

### Generator

```bash
# Create new controller
bin/rails generate stimulus example

# Creates app/javascript/controllers/example_controller.js
```

### File Structure

```
app/javascript/
├── application.js
├── controllers/
│   ├── index.js           # Auto-registration
│   ├── application.js     # Stimulus app setup
│   └── example_controller.js
└── helpers/               # Shared utilities
    └── timing_helpers.js
```

### Controller Setup (Import Map)

```javascript
// app/javascript/controllers/application.js
import { Application } from "@hotwired/stimulus"

const application = Application.start()
application.debug = false
window.Stimulus = application

export { application }
```

```javascript
// app/javascript/controllers/index.js
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
```

### Import Map Config

```ruby
# config/importmap.rb
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
```

## Testing

### Turbo Stream Assertions

```ruby
class ItemsControllerTest < ActionDispatch::IntegrationTest
  test "create returns turbo stream" do
    post items_path, params: { item: { name: "Test" } },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_turbo_stream action: :append, target: "items"
  end
end
```

Available assertions:
```ruby
assert_turbo_stream action: :append, target: "items"
assert_turbo_stream action: :replace, target: dom_id(@item)
assert_turbo_stream action: :remove, target: dom_id(@item)
assert_turbo_stream action: :update, target: "counter"
assert_no_turbo_stream action: :remove
```

### Broadcast Test Helper

```ruby
class MessageTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  test "broadcasts on create" do
    assert_broadcasts_on [:messages], count: 1 do
      Message.create!(content: "Hello")
    end
  end

  test "no broadcast on invalid" do
    assert_no_broadcasts_on [:messages] do
      Message.create(content: nil)  # Invalid
    end
  end
end
```

### System Test Helpers

```ruby
class MessagesSystemTest < ApplicationSystemTestCase
  test "creates message with turbo" do
    visit messages_path

    fill_in "Content", with: "Hello"
    click_button "Send"

    # Wait for turbo cable stream to connect
    connect_turbo_cable_stream_sources

    assert_text "Hello"
  end
end
```

## Action Cable

### Channel for Turbo Streams

Turbo automatically uses `Turbo::StreamsChannel` for broadcasts.

**Custom channel:**
```ruby
# app/channels/room_channel.rb
class RoomChannel < ApplicationCable::Channel
  def subscribed
    if @room = current_user.rooms.find_by(id: params[:room_id])
      stream_for @room
    else
      reject
    end
  end
end
```

### Solid Cable (No Redis)

```ruby
# Gemfile
gem "solid_cable"
```

```yaml
# config/cable.yml
production:
  adapter: solid_cable
```

```yaml
# config/database.yml
production:
  cable:
    <<: *default
    database: storage/production_cable.sqlite3
    migrations_paths: db/cable_migrate
```

### Development Note

In development, broadcasts only work within the same process. Use `web-console` instead of `rails console` to test broadcasts.
