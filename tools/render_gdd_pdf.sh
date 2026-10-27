#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/docs/design/gdd-pdf/index.html"
OUTPUT="$ROOT/docs/design/GDD.pdf"
CHROME="${CHROME:-$(ls -d "$HOME"/.cache/ms-playwright/chromium-*/chrome-linux64/chrome 2>/dev/null | tail -n 1)}"

if [ -z "$CHROME" ] || [ ! -x "$CHROME" ]; then
	echo "Chromium não encontrado. Defina CHROME=/caminho/do/chrome (ou google-chrome)." >&2
	exit 1
fi

"$CHROME" --headless --no-sandbox --disable-gpu --no-pdf-header-footer \
	--allow-file-access-from-files --virtual-time-budget=10000 \
	--print-to-pdf="$OUTPUT" "file://$SOURCE" 2>/dev/null

echo "PDF gerado: $OUTPUT"
