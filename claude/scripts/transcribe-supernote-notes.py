#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "supernotelib>=0.6.0",
#     # svglib>=1.6 drags in rlpycairo -> pycairo, which needs a system cairo
#     # build we don't have (and don't need: we only use the raster converter).
#     "svglib<1.6",
# ]
# ///
"""Transcribe new Supernote notes into Markdown in the Obsidian vault.

The Supernote tablet syncs its notes to Google Drive, and Google Drive for
Desktop mirrors that folder to a local path on this Mac. This script walks that
local folder, turns each new or updated note into Markdown, and drops it in the
vault's Daily/ folder. It is the automated half of the `daily` skill's step 5.

Pipeline:
  <name>.note            --supernotelib--> temp <name>.pdf --notedmd--> body
  <name>.png/.jpg/.jpeg  ----------------(direct)--------- --notedmd--> body

Source PDFs are skipped on purpose: publish-to-supernote drops published
daily-note PDFs into this same tree, so transcribing them would round-trip a
note you already have as clean Markdown.

Output: all notes sharing a (date, folder) are combined into one
`YYYY-MM-DD-<folder>-notes.md`, matching the vault's daily notes (`YYYY-MM-DD.md`)
with the note's immediate parent folder and a `-notes` suffix. Each note becomes
a `## HH:MM` section (its file name when no time is known) in chronological order.

<date> is the note's own date, not its mtime. For a `.note` it comes from the
embedded FILE_ID (`F<YYYYMMDDHHMMSS>...`, set when the note was created on the
device); failing that, a YYYYMMDD stamp in the file name; failing that, the file
mtime. Images carry no metadata, so they use the file name then mtime. mtime is
avoided as the primary source because Google Drive for Desktop sets it to the
sync time, which can trail the real note date by days.

Each combined file gets YAML frontmatter: `creation date` (the earliest member's
timestamp), `tags: [[supernote]] <year>`, and `source` (a list of every note
that fed the file, each relative to the Supernote folder).

noted.md (`notedmd`, installed via Homebrew) does the OCR/transcription using
whichever provider you configured with `notedmd config` (Gemini, by default
here). `.note` is Supernote's proprietary format, which noted.md cannot read, so
those are rendered to a multi-page PDF with supernotelib first.

A combined file is rebuilt whenever any member note is newer than it (and always
the first time, when the file doesn't exist yet); when nothing changed it is left
alone. Rebuilding re-transcribes every member of that group, not just the one
that changed. The write is atomic: the combined note is assembled in a temp dir
and moved into place, so a failed run never clobbers an existing file. If a
single member fails to transcribe, its section carries an inline warning and the
rest are still written; if every member fails, the file is left untouched.

Usage:
  transcribe-supernote-notes.py [source-dir] [dest-dir]

`source-dir` defaults to the single-line path in
~/.claude/secrets/supernote-notes-dir; `dest-dir` defaults to the vault Daily/
folder. uv resolves supernotelib (and its Pillow dependency) automatically.
"""
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime
from pathlib import Path

import supernotelib as sn
from supernotelib.converter import ImageConverter

SOURCE_DIR_FILE = Path.home() / ".claude" / "secrets" / "supernote-notes-dir"
DEFAULT_DEST = Path.home() / "Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian/Daily"
NOTE_EXT = ".note"
# Source images handed straight to notedmd. PDFs are intentionally excluded:
# publish-to-supernote drops published daily-note PDFs into the Note tree, and
# transcribing those back would round-trip notes already in the vault.
IMAGE_EXTS = {".png", ".jpg", ".jpeg"}


def die(msg: str) -> None:
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(1)


def note_timestamp(src: Path) -> tuple[datetime, bool]:
    """The note's own date/time, and whether a precise clock time was found.

    The datetime drives both the group key (its YYYY-MM-DD) and the per-note
    section heading; the bool is True only when a real time was recovered, so the
    heading can show HH:MM instead of the file name.

    Precedence, most authoritative first:
      1. A .note's embedded FILE_ID (`F<YYYYMMDDHHMMSS>...`) — when the note was
         created on the device. This is the "date in the note".
      2. A YYYYMMDD stamp in the file name (Supernote's default note names, and
         the only date image exports carry).
      3. The file mtime — last resort; Google Drive for Desktop sets this to the
         sync time, which can trail the real note date by days.

    `.note` files are loaded here and again in note_to_pdf during render. With a
    handful of notes the double parse is negligible; cache Notebook objects in
    main() if it ever matters.
    """
    if src.suffix.lower() == NOTE_EXT:
        try:
            file_id = sn.load_notebook(str(src), policy="loose").get_fileid()
            if file_id:
                m = re.match(r"F(\d{14})", file_id)
                if m:
                    return datetime.strptime(m.group(1), "%Y%m%d%H%M%S"), True
        except Exception:  # noqa: BLE001 - corrupt note: fall back to name/mtime
            pass
    m = re.search(r"(\d{8})", src.stem)
    if m:
        try:
            return datetime.strptime(m.group(1), "%Y%m%d"), False
        except ValueError:
            pass
    return datetime.fromtimestamp(src.stat().st_mtime), False


