---
description: Manage pull requests - create, review comments, check status
argument-hint: [create|update|comments|status] [options]
---

# Pull Request Management

Manage GitHub pull requests for the current branch.

## Usage

- `/pr` or `/pr create` - Create a new PR
- `/pr update` - Update existing PR (title, description, ready status)
- `/pr comments` - Review and respond to PR comments
- `/pr status` - Check PR status and CI checks

User provided: $ARGUMENTS

## Context

Current branch: !`git branch --show-current`
PR for this branch: !`gh pr view --json number,title,state,url --jq '"#\(.number) \(.title) (\(.state)) - \(.url)"' 2>/dev/null || echo "No PR exists"`

---

## Command: `create` (default)

Create a pull request following best practices for clear, reviewable PRs.

### Create Options

- `--draft` - Create as draft PR (default)
- `--ready` - Create as ready for review
- `--title "..."` - Override auto-generated title
- `--base <branch>` - Target branch (default: main)

### Create Context

Uncommitted changes:
!`git status --short`

Commits since main:
!`git log main..HEAD --oneline 2>/dev/null || echo "No commits"`

Files changed:
!`git diff main...HEAD --stat 2>/dev/null | tail -1`

### Workflow

1. Check pre-flight criteria (see `pull-requests.md` rule)
2. Prompt to commit uncommitted changes if needed
3. Push branch to remote with `-u` if not already pushed
4. Generate PR description using What/Why/How/Testing format (see `pull-requests.md` rule)
5. Create PR via `gh pr create`

### Command Execution

```bash
gh pr create [--draft] --title "<type>: <description>" --base <branch> --body "$(cat <<'EOF'
...
EOF
)"
```

Return the PR URL when complete.

---

## Command: `update`

Update an existing PR's title, description, or ready status.

### Update Options

- `--ready` - Mark PR as ready for review (remove draft status)
- `--draft` - Convert back to draft
- `--title "..."` - Update the PR title
- `--body` - Regenerate the PR description based on current commits

### Update Context

Current PR:
!`gh pr view --json number,title,state,isDraft,body --jq '{number, title, state, isDraft}' 2>/dev/null || echo "No PR exists"`

New commits since PR created:
!`gh pr view --json commits --jq '.commits | length' 2>/dev/null || echo "0"` commits

### Update Instructions

1. If `--ready`: run `gh pr ready`
2. If `--draft`: run `gh pr ready --undo`
3. If `--title`: run `gh pr edit --title "..."`
4. If `--body`: regenerate description from current commits using the What/Why/How/Testing format, then run `gh pr edit --body "..."`
5. If no flags provided, show current PR state and ask what to update

---

## Command: `comments`

Review and respond to comments on the existing PR.

### Comments Context

PR info:
!`gh pr view --json number,url 2>/dev/null || echo "No PR exists"`

PR comments:
!`gh pr view --json comments --jq '.comments[] | "**\(.author.login)** (\(.createdAt | split("T")[0])):\n\(.body)\n---"' 2>/dev/null || echo "No comments"`

Reviews:
!`gh pr view --json reviews --jq '.reviews[] | "**\(.author.login)** (\(.state)):\n\(.body)\n---"' 2>/dev/null || echo "No reviews"`

### Comments Instructions

1. Fetch inline review comments using `gh api` with the PR number from context above
2. Summarize feedback received
3. Group by theme: questions, requested changes, approvals, nits
4. For each actionable item:
    - Address with code change, OR
    - Explain why no change is needed
5. Suggest replies using `gh pr comment` or `gh pr review --comment`

---

## Command: `status`

Check PR status including CI checks and review state.

### Status Context

CI checks:
!`gh pr checks 2>/dev/null || echo "No PR or checks"`

### Status Instructions

1. Show CI check results (passing/failing/pending)
2. Show review status (approved/changes requested/pending)
3. Identify blockers to merge
4. Suggest next steps (fix failing checks, request review, etc.)