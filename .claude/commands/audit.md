---
description: Audit app code against CLAUDE.md and rules conventions
argument-hint: [category]
allowed-tools: Read, Grep, Glob, Task
---

## Project Conventions

@CLAUDE.md

## Rules to Check

@.claude/rules/models.md
@.claude/rules/controllers.md
@.claude/rules/views.md
@.claude/rules/turbo.md
@.claude/rules/stimulus.md
@.claude/rules/css.md
@.claude/rules/testing.md

## Task

Audit this codebase against the conventions defined above.

**Scope:** $1

If a category is specified (models, controllers, views, turbo, stimulus, css, testing), audit only that category. Otherwise, audit all categories.

For each rule file, use the `paths` frontmatter to identify which files to check, then verify the code follows the patterns described in that rule.

### Output Format

```
# Convention Audit Report

## Summary
- X issues found
- Y files checked

## Issues by Category

### [Category Name]
- **File:** path/to/file.rb:line
  **Issue:** Description of violation
  **Convention:** Quote the relevant rule
  **Suggestion:** How to fix

## Compliant Patterns
Notable examples of good convention adherence (optional).
```

Focus on actionable issues. Skip compliant files unless they demonstrate exemplary patterns.
