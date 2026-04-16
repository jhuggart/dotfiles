---
name: cpprs
description: Use when the user asks to commit, push, open a PR, watch CI, and deploy to staging
---

# Commit, Push, PR, Watch Actions, Deploy to Staging

1. Commit all staged changes with an appropriate message
2. Push to remote
3. Open a pull request using `gh pr create`
4. Watch GitHub Actions with `gh run watch` and notify me when they pass or fail
5. If actions pass, deploy the branch to staging using the staging workflow. Use @.github/workflows/staging.yml for context on how to trigger the deployment when available.
