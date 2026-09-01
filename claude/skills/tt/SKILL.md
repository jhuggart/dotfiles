---
name: tt
description: Use when the user asks what work is due - "/tt", "what's due", "what's on today", "what's due today and tomorrow", "my tasks" - to list open delivery tasks due today and tomorrow (plus Friday when today is Wednesday) from the devclarity-ops platform.
allowed-tools: Bash, mcp__devclarity-ops__list_tasks
---

# tt - what's due

Fetch open delivery tasks from the ops platform, bucket them by day, print the list.

**Read-only.** Never complete, reschedule, or create a task from this skill, even if the
list makes an obvious next action tempting. Working the list is `/interactive-tasks`.

## Step 1: Establish the window

Get the real date from the shell. Never infer it from conversation context or the
system prompt.

```bash
date +%Y-%m-%d && date +%u
```

`%u` is the ISO weekday: 1 = Monday ... 7 = Sunday.

The window is **today**, **tomorrow**, and - only when `%u` is `3` (Wednesday) -
**Friday** as well.

"Tomorrow" is literal. On a Friday run it is Saturday; on a Saturday run it is Sunday.
There is no weekend skipping and no holiday calendar. A weekend bucket that comes back
empty is a true answer, not a bug.

Compute the other dates in the shell rather than doing calendar arithmetic in your head:

```bash
date -v+1d +%Y-%m-%d      # tomorrow
date -v+2d +%Y-%m-%d      # Friday, when today is Wednesday
```

(macOS `date`. GNU coreutils wants `date -d '+1 day' +%F`.)

The latest date in the window is the **window end** - the only date the query needs.

## Step 2: Fetch

One call covers the whole window *and* everything overdue, because the filter is
inclusive of the past:

```
list_tasks(due_on_or_before: "<window end>")
```

The MCP token identifies the user, so there is no assignee filter to pass - it already
returns their tasks only, open by default.

Check `truncated` on the response. If it is true, narrow with `project` or `source` and
make more calls. Do not just raise `limit`.

## Step 3: Bucket

Bucket on each task's `due_date`.

| Bucket | Rule |
|--------|------|
| **Overdue** | `due_date` strictly before today, still open. Sort oldest first. |
| **Today** | `due_date` == today |
| **Tomorrow** | `due_date` == tomorrow |
| **Friday** | `due_date` == Friday. Only on a Wednesday run. |

Anything dated past the window end is out of scope - drop it silently.

## Step 4: Print

`###` heading per bucket, one line per task: the title, then its `project_name`.

```
### Overdue (2)
- Draft QTM opening report - Reflect AI Jumpstart - 2d late
- Send DE-D pre-read - Reflect AI Jumpstart - 1d late

### Today - Tue 2026-09-01
- 2.3 Cleanup Assessment Notes - RxBenefits AI Jumpstart

### Tomorrow - Wed 2026-09-02
- 2.2.3 Hold Assessment Call 3 - InTandem AI Jumpstart
- 4.1 Generate Opening Report - RxBenefits AI Jumpstart
```

**Print every bucket, including empty ones**, as a single line:

```
### Tomorrow - Wed 2026-09-02
Nothing due.
```

A bucket that vanishes when empty is indistinguishable from a bucket that failed to load.

Close with a one-line count: `8 open.`

## Failing loudly

If the fetch errors, is unauthorized, or returns nothing when it plainly should not, **say
so** rather than printing empty buckets. An empty list and a failed list read identically
otherwise, and that is the mistake this skill most needs to avoid.

A `devclarity-ops` token that connects but returns nothing usually means the admin-side My
Work grant or person-linking is still pending - see `setup-personal-workspace` step 10.
