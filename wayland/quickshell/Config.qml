// Config.qml — the shell's settings. Edited by hand here; the only value
// changed at runtime (notch <-> island, from the Control Centre), the launcher favourites and
// the launch history are saved to ~/.local/state/quickshell/config.json.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root


    // ───────── notch ─────────
    // "notch" = stuck to the top edge with inverted corners (MacBook).
    // "island" = floating pill detached from the edge (Dynamic Island).
    property alias notchStyle: opts.notchStyle
    readonly property bool island: opts.notchStyle === "island"
    readonly property int islandGap: 4

    readonly property int bandH: 32        // band height = notch height at rest
    readonly property int flare: 13        // radius of the inverted top corner
    readonly property int roundMax: 30     // maximum bottom radius
    readonly property int idleW: 140       // width at rest for the time alone
    readonly property bool hoverPreview: true
    readonly property int hoverDelay: 240  // ms before the "peek" opens
    // Does a browser video count as "music playing"? Off: the notch only
    // changes face for real players. See ShellState.isBrowser.
    readonly property bool browserMedia: false
    readonly property bool showDate: false
    readonly property bool showBattery: false
    readonly property bool reserveSpace: true

    // ───────── bar ─────────
    readonly property real scrimAlpha: 0.0  // veil under the bar (0 = transparent)
    readonly property int sideMargin: 16
    readonly property bool showArch: true
    readonly property bool showWorkspaces: true
    readonly property bool stageEnabled: false
    readonly property bool showAppName: true
    readonly property bool showTray: true

    // ───────── launcher ─────────
    // Favourites, by .desktop entry `id` and IN ORDER.
    property alias favApps: opts.favApps
    property alias launches: opts.launches   // launch history, see ShellState.launchScore
    readonly property bool learnLauncher: true
    readonly property bool batteryAllowIdle: true

    // ───────── typography ─────────
    readonly property string fontUI: "Adwaita Sans"
    readonly property int clockSize: 20

    property bool loaded: false
    function save() { if (root.loaded) saver.restart(); }
    Timer { id: saver; interval: 0; onTriggered: file.writeAdapter() }

    FileView {
        id: file
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state")
              + "/quickshell/config.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: root.save()
        onLoaded: root.loaded = true
        // First time: it does not exist -> it is created with the defaults.
        onLoadFailed: function (error) {
            if (error === FileViewError.FileNotFound) { root.loaded = true; root.save(); }
        }

        JsonAdapter {
            id: opts
            property string notchStyle: "notch"
            property list<string> favApps: []
            property var launches: ({})
        }
    }
}
