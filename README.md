# dotfiles

macOS shell setup with zsh, Ghostty, tmux, and vim.

## Quick Start

```bash
git clone https://github.com/jhuggart/dotfiles.git ~/code/dotfiles
cd ~/code/dotfiles
./setup.sh
```

## What's Included

### Zsh
- Custom prompt with git branch and colors
- Autosuggestions (ghost text from history)
- Syntax highlighting (green = valid, red = invalid)
- Fuzzy history search (`Ctrl+R`)
- Auto-cd, typo correction
- 50k shared history across terminals
- `eza` aliases: `ls` (icons), `ll` (detailed + git), `lt` (tree)
- `zoxide` smart directory jumping: `z foo` jumps to any directory containing "foo"
- Lazy-loaded NVM for faster shell startup

### Ghostty
- JetBrains Mono Nerd Font
- GruvboxDark theme
- Clean padding and block cursor

### Tmux

Prefix is `Ctrl+A` (not the default `Ctrl+B`).

| Keys | Action |
|------|--------|
| `Ctrl+A p` | Split pane horizontally |
| `Ctrl+A v` | Split pane vertically |
| `Ctrl+A x` | Kill pane (no confirm) |
| `Ctrl+A r` | Reload config |
| `Ctrl+A T` | Move window to first position |
| `Ctrl+A h/j/k/l` | Resize pane |
| `Ctrl+h/j/k/l` | Navigate panes (vim-aware) |
| `Ctrl+A I` | Install TPM plugins |
| `Ctrl+A U` | Update TPM plugins |

**Vim integration:** Pane navigation works seamlessly between tmux and vim splits using `Ctrl+h/j/k/l`.

**Session persistence:** Sessions are automatically saved and restored on restart via tmux-resurrect and tmux-continuum.

### Neovim

| Keys | Action |
|------|--------|
| `\e` | Toggle file explorer (neo-tree) |
| `\o` | Focus file explorer |
| `Ctrl+p` | Find files (telescope) |
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | Find references |
| `gi` | Go to implementation |
| `K` | Hover documentation |
| `\rn` | Rename symbol |
| `\ca` | Code actions |
| `\fg` | Live grep (search in files) |
| `\fb` | List buffers |
| `Ctrl+h/j/k/l` | Navigate splits/tmux panes |

**Auto-completion:** Full LSP-powered completion with nvim-cmp. Use `Tab`/`S-Tab` to navigate, `Enter` to confirm, `Ctrl+Space` to trigger manually.

**LSP support:** Go (gopls) and TypeScript (typescript-language-server).

### Claude Code

**Skills:**
| Skill | Action |
|-------|--------|
| `cp` | Commit and push |
| `cps` | Commit, push, deploy to staging |
| `cppr` | Commit, push, open PR, watch GitHub Actions |
| `cpprs` | Commit, push, open PR, watch Actions, deploy to staging |
| `merge` | Merge current branch's PR to main |
| `daily` | Daily startup workflow |
| `organize-daily-notes` | File past months' daily notes into `Daily/YYYY/MM-Month` folders |
| `setup-personal-proj` | Scaffold Cloudflare MCP permissions for a personal project |
| `use-spark` | Query Spark Mail — emails, calendar, contacts, meetings |

**Tmux window highlighting:**
- Yellow - Claude is waiting for input
- Green - Claude has finished
- Highlighting only appears on background windows and clears when focused

### Tools Installed
- neovim
- tmux (with TPM plugin manager)
- zsh-autosuggestions
- zsh-syntax-highlighting
- fzf
- eza
- zoxide
- nvm
- ripgrep
- go
- terminal-notifier
- uv (provides `uvx`, used to launch the Things MCP server)
- pandoc + typst (Markdown → PDF for the `daily` skill's Supernote publishing)
- notedmd ([noted.md](https://github.com/tejas-raskar/noted.md), via `tejas-raskar/noted.md` tap) — transcribes Supernote notes to Markdown for the `daily` skill
- JetBrainsMono Nerd Font

**Things MCP:** `setup.sh` registers [hald/things-mcp](https://github.com/hald/things-mcp) with Claude Code at user scope (`uvx things-mcp`) so the `daily` skill can read your Things 3 today/inbox. Requires Things 3 with "Enable Things URLs" turned on.

**Supernote publishing:** the `daily` skill can publish your daily note to a Supernote tablet. It pulls Escape Collective articles into the note as summaries with links, then converts the note to PDF and uploads it to the Google Drive folder the Supernote syncs — the same Drive delivery `ebook-sync` uses. Put the four `GDRIVE_*` credentials in `~/.claude/secrets/gdrive-supernote.env`; the upload script (run via `uv`) resolves its Python dependencies itself.

**Supernote transcription:** the `daily` skill (step 6) also goes the other direction — it turns new and updated handwritten Supernote notes into Markdown in your Obsidian `Daily/` folder via `claude/scripts/transcribe-supernote-notes.py`. `.note` files are rendered to PDF with `supernotelib`, then [noted.md](https://github.com/tejas-raskar/noted.md) (`notedmd`) transcribes them; PNG/JPG/PDF exports are transcribed directly. Output is named `YYYY-MM-DD-<folder>-notes.md` to match your daily notes — the date is the note's last edit, `<folder>` is its parent folder (so same-date notes from different folders don't collide), and the note's name is appended when two notes in the same folder share a date. A note is (re)transcribed whenever its source is newer than the existing `.md`, overwriting it (so edits you make to a transcription are replaced if you later add to that note on the device); the write is atomic, so a failed run never clobbers an existing `.md`. One-time setup:

1. `setup.sh` installs `notedmd`. Configure it once with `notedmd config --edit`: choose the **OpenAI-compatible** provider and enter URL `https://generativelanguage.googleapis.com/v1beta/openai`, model `gemini-2.5-flash`, and a free [Google AI Studio](https://aistudio.google.com/) API key. (We drive Gemini through its OpenAI-compatible endpoint on purpose: notedmd's built-in **Gemini** provider hardcodes the `gemma-3-27b-it` model, which the public Gemini API rejects with a 404. Claude or Ollama work via their own providers.) The result is `~/Library/Application Support/com.company.notedmd/config.toml` with `active_provider = "openai"` and an `[openai]` section holding the URL, model, and key.
2. Create `~/.claude/secrets/supernote-notes-dir` (chmod 600) containing a single line: the local Google Drive for Desktop path to the folder the Supernote syncs its notes to (e.g. `~/Library/CloudStorage/GoogleDrive-you@example.com/My Drive/Supernote/Note`).

**Spark Mail:** the `use-spark` skill drives the `spark` CLI — a thin client over the Spark Desktop app — to query email, calendar, contacts, and meetings. Requires the Spark Desktop app installed and running; the `spark` CLI ships inside it. `setup.sh` does not install Spark. The skill file is generated by `spark skill`; write actions (drafts, archiving, etc.) require granting `triage` access per account in Spark Desktop → Settings → AI Agents.

## Customization

**Change Ghostty theme:**
```bash
ghostty +list-themes  # see available themes
```
Then edit `ghostty/config` and change the `theme` line.

**Prompt colors** are in `.zshrc` using `%F{color}` format:
- `cyan` - directory
- `magenta` - git branch
- `green` - prompt arrow
