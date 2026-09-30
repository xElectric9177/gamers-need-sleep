#!/bin/bash
# Run the pure-helper unit tests.
#
# qmltestrunner is broken on this box (exits 1 with no output for any input), so
# the tests run through Quickshell instead — the runtime the app already uses.
# We assemble core/ beside the harness (Quickshell only imports from inside the
# config dir), launch it headless with `qs`, and parse its result sentinel.
#
# Exit status: 0 = all passed, 1 = a check failed, 2 = harness never ran,
# 127 = qs missing.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"
BUNDLE="$ROOT/build/test"

command -v qs >/dev/null 2>&1 || { echo "quickshell (qs) not found on PATH" >&2; exit 127; }

rm -rf "$BUNDLE"
install -d "$BUNDLE"
install -m644 "$DIR/harness.qml" "$BUNDLE/harness.qml"
cp -r "$ROOT/core" "$BUNDLE/core"

# Qt.exit() should quit qs immediately; the timeout is a safety net in case a
# given Quickshell build keeps its event loop alive. The sentinel is printed
# before the exit call either way, so we can still read the result.
out="$(timeout 30 qs -p "$BUNDLE/harness.qml" 2>&1 || true)"

# Surface any individual failures.
echo "$out" | grep -F "FAIL " || true

line="$(echo "$out" | grep -F "[[GNS-TESTS]]" | tail -1 || true)"
if [[ -z "$line" ]]; then
  echo "no result sentinel — harness did not run. Full qs output:" >&2
  echo "$out" >&2
  exit 2
fi

echo "${line#\[\[GNS-TESTS\]\] }"
[[ "$line" == *PASS* ]]
