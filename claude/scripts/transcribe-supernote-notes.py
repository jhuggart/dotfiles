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
vault's Daily/ folder. It is the automated half of the `daily` skill's step 6.

Pipeline:
  <name>.note            --supernotelib--> temp <name>.pdf --notedmd--> Daily/<date>-<folder>-notes.md
  <name>.png/.jpg/.jpeg  ----------------(direct)--------- --notedmd--> Daily/<date>-<folder>-notes.md

Source PDFs are skipped on purpose: publish-to-supernote drops published
daily-note PDFs into this same tree, so transcribing them would round-trip a
note you already have as clean Markdown.

Output is named `YYYY-MM-DD-<folder>-notes.md`, matching the vault's daily notes
(`YYYY-MM-DD.md`) with the note's immediate parent folder and a `-notes` suffix.
<date> is the note's last-modified day (which Google Drive for Desktop mirrors
from Drive's modifiedTime), and <folder> keeps notes from different folders on
the same date apart. If two notes in the same folder still share a date, the
note's own name is appended — `...-notes (Name).md` — so neither overwrites the
other.

Each transcription gets YAML frontmatter: `creation date` (the note's last
edit), `tags: [[supernote]] <year>`, and `source` (the note's path under the
Supernote folder).

noted.md (`notedmd`, installed via Homebrew) does the OCR/transcription using
whichever provider you configured with `notedmd config` (Gemini, by default
here). `.note` is Supernote's proprietary format, which noted.md cannot read, so
those are rendered to a multi-page PDF with supernotelib first.

A note is (re)transcribed whenever the source file is newer than its existing
Daily/<date>-<folder>-notes.md (and always the first time, when no .md exists yet); an
unchanged note is left alone. Re-transcribing OVERWRITES that file, so if you
edit a transcription in Obsidian and later add to the same note on the device,
the next run replaces your edits. The write is atomic: notedmd renders into a
temp dir first, so a failed run never clobbers an existing .md.

Usage:
  transcribe-supernote-notes.py [source-dir] [dest-dir]

`source-dir` defaults to the single-line path in
~/.claude/secrets/supernote-notes-dir; `dest-dir` defaults to the vault Daily/
folder. uv resolves supernotelib (and its Pillow dependency) automatically.
"""
import shutil
import subprocess
import sys
import tempfile
from collections import Counter
from datetime import datetime
from pathlib import Path

import supernotelib as sn
from supernotelib.converter import ImageConverter

SOURCE_DIR_FILE = Path.home() / ".claude" / "secrets" / "supernote-notes-dir"
DEFAULT_DEST = Path(
    "/Users/jake/Library/Mobile Documents/iCloud~md~obsidian"
    "/Documents/Obsidian/Daily"
)
NOTE_EXT = ".note"
# Source images handed straight to notedmd. PDFs are intentionally excluded:
# publish-to-supernote drops published daily-note PDFs into the Note tree, and
# transcribing those back would round-trip notes already in the vault.
IMAGE_EXTS = {".png", ".jpg", ".jpeg"}


def die(msg: str) -> None:
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(1)


def note_date(src: Path) -> str:
    """The note's last-updated day as YYYY-MM-DD.

    Uses the file's modified time, which Google Drive for Desktop mirrors from
    Drive's modifiedTime — i.e. when the note was last written on the device.
    """
    return datetime.fromtimestamp(src.stat().st_mtime).strftime("%Y-%m-%d")


def build_frontmatter(src: Path, source_dir: Path) -> str:
    """YAML frontmatter prepended to each transcription.

    Follows the vault convention (`creation date`, `tags`) but tags the note
    [[supernote]] to set transcriptions apart from daily reports, and records
    the source path (relative to the Supernote folder) for provenance.
    """
    dt = datetime.fromtimestamp(src.stat().st_mtime)
    try:
        source = src.relative_to(source_dir).as_posix()
    except ValueError:
        source = src.name
    return (
        "---\n"
        f"creation date: {dt.strftime('%Y-%m-%d %H:%M')}\n"
        f"tags: [[supernote]] {dt.year}\n"
        f"source: {source}\n"
        "---\n\n"
    )


def build_targets(candidates: list[Path]) -> dict[Path, str]:
    """Map each source file to its Daily/ filename.

    Named `YYYY-MM-DD-<folder>-notes.md`, matching the vault's daily notes
    (`YYYY-MM-DD.md`) with the note's immediate parent folder and a `-notes`
    suffix — the folder keeps notes from different folders on the same date
    apart. If two notes in the *same* folder still share a date, the note's own
    name is appended so neither overwrites the other: `...-notes (Name).md`.
    """
    keys = [(note_date(s), s.parent.name) for s in candidates]
    counts = Counter(keys)
    targets: dict[Path, str] = {}
    for src, (date, folder) in zip(candidates, keys):
        base = f"{date}-{folder}-notes"
        if counts[(date, folder)] > 1:
            targets[src] = f"{base} ({src.stem}).md"
        else:
            targets[src] = f"{base}.md"
    return targets


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


def transcribe(src: Path, target: Path, tmp: Path, frontmatter: str) -> None:
    """Transcribe one source file to `target`, overwriting it atomically.

    notedmd renders into a fresh temp dir; we prepend `frontmatter` to its
    output and only then move the result over `target`, so a failed run never
    clobbers an existing .md.
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
    final = out_dir / "final.md"
    final.write_text(frontmatter + produced.read_text())
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

    targets = build_targets(candidates)
    transcribed, uptodate, failed = [], [], []
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        for src in candidates:
            target = dest_dir / targets[src]
            if target.exists() and target.stat().st_mtime >= src.stat().st_mtime:
                uptodate.append(src.name)
                continue
            verb = "Re-transcribing" if target.exists() else "Transcribing"
            print(f"{verb} {src.name} -> {target.name} ...")
            try:
                transcribe(src, target, tmp, build_frontmatter(src, source_dir))
                transcribed.append(target.name)
            except Exception as err:  # noqa: BLE001 - report and keep going
                print(f"  failed: {err}", file=sys.stderr)
                failed.append(src.name)

    print(
        f"\nDone: {len(transcribed)} transcribed, "
        f"{len(uptodate)} up to date, {len(failed)} failed."
    )
    if transcribed:
        print("Transcribed: " + ", ".join(transcribed))
    if failed:
        print("Failed: " + ", ".join(failed), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
