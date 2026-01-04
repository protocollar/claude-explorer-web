---
paths:
  - app/views/**/*.erb
  - app/controllers/**/*.rb
---

# Turbo Conventions

## Turbo Frames

**Lazy loading for expensive content:**
```erb
<%= turbo_frame_tag "analytics",
      src: analytics_path,
      loading: "lazy" do %>
  <div class="skeleton">Loading...</div>
<% end %>
```

**Breaking out for full navigation:**
```erb
<%= link_to "Cancel", root_path, data: { turbo_frame: "_top" } %>
```

**Preserve DOM state with morph:**
```erb
<%= turbo_frame_tag "notifications",
      src: notifications_path,
      refresh: "morph" %>
```

**Nested frames per model:**
```erb
<%= turbo_frame_tag @card, :header, src: card_header_path(@card) %>
<%= turbo_frame_tag @card, :body, src: card_body_path(@card) %>
```

## Turbo Streams

**Real-time with broadcasts_refreshes:**
```ruby
class Card < ApplicationRecord
  broadcasts_refreshes
end
```

Combined with morphing in layout:
```html
<meta name="turbo-refresh-method" content="morph">
```

**Flash via stream:**
```ruby
format.turbo_stream do
  render turbo_stream: turbo_stream.update(:flash, partial: "shared/flash")
end
```

## Modal Dialog Pattern

```erb
<%# Trigger %>
<%= link_to "Open", edit_item_path(@item), data: { turbo_frame: "modal" } %>

<%# Empty frame in layout %>
<%= turbo_frame_tag "modal" %>

<%# Response wraps dialog in frame %>
<%= turbo_frame_tag "modal" do %>
  <dialog open data-controller="dialog">
    <%= render "form" %>
  </dialog>
<% end %>
```

## Inline Edit Pattern

```erb
<%# Show state %>
<%= turbo_frame_tag @item do %>
  <%= @item.name %>
  <%= link_to "Edit", edit_item_path(@item) %>
<% end %>

<%# Edit state (same frame ID) %>
<%= turbo_frame_tag @item do %>
  <%= form_with model: @item do |f| %>
    <%= f.text_field :name %>
    <%= f.submit "Save" %>
    <%= link_to "Cancel", @item %>
  <% end %>
<% end %>
```

## Search with Debounce

```erb
<%= form_with url: search_path, method: :get,
      data: { controller: "search", turbo_frame: "results" } do |f| %>
  <%= f.text_field :q, data: { action: "input->search#submit" } %>
<% end %>

<%= turbo_frame_tag "results" do %>
  <%= render @results %>
<% end %>
```

## Tabs

```erb
<nav>
  <%= link_to "Tab 1", tab1_path, data: { turbo_frame: "tab_content" } %>
  <%= link_to "Tab 2", tab2_path, data: { turbo_frame: "tab_content" } %>
</nav>

<%= turbo_frame_tag "tab_content" do %>
  <%= yield %>
<% end %>
```

## Infinite Scroll

```erb
<div id="items">
  <%= render @items %>
</div>

<%= turbo_frame_tag "pagination",
      src: items_path(page: @next_page),
      loading: "lazy" do %>
  <div class="loading-spinner"></div>
<% end %>
```

Pagination response appends and chains:
```erb
<%= turbo_frame_tag "pagination" do %>
  <%= render @items %>

  <% if @next_page %>
    <%= turbo_frame_tag "pagination",
          src: items_path(page: @next_page + 1),
          loading: "lazy" %>
  <% end %>
<% end %>
```

## Toast Notifications

```erb
<%# Layout %>
<div id="toasts"></div>

<%# Stream after action %>
<%= turbo_stream.append :toasts do %>
  <div data-controller="toast" data-toast-duration-value="3000">
    <%= message %>
  </div>
<% end %>
```
