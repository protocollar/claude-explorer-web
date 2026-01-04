---
paths: app/views/**/*.erb
---

# View Conventions

## Template Structure

```erb
<% @page_title = @card.title %>

<% content_for :header do %>
  <h1><%= @page_title %></h1>
<% end %>

<%= turbo_stream_from @card %>
<%= render "cards/container", card: @card %>
```

## Partials

- **Prefix with `_`**: `_card.html.erb`
- **Named after model**: `_message.html.erb` for Message
- **Pass locals explicitly**: `render "cards/container", card: @card`
- **Collection rendering**: `render @cards` auto-infers partial

## Forms

```erb
<%= form_with model: @card, data: { controller: "autosave" } do |form| %>
  <%= form.text_field :title, class: "input" %>
  <%= form.submit "Save", class: "btn" %>
<% end %>
```

## Key Patterns

- **ERB only** - No Haml, Slim
- **`content_for` for layout slots** - Header, footer, sidebar
- **`dom_id` for IDs** - `dom_id(@card)`, `dom_id(@card, :edit)`
- **Cache partials** - `cache message do` for expensive renders
- **Instance variables for layout** - `@page_title`, `@body_class`

## Helpers

Tag helper pattern for complex HTML:

```ruby
def message_tag(message, &block)
  tag.div id: dom_id(message), class: "message", &block
end
```
