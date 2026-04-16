---
name: merge
description: Use when the user asks to merge the current branch's PR into main
---

# Merge PR to Main

1. Find the PR for the current branch using `gh pr view`
2. Merge the PR using `gh pr merge` with squash
3. Switch back to main and pull latest
4. Ask if I would like to delete local feature branch and worktree if applicable
