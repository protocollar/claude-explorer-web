---
name: hotwire
description: "Build modern Rails interfaces with Hotwire (Turbo + Stimulus). Use when implementing: (1) Page navigation and form handling with Turbo Drive, (2) Partial page updates with Turbo Frames, (3) Real-time DOM updates with Turbo Streams, (4) JavaScript behaviors with Stimulus controllers, (5) WebSocket broadcasts with Action Cable, (6) Any interactive UI without heavy JavaScript frameworks."
---

# Hotwire

Hotwire sends HTML over the wire instead of JSON, enabling SPA-like interactivity without JavaScript frameworks.

## Decision Framework

Choose the right tool for each interaction:

| Need | Tool | Example |
|------|------|---------|
| Fast page navigation | Turbo Drive | Links, form submissions |
| Update one section | Turbo Frame | Edit-in-place, tabs, modals |
| Update multiple sections | Turbo Stream | Form creates item + clears form |
| Real-time updates | Turbo Stream + Action Cable | Chat, notifications |
| JavaScript behavior | Stimulus | Dropdowns, copy-to-clipboard |

**Rule of thumb:** Use Turbo for server-driven updates, Stimulus for client-side behavior.

## Turbo Frames Quick Reference

Wrap content in a frame to scope navigation:

```erb
<%= turbo_frame_tag @todo do %>
  <p><%= @todo.description %></p>
  <%= link_to "Edit", edit_todo_path(@todo) %>
<% end %>
```

Clicking "Edit" replaces only this frame with the matching frame from the response.

**Lazy loading:**
```erb
<%= turbo_frame_tag "sidebar", src: sidebar_path, loading: "lazy" %>
```

**Break out of frame:**
```erb
<%= link_to "Full page", path, data: { turbo_frame: "_top" } %>
```

See [references/turbo.md](references/turbo.md) for complete Turbo documentation.

## Turbo Streams Quick Reference

Stream actions for DOM updates:

| Action | Effect |
|--------|--------|
| `append` | Add to end of target |
| `prepend` | Add to beginning |
| `replace` | Replace entire element |
| `update` | Replace innerHTML only |
| `remove` | Delete element |
| `before/after` | Insert adjacent |

**Controller response:**
```ruby
respond_to do |format|
  format.turbo_stream
  format.html { redirect_to @item }
end
```

**Template (create.turbo_stream.erb):**
```erb
<%= turbo_stream.append :items, @item %>
<%= turbo_stream.update :form, partial: "form" %>
```

**Real-time broadcasts:**
```ruby
# In model
broadcasts_refreshes  # Simple: triggers page refresh with morphing

# Or manual:
broadcast_append_to :items, target: :items
```

See [references/turbo.md](references/turbo.md) for stream actions and broadcasting.

## Stimulus Quick Reference

Controller structure:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "output"]
  static values = { url: String, count: { type: Number, default: 0 } }
  static classes = ["active"]
  static outlets = ["other-controller"]

  connect() { /* called when controller connects to DOM */ }
  disconnect() { /* called when removed from DOM */ }

  // Action methods (called from data-action)
  submit() {
    this.outputTarget.textContent = this.inputTarget.value
    this.countValue++
    this.dispatch("submitted", { detail: { value: this.inputTarget.value } })
  }

  // Private methods
  #helperMethod() { }
}
```

**HTML:**
```html
<div data-controller="example"
     data-example-url-value="/api"
     data-example-active-class="is-active">
  <input data-example-target="input" data-action="input->example#submit">
  <span data-example-target="output"></span>
</div>
```

**Action syntax:** `event->controller#method`
- Default events: `click` for buttons, `submit` for forms, `input` for inputs
- Modifiers: `:prevent`, `:stop`, `:once`, `@window`, `@document`
- Key filters: `keydown.enter->controller#method`

See [references/stimulus.md](references/stimulus.md) for complete reference.

## Rails Helpers

**Turbo Frame tag:**
```erb
<%= turbo_frame_tag @model %>
<%= turbo_frame_tag @model, :section %>
<%= turbo_frame_tag "custom_id", src: path, loading: "lazy" %>
```

**Turbo Stream tag:**
```erb
<%= turbo_stream.append :target, partial: "item", locals: { item: @item } %>
<%= turbo_stream.replace @model %>
<%= turbo_stream.remove @model %>
```

**Stimulus controller generator:**
```bash
bin/rails generate stimulus controller_name
```

See [references/rails-integration.md](references/rails-integration.md) for helpers and setup.
