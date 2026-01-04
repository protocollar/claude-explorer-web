# Turbo Reference

## Table of Contents
- [Turbo Drive](#turbo-drive)
- [Turbo Frames](#turbo-frames)
- [Turbo Streams](#turbo-streams)
- [Morphing](#morphing)

## Turbo Drive

Turbo Drive intercepts link clicks and form submissions, fetching pages via AJAX and replacing the body.

### How It Works

1. User clicks link or submits form
2. Turbo prevents default browser behavior
3. Turbo fetches page via `fetch()`
4. Turbo replaces `<body>` and merges `<head>`
5. URL updates via History API

### Disabling Drive

**Per element:**
```html
<a href="/path" data-turbo="false">Regular link</a>
<form action="/path" data-turbo="false">...</form>
```

**Globally:**
```javascript
import "@hotwired/turbo-rails"
Turbo.session.drive = false
```

Then enable per-element with `data-turbo="true"`.

### Visit Actions

```html
<!-- Default: pushState (add to history) -->
<a href="/edit">Edit</a>

<!-- Replace: replaceState (no history entry) -->
<a href="/edit" data-turbo-action="replace">Edit</a>
```

Programmatic:
```javascript
Turbo.visit("/path")
Turbo.visit("/path", { action: "replace" })
```

### Form Methods

```html
<a href="/items/1" data-turbo-method="delete">Delete</a>
```

### Confirmation

```html
<a href="/items/1"
   data-turbo-method="delete"
   data-turbo-confirm="Are you sure?">Delete</a>
```

### Progress Bar

Turbo shows `.turbo-progress-bar` for requests >500ms.

```css
.turbo-progress-bar {
  height: 5px;
  background-color: green;
}

/* Hide it */
.turbo-progress-bar {
  visibility: hidden;
}
```

### Prefetching

Turbo prefetches links on hover (since v8).

```html
<!-- Disable for specific link -->
<a href="/heavy" data-turbo-prefetch="false">Heavy page</a>

<!-- Disable globally -->
<meta name="turbo-prefetch" content="false">
```

### Asset Tracking

Force reload when assets change:
```html
<link rel="stylesheet" href="/app-abc123.css" data-turbo-track="reload">
<script src="/app-def456.js" data-turbo-track="reload"></script>
```

### Events

| Event | When |
|-------|------|
| `turbo:click` | Link clicked |
| `turbo:before-visit` | Before navigation |
| `turbo:visit` | Visit started |
| `turbo:before-fetch-request` | Before fetch |
| `turbo:before-fetch-response` | Response received |
| `turbo:submit-start` | Form submission started |
| `turbo:submit-end` | Form submission ended |
| `turbo:before-render` | Before rendering |
| `turbo:render` | After rendering |
| `turbo:load` | Page fully loaded |

Cancel navigation:
```javascript
document.addEventListener("turbo:before-visit", (event) => {
  if (shouldCancel(event.detail.url)) {
    event.preventDefault()
  }
})
```

## Turbo Frames

Frames scope navigation to a specific part of the page.

### Basic Frame

```erb
<%= turbo_frame_tag @todo do %>
  <p><%= @todo.description %></p>
  <%= link_to "Edit", edit_todo_path(@todo) %>
<% end %>

<!-- Generates -->
<turbo-frame id="todo_123">
  <p>Description</p>
  <a href="/todos/123/edit">Edit</a>
</turbo-frame>
```

Clicking "Edit" fetches the edit page and replaces only the matching frame.

### Frame IDs

```erb
<%= turbo_frame_tag @model %>              <!-- model_123 -->
<%= turbo_frame_tag @model, :section %>    <!-- model_123_section -->
<%= turbo_frame_tag "custom_id" %>         <!-- custom_id -->
```

### Eager Loading (src)

```erb
<%= turbo_frame_tag "sidebar", src: sidebar_path %>
```

Loads content immediately after page renders.

### Lazy Loading

```erb
<%= turbo_frame_tag "comments",
      src: comments_path,
      loading: "lazy" %>
```

Loads only when frame enters viewport.

### Targeting

**Break out of frame:**
```erb
<%= link_to "Full page", path, data: { turbo_frame: "_top" } %>
```

**Target another frame:**
```erb
<%= link_to "Load here", path, data: { turbo_frame: "other_frame" } %>
```

**Frame default target:**
```erb
<%= turbo_frame_tag "nav", target: "_top" do %>
  <!-- All links break out by default -->
<% end %>
```

### Promote to Page Visit

Update browser URL with frame navigation:
```erb
<%= turbo_frame_tag "results", data: { turbo_action: "advance" } %>
```

### Attributes

| Attribute | Purpose |
|-----------|---------|
| `id` | Unique identifier |
| `src` | URL to load content from |
| `loading="lazy"` | Defer until visible |
| `target` | Default navigation target |
| `data-turbo-action` | "advance" or "replace" |
| `refresh="morph"` | Use morphing for updates |
| `autoscroll` | Preserve scroll position |

### Events

| Event | When |
|-------|------|
| `turbo:frame-load` | Frame content loaded |
| `turbo:frame-render` | Frame rendered |
| `turbo:before-frame-render` | Before rendering |
| `turbo:frame-missing` | No matching frame in response |

### Custom Layouts

For turbo frame requests, return minimal layout:
```ruby
layout :custom_layout

private

def custom_layout
  return "turbo_rails/frame" if turbo_frame_request?
  "application"
end
```

## Turbo Streams

Streams update multiple parts of the page with CRUD-like actions.

### Actions

| Action | Effect | Template Required |
|--------|--------|-------------------|
| `append` | Add to end of target | Yes |
| `prepend` | Add to start of target | Yes |
| `replace` | Replace entire target | Yes |
| `update` | Replace target's innerHTML | Yes |
| `remove` | Delete target | No |
| `before` | Insert before target | Yes |
| `after` | Insert after target | Yes |
| `morph` | Morph target | Yes |
| `refresh` | Refresh page | No |

### HTML Format

```html
<turbo-stream action="append" target="messages">
  <template>
    <div id="message_1">New message</div>
  </template>
</turbo-stream>
```

Multiple targets via CSS selector:
```html
<turbo-stream action="remove" targets=".old_records">
</turbo-stream>
```

### Rails Helpers

**In views (create.turbo_stream.erb):**
```erb
<%= turbo_stream.append :messages, @message %>
<%= turbo_stream.prepend :messages, partial: "message", locals: { message: @message } %>
<%= turbo_stream.replace @message %>
<%= turbo_stream.update :counter, "42" %>
<%= turbo_stream.remove @message %>
<%= turbo_stream.before @message, partial: "divider" %>
<%= turbo_stream.after @message, partial: "footer" %>
```

**Inline in controller:**
```ruby
render turbo_stream: [
  turbo_stream.append(:messages, @message),
  turbo_stream.update(:flash, partial: "flash")
]
```

### Responding to Streams

```ruby
def create
  @item = Item.create!(item_params)

  respond_to do |format|
    format.turbo_stream
    format.html { redirect_to @item }
  end
end
```

Turbo adds `text/vnd.turbo-stream.html` to Accept header for forms.

### Broadcasting (Real-time)

**Simple refresh broadcasts:**
```ruby
class Message < ApplicationRecord
  broadcasts_refreshes
end
```

**Manual broadcasts:**
```ruby
class Message < ApplicationRecord
  after_create_commit -> {
    broadcast_append_to :messages, target: :messages
  }

  after_destroy_commit -> {
    broadcast_remove_to :messages
  }
end
```

**In views, subscribe:**
```erb
<%= turbo_stream_from :messages %>
```

### Broadcast Methods

```ruby
broadcast_append_to(stream, target:, partial:, locals:)
broadcast_prepend_to(stream, target:, partial:, locals:)
broadcast_replace_to(stream, target:, partial:, locals:)
broadcast_update_to(stream, target:, partial:, locals:)
broadcast_remove_to(stream)
broadcast_before_to(stream, target:, partial:, locals:)
broadcast_after_to(stream, target:, partial:, locals:)
broadcast_refresh_to(stream)
```

### Testing Streams

```ruby
assert_turbo_stream action: :append, target: "messages"
assert_no_turbo_stream action: :remove
```

## Morphing

Morphing intelligently updates DOM while preserving state.

### Page Refresh with Morphing

```html
<head>
  <meta name="turbo-refresh-method" content="morph">
  <meta name="turbo-refresh-scroll" content="preserve">
</head>
```

### Frame Morphing

```erb
<%= turbo_frame_tag "items", refresh: "morph" %>
```

### Stream Morphing

```erb
<%= turbo_stream.replace @item, method: :morph %>
```

Or:
```ruby
broadcast_replace_to :items, target: @item, method: :morph
```

### Benefits

- Preserves form input values
- Preserves focus state
- Preserves scroll position
- Smoother animations
- Works with Stimulus controllers (no disconnect/reconnect)
