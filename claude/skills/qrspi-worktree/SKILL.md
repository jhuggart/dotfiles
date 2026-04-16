---
name: qrspi-worktree
description: "QRSPI Phase 6: Worktree — Create git worktree and task hierarchy for implementation"
---

# QRSPI: Worktree

## Context

Create an isolated git worktree for implementation and parse the plan into a machine-readable task list. This keeps the main workspace clean while the feature is being built, and gives the implement phase a structured task file to track progress slice by slice.

## Prerequisites

- Phase `plan` must be complete (check manifest.json)

## Instructions

1. Locate the active spec directory:
   ```bash
   source ~/.claude/scripts/qrspi-utils.sh && qrspi_find_active_spec
   ```
   If `$ARGUMENTS` contains a feature name, use `qrspi_spec_dir <feature-name>` instead.

2. Read `manifest.json` and verify `plan` phase is complete:
   ```bash
   source ~/.claude/scripts/qrspi-utils.sh && qrspi_check_prereq <spec-dir> plan
   ```

3. Read the branch name and feature name from `manifest.json`.

4. Read `plan.md` from the spec directory.

5. Determine the worktree path. By default:
   ```bash
   repo=$(source ~/.claude/scripts/qrspi-utils.sh && qrspi_repo_name)
   worktree_path="../${repo}-${feature_name}"
   ```
   Present the proposed worktree path to the user for confirmation or override.

6. Wait for user confirmation of the worktree location.

7. Ensure the branch exists:
   ```bash
   git branch --list {branch-name}
   ```
   If it doesn't exist, create it: `git branch {branch-name}`

8. Create the git worktree:
   ```bash
   git worktree add {worktree-path} {branch-name}
   ```

9. Copy the spec directory into the worktree so artifacts are accessible during implementation:
   ```bash
   mkdir -p {worktree-path}/.claude-specs
   cp -r <spec-dir>/* {worktree-path}/.claude-specs/
   ```

10. Parse `plan.md` into a structured `tasks.json` file. Extract each slice and its steps:
    ```json
    {
      "feature": "{feature-name}",
      "repo": "{repo}",
      "worktree": "{worktree-path}",
      "slices": [
        {
          "name": "Slice 1: {slice name}",
          "status": "pending",
          "steps": [
            "Step 1 description",
            "Step 2 description"
          ],
          "tests": ["path/to/test.ts — description"],
          "checkpoint": {
            "commands": ["npm test -- --grep slice-1"],
            "passed": false
          }
        }
      ],
      "current_slice": 0
    }
    ```

11. If `plan.md` includes a **Shared Setup** section, include it as a special first entry in the slices array with `"name": "Shared Setup"`.

12. Write `tasks.json` to `{worktree-path}/.claude-specs/tasks.json`.

13. Update `manifest.json` in the original spec directory:
    ```bash
    source ~/.claude/scripts/qrspi-utils.sh && qrspi_update_manifest <spec-dir> worktree complete
    ```

14. Present to the user:
    - Worktree path and how to `cd` into it
    - Task breakdown summary (number of slices, total steps)
    - Instructions: "Open a new Claude Code session in the worktree directory and run `/qrspi-implement` to start building"

## Output Format

**tasks.json:** JSON object as specified in step 10.

The worktree will contain:
```
{worktree-path}/
├── .claude-specs/
│   ├── ticket.md
│   ├── manifest.json
│   ├── questions.md
│   ├── research.md
│   ├── design.md
│   ├── structure.md
│   ├── plan.md
│   └── tasks.json
├── (all repo files on the feature branch)
```

## Human Checkpoint

Confirm the worktree location before creation. Optionally review the task breakdown. The user may adjust the worktree path if the default conflicts with their workspace layout.
