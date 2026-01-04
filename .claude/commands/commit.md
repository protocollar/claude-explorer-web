---
description: Create a conventional commit following project git rules
argument-hint: [--amend] [--fixup <commit>] [--wip] [--staged] [--all] [message]
allowed-tools: Bash(git add:*), Bash(git commit:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*)
---

# Context

**Git Status:**
```
!`git status --short`
```

**Staged Changes:**
```
!`git diff --staged --stat`
```

**Recent Commits:**
```
!`git log --oneline -5`
```

# Task

Create a git commit following the conventional commits format from `.claude/rules/git.md`.

## Arguments

- `--amend` - Amend the previous commit
- `--fixup <commit>` - Create a fixup commit for the specified commit
- `--wip` - Create a work-in-progress commit (chore: WIP)
- `--staged` - Only commit staged changes (do not stage anything new)
- `--all` - Stage and commit all changes
- Any other arguments are treated as the commit message

## Staging Behavior

**IMPORTANT: Follow these rules exactly. Do NOT override based on your own judgment.**

1. If `--staged` is provided: commit only what's currently staged
2. If `--all` is provided: stage everything with `git add -A` then commit
3. **Default behavior (no flags):**
    - If there ARE staged changes: commit ONLY the staged changes. Do NOT stage additional files.
    - If there are NO staged changes: stage everything with `git add -A` then commit

## Requirements

1. Follow conventional commit format: `<type>[optional scope]: <description>`
2. Use appropriate type: feat, fix, docs, style, refactor, perf, test, build, ci, chore
3. Never reference Claude, Anthropic, or AI in the commit message
4. Ensure the commit is atomic and doesn't leave the app in a broken state

User provided: $ARGUMENTS
