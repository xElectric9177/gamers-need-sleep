# Changelog

Notable changes to Gamers Need Sleep, newest first.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions are milestones for how much of the app changed — semver is followed in
spirit rather than to the letter.

## [v0.1.0] — 2026-09-30

First tagged release of the standalone app + shared engine.

### Added

- **Shutdown / sleep timer.** Power off, restart, suspend, or hibernate after a
  **countdown** or at a **specific local time**, scheduled as a transient
  `systemd-run --user` timer so it survives the GUI closing and needs no root.
- **Timezone-correct specific time.** A specific time is the local wall-clock
  moment (`--on-calendar` in the system timezone), never a UTC-shifted one.
- **Behaviour toggles.** Force (`--force` / `-i`), wall broadcast (`--no-wall`),
  and a desktop notification on arm plus a pre-warning before firing.
- **Live command preview**, inhibitor-lock detection (`block`-mode only), swap
  detection to gate Hibernate, and schedule restore across restarts via a small
  state file.
- **Theme-agnostic components** so the same `core/` + `ui/` render both here
  (Midnight Neon Lo-Fi) and in the Omarchy bar plugin.
- **Unit tests** for the pure helpers (`tests/`, run with `./tests/run.sh`).

### Fixed

- The specific-time **pre-warning no longer drifts from the action across a
  suspend**: it is now a calendar target `lead` seconds before the run, sharing
  the action's wall-clock basis instead of a monotonic timer.
- The **countdown target is anchored at arm-confirmed time**, not click time, so
  the countdown ring is not skewed by the stop→reset→run chain latency.
- A stale **Hibernate** selection falls back to Power Off when the swap probe
  reports no swap, so an unsatisfiable hibernate is never armed.
