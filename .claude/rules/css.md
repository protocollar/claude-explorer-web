---
paths:
  - app/views/**/*.erb
  - app/assets/stylesheets/**/*.css
---

# CSS Conventions

## Organization

One file per feature: `buttons.css`, `cards.css`, `inputs.css`

```
app/assets/stylesheets/
├── _global.css           # Layer order, variables
├── reset.css
├── base.css
├── buttons.css
├── inputs.css
└── utilities.css
```

## CSS Layers

```css
@layer reset, base, components, utilities;
```

## Two-Tier Variables

```css
:root {
  /* Tier 1: Named values */
  --lch-blue: 54% 0.23 255;

  /* Tier 2: Semantic abstractions */
  --color-link: oklch(var(--lch-blue));
}
```

## Component Variables

Override via CSS variables:

```css
.btn {
  background: var(--btn-background, var(--color-text-reversed));
  color: var(--btn-color, var(--color-text));
}

.btn--negative {
  --btn-background: var(--color-negative);
  --btn-color: var(--color-text-reversed);
}
```

## Dark Mode

Redefine base values only:

```css
:root {
  --lch-black: 0% 0 0;
  @media (prefers-color-scheme: dark) {
    --lch-black: 100% 0 0;
  }
}
```

## Key Patterns

- **Pure CSS** - No Sass, Tailwind, or preprocessors
- **Native nesting** with `&`
- **Modern selectors** - `:is()`, `:where()`, `:has()`
- **Logical properties** - `inline-size`, `block-space` for RTL
- **Focus-visible** - Keyboard-only focus rings
- **Reduced motion** - Respect `prefers-reduced-motion`

## Turbo Integration

```css
turbo-frame { display: contents; }
```
