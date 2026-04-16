---
name: setup-personal-proj
description: Use when setting up a personal project with Claude Code Cloudflare MCP permissions
---

# Set up Personal Project

1. Create `.claude/` directory in the current project if it doesn't exist
2. Copy the personal project permissions template into place by running: `cp ~/code/dotfiles/claude/templates/personal-permissions.json .claude/settings.local.json`
3. Confirm the file was created and show the user what permissions were added
4. Check if `.claude/settings.local.json` is gitignored — if not, warn the user to add it
