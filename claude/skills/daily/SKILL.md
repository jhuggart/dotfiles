---
name: daily
description: Use when starting the workday to review tasks, calendar, and set up daily note
---

# Daily Startup

## Workflow

```dot
digraph daily {
    rankdir=TB;
    node [shape=box];

    "1. Get today's calendar" -> "2. Get Things Today tasks";
    "2. Get Things Today tasks" -> "3. Check Things Inbox";
    "3. Check Things Inbox" -> "4. Escape Collective feed";
    "4. Escape Collective feed" -> "5. Indivisible daily action";
    "5. Indivisible daily action" -> "6. Check yesterday's notes";
    "6. Check yesterday's notes" -> "7. Summarize & prompt";
    "7. Summarize & prompt" -> "8. Create & publish daily note";
}
```

## Steps

1. **Calendar** - Fetch today's meetings via `icalbuddy`
2. **Things Today** - Get critical work tasks using `mcp__things__get_today`
3. **Things Inbox** - Surface items needing triage using `mcp__things__get_inbox`
4. **Escape Collective** - Read RSS feed URL from `~/.claude/secrets/escape-collective-rss-url`. If the file is missing or empty, prompt the user to create it (single line containing their personal feed URL) and skip this step. Otherwise fetch via WebFetch. In the on-screen summary, show title, author, and a one-line summary per article. In the daily note, include title, author, a concise summary (a few sentences), and the full article URL as visible text so it can be opened from the tablet or Obsidian
5. **Indivisible Daily Action** - Search Gmail threads for the most recent thread from `action@birminghamindivisible.org`, read it, and summarize the action items
6. **Yesterday's Notes** - Prompt to ensure yesterday's notes have been transcribed
7. **Summarize** - Present overview and offer to create daily note
8. **Publish** - After the daily note is created, offer to publish it to the Supernote tablet

## Output Format

Present a clean summary:

```
## Today's Focus

### Meetings
- 9:00 AM - Standup
- 2:00 PM - 1:1 with [[Person Name]]

### Critical Tasks
- [ ] Task from Things Today
- [ ] Another task

### Inbox (needs triage)
- Item 1
- Item 2

### Escape Collective
- Article Title - Author - Brief summary
- Article Title - Author - Brief summary

### Indivisible Daily Action
- Action summary from latest email
- Key dates/deadlines
- Links to take action

### Yesterday's Notes
Have you transcribed yesterday's notes? (meetings, conversations, ideas)

---
Ready to create daily note? (Daily/{date}.md)
```

## Daily Note

If user confirms, create `Daily/YYYY-MM-DD.md` in the Obsidian vault
(`/Users/jake/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian/Daily/`)
following the Output Format structure, with the Escape Collective section
expanded to a concise summary and visible article URL per item:
- Frontmatter with date and tags
- Meetings section pre-filled
- Critical Tasks and Inbox sections
- Escape Collective section - each article's title, author, a concise summary, and the article URL as visible text
- Indivisible Daily Action summary
- Space for a daily log

## Publish to Supernote

After the note is created, ask: "Publish today's note to your Supernote? [y/N]"
If the user confirms, run:

```
~/.claude/scripts/publish-to-supernote.sh "<path to the daily note just created>"
```

The script converts the note to PDF (via `pandoc`/`typst`) and uploads it to
Supernote Cloud with `sncloud`; the tablet picks it up on its next sync. Its
input is the Obsidian note file itself, so the tablet PDF is a faithful mirror
of the Obsidian note.

Requires a one-time `sncloud login` — if that hasn't been done the script prints
a reminder; relay it to the user.

## Tools Used

- `icalbuddy eventsToday` - calendar events
- `mcp__things__get_today` - today's tasks
- `mcp__things__get_inbox` - inbox items
- `WebFetch` - fetch Escape Collective RSS feed:
  - Read the feed URL from `~/.claude/secrets/escape-collective-rss-url` (a single line containing the full URL with auth params)
  - If the file is missing or empty, tell the user: "Create `~/.claude/secrets/escape-collective-rss-url` with your personal Escape Collective RSS URL (chmod 600), then re-run." Skip this step for now.
  - Parse XML to extract recent article titles, authors, summaries, and links
  - Show articles not older than 3 days
  - In the daily note, render each article as title + author, a concise summary, and the article URL shown as visible text (e.g. `Read: https://escapecollective.com/...`) so the link stays reachable from the Supernote PDF
- `mcp__claude_ai_Gmail__search_threads` - find latest Indivisible action thread:
  - Query: `from:action@birminghamindivisible.org` (most recent 1 result)
- `mcp__claude_ai_Gmail__get_thread` - read the full thread and extract:
  - Action items and calls to action
  - Key dates or deadlines
  - Links to take action
- `~/.claude/scripts/publish-to-supernote.sh` - publish the daily note to the Supernote tablet:
  - Pass the daily note's full path as the argument
  - Converts the note to PDF via `pandoc`/`typst` and uploads it to Supernote Cloud via `sncloud put`
  - Requires a one-time `sncloud login`; the script prints a reminder if auth is missing