def rel_source(src: Path, source_dir: Path) -> str:
    """Path of a source note relative to the Supernote folder (for provenance)."""
    try:
        return src.relative_to(source_dir).as_posix()
    except ValueError:
        return src.name


def group_sources(
    candidates: list[Path],
) -> dict[tuple[str, str], list[tuple[Path, datetime, bool]]]:
    """Group sources into one output file per (date, folder).

    The date is the note's own date (see note_timestamp); the folder is the
    note's immediate parent. Every note sharing a (date, folder) is merged into a
    single `YYYY-MM-DD-<folder>-notes.md`. Members are sorted chronologically so
    the combined file reads top-to-bottom in the order the notes were taken.
    """
    groups: dict[tuple[str, str], list[tuple[Path, datetime, bool]]] = {}
    for src in candidates:
        dt, has_time = note_timestamp(src)
        key = (dt.strftime("%Y-%m-%d"), src.parent.name)
        groups.setdefault(key, []).append((src, dt, has_time))
    for members in groups.values():
        members.sort(key=lambda m: m[1])
    return groups


def build_group_frontmatter(
    members: list[tuple[Path, datetime, bool]], date: str, source_dir: Path
) -> str:
    """YAML frontmatter for a combined day's note.

    `creation date` is the earliest member's timestamp (members are pre-sorted).
    `source` lists every note that fed the file. Tagged [[supernote]] to set
    transcriptions apart from daily reports.
    """
    earliest = members[0][1]
    lines = [
        "---",
        f"creation date: {earliest.strftime('%Y-%m-%d %H:%M')}",
        f"tags: [[supernote]] {date[:4]}",
        "source:",
    ]
    lines += [f"  - {rel_source(src, source_dir)}" for src, _, _ in members]
    lines += ["---", "", ""]
    return "\n".join(lines)


def read_source_dir() -> Path:
    """Resolve the local Supernote folder from the secrets file."""
    if not SOURCE_DIR_FILE.is_file():
        die(
            f"missing {SOURCE_DIR_FILE}\n"
            "Create it (chmod 600) with a single line: the local path to the\n"
            "Supernote notes folder that Google Drive for Desktop syncs, e.g.\n"
            "  ~/Library/CloudStorage/GoogleDrive-you@example.com/My Drive/Supernote/Note"
        )
    for line in SOURCE_DIR_FILE.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            return Path(line).expanduser()
    die(f"{SOURCE_DIR_FILE} is empty — add the Supernote folder path.")


def note_to_pdf(note_path: Path, pdf_path: Path) -> None:
    """Render every page of a .note file into a single multi-page PDF.

    Done page-by-page through ImageConverter rather than PdfConverter so we
    avoid PdfConverter's ProcessPoolExecutor, which is brittle under `uv run`'s
    spawned interpreter. Pillow assembles the pages into one PDF.
    """
    notebook = sn.load_notebook(str(note_path), policy="loose")
    total = notebook.get_total_pages()
    converter = ImageConverter(notebook)
    pages = [converter.convert(i).convert("RGB") for i in range(total)]
    if not pages:
        raise ValueError("note has no pages")
    pages[0].save(
        str(pdf_path), "PDF", save_all=True, append_images=pages[1:], resolution=200
    )


