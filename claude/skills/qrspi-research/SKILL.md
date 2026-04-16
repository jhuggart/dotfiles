---
name: qrspi-research
description: "QRSPI Phase 2: Research — Gather objective codebase facts via scout sub-agents"
---

# QRSPI: Research

## Context

Gather objective facts about the codebase by answering each question from the questions phase. The agent maps what exists without forming opinions about what to change. This phase deliberately does NOT load `ticket.md` — the agent is building a technical map, not forming an implementation opinion. This prevents premature solution-locking.

## Prerequisites

- Phase `questions` must be complete (check manifest.json)

## Instructions

1. Locate the active spec directory:
   ```bash
   source ~/.claude/scripts/qrspi-utils.sh && qrspi_find_active_spec
   ```
   If `$ARGUMENTS` contains a feature name, use `qrspi_spec_dir <feature-name>` instead.

2. Read `manifest.json` and verify `questions` phase is complete:
   ```bash
   source ~/.claude/scripts/qrspi-utils.sh && qrspi_check_prereq <spec-dir> questions
   ```

3. Read `questions.md` from the spec directory. **Do NOT read ticket.md.** This is critical — research must be objective, not influenced by the desired end state.

4. Create the `.cache/` directory if it doesn't exist:
   ```bash
   mkdir -p <spec-dir>/.cache
   ```

5. For each question (or logical group of related questions), spawn a scout sub-agent using the Agent tool with these constraints:
   - Give each scout a narrow, specific task: "Find how X is implemented", "Trace the data flow from A to B", "List all usages of interface Y"
   - Instruct the scout to search the codebase using Grep, Glob, and Read tools
   - Instruct the scout to write raw findings to `<spec-dir>/.cache/research-q{N}.md`
   - Instruct the scout to return a summary of ≤50 lines to the orchestrator
   - Run independent scouts in parallel where possible

6. As scout results come back, assemble findings into a structured `research.md`. Start with a **Codebase Map** section:
   - Key directories relevant to the questions
   - Entry points and main modules
   - Dependency relationships between relevant components

7. For each question, write a section containing:
   - The original question
   - Factual findings (what the code actually does)
   - Relevant file paths with line references
   - Brief code snippets where helpful (keep short)
   - **No recommendations. No opinions. No "we should." Pure factual mapping.**

8. If any question could not be fully answered, note what was found and what remains unknown.

9. Present the complete `research.md` to the user for accuracy review. Ask them to:
   - Correct any misunderstandings about the codebase
   - Add context the agent missed ("that module is deprecated, look at X instead")
   - Flag any inaccuracies in the factual findings

10. Incorporate user corrections and write the final `research.md` to the spec directory.

11. Update `manifest.json`:
    ```bash
    source ~/.claude/scripts/qrspi-utils.sh && qrspi_update_manifest <spec-dir> research complete
    ```

12. Confirm to the user and prompt them to proceed with `/qrspi-design` when ready.

## Sub-Agent Tasks

Each scout sub-agent should receive a prompt like:

```
You are a codebase research scout. Your task is to answer this specific question
by searching the codebase:

**Question:** {question text}

Instructions:
1. Use Grep and Glob to find relevant files
2. Use Read to examine key files
3. Write your raw findings to {cache-path}
4. Return a ≤50-line factual summary including:
   - File paths and line numbers for key findings
   - Brief code snippets (only the essential parts)
   - Factual description of what the code does
   - Do NOT make recommendations or suggestions
```

Run scouts for independent questions in parallel. Group tightly related questions into a single scout if they'd search the same files.

## Output Format

**research.md:**
```markdown
# Codebase Research

Date: YYYY-MM-DD
Source: questions.md

## Codebase Map

### Key Directories
- `src/auth/` — Authentication and authorization
- `src/api/` — API route handlers
...

### Entry Points
- `src/index.ts` — Application entry
...

### Dependency Graph
- Module A → Module B → Module C
...

---

## Q1: {Original question text}

**Findings:**
{Factual description of what was found}

**Key Files:**
- `path/to/file.ts:42` — {what this file does relevant to the question}

**Code:**
```{lang}
// Brief relevant snippet
```

---

## Q2: {Next question}
...
```

## Human Checkpoint

Present the assembled research for accuracy review. The user verifies factual correctness and adds context the agent couldn't infer from code alone (deprecation plans, team conventions, historical decisions).
