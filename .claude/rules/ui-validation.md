# UI Validation

Validate UI features using browser automation before considering work complete.

## When to Validate

- After implementing Turbo Frame/Stream features
- After adding or modifying Stimulus controllers
- After CSS/layout changes
- When fixing visual bugs

## Prerequisites

The dev server must be running at `localhost:3001`.

**Before validation:**
1. Check if server is already running (e.g., `curl -s localhost:3001 > /dev/null`)
2. If not running, start with `bin/dev` in the background
3. Track whether you started it

**After validation:**
- Only stop the server if you started it
- Leave it running if the user had it running already

## Validation Process

Use `claude-in-chrome` MCP tools to:

1. **Navigate** to the relevant page
2. **Interact** with UI elements (clicks, form inputs, navigation)
3. **Verify** expected behavior:
   - Turbo Frames update without full page reload
   - Stimulus controllers respond to actions
   - Forms submit and display feedback correctly
   - Visual layout matches expectations

## What to Check

| Feature Type | Verify |
|--------------|--------|
| Turbo Frame | Content updates in-place, URL changes if expected |
| Turbo Stream | Elements append/replace/remove correctly |
| Stimulus | Controller connects, actions fire, DOM updates |
| Forms | Validation messages, success states, redirects |
| Layout | Responsive behavior, spacing, alignment |

## Screenshots

Capture screenshots for:
- Significant visual changes (before/after)
- Bug fixes (showing resolved state)
- New UI features (documenting final appearance)

Use descriptive filenames: `feature-name-state.png`