def run_notedmd(src: Path, dest_dir: Path) -> None:
    result = subprocess.run(
        ["notedmd", "convert", str(src), "-o", str(dest_dir)],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        detail = (result.stderr or result.stdout).strip()
        raise RuntimeError(detail or f"notedmd exited {result.returncode}")


def transcribe_body(src: Path, tmp: Path) -> str:
    """Transcribe one source file and return its Markdown body (no frontmatter).

    notedmd renders into a fresh temp dir; we read and return that text so the
    caller can stitch several notes into one combined file.
    """
    out_dir = Path(tempfile.mkdtemp(dir=tmp))
    if src.suffix.lower() == NOTE_EXT:
        pdf = tmp / f"{src.stem}.pdf"
        note_to_pdf(src, pdf)
        run_notedmd(pdf, out_dir)
    else:
        run_notedmd(src, out_dir)
    produced = out_dir / f"{src.stem}.md"
    if not produced.is_file():
        raise RuntimeError(f"notedmd did not produce {produced.name}")
    return produced.read_text()


def format_section(dt: datetime, has_time: bool, src: Path, body: str) -> str:
    """One note's section: an HH:MM heading (or its name) above the transcription."""
    heading = dt.strftime("%H:%M") if has_time else src.stem
    return f"## {heading}\n\n{body.strip()}\n"


def write_group(target: Path, frontmatter: str, sections: list[str], tmp: Path) -> None:
    """Write the combined note atomically: assemble in tmp, then move over target."""
    final = Path(tempfile.mkdtemp(dir=tmp)) / "final.md"
    final.write_text(frontmatter + "\n".join(sections))
    shutil.move(str(final), str(target))


def main() -> None:
    if len(sys.argv) > 3:
        die("usage: transcribe-supernote-notes.py [source-dir] [dest-dir]")

    source_dir = Path(sys.argv[1]).expanduser() if len(sys.argv) >= 2 else read_source_dir()
    dest_dir = Path(sys.argv[2]).expanduser() if len(sys.argv) == 3 else DEFAULT_DEST

    if not source_dir.is_dir():
        die(f"source folder not found: {source_dir}")
    if not dest_dir.is_dir():
        die(f"destination folder not found: {dest_dir}")
    if shutil.which("notedmd") is None:
        die(
            "notedmd is not installed — run setup.sh (brew install notedmd), then\n"
            "configure a provider once with `notedmd config --edit`."
        )

    candidates = sorted(
        p
        for p in source_dir.rglob("*")
        if p.is_file() and (p.suffix.lower() == NOTE_EXT or p.suffix.lower() in IMAGE_EXTS)
    )
    if not candidates:
        print(f"No notes or images found under {source_dir}")
        return

    groups = group_sources(candidates)
    transcribed: list[tuple[str, list[str]]] = []
    uptodate: list[str] = []
    failed: list[str] = []
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        for (date, folder), members in sorted(groups.items()):
            target = dest_dir / f"{date}-{folder}-notes.md"
            newest_src = max(src.stat().st_mtime for src, _, _ in members)
            if target.exists() and target.stat().st_mtime >= newest_src:
                uptodate.append(target.name)
                continue
            # Any member newer than the file rebuilds the whole group: notedmd
            # re-runs for every member, not just the one that changed. Fine for a
            # personal daily workflow; revisit with per-source caching if needed.
            verb = "Re-transcribing" if target.exists() else "Transcribing"
            print(f"{verb} -> {target.name} ({len(members)} notes) ...")
            sections: list[str] = []
            any_ok = False
            for src, dt, has_time in members:
                try:
                    body = transcribe_body(src, tmp)
                    sections.append(format_section(dt, has_time, src, body))
                    any_ok = True
                except Exception as err:  # noqa: BLE001 - mark and keep going
                    print(f"  failed: {src.name}: {err}", file=sys.stderr)
                    failed.append(src.name)
                    heading = dt.strftime("%H:%M") if has_time else src.stem
                    sections.append(
                        f"## {heading}\n\n> [!warning] Transcription failed for "
                        f"`{rel_source(src, source_dir)}`: {err}\n"
                    )
            if any_ok:
                frontmatter = build_group_frontmatter(members, date, source_dir)
                write_group(target, frontmatter, sections, tmp)
                transcribed.append((target.name, [src.name for src, _, _ in members]))
            else:
                # Every member failed — leave any existing good file untouched.
                print(f"  skipped {target.name}: all notes failed", file=sys.stderr)

    print(
        f"\nDone: {len(transcribed)} files written, "
        f"{len(uptodate)} up to date, {len(failed)} notes failed."
    )
    for name, sources in transcribed:
        print(f"Transcribed: {name} (from {', '.join(sources)})")
    if failed:
        print("Failed: " + ", ".join(failed), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
