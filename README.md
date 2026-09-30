# Gamers Need Sleep

A shutdown / sleep timer for Arch Linux, built in [Quickshell](https://quickshell.org).
Set your PC to **power off, restart, suspend, or hibernate** either after a countdown or at a
specific time of day — and go to bed.

A standalone desktop app with a *Midnight Neon Lo-Fi* look.

> **"At a specific time" means your PC's local wall-clock time.** If you set **23:00** while your
> machine is on BST, it fires at **23:00 BST** — never 23:00 UTC. This is guaranteed by scheduling
> through systemd's `OnCalendar`, which is interpreted in the system timezone.

## Features

- **Countdown** (HH:MM:SS, with +15m / +30m / +1h quick chips) or **Specific time**
  (HH:MM, Today / Tomorrow, presets like *End of Work* and *Midnight*).
- Actions: **Power Off · Restart · Suspend · Hibernate** (hibernate auto-disabled if there's no swap).
- Toggles: **Force** (`--force` / ignore inhibitor locks), **Wall broadcast**, **Desktop
  notification** (on arm and ~2 min before firing).
- **Live command preview** of exactly what will be scheduled, with one-click copy.
- **Active view**: a T-minus countdown ring, the target time in local time, and a big **Abort**.
- **Inhibitor detection** — warns when a process holds a `block`-mode sleep/shutdown lock.
- **Survives the UI closing** — the schedule lives in your systemd user manager; reopen to see it.

## How it works (and why it needs no root)

Every schedule becomes a transient **user** systemd timer:

```
systemd-run --user --collect --unit=gamers-need-sleep --on-active=<delay>s   systemctl <action>
systemd-run --user --collect --unit=gamers-need-sleep --on-calendar=<local>  systemctl <action>
```

- `systemctl poweroff/reboot/suspend/hibernate` goes through **logind**, which polkit permits for
  the active graphical session — so no `sudo`, no root.
- `--on-calendar` uses your **local timezone**, the whole point of the tool.
- Aborting just stops the unit: `systemctl --user stop gamers-need-sleep.timer`.
- Only one schedule exists at a time (fixed unit name); arming a new one replaces it.

## Install

Requires `quickshell` (in the `extra` repo). Optional: `libnotify` (notifications) and
`wl-clipboard` (copy the command).

```
git clone https://github.com/xElectric9177/gamers-need-sleep
cd gamers-need-sleep
./install.sh            # per-user install into ~/.local (no root)
```

Then launch **Gamers Need Sleep** from your app menu, or run `gamers-need-sleep` (ensure
`~/.local/bin` is on your `PATH`).

- `./install.sh --system` installs into `/usr/local` (uses `sudo`).
- `./install.sh --uninstall` removes it.
- `./install.sh --dev` just assembles `build/app/` so you can run `qs -p build/app/shell.qml`
  without installing.

Hyprland tiles new windows; if you'd rather it float, add a rule:

```
windowrulev2 = float, title:^(Gamers Need Sleep)$
windowrulev2 = size 400 720, title:^(Gamers Need Sleep)$
```

### Omarchy bar widget

This repo is the standalone app and the shared engine. The **Omarchy bar drop-down** version of
the timer lives in the [Osiris](https://github.com/xElectric9177/Osiris) config project as the
`amendale.shutdown` plugin, which reuses this repo's `core/` and `ui/` (fetched from here). If you
run Omarchy and want the bar pill, install it from there.

## Limitations

- A **suspend/hibernate** timer does not wake the machine to then power off — one action, one timer.
- User timers run while you're logged in; they don't fire from a logged-out session.

## Project layout

```
core/       scheduler engine + command builder + formatting (frontend-agnostic)
ui/         theme-agnostic Quickshell components + the Midnight Neon Lo-Fi theme
standalone/ standalone app entry (shell.qml), launcher, .desktop
install.sh  assemble + install the standalone bundle (see --help)
```

The UI components read colours/fonts from an injected `theme` object, so the same `core/` and `ui/`
render in this neon standalone app and in the Omarchy plugin (where an `OmarchyTheme` adapter — kept
in the Osiris repo — binds the contract to the live Omarchy palette). See `CLAUDE.md` for the full
architecture and dev notes.

## License

MIT — see [LICENSE](LICENSE).
