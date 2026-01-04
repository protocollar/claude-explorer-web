# Stimulus Reference

## Table of Contents
- [Controllers](#controllers)
- [Actions](#actions)
- [Targets](#targets)
- [Values](#values)
- [CSS Classes](#css-classes)
- [Outlets](#outlets)
- [Lifecycle Callbacks](#lifecycle-callbacks)
- [Cross-Controller Communication](#cross-controller-communication)

## Controllers

Controllers are JavaScript classes that connect to DOM elements via `data-controller`.

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Static declarations
  static targets = ["input", "output"]
  static values = { url: String }
  static classes = ["active"]
  static outlets = ["other"]

  // Lifecycle
  connect() { }
  disconnect() { }

  // Actions
  submit() { }

  // Private
  #helper() { }
}
```

### File Naming

| File | Identifier |
|------|------------|
| `clipboard_controller.js` | `clipboard` |
| `date_picker_controller.js` | `date-picker` |
| `users/list_item_controller.js` | `users--list-item` |

### Properties

- `this.element` - The controller's element
- `this.application` - The Stimulus Application instance
- `this.identifier` - The controller's identifier string

### Multiple Controllers

```html
<div data-controller="clipboard list-item"></div>
```

### Scopes

Controllers are only aware of elements within their scope (descendants of controller element).

## Actions

Actions connect DOM events to controller methods.

### Syntax

```
event->controller#method
```

```html
<button data-action="click->gallery#next">Next</button>
```

### Default Events

| Element | Default Event |
|---------|---------------|
| `a` | click |
| `button` | click |
| `form` | submit |
| `input` | input |
| `input[type=submit]` | click |
| `select` | change |
| `textarea` | input |
| `details` | toggle |

Shorthand (omit event for defaults):
```html
<button data-action="gallery#next">Next</button>
```

### Multiple Actions

```html
<input data-action="focus->field#highlight input->search#update">
```

### Key Filters

```html
<div data-action="keydown.enter->modal#submit"></div>
<div data-action="keydown.esc->modal#close"></div>
<div data-action="keydown.ctrl+a->list#selectAll"></div>
```

Available filters: `enter`, `tab`, `esc`, `space`, `up`, `down`, `left`, `right`, `home`, `end`, `page_up`, `page_down`, `[a-z]`, `[0-9]`

Modifiers: `alt`, `ctrl`, `meta`, `shift`

### Global Events

```html
<div data-action="resize@window->gallery#layout"></div>
<div data-action="click@document->modal#close"></div>
```

### Action Options

```html
<div data-action="scroll->gallery#layout:!passive">
<img data-action="click->gallery#open:capture">
<a data-action="click->nav#follow:prevent">
<button data-action="click->form#submit:stop">
<div data-action="click->menu#toggle:self">
```

| Option | Effect |
|--------|--------|
| `:capture` | Use capture phase |
| `:once` | Remove after first invocation |
| `:passive` | Passive listener |
| `:!passive` | Non-passive listener |
| `:stop` | Call `stopPropagation()` |
| `:prevent` | Call `preventDefault()` |
| `:self` | Only if event.target is this element |

### Action Parameters

```html
<button data-action="item#upvote"
        data-item-id-param="12345"
        data-item-url-param="/votes">
```

```javascript
upvote({ params: { id, url } }) {
  console.log(id)   // 12345 (Number)
  console.log(url)  // "/votes" (String)
}
```

Auto-typecast: Number, String, Boolean, Object (JSON)

## Targets

Targets reference important elements by name.

### Definition

```javascript
static targets = ["query", "results", "errorMessage"]
```

```html
<input data-search-target="query">
<div data-search-target="results"></div>
```

### Properties

| Property | Returns |
|----------|---------|
| `this.queryTarget` | First matching element |
| `this.queryTargets` | Array of all matching |
| `this.hasQueryTarget` | Boolean |

### Connected/Disconnected Callbacks

```javascript
static targets = ["item"]

itemTargetConnected(element) {
  // Called when target added to DOM
}

itemTargetDisconnected(element) {
  // Called when target removed from DOM
}
```

### Shared Targets

Elements can have multiple target attributes:
```html
<input data-search-target="input" data-form-target="field">
```

## Values

Values read/write typed data attributes.

### Definition

```javascript
static values = {
  url: String,
  count: Number,
  active: Boolean,
  items: Array,
  config: Object
}
```

With defaults:
```javascript
static values = {
  url: { type: String, default: "/api" },
  count: { type: Number, default: 0 }
}
```

### HTML

```html
<div data-controller="loader"
     data-loader-url-value="/messages"
     data-loader-count-value="5"
     data-loader-active-value="true"
     data-loader-items-value='["a","b"]'
     data-loader-config-value='{"key":"val"}'>
```

### Properties

| Property | Effect |
|----------|--------|
| `this.urlValue` | Get value |
| `this.urlValue = x` | Set value |
| `this.hasUrlValue` | Check presence |

### Type Defaults

| Type | Default |
|------|---------|
| Array | `[]` |
| Boolean | `false` |
| Number | `0` |
| Object | `{}` |
| String | `""` |

### Change Callbacks

```javascript
urlValueChanged(value, previousValue) {
  fetch(this.urlValue).then(/* ... */)
}
```

Called on initialization and whenever the data attribute changes.

## CSS Classes

Reference CSS classes by logical name.

### Definition

```javascript
static classes = ["loading", "active", "hidden"]
```

```html
<div data-controller="search"
     data-search-loading-class="search--busy"
     data-search-active-class="is-active text-bold">
```

### Properties

| Property | Returns |
|----------|---------|
| `this.loadingClass` | First class name |
| `this.loadingClasses` | Array of all classes |
| `this.hasLoadingClass` | Boolean |

### Usage

```javascript
this.element.classList.add(this.loadingClass)
this.element.classList.add(...this.loadingClasses)
```

## Outlets

Outlets reference other controller instances.

### Definition

```javascript
// chat_controller.js
static outlets = ["user-status"]
```

```html
<div data-controller="user-status" class="online-user">...</div>

<div data-controller="chat"
     data-chat-user-status-outlet=".online-user">
```

### Properties

| Property | Returns |
|----------|---------|
| `this.userStatusOutlet` | First controller instance |
| `this.userStatusOutlets` | Array of all instances |
| `this.hasUserStatusOutlet` | Boolean |
| `this.userStatusOutletElement` | First controller's element |
| `this.userStatusOutletElements` | Array of elements |

### Usage

```javascript
// Access outlet's values, targets, methods
this.userStatusOutlet.idValue
this.userStatusOutlet.imageTarget
this.userStatusOutlet.markAsSelected()
```

### Outlet Callbacks

```javascript
userStatusOutletConnected(outlet, element) { }
userStatusOutletDisconnected(outlet, element) { }
```

## Lifecycle Callbacks

### Methods

| Method | Called |
|--------|--------|
| `initialize()` | Once, when first instantiated |
| `connect()` | When connected to DOM |
| `disconnect()` | When disconnected from DOM |
| `[name]TargetConnected(el)` | When target added (before connect) |
| `[name]TargetDisconnected(el)` | When target removed (after disconnect) |

### Example

```javascript
export default class extends Controller {
  initialize() {
    // One-time setup
  }

  connect() {
    // DOM connected - add listeners, start timers
    this.interval = setInterval(this.refresh.bind(this), 1000)
  }

  disconnect() {
    // Cleanup
    clearInterval(this.interval)
  }
}
```

## Cross-Controller Communication

### Via Events (dispatch)

```javascript
// Sender
this.dispatch("copied", { detail: { content: "text" } })
```

```html
<!-- Receiver listens via action -->
<div data-controller="effects"
     data-action="clipboard:copied->effects#flash">
```

```javascript
// Receiver
flash({ detail: { content } }) {
  console.log(content)
}
```

For non-parent elements, use `@window`:
```html
<div data-action="clipboard:copied@window->effects#flash">
```

### Dispatch Options

```javascript
this.dispatch("event", {
  detail: {},        // Custom data
  target: element,   // Event target (default: this.element)
  prefix: "custom",  // Event name prefix (default: controller identifier)
  bubbles: true,     // Bubble up (default: true)
  cancelable: true   // Can be prevented (default: true)
})
```

### Via Outlets (Direct)

```javascript
static outlets = ["other"]

doSomething() {
  this.otherOutlet.methodOnOther()
}
```

Use outlets for tight coupling, events for loose coupling.
