---
paths:
  - app/views/**/*.erb
  - app/javascript/controllers/**/*.js
---

# Stimulus Controller Conventions

## Controller Structure

Organize code in this order:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // 1. Static declarations (always at top)
  static targets = ["input", "output"]
  static values = { delay: { type: Number, default: 300 } }
  static classes = ["loading", "error"]
  static outlets = ["results"]

  // 2. Lifecycle methods
  connect() { }
  disconnect() { }

  // 3. Public action methods (API)
  search() { }
  clear() { }

  // 4. Private methods (implementation)
  #performSearch() { }
}
```

## Single Responsibility

Each controller handles one thing:

| Controller | Purpose |
|------------|---------|
| `dialog_controller` | Open/close dialogs |
| `toggle_controller` | Toggle CSS classes |
| `clipboard_controller` | Copy to clipboard |
| `auto_submit_controller` | Submit form automatically |

Create new controllers rather than adding unrelated features.

## Helper Modules

Extract shared logic to `app/javascript/helpers/`:

```javascript
// helpers/timing_helpers.js
export function debounce(fn, delay = 300) {
  let timeoutId = null
  return (...args) => {
    clearTimeout(timeoutId)
    timeoutId = setTimeout(() => fn.apply(this, args), delay)
  }
}
```

## Cross-Controller Communication

**Prefer events (loose coupling):**
```javascript
// Sender
this.dispatch("copied", { detail: { text: "value" } })

// Receiver via HTML: data-action="clipboard:copied->toast#show"
```

**Use outlets only when tight coupling needed:**
```javascript
static outlets = ["modal"]

openModal() {
  this.modalOutlet.open()
}
```

## Common Patterns

**Toggle classes:**
```javascript
static classes = ["active"]

toggle() {
  this.element.classList.toggle(this.activeClass)
}
```

**Auto-submit on connect:**
```javascript
connect() {
  this.element.requestSubmit()
}
```

**Debounced form submission:**
```javascript
connect() {
  this.submit = debounce(this.submit.bind(this), 300)
}

submit() {
  this.element.requestSubmit()
}
```

**Clipboard:**
```javascript
static targets = ["source"]

copy() {
  navigator.clipboard.writeText(this.sourceTarget.value)
  this.dispatch("copied")
}
```
