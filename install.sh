#!/bin/bash
# Gamers Need Sleep — standalone installer.
#
# Assembles the Quickshell bundle (shell.qml beside the shared ui/ and core/ —
# Quickshell only imports from inside the config folder, so they must sit side
# by side) and installs it under ~/.local by default. No root needed.
#
#   ./install.sh                 install for the current user (~/.local)
#   ./install.sh --system        install system-wide (/usr/local, uses sudo)
#   ./install.sh --dev           just assemble build/app for `qs -p` testing
#   ./install.sh --uninstall     remove an installed copy (respects --system)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mode="install"
scope="user"
for arg in "$@"; do
  case "$arg" in
    --system) scope="system" ;;
    --dev) mode="dev" ;;
    --uninstall) mode="uninstall" ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

if [[ "$scope" == "system" ]]; then
  PREFIX="/usr/local"; SUDO="sudo"
else
  PREFIX="$HOME/.local"; SUDO=""
fi
SHARE="$PREFIX/share/gamers-need-sleep"
BIN="$PREFIX/bin"
APPS="$PREFIX/share/applications"

assemble() {  # assemble <dest-app-dir>
  local app="$1"
  $SUDO rm -rf "$app"
  $SUDO install -d "$app"
  $SUDO install -m644 "$ROOT/standalone/shell.qml" "$app/shell.qml"
  $SUDO cp -r "$ROOT/ui" "$app/ui"
  $SUDO cp -r "$ROOT/core" "$app/core"
}

case "$mode" in
  dev)
    assemble "$ROOT/build/app"
    echo "Assembled $ROOT/build/app"
    echo "Run:  qs -p \"$ROOT/build/app/shell.qml\""
    ;;

  uninstall)
    $SUDO rm -rf "$SHARE"
    $SUDO rm -f "$BIN/gamers-need-sleep" "$APPS/gamers-need-sleep.desktop"
    echo "Removed Gamers Need Sleep from $PREFIX"
    ;;

  install)
    command -v qs >/dev/null 2>&1 || echo "note: quickshell (qs) not found — install it to run the app." >&2
    assemble "$SHARE/app"
    $SUDO install -d "$BIN" "$APPS"
    # Launcher, pinned to this share dir so it finds the bundle.
    $SUDO install -m755 "$ROOT/standalone/gamers-need-sleep" "$BIN/gamers-need-sleep"
    $SUDO sed -i "1a export GNS_SHARE_DIR=\"$SHARE\"" "$BIN/gamers-need-sleep"
    $SUDO install -m644 "$ROOT/standalone/gamers-need-sleep.desktop" "$APPS/gamers-need-sleep.desktop"

    echo "Installed Gamers Need Sleep to $PREFIX"
    echo "  launcher: $BIN/gamers-need-sleep"
    case ":$PATH:" in
      *":$BIN:"*) ;;
      *) echo "  note: $BIN is not on your PATH — add it, or launch from your app menu." ;;
    esac
    ;;
esac
