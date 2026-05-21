#!/bin/bash
# publish-to-supernote.sh — convert a markdown note to PDF and upload it to
# Supernote Cloud, where the tablet picks it up on its next sync.
#
# Usage: publish-to-supernote.sh <markdown-file> [supernote-folder]
#   markdown-file     path to the source .md file
#   supernote-folder  Supernote Cloud target folder (default: /Document)
#
# Requires pandoc, typst, and sncloud — all installed by setup.sh.
# Run `sncloud login` once before first use.

set -euo pipefail

# uv installs the sncloud binary here; ensure it resolves under any shell.
export PATH="$HOME/.local/bin:$PATH"

SRC="${1:-}"
SN_FOLDER="${2:-/Document}"

if [[ -z "$SRC" ]]; then
  echo "usage: publish-to-supernote.sh <markdown-file> [supernote-folder]" >&2
  exit 1
fi

if [[ ! -f "$SRC" ]]; then
  echo "error: file not found: $SRC" >&2
  exit 1
fi

for tool in pandoc sncloud; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "error: '$tool' is not installed — run setup.sh" >&2
    exit 1
  fi
done

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

stem="$(basename "${SRC%.*}")"
pdf="$workdir/$stem.pdf"

echo "Converting $(basename "$SRC") to PDF..."
# -task_lists: render `- [ ]` as literal text — typst's default font has no
#   ballot-box glyph. wikilinks_*: render Obsidian [[links]] as plain text.
pandoc "$SRC" -o "$pdf" \
  --pdf-engine=typst \
  -f markdown-task_lists+wikilinks_title_after_pipe

echo "Uploading $stem.pdf to Supernote Cloud ($SN_FOLDER)..."
# Run under a timeout (perl's alarm survives exec; macOS has no GNU `timeout`)
# and with stdin closed, so an unauthenticated sncloud fails fast instead of
# blocking forever on its interactive "Email:" login prompt.
if ! output="$(perl -e 'alarm shift @ARGV; exec @ARGV' 120 \
    sncloud put "$pdf" --parent "$SN_FOLDER" </dev/null 2>&1)"; then
  echo "$output" >&2
  echo "" >&2
  echo "error: sncloud upload failed or timed out." >&2
  echo "If this Mac is not paired with Supernote Cloud yet, run:  sncloud login" >&2
  exit 1
fi

[[ -n "$output" ]] && echo "$output"
echo "Published $stem.pdf — sync your Supernote to pick it up."
