import QtQuick
import Quickshell
import "core" as Core

// Headless test harness for the PURE helpers (Formatting, CommandBuilder).
//
// Why not qmltestrunner? On this Arch/Qt 6.11 box qmltestrunner exits 1 with no
// output for any input (even a trivial one-test file), so QuickTest is unusable
// here. Quickshell (`qs`) is the runtime the app already uses and runs fine, so
// tests run through it instead. `tests/run.sh` assembles core/ beside this file
// (Quickshell only imports from inside the config dir) and launches it.
//
// Only Formatting + CommandBuilder are covered — they are side-effect-free.
// Scheduler drives systemd/processes and is out of scope for a unit harness.
ShellRoot {
  Core.Formatting { id: fmt }
  Core.CommandBuilder { id: cb }

  property int checks: 0
  property int fails: 0

  function eq(got, want, tag) {
    checks++
    if (JSON.stringify(got) !== JSON.stringify(want)) {
      fails++
      console.log("FAIL " + tag + ": got " + JSON.stringify(got) + " want " + JSON.stringify(want))
    }
  }
  function ok(cond, tag) {
    checks++
    if (!cond) { fails++; console.log("FAIL " + tag + ": expected truthy") }
  }
  function has(argv, s) { return argv.indexOf(s) !== -1 }
  function hasPrefix(argv, prefix) {
    for (var i = 0; i < argv.length; i++)
      if (String(argv[i]).indexOf(prefix) === 0) return true
    return false
  }

  function run() {
    // ---- Formatting ----
    eq(fmt.pad2(0), "00", "pad2.0"); eq(fmt.pad2(9), "09", "pad2.9")
    eq(fmt.pad2(10), "10", "pad2.10"); eq(fmt.pad2(7.9), "07", "pad2.floor")

    eq(fmt.humanDuration(0), "0s", "hd.zero"); eq(fmt.humanDuration(45), "45s", "hd.sec")
    eq(fmt.humanDuration(65), "1m 5s", "hd.ms"); eq(fmt.humanDuration(120), "2m 0s", "hd.exactmin")
    eq(fmt.humanDuration(3600), "1h 0m 0s", "hd.hour"); eq(fmt.humanDuration(3661), "1h 1m 1s", "hd.hms")
    eq(fmt.humanDuration(-10), "0s", "hd.neg")

    eq(fmt.clock(0), "00:00:00", "ck.0"); eq(fmt.clock(65), "00:01:05", "ck.mmss")
    eq(fmt.clock(3661), "01:01:01", "ck.full"); eq(fmt.clock(36000), "10:00:00", "ck.big")

    eq(fmt.firesIn(0), "in the past", "fi.past"); eq(fmt.firesIn(-5), "in the past", "fi.neg")
    eq(fmt.firesIn(30), "under a minute", "fi.sub"); eq(fmt.firesIn(300), "5m", "fi.min")
    eq(fmt.firesIn(3660), "1h 1m", "fi.hours"); eq(fmt.firesIn(90000), "1d 1h", "fi.days")

    eq(fmt.timeOfDay(new Date(2025, 0, 5, 23, 5, 0), true), "23:05", "tod.24")
    eq(fmt.timeOfDay(new Date(2025, 0, 5, 23, 5, 0), false), "11:05 PM", "tod.12")
    eq(fmt.timeOfDay(new Date(2025, 0, 5, 12, 0, 0), false), "12:00 PM", "tod.noon")
    eq(fmt.timeOfDay(new Date(2025, 0, 5, 0, 0, 0), false), "12:00 AM", "tod.midnight")

    // The hard requirement: local wall-clock components round-trip verbatim,
    // regardless of the machine's timezone.
    eq(fmt.onCalendar(new Date(2025, 5, 15, 23, 0, 0)), "2025-06-15 23:00:00", "oc.local")
    eq(fmt.onCalendar(new Date(2025, 0, 5, 2, 3, 4)), "2025-01-05 02:03:04", "oc.pad")

    ok(fmt.tzAbbrev().length > 0, "tz.nonempty")

    // ---- CommandBuilder ----
    eq(cb.actionLabel("poweroff"), "Power Off", "al.po"); eq(cb.actionLabel("reboot"), "Restart", "al.rb")
    eq(cb.actionVerb("suspend"), "suspend", "av.su"); eq(cb.actionLabel("nonsense"), "nonsense", "al.pass")

    ok(cb.supportsWall("poweroff"), "sw.po"); ok(cb.supportsWall("reboot"), "sw.rb")
    ok(!cb.supportsWall("suspend"), "sw.su"); ok(!cb.supportsWall("hibernate"), "sw.hi")

    ok(has(cb.actionArgv("poweroff", { force: true, wall: true }), "--force"), "aa.force")
    var susp = cb.actionArgv("suspend", { force: true, wall: true })
    ok(has(susp, "-i"), "aa.i"); ok(!has(susp, "--force"), "aa.noforce")
    ok(has(cb.actionArgv("poweroff", { force: false, wall: false }), "--no-wall"), "aa.nowall")
    ok(!has(cb.actionArgv("poweroff", { force: false, wall: true }), "--no-wall"), "aa.wallon")
    ok(!has(cb.actionArgv("suspend", { force: false, wall: false }), "--no-wall"), "aa.suspnowall")

    var cdSpec = { kind: "countdown", seconds: 1800, secondsUntil: 1800, targetEpochMs: Date.now() + 1800000 }
    var cdArm = cb.armArgv(cdSpec, "poweroff", { force: false, wall: true })
    ok(has(cdArm, "--on-active=1800s"), "arm.cd"); ok(has(cdArm, "--unit=" + cb.unit), "arm.unit")
    ok(has(cdArm, "poweroff"), "arm.po")

    var target = new Date(2025, 5, 15, 23, 0, 0)
    var spSpec = { kind: "specific", calendar: fmt.onCalendar(target), secondsUntil: 9999, targetEpochMs: target.getTime() }
    var spArm = cb.armArgv(spSpec, "reboot", { force: false, wall: true })
    ok(has(spArm, "--on-calendar=2025-06-15 23:00:00"), "arm.cal"); ok(!hasPrefix(spArm, "--on-active"), "arm.noactive")

    // Countdown warn stays monotonic.
    var cdWarn = cb.warnArgv(cdSpec, "poweroff", { notify: true }, 120)
    ok(has(cdWarn, "--on-active=1680s"), "warn.cd"); ok(!hasPrefix(cdWarn, "--on-calendar"), "warn.cdnocal")
    ok(has(cdWarn, "notify-send"), "warn.notify")

    // Specific-time warn is a CALENDAR target `lead` before the action (the fix).
    var spWarn = cb.warnArgv(spSpec, "poweroff", { notify: true }, 120)
    var expected = fmt.onCalendar(new Date(target.getTime() - 120 * 1000))
    eq(expected, "2025-06-15 22:58:00", "warn.expcalc")
    ok(has(spWarn, "--on-calendar=" + expected), "warn.cal"); ok(!hasPrefix(spWarn, "--on-active"), "warn.noactive")

    var floorSpec = { kind: "countdown", seconds: 30, secondsUntil: 30, targetEpochMs: Date.now() + 30000 }
    ok(has(cb.warnArgv(floorSpec, "poweroff", { notify: true }, 120), "--on-active=1s"), "warn.floor")

    var pvSpec = { kind: "countdown", seconds: 60, secondsUntil: 60, targetEpochMs: Date.now() + 60000 }
    var pvOpts = { force: false, wall: true }
    eq(cb.preview(pvSpec, "poweroff", pvOpts), cb.armArgv(pvSpec, "poweroff", pvOpts).join(" "), "prev")
  }

  Component.onCompleted: {
    run()
    // A machine-readable sentinel run.sh greps for, plus a human summary.
    console.log("[[GNS-TESTS]] " + (fails === 0 ? "PASS" : "FAIL") + " " + (checks - fails) + "/" + checks)
    Qt.exit(fails === 0 ? 0 : 1)
  }
}
