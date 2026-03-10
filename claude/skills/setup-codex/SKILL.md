---
name: setup-codex
description: Use when setting up OpenAI Codex CLI to mirror the current Claude Code environment - MCP servers, skills, instructions, and notifications
---

# Setup Codex CLI

Configure OpenAI Codex CLI with equivalent MCP servers, skills, instructions, and notifications from the current Claude Code setup.

## Prerequisites

- Codex CLI installed (`npm install -g @openai/codex`)
- `uv` installed (for Things MCP server)
- `gh` CLI installed (for git workflow skills)
- Unblocked app installed (for context engine)

## Steps

1. Run the setup script: `bash ~/.claude/skills/setup-codex/setup-codex.sh`
2. Authenticate Atlassian: `codex mcp login atlassian`
3. Verify with: `codex --ask-for-approval never "List your available MCP tools"`

## What Gets Configured

### MCP Servers (in `~/.codex/config.toml`)

| Server | Type | Source |
|--------|------|--------|
| unblocked | stdio | Unblocked.app context engine |
| grafana | http | Fetch Rewards Grafana MCP |
| things | stdio | Things 3 task management |
| atlassian | http | Jira + Confluence |

### Instructions (`~/.codex/AGENTS.md`)

Symlinked from `~/.claude/CLAUDE.md` so both tools share the same coding guidelines.

### Skills (in `~/.agents/skills/`)

| Skill | Equivalent Claude Code Command |
|-------|-------------------------------|
| cp | /cp - commit and push |
| cppr | /cppr - commit, push, PR, watch actions |
| merge | /merge - merge PR to main |
| daily | /daily - daily startup workflow |

### Notifications

Codex `notify` hook runs the same tmux notification script used by Claude Code.

## Manual Steps After Setup

- Run `codex mcp login atlassian` to authenticate Atlassian OAuth
- Unblocked uses `--client mcpVscode` as fallback; if Unblocked adds a Codex client, update the args in `~/.codex/config.toml`
