#!/bin/bash
# Install the Gamers Need Sleep bar widget into the current user's Omarchy
# config. Copies the self-contained plugin bundle into ~/.config/omarchy/plugins
# and prints how to enable it. Run as your normal user (not root).
set -euo pipefail

# Source bundle: the packaged copy, or a local dev build.
SRC=""
for cand in \
  "/usr/share/gamers-need-sleep/omarchy-plugin" \
  "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/build/plugin"; do
  if [[ -d "$cand" ]]; then SRC="$cand"; break; fi
done

if [[ -z "$SRC" ]]; then
  echo "No plugin bundle found. Run ./scripts/build.sh first, or install the package." >&2
  exit 1
fi

DEST="$HOME/.config/omarchy/plugins/amendale.shutdown"
mkdir -p "$(dirname "$DEST")"
rm -rf "$DEST"
cp -r "$SRC" "$DEST"

echo "Installed plugin to: $DEST"
cat <<'EOF'

Enable it by adding "amendale.shutdown" to a section of your bar layout in
  ~/.config/omarchy/shell.json
for example:
  "bar": { "layout": { "right": [ "amendale.shutdown", ... ] } }

Then reload the shell (e.g. `omarchy-shell` restart, or log out/in).
EOF
