import QtQuick
import Quickshell
import "ui" as Ui

// Standalone app entry point. A normal desktop window hosting the shared
// TimerPanel with the Midnight Neon Lo-Fi theme (ui/Theme.qml). Launched via
// the `gamers-need-sleep` wrapper (qs -p <this file>).
ShellRoot {
  FloatingWindow {
    id: win
    title: "Gamers Need Sleep"
    color: theme.background

    readonly property int pad: 20
    implicitWidth: 400
    implicitHeight: Math.max(360, Math.min(880, panel.contentHeight + pad * 2))
    minimumSize.width: 400
    minimumSize.height: 360

    Ui.Theme { id: theme }

    // Solid backdrop so the app reads as opaque even if the compositor applies
    // window transparency to floating windows (Omarchy does by default).
    Rectangle {
      anchors.fill: parent
      color: theme.background
    }

    Ui.TimerPanel {
      id: panel
      theme: theme
      anchors.fill: parent
      anchors.margins: win.pad
    }
  }
}
