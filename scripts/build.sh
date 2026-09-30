#!/bin/bash
# Assemble runnable bundles from the shared sources. Quickshell restricts QML
# imports to the config folder, so each frontend needs its own copy of ui/ and
# core/ beside its entry file. This mirrors exactly what the PKGBUILD installs.
#
# Produces:
#   build/app/     -> standalone app (run: qs -p build/app/shell.qml)
#   build/plugin/  -> Omarchy bar-widget plugin (id: amendale.shutdown)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$ROOT/build}"

rm -rf "$OUT"
mkdir -p "$OUT/app" "$OUT/plugin"

# --- standalone app ---
cp "$ROOT/standalone/shell.qml" "$OUT/app/"
cp -r "$ROOT/ui" "$OUT/app/ui"
cp -r "$ROOT/core" "$OUT/app/core"

# --- omarchy plugin ---
cp "$ROOT/omarchy/manifest.json" "$OUT/plugin/"
cp "$ROOT/omarchy/BarWidget.qml" "$OUT/plugin/"
cp "$ROOT/omarchy/OmarchyTheme.qml" "$OUT/plugin/"
cp -r "$ROOT/ui" "$OUT/plugin/ui"
cp -r "$ROOT/core" "$OUT/plugin/core"

echo "Built:"
echo "  $OUT/app/shell.qml      (qs -p \"$OUT/app/shell.qml\")"
echo "  $OUT/plugin             (Omarchy plugin: amendale.shutdown)"
