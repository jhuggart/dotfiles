#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "google-api-python-client>=2.149",
#     "google-auth>=2.35",
# ]
# ///
"""Convert a markdown note to PDF and upload it to a Google Drive folder.

The Supernote tablet syncs that Drive folder via its built-in Google Drive
integration, so the note lands on the device. This mirrors how the
ebook-sync sidecar in ~/code/synology-docker delivers books — same Drive
API, same `drive.file` OAuth scope, and the same Drive folder.

Usage:
  publish-to-supernote.py <markdown-file> [drive-filename]

Credentials are read from ~/.claude/secrets/gdrive-supernote.env, which must
contain the four values from the NAS ebook-sync .env:
  GDRIVE_CLIENT_ID=...
  GDRIVE_CLIENT_SECRET=...
  GDRIVE_REFRESH_TOKEN=...
  GDRIVE_FOLDER_ID=...

Requires pandoc + typst (installed by setup.sh). uv resolves the Google
libraries automatically from the inline metadata above.
"""
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from google.auth.exceptions import RefreshError
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaFileUpload

SECRETS_FILE = Path.home() / ".claude" / "secrets" / "gdrive-supernote.env"
REQUIRED_KEYS = (
    "GDRIVE_CLIENT_ID",
    "GDRIVE_CLIENT_SECRET",
    "GDRIVE_REFRESH_TOKEN",
    "GDRIVE_FOLDER_ID",
)
SCOPES = ["https://www.googleapis.com/auth/drive.file"]


def die(msg: str) -> None:
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(1)


def load_credentials_config() -> dict[str, str]:
    if not SECRETS_FILE.is_file():
        die(
            f"missing {SECRETS_FILE}\n"
            "Create it (chmod 600) with the four GDRIVE_* values from your NAS\n"
            "ebook-sync .env:\n"
            "  GDRIVE_CLIENT_ID=...\n"
            "  GDRIVE_CLIENT_SECRET=...\n"
            "  GDRIVE_REFRESH_TOKEN=...\n"
            "  GDRIVE_FOLDER_ID=..."
        )
    cfg: dict[str, str] = {}
    for line in SECRETS_FILE.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        cfg[key.strip()] = value.strip().strip("'\"")
    missing = [k for k in REQUIRED_KEYS if not cfg.get(k)]
    if missing:
        die(f"{SECRETS_FILE} is missing values for: {', '.join(missing)}")
    return cfg


def strip_frontmatter(text: str) -> str:
    """Drop a leading YAML frontmatter block (--- ... ---).

    The vault's daily-note frontmatter is not strictly valid YAML — an
    unquoted `creation date` whose time contains a colon, `[[wikilink]]`
    tags — so pandoc's metadata parser rejects it. It isn't needed in the
    tablet PDF, so strip it before converting.
    """
    lines = text.splitlines(keepends=True)
    if not lines or lines[0].rstrip("\n") != "---":
        return text
    for i in range(1, len(lines)):
        if lines[i].rstrip("\n") == "---":
            return "".join(lines[i + 1:]).lstrip("\n")
    return text


def convert_to_pdf(src: Path, pdf: Path) -> None:
    if shutil.which("pandoc") is None:
        die("pandoc is not installed — run setup.sh")
    print(f"Converting {src.name} to PDF...")
    # Convert a frontmatter-stripped copy: the vault's daily-note YAML is not
    # strictly valid and crashes pandoc's metadata parser. The copy lives
    # beside the PDF in the caller's temp dir.
    sanitized = pdf.parent / f"{src.stem}.md"
    sanitized.write_text(strip_frontmatter(src.read_text()))
    # -task_lists: render `- [ ]` as literal text — typst's default font has
    #   no ballot-box glyph. -citations: don't treat `@handle` (e.g. a YouTube
    #   URL like .../@BHMIndivisible) as a citation — that emits a typst #cite()
    #   and fails with "document does not contain a bibliography".
    #   wikilinks_*: render Obsidian [[links]] as plain text.
    result = subprocess.run(
        [
            "pandoc", str(sanitized), "-o", str(pdf),
            "--pdf-engine=typst",
            "-f", "markdown-task_lists-citations+wikilinks_title_after_pipe",
        ],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        die(f"pandoc conversion failed:\n{result.stderr.strip()}")


def upload(cfg: dict[str, str], pdf: Path, drive_name: str) -> None:
    creds = Credentials(
        token=None,
        refresh_token=cfg["GDRIVE_REFRESH_TOKEN"],
        client_id=cfg["GDRIVE_CLIENT_ID"],
        client_secret=cfg["GDRIVE_CLIENT_SECRET"],
        token_uri="https://oauth2.googleapis.com/token",
        scopes=SCOPES,
    )
    service = build("drive", "v3", credentials=creds, cache_discovery=False)
    folder = cfg["GDRIVE_FOLDER_ID"]
    media = MediaFileUpload(str(pdf), mimetype="application/pdf", resumable=False)

    print(f"Uploading {drive_name} to Google Drive...")
    try:
        # drive.file scope only sees files this app created — so this finds a
        # prior run's upload and updates it in place rather than duplicating.
        query = (
            f"name = '{drive_name}' and '{folder}' in parents "
            "and trashed = false"
        )
        existing = (
            service.files()
            .list(q=query, spaces="drive", fields="files(id)")
            .execute()
            .get("files", [])
        )
        if existing:
            service.files().update(
                fileId=existing[0]["id"], media_body=media, fields="id"
            ).execute(num_retries=2)
        else:
            service.files().create(
                body={"name": drive_name, "parents": [folder]},
                media_body=media,
                fields="id",
            ).execute(num_retries=2)
    except RefreshError:
        die(
            "Google Drive rejected the refresh token — it is invalid, revoked,\n"
            "or expired. Re-mint it with ebook-sync's auth.py (~/code/synology-docker)\n"
            "and update ~/.claude/secrets/gdrive-supernote.env."
        )
    except HttpError as err:
        if err.status_code in (401, 403):
            die(
                "Google Drive rejected the request (401/403). Check that the\n"
                "Drive API is enabled and GDRIVE_FOLDER_ID is correct in\n"
                "~/.claude/secrets/gdrive-supernote.env."
            )
        die(f"Google Drive upload failed: {err}")


def main() -> None:
    if len(sys.argv) not in (2, 3):
        die("usage: publish-to-supernote.py <markdown-file> [drive-filename]")

    src = Path(sys.argv[1]).expanduser()
    if not src.is_file():
        die(f"file not found: {src}")

    drive_name = sys.argv[2] if len(sys.argv) == 3 else f"Daily-{src.stem}.pdf"
    cfg = load_credentials_config()

    with tempfile.TemporaryDirectory() as tmp:
        pdf = Path(tmp) / f"{src.stem}.pdf"
        convert_to_pdf(src, pdf)
        upload(cfg, pdf, drive_name)

    print(f"Published {drive_name} — sync your Supernote to pick it up.")


if __name__ == "__main__":
    main()
