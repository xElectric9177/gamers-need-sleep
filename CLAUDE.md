# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this repo is

**Gamers Need Sleep** — a shutdown / sleep timer for Arch Linux, built in
[Quickshell](https://quickshell.org) (QML). It schedules the PC to power off,
restart, suspend, or hibernate after a countdown or at a specific local time.

- **This repo is the standalone app + the shared engine.** The Omarchy bar
  drop-down version lives in the **Osiris** config repo
  (`github.com/xElectric9177/Osiris`) as the `amendale.shutdown` plugin, which
  **reuses this repo's `core/` and `ui/`** (fetched from here) plus its own
  Omarchy-specific glue (`manifest.json`, `BarWidget.qml`, `OmarchyTheme.qml`).
  Do **not** re-add Omarchy files here.
- **Remote:** `github.com/xElectric9177/gamers-need-sleep`, branch `main`.
- **License:** MIT (`LICENSE`). Git identity: `Lukasz <lhumeniuk1@gmail.com>`.

## The hard requirement (don't regress it)

"At a specific time" means the **local wall-clock time**. 23:00 set on BST must
fire at 23:00 BST, never 23:00 UTC. This is why scheduling goes through
`systemd-run --user --on-calendar=<local timestamp>` — systemd interprets an
unqualified `OnCalendar` in the system timezone. Countdown mode uses
`--on-active=<seconds>s` (monotonic). Never convert times to UTC.

## Architecture

Everything is QML. Components are **theme-agnostic**: they read colours/fonts
from an injected `theme` object (never a color singleton), so the same `core/` +
`ui/` render both here (neon `ui/Theme.qml`) and in the Omarchy plugin (an
`OmarchyTheme` adapter, kept in Osiris, binds the same contract to `qs.Commons`
`Color`/`Style`).

```
core/
  Scheduler.qml       engine: arm/abort, status polling, inhibitor detection,
                      state persistence (~/.local/state/gamers-need-sleep/current.json).
                      Uses Quickshell.Io.Process directly, so it is frontend-agnostic.
                      Accepts an external scheduler (externalScheduler) so a host
                      can own one instance; otherwise TimerPanel creates its own.
  CommandBuilder.qml  builds the systemd-run/systemctl argv + the preview string.
  Formatting.qml      local-tz duration/time formatting, OnCalendar timestamp.
ui/
  Theme.qml           the Midnight Neon Lo-Fi palette (accentInk, ringTrack, etc.)
                      AND the theme contract every component reads.
  TimerPanel.qml      composes the whole UI (config view + active view). Owns the
                      Scheduler (or takes externalScheduler). Exposes contentHeight,
                      active, remainingSeconds, activeAction for a host to bind to.
  <widgets>           SegTabs, DurationPicker, TimePicker steppers, ActionSelector,
                      GnsToggle, Chip, CommandPreview, CountdownRing, InhibitorWarning,
                      GnsButton, SectionLabel, Stepper.
standalone/
  shell.qml           FloatingWindow -> TimerPanel with ui/Theme. Imports "ui".
  gamers-need-sleep   launcher; finds the bundle in install/dev locations.
  gamers-need-sleep.desktop
install.sh            assemble + install (see below)
```

## Build / run / install

**Quickshell sandboxes QML imports to the config folder** — `ui/` and `core/`
must sit *beside* `shell.qml`, not be imported from a sibling dir. So nothing
runs from the source tree directly; it must be assembled into a bundle first.

- **Dev run:** `./install.sh --dev` assembles `build/app/` (shell.qml + ui + core),
  then `qs -p build/app/shell.qml`.
- **Install:** `./install.sh` (per-user, `~/.local`, no root) or `--system`
  (`/usr/local`, sudo). `--uninstall` removes it. The installed launcher gets
  `GNS_SHARE_DIR` pinned to its share dir.
- `build/` is git-ignored.

## Tests

`tests/` unit-tests the **pure** helpers — `Formatting` (duration/clock/
onCalendar/tzAbbrev/timeOfDay) and `CommandBuilder` (argv + preview builders,
including the timezone-correct specific-time warn). `Scheduler` drives systemd/
processes and is out of scope for a unit harness.

- **Run:** `./tests/run.sh` → prints `PASS n/n` (exit 0) or lists `FAIL` lines
  (exit 1). It assembles `core/` into `build/test/` beside `harness.qml` and runs
  it with `qs`.
- **Why `qs`, not `qmltestrunner`:** on this box (Arch, Qt 6.11.2) qmltestrunner
  exits 1 with no output for *any* input — even a trivial one-test file — so
  QuickTest is unusable here. The harness (`tests/harness.qml`) is a headless
  `ShellRoot` that runs the assertions in Quickshell (the app's own runtime),
  prints a `[[GNS-TESTS]]` sentinel, and `Qt.exit`s with the status.
- These lock the hard requirement: `onCalendar`/`timeOfDay` build Dates from
  local components and assert the same components back, so they'd catch any
  UTC-conversion regression regardless of the host timezone.

## Gotchas (learned the hard way)

- A QML property named `on<Capital>` is parsed as a signal handler — the "text
  on accent" colour is `accentInk`, **not** `onAccent`.
- `font.pixelSize` rejects non-integers (no `10.5`).
- Swap detection can't use `test -s /proc/swaps` (procfs reports size 0); count
  lines instead.
- Inhibitor warning filters to **`block`-mode** sleep/shutdown locks only — delay
  locks (NetworkManager, UPower) are always present and would false-alarm.
- Timezone abbreviation comes from `date +%Z` (Qt's `Date.toString()` omits the
  tz name); the panel falls back to `Formatting.tzAbbrev()`.
- Status parse only reads `ActiveState` — `systemctl show --value` formats the
  next-elapse as a localized date string, so the exact target comes from the
  persisted state file, not systemd.
- The pre-warning timer must share the **action's time basis**: a countdown
  action is monotonic (`--on-active`) so its warn is too; a specific-time action
  is wall-clock (`--on-calendar`) so its warn is a calendar target `lead` seconds
  before the run. Mixing them lets the warn drift from the action across a
  suspend. (`CommandBuilder.warnArgv`.)
- The displayed countdown target is anchored at arm-*confirmed* time
  (`Scheduler._onArmed`), not click time — the async stop→reset→run chain adds
  latency, and `--on-active` counts from when the timer actually starts.

## Git / commit workflow

- Commit subjects: imperative mood.
- Commit + push to `origin/main` when the user asks; confirm before force-pushing.
- **Keep this `CLAUDE.md` current with every change** (standing user rule for all
  projects). When the architecture, build/install steps, or a gotcha change,
  update this file in the same commit. Keep the README in sync too.
- When `core/`/`ui/` change in a way the Omarchy plugin depends on, note it — the
  Osiris `amendale.shutdown` plugin fetches these from here and must be re-synced.
  **Pending re-sync:** `core/CommandBuilder.qml` (calendar-based specific-time
  warn) and `core/Scheduler.qml` (arm-confirmed countdown target) changed.
