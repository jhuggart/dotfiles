---
name: qrspi-init
description: "QRSPI Phase 0: Init — Bootstrap feature workspace from ticket, issue, or description"
---

# QRSPI: Init

## Context

Bootstrap the feature workspace. Takes a ticket source (free text, GitHub issue URL/shorthand, or Jira ticket ID), creates the spec directory structure, writes the initial ticket artifact and manifest, and creates the git branch. This is the entry point for the entire QRSPI workflow.

## Instructions

1. Parse `$ARGUMENTS` to detect the input type:
   - GitHub issue URL (contains `github.com` and `/issues/`) → extract owner/repo and issue number
   - GitHub issue shorthand (`#42` or `org/repo#42`) → extract issue number
   - Jira ticket ID (matches pattern like `PROJ-123`) → treat as Jira
   - Anything else → treat as free text description

2. Fetch ticket content based on type:
   - **GitHub URL or shorthand:** Run `gh issue view <number> --json title,body,labels,assignees,comments` and capture the full output
   - **Jira ticket:** Run `jira issue view <id>` — if jira-cli is not available, ask the user to paste the ticket content
   - **Free text:** Use the provided text directly as the ticket content

3. Derive `{feature-name}` from the ticket title (or first line of free text):
   - Lowercase, replace non-alphanumeric chars with hyphens, collapse multiple hyphens, trim leading/trailing hyphens
   - Limit to 50 characters
   - Present the proposed name to the user for confirmation or override

4. Wait for user confirmation of the feature name. Accept any override they provide.

5. Derive `{repo}` by running:
   ```bash
   source ~/.claude/scripts/qrspi-utils.sh && qrspi_repo_name
   ```

6. Create the spec directory:
   ```bash
   mkdir -p .claude/{repo}/specs/{feature-name}
   ```

7. Write `ticket.md` to the spec directory with:
   - A YAML-style header with source type, source URL (if applicable), and date
   - The raw ticket content (title, body, labels, comments — whatever was fetched)
   - Any metadata from the source (assignees, labels, etc.)

8. Write `manifest.json` to the spec directory:
   ```json
   {
     "feature": "{feature-name}",
     "repo": "{repo}",
     "branch": "{feature-name}",
     "created": "ISO-8601-timestamp",
     "ticket_source": "github|jira|text",
     "phases": {
       "init": { "status": "complete", "completed_at": "ISO-8601-timestamp" },
       "questions": { "status": "pending" },
       "research": { "status": "pending" },
       "design": { "status": "pending" },
       "structure": { "status": "pending" },
       "plan": { "status": "pending" },
       "worktree": { "status": "pending" },
       "implement": { "status": "pending" },
       "pr": { "status": "pending" }
     }
   }
   ```

9. Create the `.cache/` subdirectory inside the spec folder for future sub-agent scratch work:
   ```bash
   mkdir -p .claude/{repo}/specs/{feature-name}/.cache
   ```

10. Check if the git branch `{feature-name}` already exists:
    - If it exists locally, check it out
    - If not, create and checkout: `git checkout -b {feature-name}`

11. Confirm to the user:
    - Feature name and branch created
    - Spec directory path
    - Summary of the ticket content
    - Prompt them to proceed with `/qrspi-questions` when ready

## Output Format

**ticket.md:**
```markdown
---
source: github|jira|text
url: <source-url-if-applicable>
date: YYYY-MM-DD
---

# <Ticket Title>

<Full ticket body / description>

## Metadata
- Labels: ...
- Assignees: ...
- Comments: ...
```

**manifest.json:** JSON object as specified in step 8.

## Human Checkpoint

Present the derived feature name and branch name before creating them. The user must confirm or provide an override. Do not create the branch or directories until confirmed.
