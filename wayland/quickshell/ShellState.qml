// ShellState.qml — data and state hub for the top surface.
//
// All the logic and the data live here, and
// TopShell.qml stays pure UI. That way the bar and the notch read EXACTLY the
// same state and cannot fall out of sync.
pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    // The locale with which the WHOLE shell formats dates and numbers. It has
    // to follow the language: with the shell in English, a "miércoles" in the
    // notch sticks out as much as an untranslated label.
    //
    // en_GB and not en_US because this repo's English is the British of the
    // README ("recoloured", "licence", "centre"), and because the format fits:
    // en_GB puts the day before the month (3/9/2026) and the time in 24 h, just
    // like Spanish. With en_US the date would flip round (9/3/2026) and "PM"
    // would appear, which nobody here uses.
    readonly property var loc: Qt.locale("en_GB")

    // ═════════════════════════ notch state ══════════════════════════
    // The notch is the desktop's entry point: panels unfold from it.
    // "" = none. Adding a new one = one more value here, its size in
    // notchW/notchH, and its layer in NotchContent.qml.
    property string panel: ""     // "" | "control" | "system" | "launcher" | "power" | "overview" | "calendar"
    readonly property bool open: panel !== ""

    function togglePanel(name) {
        // The launcher is the only panel that opens in several modes, so it has
        // its own door (openLauncher). Through here you ALWAYS enter "apps":
        // neither Super+R nor the Arch logo asks for the clipboard or windows.
        if (name === "launcher") { root.openLauncher("apps"); return; }
        root.panel = (root.panel === name) ? "" : name;
    }
    function closePanel() { root.panel = ""; }

    // The transient dies with the panel, on opening it AND on closing it. It is
    // the other half of the fix above: flash() stops it being BORN covered, and
    // this stops it SURVIVING a panel that opens afterwards. It goes on the
    // property change and not in closePanel() because there are seven places
    // that assign `root.panel` by hand (the ">" mode actions, openLauncher, the
    // toggle) and all of them would have to remember.
    onPanelChanged: {
        if (root.panel !== "") {
            // A PANEL OPENS. Whatever expires with the gesture that caused it
            // -volume, workspace, song, notification- is dropped: showing it
            // later is noise. The "Copiado" (Copied) receipt is frozen instead:
            // it was born of a gesture of yours inside the panel.
            if (root.activity === "toast") {
                activityTimer.stop();
            } else if (root.activity !== "") {
                root.activity = "";
                activityTimer.stop();
            }
        } else {
            // IT CLOSES. Whatever was frozen starts now, with its full clock.
            if (root.activity !== "")
                activityTimer.restart();
        }
    }
    property bool hovered: false             // mouse over the notch
    property string activity: ""             // "" | "volume" | "brightness" | "track"
    property bool armed: false               // start-up is over: OSDs are allowed

    Timer { interval: 1500; running: true; onTriggered: root.armed = true }
    Timer { id: activityTimer; onTriggered: root.activity = "" }

    function flash(kind, ms) {
        // WITH A PANEL IN FRONT THERE IS NO NOTICE TO GIVE.
        //
        // `mode` puts `panel !== ""` first, so with any panel open the notice
        // is not seen. But the clock started anyway: you moved the volume in
        // the control centre, closed it, and the OSD came out AFTERWARDS, when
        // it was no longer relevant. With a notification it is worse, because
        // the clock is 4200 or 11000 ms. It is dropped at the source, as
        //
        // The "Copiado" (Copied) receipt is spared on purpose: it was born of a
        // gesture of yours INSIDE the panel -clicking in the launcher's
        // clipboard- and seeing it a moment late is better than not seeing it.
        if (root.panel !== "" && kind !== "toast")
            return;
        root.activity = kind;
        // "ws" lasts less than the rest on purpose: it is not information you
        // have to read, it is the receipt of a gesture you have just made.
        // A volume OSD is looked at; this one is only checked out of the corner
        // of your eye. An explicit duration wins: today only notifications use
        // it, being the only ones that bring a time requested from outside (see
        // notifFlashMs). The other callers pass a single argument, so ms arrives
        // undefined and the notch lasts exactly as long as it did.
        activityTimer.interval = (ms !== undefined && ms > 0) ? ms
            : (kind === "track" || kind === "notif") ? 4200
            : kind === "toast" ? 1600
            : kind === "ws" ? 1100
            : 1800;
        // Covered does not count. The only one that gets here with a panel in
        // front is the "Copiado" receipt, and onPanelChanged starts its clock on
        // uncovering: that way it is read in full instead of arriving half spent.
        if (root.panel === "")
            activityTimer.restart();
    }

    // "There is music playing AND it rules the notch". The WHOLE music face
    // hangs off this: the resting width (restW), the face, the shifted clock,
    // the hidden date and battery and the cava visualiser. `mediaDrives`
    // —defined next to the MPRIS block— is what leaves the browser out.
    readonly property bool mediaLive: player !== null && player.isPlaying && root.mediaDrives

    readonly property string mode: panel !== "" ? panel
        : activity === "notif" ? "notif"
        : activity === "toast" ? "toast"
        : activity === "track" ? "track"
        : activity === "ws" ? "ws"
        : activity !== "" ? "activity"
        : hovered ? "peek"
        : mediaLive ? "media" : "idle"

    // Target geometry of the notch (a loose island stuck to the top edge).
    // RULE: at rest and with music the height is EXACTLY the reserved band
    // (barH) so that the notch never covers any window. It only sticks out
    // when you cause something: hover, OSD, song change or the panel.
    readonly property int bandH: Config.bandH

    // Gap between the screen edge and the pill in island mode. It lives here and
    // not only in TopShell because the panels that compute their exact height
    // have to subtract it: TopShell draws the notch with `height: notchH - gap`.
    readonly property int notchTopGap: Config.island ? Config.islandGap : 0

    // No panel can be wider than the screen it appears on. The widths below
    // were chosen looking at THIS laptop, where they fit with room to spare (the
    // fattest, the control centre, is 1080 on 1920: 420 px of air per side).
    // But they are fixed numbers, and on a narrower output the notch would spill
    // over both sides with its content cut off and no warning at all. 48 px of
    // breathing room on each side; if the screen is not known yet, nothing is
    // trimmed, which is how it has behaved until today.
    readonly property int notchW: Math.min(root.notchWWanted, root.maxNotchW)
    readonly property int maxNotchW: {
        const s = root.focusedScreen;
        return (s && s.width > 0) ? Math.max(220, s.width - 96) : 100000;
    }
    readonly property int notchWWanted: mode === "launcher" ? 660
        : mode === "overview" ? ovW
        : mode === "control" ? 1080
        : mode === "system" ? 920
        : mode === "power" ? 430
        : mode === "calendar" ? 350
        : mode === "notif" ? 430
        : mode === "toast" ? 330
        : mode === "ws" ? 220
        : mode === "track" ? 400
        : mode === "peek" ? 380
        : mode === "activity" ? 330
        : mode === "media" ? root.mediaW : root.idleW

    readonly property int mediaW: 268

    // Width of the notch in its RESTING face: the time alone, or the music one
    // if something is playing. The PASSING faces (panels, OSD, the song-change
    // flash, the map) do not count: those really do have to swallow the
    // satellite bubble and give it back as they shrink, which is the metaphor.
    //
    // This used to be plain `idleW` and the bubble stayed under the notch for
    // the whole of playback: with music on -i.e. nearly always- a running
    // countdown was invisible.
    readonly property int restW: root.mediaLive ? root.mediaW : root.idleW

    // The launcher fits what there is: if you search for something and three apps
    // come up, or it is a sum, the panel shrinks upwards instead of leaving a
    // black hole. LauncherPanel publishes here how many rows it has after each search.
    property int launcherRows: 0
    property bool launcherCalc: false
    // The favourites row only exists with the field empty, so it too enters
    // and leaves the panel's height just like the calculator's.
    property bool launcherFavs: false

    // CAREFUL with these constants: they have to match LauncherPanel.qml's margins
    // EXACTLY. If they fall short, the list gets less height than its rows take
    // up and the last one is clipped at the bottom.
    //   4 (topMargin) + 50 (search box) + 1 + 6 (separator) + 12 (bottom margin)
    readonly property int launcherChrome: 73
    // The row height depends on the MODE, and it is the only one that departs
    // from 48: a clipboard entry shows a real thumbnail, not a 30 px icon, and at
    // 48 the images could not be told apart.
    readonly property int launcherRowH: root.launcherMode === "clip" ? 60 : 48
    readonly property int launcherCalcH: 62      // 56 for the row + 6 of margin
    readonly property int launcherFavH: 70       // 58 for the row + 12 of margin
    readonly property int launcherMaxRows: 7     // beyond this, scrolling

    readonly property int launcherH: {
        const calc = root.launcherCalc ? root.launcherCalcH : 0;
        const favs = root.launcherFavs ? root.launcherFavH : 0;
        const rows = Math.min(root.launcherRows, root.launcherMaxRows) * root.launcherRowH;
        const vacio = (root.launcherRows === 0 && !root.launcherCalc) ? 46 : 0;  // "Sin resultados"
        // Island mode's gap is NOT usable height: TopShell lifts the pill off the
        // edge with `height: nh - gap`, so the content gets islandGap less than
        // this calculation asks for. Without adding it here, the list (fillHeight)
        // swallows the shortfall and clips the last row right at its rounded
        // corners — it shows most with a single result.
        // The island gap is NO longer added here: notchH adds it for all the
        // panel faces at once (see the carasDePanel block).
        return root.launcherChrome + calc + favs + rows + vacio;
    }

    // Config.idleW is the width for the time ALONE. If you turn the date or the
    // battery back on in Config.qml, the notch widens by itself.
    readonly property int idleW: Config.idleW
        + (Config.showDate ? 92 : 0)
        + (Config.showBattery ? 64 : 0)
    // PANEL FACES ADD THE ISLAND GAP; NOTICE FACES DO NOT, AND IT IS NOT AN
    // OVERSIGHT.
    //
    // TopShell draws the notch with `y: gap` and `height: nh - gap`, so the
    // BOTTOM edge always lands at `nh` and the gap is eaten from the height. For
    // a panel face that matters: it declares the height its content needs and
    // without adding the gap it gets four pixels less -the control centre
    // measured 522 where it declared 526-. For the notice faces and the resting
    // one it is NOT added on purpose: there `nh` is the reserved band, and adding
    // the gap would push the bottom edge OUT of the band, i.e. the notch would
    // cover windows.
    //
    // A single list that lives here, so adding a panel face does not rely on
    // remembering.
    readonly property var carasDePanel: ["launcher", "overview", "control", "system",
                                         "power", "calendar"]
    readonly property int notchGapDeCara: root.carasDePanel.indexOf(root.mode) >= 0 ? root.notchTopGap : 0

    readonly property int notchH: root.notchBaseH + root.notchGapDeCara

    readonly property int notchBaseH: mode === "launcher" ? launcherH
        : mode === "overview" ? ovH
        : mode === "control" ? 526
        : mode === "system" ? 420
        : mode === "power" ? 158
        : mode === "calendar" ? 320
        : mode === "notif" ? 66
        : mode === "toast" ? 44
        : mode === "ws" ? 44
        : mode === "track" ? 52
        : mode === "peek" ? 44
        : mode === "activity" ? 42
        : bandH

    // ═════════════════════════ workspace overview ══════════════════════════
    // The overview grid (OverviewPanel.qml) sizes ITSELF from the monitor: each
    // cell is the screen's usable area to scale. It is here and not in the
    // panel because the notch has to know how big it will be BEFORE the panel
    // exists — the shape morph starts on the same frame as the layer.
    //
    // 5x2 is not a pretty number: it is exactly the ten workspaces that
    // hyprland.conf binds to Super+1..0. If one day there were twelve, this and
    // the shortcuts have to change together or the map would lie.
    readonly property int ovCols: 5
    readonly property int ovRows: 2
    readonly property int ovCount: ovCols * ovRows

    // The scale. 0.14 comes from a real constraint: 5 cells + gaps + air have
    // to fit comfortably in 1920 px, and a cell below ~250 px wide no longer
    // lets you recognise a window by its content, which is the only thing that
    // justifies capturing live instead of painting icons.
    readonly property real ovScale: 0.14
    readonly property real ovGap: 6          // gap between cells
    readonly property real ovPad: 14         // air at the sides and at the bottom
    readonly property real ovPadTop: 16
    readonly property real ovFooterH: 24     // the strip with the title of the pointed-at window

    // The reserved band (`reserved`) is subtracted, not the whole height: windows
    // are placed inside the USABLE area, so if the cell stood for the full screen
    // they would all come out shifted 32 px upwards.
    // It is looked up by NAME with the focus we already have seeded (see
    // focusedMon, further down) instead of trusting Hyprland.focusedMonitor: that
    // property is born empty and is only filled on the first event, so with the
    // shell freshly started the overview was drawn with the 1920x1080 fallback.
    // On this laptop it went unnoticed because the panel MEASURES 1920x1080; on
    // a screen of another size the cells come out with the wrong proportion and
    // the thumbnails do not match the real windows.
    readonly property var ovMon: {
        const ms = Hyprland.monitors ? Hyprland.monitors.values : [];
        for (let i = 0; i < ms.length; i++)
            if (ms[i] && ms[i].name === root.focusedMon) return ms[i].lastIpcObject;
        return Hyprland.focusedMonitor ? Hyprland.focusedMonitor.lastIpcObject : null;
    }
    // And if not even that, Quickshell's screen rather than a fixed number.
    readonly property real ovMonW: (ovMon && ovMon.width) ? ovMon.width
        : (root.focusedScreen ? root.focusedScreen.width : 1920)
    readonly property real ovMonH: (ovMon && ovMon.height) ? ovMon.height
        : (root.focusedScreen ? root.focusedScreen.height : 1080)
    readonly property var ovRes: (ovMon && ovMon.reserved) ? ovMon.reserved : [0, bandH, 0, 0]
    readonly property real ovCellW: (ovMonW - ovRes[0] - ovRes[2]) * ovScale
    readonly property real ovCellH: (ovMonH - ovRes[1] - ovRes[3]) * ovScale
    readonly property real ovGridW: ovCols * ovCellW + (ovCols - 1) * ovGap
    readonly property real ovGridH: ovRows * ovCellH + (ovRows - 1) * ovGap
    readonly property int ovW: Math.round(ovGridW + 2 * ovPad)
    readonly property int ovH: Math.round(ovPadTop + ovGridH + ovFooterH + ovPad)

    // ═══════════════════════ clock ═══════════════════════
    property var now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    // ═══════════════════════ active window ════════════════════════
    readonly property var activeToplevel: ToplevelManager.activeToplevel
    readonly property bool fullscreen: activeToplevel ? activeToplevel.fullscreen : false
    readonly property string appName: {
        if (!activeToplevel || !activeToplevel.appId) return "";
        const a = String(activeToplevel.appId).split(".").pop();
        return a.charAt(0).toUpperCase() + a.slice(1);
    }
    readonly property string winTitle: activeToplevel ? (activeToplevel.title || "") : ""

    // ═══════════════════════ media (MPRIS) ═══════════════════════
    readonly property var player: {
        const ps = Mpris.players.values;
        if (!ps || ps.length === 0) return null;
        for (let i = 0; i < ps.length; i++) if (ps[i].isPlaying) return ps[i];
        // With everything paused the first in the list won, and that is usually
        // a browser media session with nothing loaded any more: the panel said
        // "Sin reproducción" (Nothing playing) with Spotify right beside it, its
        // song loaded and paused, and the buttons controlled nothing.
        for (let i = 0; i < ps.length; i++) if (ps[i].trackTitle) return ps[i];
        return ps[0];
    }

    // ─────────── who may change the notch's face? ───────────
    //
    // Any video in a tab registers its MPRIS session just like Spotify, so the
    // notch widened to 268, hid the date and the battery and flashed for 4.2 s
    // for anything that made a sound in the browser. For Spotify that is fine;
    // for a background video, it is a nuisance.
    //
    // CAREFUL: this does NOT take the browser out of the player. `player` still
    // returns it and the music panel still shows it, which is what lets you
    // pause it from there. All it loses is ruling the notch's face at REST.
    //
    // All three fields are checked because each browser fills in different
    // ones: Chromium publishes `org.mpris.MediaPlayer2.chromium.instance<pid>`
    // and on some versions leaves `desktopEntry` empty, while others can only
    // be told apart by `identity`.
    readonly property var browserHints: ["chrome", "chromium", "brave", "edge",
                                         "opera", "vivaldi", "firefox"]
    function isBrowser(p) {
        if (!p) return false;
        const campos = [p.dbusName, p.desktopEntry, p.identity];
        for (let i = 0; i < campos.length; i++) {
            const v = String(campos[i] || "").toLowerCase();
            if (v.length === 0) continue;
            for (let j = 0; j < root.browserHints.length; j++)
                if (v.indexOf(root.browserHints[j]) >= 0) return true;
        }
        return false;
    }

    // "Hay reproductor Y tiene derecho a cambiar la cara del notch."
    // ("There is a player AND it has the right to change the notch's face.")
    readonly property bool mediaDrives: root.player !== null
        && (Config.browserMedia || !root.isBrowser(root.player))

    // The music accent is born from the cover art, not the wallpaper.
    // ColorQuantizer is asynchronous: while a new palette arrives it keeps the
    // previous accent and, if there is no image or the cover is practically grey,
    // it falls back to pywal. The lightness is normalised because the colour is
    // used on dark backgrounds: a faithful but almost black tone would be no use
    // for a 4 px bar.
    readonly property string mediaArtUrl: (player && player.trackArtUrl)
        ? String(player.trackArtUrl) : ""
    ColorQuantizer {
        id: mediaQuantizer
        source: root.mediaArtUrl
        depth: 3
        rescaleSize: 48
    }
    function mediaHsl(c) {
        const r = Number(c.r), g = Number(c.g), b = Number(c.b);
        const hi = Math.max(r, g, b), lo = Math.min(r, g, b);
        const d = hi - lo, l = (hi + lo) / 2;
        let h = 0, s = 0;
        if (d > 0.0001) {
            s = d / (1 - Math.abs(2 * l - 1));
            if (hi === r) h = ((g - b) / d) % 6;
            else if (hi === g) h = (b - r) / d + 2;
            else h = (r - g) / d + 4;
            h /= 6;
            if (h < 0) h += 1;
        }
        return { h: h, s: isFinite(s) ? s : 0, l: l };
    }
    readonly property color mediaAccent: {
        if (root.mediaArtUrl.length === 0) return Colors.accent;
        const cs = mediaQuantizer.colors;
        if (!cs || cs.length === 0) return Colors.accent;

        let best = null, bestScore = -100;
        for (let i = 0; i < cs.length; i++) {
            const hsl = root.mediaHsl(cs[i]);
            // Rewards colour and legibility; penalises cover whites and blacks.
            const score = hsl.s * 1.75 - Math.abs(hsl.l - 0.56) * 1.35
                - (hsl.l < 0.12 || hsl.l > 0.90 ? 1.5 : 0) + (i === 0 ? 0.04 : 0);
            if (score > bestScore) { bestScore = score; best = hsl; }
        }
        if (!best || best.s < 0.15) return Colors.accent;
        const saturation = Math.max(0.45, Math.min(0.90, best.s * 1.12));
        const lightness = Math.max(0.48, Math.min(0.67, best.l));
        return Qt.hsla(best.h, saturation, lightness, 1);
    }
    property real pos: 0
    readonly property real len: (player && player.lengthSupported) ? player.length : 0
    Timer {
        interval: 500; repeat: true; running: root.player !== null && (root.open || root.mediaLive)
        onTriggered: root.pos = (root.player && root.player.positionSupported) ? root.player.position : 0
    }
    // Only the first letter. Qt's Font.Capitalize capitalises EVERY word
    // and in Spanish leaves things like "Martes, 4 De Agosto".
    function capitalize(s) { return s ? s.charAt(0).toUpperCase() + s.slice(1) : ""; }

    function fmt(sec) {
        if (!sec || sec < 0) return "0:00";
        const m = Math.floor(sec / 60), s = Math.floor(sec % 60);
        return m + ":" + (s < 10 ? "0" + s : s);
    }
    // The song-change flash does NOT hang off `mediaLive`, so it has to be
    // filtered separately: without `mediaDrives`, the notch would keep opening
    // to 400 px for 4.2 s every time the browser changed video, which is
    // exactly what we want to avoid.
    Connections {
        target: root.player
        ignoreUnknownSignals: true
        function onTrackTitleChanged() {
            if (root.armed && root.mediaDrives && root.player && root.player.trackTitle) root.flash("track");
            root.recordarTema();
        }
        function onIsPlayingChanged() { if (root.armed && root.mediaDrives && root.player && root.player.isPlaying) root.flash("track"); }
    }

    // ══════════════════ whatever played last ══════════════════
    // When the player closes, MPRIS ceases to exist and the left column of the
    // control centre was left as 260x486 px saying "Sin reproducción" (Nothing
    // playing) inside an empty circle. Remembering the last track keeps that
    // column telling you something, and above all lets you GO BACK to what you
    // were listening to, which is the only thing you can really ask of it there.
    //
    // It goes to disk and not just to memory because the shell reloads every
    // time a .qml is touched, and a "last thing" that is forgotten on every
    // reload is not the last of anything.
    property string ultimoTitulo: ""
    property string ultimoArtista: ""
    property string ultimoArte: ""
    property string ultimoAppId: ""
    readonly property bool hayUltimo: root.player === null && root.ultimoTitulo.length > 0

    FileView {
        id: ultimoFile
        path: (Quickshell.env("XDG_CACHE_HOME") || root.home + "/.local/cache") + "/quickshell/ultimo-tema.json"
        // watchChanges is NOT optional even though nobody is going to touch the
        // file from outside: without it, FileView does not even do the INITIAL read
        // and onLoaded never fires. No errors and no warnings -- it just stays
        // empty, which is what this panel did until it was discovered.
        watchChanges: true
        onFileChanged: reload()
        printErrors: false      // the first time it does not exist, and that is not a failure
        onLoaded: {
            try {
                const d = JSON.parse(ultimoFile.text());
                root.ultimoTitulo = d.titulo || "";
                root.ultimoArtista = d.artista || "";
                root.ultimoArte = d.arte || "";
                root.ultimoAppId = d.app || "";
            } catch (e) {
                // Same rule as the team and github: with rubbish, touch
                // nothing. An invented "last track" is worse than none.
            }
        }
    }

    function recordarTema(): void {
        const p = root.player;
        if (!p || !p.trackTitle)
            return;
        root.ultimoTitulo = p.trackTitle;
        root.ultimoArtista = p.trackArtist || "";
        root.ultimoArte = p.trackArtUrl ? String(p.trackArtUrl) : "";
        root.ultimoAppId = p.desktopEntry || "";
        ultimoFile.setText(JSON.stringify({
            titulo: root.ultimoTitulo,
            artista: root.ultimoArtista,
            arte: root.ultimoArte,
            app: root.ultimoAppId
        }));
    }

    // It is also remembered when a player APPEARS, not only on a song change:
    // if you open the player and close it without skipping a track, without this
    // nothing would have been saved.
    onPlayerChanged: if (root.player) root.recordarTema()

    // The app that was playing it, if it is still installed. It is compared
    // without the trailing ".desktop" because MPRIS gives it sometimes with it
    // and sometimes without.
    readonly property var ultimaApp: {
        if (!root.ultimoAppId.length)
            return null;
        const pela = s => String(s || "").toLowerCase().replace(/\.desktop$/, "");
        const id = pela(root.ultimoAppId);
        const vs = DesktopEntries.applications ? DesktopEntries.applications.values : [];
        for (let i = 0; i < vs.length; i++)
            if (pela(vs[i].id) === id)
                return vs[i];
        return null;
    }

    // ═══════════════════════ audio (Pipewire) ═══════════════════════
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property int vol: (sink && sink.audio) ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool muted: (sink && sink.audio) ? sink.audio.muted : false

    // THE OSD MUST NOT APPEAR BECAUSE OF AN OUTPUT CHANGE.
    //
    // `vol` is derived from `sink`, so plugging in headphones, switching off the
    // radio or choosing another output in Settings made `vol` jump without
    // anybody having touched the volume, and an OSD you had not asked for
    // appeared.
    //
    // Listening to onSinkChanged and lowering a flag is not enough: the order in
    // which QML notifies `sink` and the `vol` that depends on it is not
    // guaranteed, and if `vol` arrived first the notice would appear anyway.
    // Comparing the sink against the last one we saw makes the result
    // independent of the order. The grace window covers the burst of changes
    // that arrives while the new output settles.
    property var _sinkVisto: null
    Timer { id: sinkGracia; interval: 500 }

    // The two paths, and both are needed. This one seeds the reference as soon
    // as the output changes, so that the FIRST volume change after a shell
    // reload does not swallow the notice. And the comparison in _audioEsTuyo()
    // is the safety net in case QML notified `vol` before `sink`, which is an
    // order that is not guaranteed.
    onSinkChanged: {
        root._sinkVisto = root.sink;
        sinkGracia.restart();
    }

    function _audioEsTuyo() {
        if (root.sink !== root._sinkVisto) {
            root._sinkVisto = root.sink;
            sinkGracia.restart();
            return false;
        }
        return !sinkGracia.running;
    }

    onVolChanged: if (armed && _audioEsTuyo()) flash("volume")
    onMutedChanged: if (armed && _audioEsTuyo()) flash("volume")

    function setVolume(pct) {
        if (!sink || !sink.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1.4, pct / 100));
    }
    function nudgeVolume(dir) {
        if (!sink || !sink.audio) return;
        // Unmutes, same as setVolume. Without this, the wheel over the notch
        // with the sound muted left the bar pinned at 0 while the real level
        // climbed behind its back up to 140%: you unmuted and got slapped in
        // the face. Moving the volume IS asking to hear.
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1.4, sink.audio.volume + dir * 0.02));
    }
    function toggleMute() { if (sink && sink.audio) sink.audio.muted = !sink.audio.muted; }

    // ═══════════════════ horizontal wheel over the notch ═══════════════════
    // Swiping over the island does something,
    // but there the gesture changes FACE and here that does not fit: in this
    // shell each face comes from a specific state or button, not from a
    // carousel. What was going spare was the horizontal axis, which did
    // nothing. Now it changes workspace.
    //
    // Two details that set it apart from "subtract and add one":
    //
    // · IT ACCUMULATES. A touchpad does not send one event per gesture, it sends
    //   a burst of dozens; without accumulating, a short drag would take you
    //   across all ten workspaces at once. 120 is the equivalent of one wheel
    //   notch, which is the unit Qt uses for "one step".
    //
    // · IT GOES TO `e+1`, NOT TO `id+1`. It is exactly what the vertical wheel
    //   with Super does in hyprland.lua: it jumps to the next workspace that
    //   EXISTS. Adding to the id would drop you into empty workspaces you had
    //   not created, and the overview map shows them anyway.
    property real wsAccum: 0
    Timer { id: wsAccumReset; interval: 350; onTriggered: root.wsAccum = 0 }

    function scrollWorkspace(dx) {
        root.wsAccum += dx;
        wsAccumReset.restart();
        while (Math.abs(root.wsAccum) >= 120) {
            const dir = root.wsAccum > 0 ? 1 : -1;
            root.wsAccum -= dir * 120;
            // `e+1` goes IN QUOTES. Since 0.55 the argument to `dispatch` is
            // a Lua expression (see the long note in OverviewPanel.qml), and
            // there the workspace target is of two kinds depending on what you
            // ask for: a bare number for "go to 3", but a STRING for symbolic
            // targets such as `e+1`. Without the quotes, Lua reads `e` as a
            // variable that does not exist and blows up with a syntax error.
            Hyprland.dispatch('hl.dsp.focus({ workspace = "e' + (dir > 0 ? "+1" : "-1") + '" })');
            // The flash is requested AT ONCE, without waiting for Hyprland to
            // answer: the face reads the active workspace through a live binding,
            // so if the first frame arrives with the old number it corrects
            // itself on the next one, and that happens inside the entry
            // animation itself.
            root.flash("ws");
        }
    }

    readonly property int activeWs: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    // ───────────────── focused monitor ─────────────────
    // With several screens, the bar is drawn on ALL of them but the panels and
    // the overlays appear only on this one. Name of the output, e.g. "eDP-1".
    //
    // Hyprland.focusedMonitor is NOT used: in Quickshell 0.3.0 that property is
    // born empty —like focusedWorkspace and monitor.focused— and is only filled
    // when the first event arrives. With the shell freshly started it would not
    // know where the focus is until you changed monitor by hand, and until then
    // the panels would not appear anywhere. Checked with test instances:
    // neither refreshMonitors() nor refreshWorkspaces() seeds it. So hyprctl is
    // asked once and from then on the events rule.
    property string focusedMon: ""

    // The same idea but as a screen object, which is what the loose surfaces
    // (wallpaper picker, media controls) ask for in order to appear only where
    // you are looking. If the focus is not known yet, the first screen: better
    // that it appears somewhere than nowhere.
    readonly property var focusedScreen: {
        const ss = Quickshell.screens;
        for (let i = 0; i < ss.length; i++)
            if (ss[i].name === root.focusedMon) return ss[i];
        return ss.length > 0 ? ss[0] : null;
    }

    Process {
        id: monSeed
        command: ["sh", "-c", "hyprctl monitors -j | jq -r '.[] | select(.focused) | .name'"]
        stdout: SplitParser {
            onRead: function (line) {
                const n = String(line).trim();
                if (n !== "") root.focusedMon = n;
            }
        }
    }
    function reseedMonitor(): void { monSeed.running = false; monSeed.running = true; }
    Component.onCompleted: root.reseedMonitor()

    // One pass per burst of events, and with some slack: plugging in a screen
    // emits several events in a row, and hyprpaper needs the output to exist to
    // be able to paint it.
    Timer {
        id: wallHotplug
        interval: 700
        onTriggered: Quickshell.execDetached([root.home + "/Documents/scripts/wayland/wallpaper.sh"])
    }

    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            const n = String(ev.name);
            if (n === "focusedmon" || n === "focusedmonv2") {
                // data = "NAME,workspace" (v2 sends the workspace id)
                const m = String(ev.data).split(",")[0].trim();
                if (m !== "") root.focusedMon = m;
            } else if (n.indexOf("monitor") === 0) {
                // monitoradded / monitorremoved / their v2s: the list of
                // outputs changed, so we have to ask again who has the focus.
                root.reseedMonitor();
                // And the screen that has just come in needs its wallpaper.
                wallHotplug.restart();
            }
        }
    }

    // ──────────────── audio spectrum (cava) ─────────────────
    // The notch's little bars. This used to be a PwNodePeakMonitor: ONE single
    // number (the sink's global peak) shifted along the array. That is not a
    // spectrum, it is the same signal repeated 14 times —all the bars rose and
    // fell together— and since the linear peak nearly always brushes 1, they
    // stayed pinned to the ceiling (barcode effect). Worse: onPeakChanged only
    // fires when the value CHANGES, so in a compressed stretch the signal
    // stopped arriving and the bars FROZE.
    //
    // cava does do an FFT: it gives `bands` independent values per frame, from
    // bass to treble, and with its own autosens (quiet music fills just the
    // same, loud music does not saturate). "raw" output in ascii, one line per
    // frame: "0;312;…;\n". The configuration lives in scripts/cava.conf.
    // Few and thick. With 14 the strip read as a pattern of stripes rather than
    // as an equaliser: at 2.5 px wide you cannot tell one bar from its
    // neighbour. If you change this, change `bars` in scripts/cava.conf.
    readonly property int bands: 8

    // WHY CAVA'S VALUE IS NOT PAINTED AS IT COMES. Because cava's values JUMP:
    // a single band goes from 2 to 1000 and back in a handful of frames.
    // Painting that directly is not an equaliser, it is a strobe — and it was
    // exactly the jitter you could see. Measured by recording the notch at 60
    // fps and measuring the PAINTED bars:
    //
    //                             max jump   jerks
    //   painting the raw value     16.7 px   0.200
    //   with this follower          1.3 px   0.079
    //
    // So cava only sets the TARGET, and what MOVES the bar is the screen's
    // clock: a FrameAnimation that on every frame brings it a little closer,
    // according to the REAL time elapsed (frameTime): alpha = 1 - exp(-dt/tau).
    //
    // Exponential on purpose: advancing a FRACTION of what is left gives no
    // jumps or sudden stops —the speed is continuous— and being tied to real
    // time it does not matter if a frame is dropped: the bar is always where it
    // should be.
    //
    // What does NOT work, tried and measured: smoothing in cava
    // (noise_reduction), smoothing the received value, or quantising the height
    // into steps. All of that touches the NUMBERS, and what has to be
    // continuous is the MOTION.
    //
    // IT RISES FAST AND FALLS SLOWLY, like a VU meter. With a single constant
    // for both directions the bar COLLAPSES as fast as it rises: at tau 35 it
    // eats 38% of what is left on every frame, so a peak comes apart in three
    // frames (~50 ms). That does not read as a bar going down, it reads as a
    // bar switching off — a blink.
    //
    // With attack and decay separated, the hit still lands just as crisply
    // (it is what marks the rhythm) but the return is a glide of ~1/3 of a
    // second, which is plenty of time for the eye to follow it as continuous
    // motion.
    //
    // tau = ms it takes to eat 63% of what is left. Lower = more glued to the
    // music and more nervous; higher = smoother and lazier. The decay cannot go
    // above ~150: beyond that, two consecutive kick-drum hits at 120 bpm
    // overlap and the bar stops marking the beat.
    readonly property int cavaSube: 32    // attack
    readonly property int cavaBaja: 110   // decay

    property var cavaTarget: new Array(bands).fill(0)   // what cava says

    // WHY EVERY BAND HAS ITS OWN RANGE. With dense music no band ever goes
    // below 200-400 out of 1000, so mapping 0-1000 straight onto the bar left
    // all eight half-to-two-thirds high, travelling 2-3 px out of 18 in half a
    // second: an equaliser that looks frozen. Each band keeps a window that
    // jumps at once to a new peak or valley and forgets it slowly, and the bar
    // is painted inside that window, so every beat goes from floor to ceiling
    // whatever the band's loudness. Simulated on the same cava output: travel
    // 2.7 -> 8.4 px every half second, at the ceiling 23% of the time.
    //
    // cavaRango = ms it takes to forget 63% of a peak or valley. Lower = more
    // nervous, it stretches even the quiet passages; higher = slower to adapt
    // when the song changes section.
    // cavaRangoMin = the narrowest window, so a near-silent band does not get
    // its noise blown up to full height.
    readonly property int cavaRango: 2500
    readonly property real cavaRangoMin: 0.25
    property var cavaHi: new Array(bands).fill(0.5)
    property var cavaLo: new Array(bands).fill(0.3)
    property real cavaUltima: 0
    property var levels: new Array(bands).fill(0)       // what gets painted
    property bool cavaQuieto: true

    FrameAnimation {
        // Keeps running after the music stops until the bars have come down
        // completely: that way they glide to the floor instead of vanishing at once.
        running: cavaProc.running || !root.cavaQuieto
        onTriggered: {
            // smoothFrameTime and not frameTime: the real gap between frames
            // fluctuates (16.7 · 12 · 21 · 16…), and since the follower's step
            // is computed from that gap, using the raw one makes the bar advance
            // in fits and starts even when the signal is perfect. Qt averages
            // that measurement precisely for this; the position error it
            // introduces corrects itself on the next frame, because the follower
            // chases the target, it does not accumulate.
            const dt = smoothFrameTime * 1000;
            const aSube = 1 - Math.exp(-dt / root.cavaSube);
            const aBaja = 1 - Math.exp(-dt / root.cavaBaja);
            const out = new Array(root.bands);
            let quieto = true;
            for (let i = 0; i < root.bands; i++) {
                const falta = root.cavaTarget[i] - root.levels[i];
                if (Math.abs(falta) > 0.001) {
                    out[i] = root.levels[i] + falta * (falta > 0 ? aSube : aBaja);
                    quieto = false;
                } else {
                    out[i] = root.cavaTarget[i];
                }
            }
            root.levels = out;
            root.cavaQuieto = quieto;
        }
    }

    // Starts and stops cava with the music, and BRINGS IT BACK if it dies.
    //
    // `running: root.mediaLive` is NOT used here, which is the natural thing and
    // was so until 7 Aug 2026: when the process dies (it crashes, or someone
    // kills it), quickshell writes running=false, and that write BREAKS the
    // binding. From then on cava never starts again —not even reloading the
    // config— and the visualiser is left with eight flat bars even though music
    // is playing. It is driven by hand: the timer reasserts the state every 3 s,
    // so at most it takes that long to get back up by itself. triggeredOnStart
    // = it starts at once when playback begins, without waiting for the first tick.
    Timer {
        interval: 3000
        repeat: true
        triggeredOnStart: true
        running: root.mediaLive
        onTriggered: cavaProc.running = true
    }
    onMediaLiveChanged: if (!root.mediaLive) cavaProc.running = false

    Process {
        id: cavaProc
        command: ["cava", "-p", root.home + "/.config/quickshell/scripts/cava.conf"]
        stdout: SplitParser {
            onRead: function (line) {
                const parts = line.split(";");
                const now = Date.now();
                const dt = root.cavaUltima ? Math.min(100, now - root.cavaUltima) : 16.7;
                root.cavaUltima = now;
                const olvido = 1 - Math.exp(-dt / root.cavaRango);
                const hi = root.cavaHi.slice();
                const lo = root.cavaLo.slice();
                const out = new Array(root.bands);
                for (let i = 0; i < root.bands; i++) {
                    const v = Math.max(0, Math.min(1, (+parts[i] || 0) / 1000));
                    hi[i] = v > hi[i] ? v : hi[i] + (v - hi[i]) * olvido;
                    lo[i] = v < lo[i] ? v : lo[i] + (v - lo[i]) * olvido;
                    // A window narrower than the minimum grows downwards, so a
                    // loud band still reaches the ceiling.
                    const span = Math.max(hi[i] - lo[i], root.cavaRangoMin);
                    const base = Math.min(lo[i], Math.max(0, hi[i] - span));
                    out[i] = Math.max(0, Math.min(1, (v - base) / span));
                }
                root.cavaHi = hi;
                root.cavaLo = lo;
                root.cavaTarget = out;   // only the target; moving is the FrameAnimation's job
                root.cavaQuieto = false;
            }
        }
        // On pause, cava dies and the target would keep the last snapshot:
        // bars at half height through the whole fade-out.
        onRunningChanged: if (!running) {
            root.cavaTarget = new Array(root.bands).fill(0);
            root.cavaUltima = 0;
        }
    }

    // ═════════════════════ brightness ═════════════════════
    property int bright: -1
    Process {
        id: brightProc
        stdout: SplitParser {
            onRead: function (line) {
                const v = parseInt(line.trim());
                if (!isNaN(v)) { root.bright = v; root.flash("brightness"); }
            }
        }
    }
    // `-c backlight` on EVERY call, and not for the sake of it: without a class,
    // brightnessctl walks backlight and then leds, and settles on the first one
    // that has something. On a machine with no internal panel there is no
    // backlight, so the XF86MonBrightness keys would end up switching the
    // caps-lock LED on and off and the notch OSD would show you that 0/100 as
    // if it were the screen brightness. With the class pinned there is no
    // device, no output, no flash: the key does nothing, which is the truth.
    function stepBrightness(dir) {
        brightProc.command = ["bash", "-c",
            "brightnessctl -c backlight -m set 5%" + (dir === "down" ? "-" : "+") +
            " >/dev/null 2>&1; brightnessctl -c backlight -m 2>/dev/null | awk -F, '{gsub(\"%\",\"\",$4); print $4}'"];
        brightProc.running = false;
        brightProc.running = true;
    }
    // 0 is reachable ON PURPOSE (screen fully off): there is no floor at 1, it is
    // only clamped to the valid range. brightnessctl also reaches 0 on its own
    // with the keys (5%- stays at raw 0, verified).
    function setBrightness(pct) {
        // With no panel there is nothing to move, and without this guard the
        // slider (no longer drawn, but the function is still public) would write
        // to the first LED it found.
        if (root.bright < 0) return;
        const v = Math.max(0, Math.min(100, Math.round(pct)));
        Quickshell.execDetached(["brightnessctl", "-c", "backlight", "-q", "set", v + "%"]);
        root.bright = v;
    }

    // ═══════════════════════ system ════════════════════════
    property int cpu: 0
    property int mem: 0
    property int batt: -1
    property int disk: 0
    property bool ac: false
    property real memUsedKib: 0
    property real memTotalKib: 0
    property real diskUsedBytes: 0
    property real diskTotalBytes: 0
    property real cpuTemp: -1
    property real cpuLoad: 0
    property int uptimeSeconds: 0
    property int cpuThreads: 1

    // Sixty samples at 1.5 s: a minute and a half of context. The arrays are
    // replaced whole (instead of mutated) so that Canvas gets valuesChanged and
    // repaints the curves even if the current percentage matches the previous one.
    property var cpuHistory: []
    property var memHistory: []
    property var tempHistory: []
    function appendMetric(history, value) {
        const next = history.slice(Math.max(0, history.length - 59));
        next.push(isFinite(value) ? value : 0);
        return next;
    }
    // 2026-09-14: this Process had neither an `id` nor an `onExited`, so if the
    // script died NOBODY relaunched it. And it is the ONLY source of cpu, mem,
    // batt, ac, disk, memUsedKib, memTotalKib, diskUsedBytes, diskTotalBytes,
    // cpuTemp, cpuLoad, uptimeSeconds and cpuThreads: the bar, the control
    // centre and the performance panel kept showing the LAST SNAPSHOT as if it
    // were the current state, with no warning at all. Lying quietly is worse
    // than saying nothing, above all in the panel you look at when the laptop
    // is acting up. The realistic case is not hypothetical: systemd-oomd kills
    // user processes under memory pressure, and this machine froze because of
    // that the very same day.
    Process {
        id: sysstatsProc
        command: [root.home + "/.config/quickshell/scripts/sysstats.sh"]
        running: true
        // Relaunch with a 2 s breather. The breather matters: if the script
        // were really broken (a syntax error, a missing binary) without it we
        // would enter a relaunch loop at full speed, which is exactly what you
        // do not want on a machine that has just run out of memory. With 2 s,
        // a permanent failure costs half a process per second instead of
        // thousands.
        onExited: function (exitCode, exitStatus) {
            console.warn(Appearance.fmt("sysstats.sh exited (code={0}, status={1}); restarting in 2 s", exitCode, exitStatus));
            sysstatsRestart.restart();
        }
        stdout: SplitParser {
            onRead: function (line) {
                const p = line.trim().split(/\s+/);
                if (p.length < 8) return;
                root.cpu = parseInt(p[0]); root.mem = parseInt(p[1]);
                root.batt = parseInt(p[2]); root.ac = p[3] === "1";
                if (p.length >= 9) root.disk = parseInt(p[8]);
                if (p.length >= 17) {
                    root.memUsedKib = parseFloat(p[9]);
                    root.memTotalKib = parseFloat(p[10]);
                    root.diskUsedBytes = parseFloat(p[11]);
                    root.diskTotalBytes = parseFloat(p[12]);
                    const milliC = parseFloat(p[13]);
                    root.cpuTemp = milliC >= 0 ? milliC / 1000 : -1;
                    root.cpuLoad = parseFloat(p[14]);
                    root.uptimeSeconds = parseInt(p[15]);
                    root.cpuThreads = Math.max(1, parseInt(p[16]));
                }
                root.cpuHistory = root.appendMetric(root.cpuHistory, root.cpu);
                root.memHistory = root.appendMetric(root.memHistory, root.mem);
                if (root.cpuTemp >= 0)
                    root.tempHistory = root.appendMetric(root.tempHistory, root.cpuTemp);
                if (root.bright < 0) root.bright = parseInt(p[4]);   // only the initial value
            }
        }
    }

    // Companion to the onExited above. Outside the Process on purpose: a Timer
    // inside the very object being restarted is fragile.
    Timer {
        id: sysstatsRestart
        interval: 2000
        repeat: false
        onTriggered: if (!sysstatsProc.running) sysstatsProc.running = true;
    }
    // PLUGGING IN AND UNPLUGGING are among the very few things that happen to
    // the laptop WITHOUT you touching anything and that you want to know about
    // right away. Everything else that appears in the notch is caused by you;
    // this is caused by the world, and that is why it deserves its own face
    // instead of one more icon in the bar.
    //
    // The `armed` is not redundant: sysstats.sh spits out the first line a few
    // milliseconds after starting and that first value is NOT a change, it is
    // the initial state. Without the guard, every shell restart would greet you
    // with a "Cargando" (Charging) you had not asked for.
    onAcChanged: if (root.armed) root.flash("charge")

    readonly property string battIcon: ac ? "󰂄"
        : batt < 0 ? "󰂑"
        : batt >= 90 ? "󰁹" : batt >= 70 ? "󰂂" : batt >= 50 ? "󰁿"
        : batt >= 30 ? "󰁼" : batt >= 15 ? "󰁻" : "󰁺"

    // UPower exposes the electrical data already normalised (Wh, W and seconds).
    // sysstats still carries the notch's fast percentage; this layer adds the
    // information that deserves a Settings screen: wear, capacity, cycles and
    // time estimate.
    readonly property var batteryDevice: {
        const ds = UPower.devices ? UPower.devices.values : [];
        for (let i = 0; i < ds.length; i++)
            if (ds[i] && ds[i].isLaptopBattery && ds[i].isPresent) return ds[i];
        const display = UPower.displayDevice;
        return (display && display.isPresent) ? display : null;
    }
    readonly property real battHealth: batteryDevice && batteryDevice.ready
        && batteryDevice.healthSupported ? batteryDevice.healthPercentage : -1
    readonly property real battFullWh: batteryDevice && batteryDevice.ready
        ? batteryDevice.energyCapacity : -1
    readonly property real battDesignWh: battHealth > 0 && battFullWh > 0
        ? battFullWh / (battHealth / 100) : -1
    readonly property real battRateW: batteryDevice && batteryDevice.ready
        ? Math.abs(batteryDevice.changeRate) : -1
    readonly property real battEstimateSeconds: {
        if (!batteryDevice || !batteryDevice.ready) return -1;
        const seconds = root.ac ? batteryDevice.timeToFull : batteryDevice.timeToEmpty;
        return seconds > 0 ? seconds : -1;
    }
    property int battCycles: -1

    function fmtBatteryTime(seconds) {
        if (!isFinite(seconds) || seconds <= 0) return "";
        const mins = Math.max(1, Math.round(seconds / 60));
        const h = Math.floor(mins / 60), m = mins % 60;
        if (h <= 0) return Appearance.fmt("{0} min", m);
        return m > 0 ? Appearance.fmt("{0} h {1} min", h, m) : Appearance.fmt("{0} h", h);
    }
    function fmtWh(value) { return value > 0 ? Appearance.fmt("{0} Wh", value.toFixed(1)) : ""; }
    readonly property string battEstimateText: {
        if (root.batt < 0) return "no battery";
        if (root.ac && root.batt >= 99 && root.battEstimateSeconds < 0) return "full";
        const time = root.fmtBatteryTime(root.battEstimateSeconds);
        if (time.length === 0) return "calculating…";
        // A whole sentence and not `time + suffix`: in English the order need not
        // be the same, and each branch needs its own translation.
        return root.ac ? Appearance.fmt("{0} to full", time) : Appearance.fmt("{0} left", time);
    }

    Process {
        id: battCyclesProc
        stdout: SplitParser {
            onRead: function (line) {
                const cycles = parseInt(line.trim());
                if (!isNaN(cycles) && cycles >= 0) root.battCycles = cycles;
            }
        }
    }
    function refreshBatteryCycles() {
        if (!root.batteryDevice || battCyclesProc.running) return;
        const nativeName = String(root.batteryDevice.nativePath || "");
        if (!/^[A-Za-z0-9._-]+$/.test(nativeName)) return;
        battCyclesProc.command = ["cat", "/sys/class/power_supply/" + nativeName + "/cycle_count"];
        battCyclesProc.running = true;
    }
    onBatteryDeviceChanged: root.refreshBatteryCycles()
    Timer {
        interval: 3600000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refreshBatteryCycles()
    }

    // ═════════════════════════ screen capture ══════════════════════════
    // Hyprland reports it on its event socket: "screencast>>state,owner".
    //
    // MEASURED on this laptop, and it is exactly what makes this non-trivial:
    //   grim (screenshot)      -> 1,monitor  …  0,monitor
    //   a region recording     -> 1,region
    //   YOUR OWN overview      -> 1,window, ONE PER WINDOW
    // So counting every event would light up the "you are being recorded"
    // notice every time you press Super+Tab. Only monitor and region count.
    //
    // And the delay is not for the sake of it either: a grim screenshot opens
    // and closes the capture in under half a second. Without waiting, the bar
    // would flash red every time you take a screenshot, which is exactly when
    // you least want a new element appearing on the screen.
    property int castCount: 0
    property bool casting: false
    Timer { id: castArm; interval: 1500; onTriggered: root.casting = root.castCount > 0 }

    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            if (String(ev.name) !== "screencast") return;
            const p = String(ev.data).split(",");
            if (p.length < 2) return;
            if (p[1] !== "monitor" && p[1] !== "region") return;
            root.castCount = Math.max(0, root.castCount + (p[0] === "1" ? 1 : -1));
            if (root.castCount > 0) {
                castArm.restart();
            } else {
                castArm.stop();
                root.casting = false;
            }
        }
    }

    // ══════════════════════ the satellite bubble ═══════════════════════
    // A small body that peeks out from BEHIND the notch's right edge when
    // something is running in the background.
    //
    // Why a satellite and not one more face: the resting notch measures exactly
    // the reserved band and cannot grow by itself — that is the rule that keeps
    // it from ever covering a window. A countdown lasts minutes, so it does not
    // fit there without breaking the rule. A separate body does: it is born
    // behind the edge, stays INSIDE the band, and the notch stays the same size.
    //
    // This is a SLOT, not a timer. Today two things fill it, and adding a third
    // (a download, a build) is one more line in bubbleKind. The timer wins over
    // background work because you asked for the timer and the other just happens.
    readonly property string bubbleKind: timerTotal > 0 ? "timer" : (busy ? "busy" : "")
    readonly property bool bubbleOn: bubbleKind !== ""
    // -1 = indeterminate: we know it is still going, not how much is left.
    readonly property real bubbleProgress: (bubbleKind === "timer" && timerTotal > 0)
        ? Math.max(0, Math.min(1, timerLeft / timerTotal)) : -1
    readonly property string bubbleIcon: bubbleKind === "timer"
        ? (timerDone ? Icons.alarm : (timerRunning ? Icons.timer : Icons.pause))
        : Icons.sync
    readonly property string bubbleLabel: bubbleKind === "timer"
        ? (timerDone ? "Time's up" : timerClock(timerLeft))
        : "Syncing"
    readonly property bool bubbleAlert: timerDone

    // "I am doing something and it is taking a while." Only the timer here.
    readonly property bool busy: false

    // ── the timer ──
    property int timerTotal: 0        // seconds requested; 0 = no timer
    property int timerLeft: 0
    property bool timerRunning: false
    property bool timerDone: false    // already went off and you have not dismissed it yet

    Timer {
        interval: 1000
        repeat: true
        running: root.timerRunning
        onTriggered: {
            root.timerLeft = Math.max(0, root.timerLeft - 1);
            if (root.timerLeft > 0) return;
            root.timerRunning = false;
            root.timerDone = true;
            // We ARE the notification server (see further down), so this
            // notify-send comes round and back to our own notch. There is no
            // need to invent a notice: the existing one is used, and along the
            // way it stays in the control centre's history.
            Quickshell.execDetached(["notify-send", "-u", "critical",
                                     "-a", "Timer",
                                     "Timer",
                                     Appearance.fmt("{0} elapsed", root.timerSpoken(root.timerTotal))]);
        }
    }

    function timerStart(seconds) {
        if (seconds <= 0) return;
        root.timerTotal = seconds;
        root.timerLeft = seconds;
        root.timerDone = false;
        root.timerRunning = true;
    }
    // A click on the bubble: if it already went off, it dismisses it; if not, pause and resume.
    function timerToggle() {
        if (root.timerDone) { root.timerClear(); return; }
        if (root.timerTotal <= 0) return;
        root.timerRunning = !root.timerRunning;
    }
    function timerClear() {
        root.timerRunning = false;
        root.timerTotal = 0;
        root.timerLeft = 0;
        root.timerDone = false;
    }

    // mm:ss, and hh:mm:ss only if there really are hours. A "00:09:59" for ten
    // minutes is two digits that say nothing taking up room in a 28 px body.
    function timerClock(sec) {
        const h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60), x = sec % 60;
        const two = n => (n < 10 ? "0" + n : String(n));
        return h > 0 ? (h + ":" + two(m) + ":" + two(x)) : (m + ":" + two(x));
    }
    // How it is said out loud, for the notice: "25 min", "1 h 30 min".
    function timerSpoken(sec) {
        const h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60), x = sec % 60;
        const parts = [];
        if (h > 0) parts.push(Appearance.fmt("{0} h", h));
        if (m > 0) parts.push(Appearance.fmt("{0} min", m));
        if (x > 0 && h === 0) parts.push(Appearance.fmt("{0} s", x));
        return parts.join(" ");
    }

    // ── from what you type to seconds ──
    // Recognises "10m", "25 min", "1h", "90s", "1h30", "1h 5 min".
    //
    // It DEMANDS A UNIT on purpose. A bare "5" is a search, and if the launcher
    // offered a countdown every time you typed a number it would get in the way
    // of every search that starts with a digit. It is the same rule the
    // calculator already uses so as not to fire on "7zip".
    function parseDuration(text) {
        const t = String(text || "").trim().toLowerCase().replace(/\s+/g, "");
        if (t.length === 0) return -1;
        // "1h30" = an hour and a half. It is how everybody writes it and it
        // does not fit the form with units, so it goes separately.
        const hm = t.match(/^(\d+)h(\d{1,2})$/);
        if (hm) return parseInt(hm[1]) * 3600 + parseInt(hm[2]) * 60;
        // Units in both languages, because the timer follows the shell's: in
        // English "5 minutes" used to be rejected and only "5 min" got through.
        const m = t.match(/^(?:(\d+)(?:horas?|hours?|hrs?|h))?(?:(\d+)(?:minutos?|minutes?|mins?|m))?(?:(\d+)(?:segundos?|seconds?|segs?|secs?|s))?$/);
        if (!m || (!m[1] && !m[2] && !m[3])) return -1;
        const sec = parseInt(m[1] || 0) * 3600 + parseInt(m[2] || 0) * 60 + parseInt(m[3] || 0);
        return (sec > 0 && sec <= 86400) ? sec : -1;
    }

    // ══════════════════════════ notifications (own server) ══════════════════════════
    // Replaces swaync: its "control centre" is a GTK window of its own, it cannot
    // be put inside the notch. Here we are the D-Bus server and we paint both the
    // pop-up notice and the history ourselves.
    property bool dnd: false
    property var lastNotif: null

    NotificationServer {
        id: notifServer
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: true
        actionIconsSupported: true

        onNotification: function (n) {
            n.tracked = true;               // stays in the history
            root.lastNotif = n;
            // ...but the history has a ceiling. With Qt.callLater and not
            // directly: here the server's list does not include `n` yet (the
            // long why, with the measurement, is in trimNotifs), so calling it
            // on the spot would leave the history at 51 instead of 50. As a
            // bonus, Qt.callLater collapses a burst of sixty into a single
            // pass, and trimNotifs already knows how to remove several at once.
            Qt.callLater(root.trimNotifs);
            if (!root.dnd) root.flash("notif", root.notifFlashMs(n));
        }
    }

    // `lastNotif` holds an object that is NOT ours: the server destroys it when
    // the notification closes (the user closes it, the application withdraws
    // it, or clearNotifs sweeps it away). Without this the notch kept showing
    // an already dead notification, and pressing its actions did nothing,
    // without saying why. Same pattern as the Connections in NetworkPanel.
    Connections {
        target: root.lastNotif
        ignoreUnknownSignals: true
        function onClosed(reason) {
            root.lastNotif = null;
            // AND THE NOTICE GOES WITH IT.
            //
            // This Connections was left half done: it removed the dead
            // notification but not the notice showing it. Since `activityTimer`
            // is the only thing that clears `activity`, and `mode` comes from
            // `activity === "notif"` without looking at `lastNotif`, the pill
            // stayed open and EMPTY -no icon, no title, no application, 430 px
            // wide- until the clock ran out. With a `notify-send -u critical`
            // (no -t, expireTimeout -1, notifFlashMs 11000) that is eleven
            // seconds of blank pill in front of you. It is enough for the
            // application to close its own notification; no panel is needed.
            if (root.activity === "notif") {
                root.activity = "";
                activityTimer.stop();
            }
        }
    }

    // most recent first
    readonly property var notifications: {
        const vs = notifServer.trackedNotifications ? notifServer.trackedNotifications.values : [];
        return vs.slice().reverse();
    }
    readonly property int notifCount: notifications.length

    // History ceiling: 50. It does NOT expire on a clock, and on purpose: what
    // `trackedNotifications` holds are the server's LIVE objects -the panel
    // invokes THEIR actions-, so a notification that deleted itself would be a
    // button vanishing while you look at it. The oldest is only thrown out when
    // a new one comes in and there is no room left. And it is closed with
    // expire(), not dismiss(): the program that sent it has to be told that it
    // expired, not that you closed it.
    readonly property int notifMax: 50

    // MIND WHEN THIS IS CALLED. `trackedNotifications.values` does NOT yet
    // contain the incoming notification while onNotification runs, not even
    // after setting `n.tracked = true`. Measured with a test NotificationServer
    // on an isolated bus (dbus-run-session, quickshell 0.3.1, without touching
    // the live shell): when the first notification arrives the list gives 0,
    // and in the following Qt.callLater it gives 1. That is why onNotification
    // does not call this on the spot: with notifMax = 5 and twelve
    // notifications in a row the history stayed at 6, i.e. notifMax + 1. With
    // Qt.callLater it stays at exactly 5.
    function trimNotifs() {
        if (!notifServer.trackedNotifications) return;
        const vs = notifServer.trackedNotifications.values;
        const sobran = vs.length - root.notifMax;
        if (sobran <= 0) return;
        // slice() before closing anything: expire() modifies the live list -also
        // checked-, and we have to iterate over a copy. values[0] is the oldest:
        // the `notifications` property up here does reverse() because the panel
        // paints the recent ones first.
        const viejas = vs.slice(0, sobran);
        for (let i = 0; i < viejas.length; i++)
            if (viejas[i] !== root.lastNotif) viejas[i].expire();
    }

    // How long the pop-up notice lasts. The application asks for its time in
    // `expireTimeout` (-1 = "you decide", 0 = "never expire") and it is obeyed,
    // but with a ceiling. The ceiling is not stinginess: the notch's activity
    // slot is ONE and music, volume, workspace and pokémon share it, so an
    // eternal notice would not be a notice, it would be a hijacked notch. That
    // is why 0 is translated to the maximum, also for a critical one: the
    // notification remains whole in the history, which is where it waits for
    // as long as needed.
    //
    // UNITS: MILLISECONDS, and nothing is converted here. The
    // org.freedesktop.Notifications specification defines expire_timeout as
    // "the timeout time in milliseconds", and Quickshell passes it through as
    // is: it exposes it as a double, but does not divide it. Measured on this
    // machine, with a test NotificationServer on an isolated bus:
    //     notify-send -t 9000   ->  expireTimeout = 9000
    //     notify-send -t 60000  ->  expireTimeout = 60000
    //     notify-send -t 0      ->  expireTimeout = 0      (never expire)
    //     notify-send  (no -t)  ->  expireTimeout = -1     (you decide)
    // The property being a double and not an int does NOT mean seconds arrive.
    function notifFlashMs(n) {
        const crit = !!n && n.urgency === NotificationUrgency.Critical;
        // A critical one -battery at 5 %, disk full- asks to be looked at twice:
        // it does not go below 10 s or above 12. The rest, from 1.5 s to 15 s.
        const suelo = crit ? 10000 : 1500;
        const techo = crit ? 12000 : 15000;
        const porDefecto = crit ? 11000 : 4200;
        if (!n) return porDefecto;
        const t = Number(n.expireTimeout);
        if (!isFinite(t) || t < 0) return porDefecto;   // -1: you decide
        if (t === 0) return techo;                      // 0: never expire
        return Math.max(suelo, Math.min(techo, Math.round(t)));
    }

    function dismissNotif(n) { if (n) n.dismiss(); }
    function clearNotifs() {
        const vs = notifServer.trackedNotifications ? notifServer.trackedNotifications.values.slice() : [];
        for (let i = 0; i < vs.length; i++) vs[i].dismiss();
    }

    readonly property string notifIcon: dnd ? (notifCount > 0 ? "󰂠" : "󰪓")
        : (notifCount > 0 ? "󱅫" : "󰂜")

    // ═══════════════════════ keyboard layout ═══════════════════════
    // The main keyboard's active layout as its short code ("US", "LATAM"),
    // re-read every time Hyprland reports a layout switch.
    property string kbLayout: ""
    Process {
        id: kbProc
        command: ["hyprctl", "devices", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const ks = JSON.parse(this.text).keyboards;
                    const k = ks.find(k => k.main) || ks[0];
                    const codes = String(k.layout).split(",");
                    root.kbLayout = (codes[k.active_layout_index] || codes[0]).toUpperCase();
                } catch (e) {}
            }
        }
    }
    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            if (String(ev.name) === "activelayout") kbProc.running = true;
        }
    }

    // ═══════════════════════ applications (launcher) ═══════════════════════
    readonly property var allApps: {
        const out = [];
        const vs = DesktopEntries.applications ? DesktopEntries.applications.values : [];
        for (let i = 0; i < vs.length; i++) if (!vs[i].noDisplay) out.push(vs[i]);
        out.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        return out;
    }

    // Score: the closer to "the start of the name" it matches, the higher. The
    // last resort is a subsequence (typing "gimp" finds "GNU Image...").
    function scoreApp(app, q) {
        const name = (app.name || "").toLowerCase();
        if (name === q) return 1000;
        if (name.startsWith(q)) return 900 - name.length * 0.1;
        const words = name.split(/[\s\-_.]+/);
        for (let i = 0; i < words.length; i++)
            if (words[i].startsWith(q)) return 800 - name.length * 0.1;
        const idx = name.indexOf(q);
        if (idx >= 0) return 700 - idx - name.length * 0.1;
        if ((app.genericName || "").toLowerCase().indexOf(q) >= 0) return 500;
        if ((app.comment || "").toLowerCase().indexOf(q) >= 0) return 400;
        let kw = "";
        try { kw = (app.keywords || []).join(" ").toLowerCase(); } catch (e) {}
        if (kw.indexOf(q) >= 0) return 300;
        // subsequence
        let ti = 0;
        for (let i = 0; i < q.length; i++) {
            ti = name.indexOf(q[i], ti);
            if (ti < 0) return -1;
            ti++;
        }
        return 200 - name.length * 0.1;
    }

    function searchApps(query) {
        const q = (query || "").trim().toLowerCase();
        if (q.length === 0) {
            const apps = root.allApps.slice();
            if (Config.learnLauncher) apps.sort((a, b) => root.launchScore(b.id)
                - root.launchScore(a.id) || (a.name || "").localeCompare(b.name || ""));
            return apps;
        }
        const hits = [];
        for (let i = 0; i < root.allApps.length; i++) {
            const s = root.scoreApp(root.allApps[i], q);
            if (s > 0) hits.push({ app: root.allApps[i], score: s });
        }
        // Usage only orders equally strong matches: an exact name always wins.
        hits.sort((a, b) => Math.floor(b.score / 100) - Math.floor(a.score / 100)
            || (Config.learnLauncher ? root.launchScore(b.app.id) - root.launchScore(a.app.id) : 0)
            || b.score - a.score || (a.app.name || "").localeCompare(b.app.name || ""));
        return hits.map(h => h.app);
    }

    // ════════════════ the launcher as a command centre ═════════════════
    //
    // The launcher stops being "the list of applications" and becomes the only
    // box where you type. A character at the start decides WHAT is searched:
    //
    //   (none)  applications, plus the calculator and the timer thrown in
    //   #       clipboard history (text and images)
    //   >       system actions
    //   @       open windows
    //
    // WHY PREFIXES AND NOT FOUR SHORTCUTS. Shortcuts have to be remembered with
    // your fingers and each opens a different window that has to be learnt
    // separately. A prefix discovers itself (they are written in the panel
    // itself when it is empty), is corrected with one backspace, and above all:
    // the habit is a single one —Super+R and type—, which is exactly the one
    // there already was.
    //
    // IT IS THE SAME DOOR THE CALCULATOR OPENED. Typing "2+2" in the launcher
    // was already typing something that is not an application name; this just
    // finishes the idea. That is why the calculator and the timer still have no
    // prefix: they are not a mode, they are what happens when what you type
    // turns out to be a sum or a duration.
    //
    property string launcherMode: "apps"     // "apps" | "clip" | "cmd" | "win"

    readonly property var launcherModes: [
        { key: "clip", prefix: "#", icon: Icons.clipboard, name: "Clipboard",
          hint: "Search the clipboard…" },
        { key: "cmd",  prefix: ">", icon: Icons.bolt,      name: "Actions",
          hint: "Search system actions…" },
        { key: "win",  prefix: "@", icon: Icons.windows,   name: "Windows",
          hint: "Search open windows…" }
    ]

    readonly property var launcherAppsMode: ({ key: "apps", prefix: "", icon: "󰍉",
        name: "Apps", hint: "Search applications…" })

    // "#" -> "clip". Returns "" if that character opens no mode.
    function launcherModeOf(ch) {
        for (let i = 0; i < root.launcherModes.length; i++)
            if (root.launcherModes[i].prefix === ch) return root.launcherModes[i].key;
        return "";
    }

    function launcherModeInfo(key) {
        for (let i = 0; i < root.launcherModes.length; i++)
            if (root.launcherModes[i].key === key) return root.launcherModes[i];
        return root.launcherAppsMode;
    }

    // Open the launcher ALREADY in a mode. Pressing the shortcut of the mode that
    // is already open closes it, just as togglePanel does with the other panels:
    // a shortcut that opens but does not close forces you to reach for Escape.
    function openLauncher(m) {
        const mode = m || "apps";
        if (root.panel === "launcher" && root.launcherMode === mode) { root.closePanel(); return; }
        root.launcherMode = mode;
        root.launcherPreload(mode);
        if (mode === "clip") root.clipRefresh();
        if (mode === "win") root.winRefresh();
        root.panel = "launcher";
    }

    // The starting height. Without this the panel is born with the height of the
    // PREVIOUS SEARCH and corrects on the next frame: you see a double movement.
    // In "clip" there is no knowing how many rows there will be until the
    // process answers, so the maximum is requested and the panel shrinks
    // —upwards, which is its natural gesture— during the opening animation itself.
    function launcherPreload(mode) {
        root.launcherCalc = false;
        root.launcherFavs = mode === "apps" && root.favApps.length > 0;
        root.launcherRows = mode === "apps" ? root.allApps.length
            : mode === "cmd" ? root.sysActions.length
            : mode === "win" ? root.winItems.length
            : root.clipItems.length > 0 ? root.clipItems.length : root.launcherMaxRows;
    }

    // ──────────────── # clipboard ─────────────────
    // The data is served by scripts/cliphist-tool.sh, which replaces the pair of
    // rofi scripts. Nothing is decoded here: an image entry is binary, and
    // putting binaries into a QML string is asking for something to break
    // silently. The script delivers id, type, thumbnail path and label.
    readonly property string clipTool: root.home + "/.config/quickshell/scripts/cliphist-tool.sh"

    property var clipItems: []
    property bool clipLoading: false

    Process {
        id: clipListProc
        command: [root.clipTool, "list"]
        stdout: StdioCollector {
            id: clipOut
            onStreamFinished: {
                const out = [];
                const lines = String(clipOut.text).split("\n");
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].length === 0) continue;
                    const p = lines[i].split("\t");
                    if (p.length < 4) continue;
                    out.push({
                        kind: "clip",
                        id: p[0],
                        image: p[1] === "image",
                        thumb: p[2] === "-" ? "" : p[2],
                        // join in case the label carried a tab the script had
                        // not cleaned: splitting on the first and joining the rest
                        // back loses no text.
                        label: p.slice(3).join("\t")
                    });
                }
                root.clipItems = out;
                root.clipLoading = false;
            }
        }
        // Safety net: if the process died without writing anything (script
        // deleted, cliphist uninstalled), without this the panel would stay for
        // ever on "Leyendo el portapapeles…" (Reading the clipboard…) with the
        // maximum height set.
        onExited: root.clipLoading = false
    }

    function clipRefresh() {
        if (clipListProc.running) return;
        root.clipLoading = true;
        clipListProc.running = true;
    }

    function searchClip(query) {
        const q = (query || "").trim().toLowerCase();
        if (q.length === 0) return root.clipItems;
        const out = [];
        for (let i = 0; i < root.clipItems.length; i++)
            if (root.clipItems[i].label.toLowerCase().indexOf(q) >= 0) out.push(root.clipItems[i]);
        return out;
    }

    // The notice cannot carry the preview's 200 characters: the "toast" face
    // is a fixed 330 px and the text would spill out of the notch at the sides.
    function clipShort(t) {
        const s = String(t).replace(/\s+/g, " ").trim();
        return s.length > 32 ? s.slice(0, 32) + "…" : s;
    }

    function clipCopy(item) {
        if (!item) return;
        Quickshell.execDetached([root.clipTool, "copy", String(item.id)]);
        root.closePanel();
        root.toast(item.image ? Icons.image : "󰆏",
                   item.image ? "Image copied"
                              : Appearance.fmt("Copied: {0}", root.clipShort(item.label)));
    }

    function clipDelete(item) {
        if (!item) return;
        Quickshell.execDetached([root.clipTool, "delete", String(item.id)]);
        // It is removed from the list HERE instead of re-reading it whole:
        // re-reading is 150 lines and one more process to strike out a row the
        // user has just seen disappear. cliphist ids are not reused, so the local
        // copy cannot end up pointing at something else.
        const out = [];
        for (let i = 0; i < root.clipItems.length; i++)
            if (root.clipItems[i].id !== item.id) out.push(root.clipItems[i]);
        root.clipItems = out;
    }

    // ────────────────── > system actions ──────────────────
    // Only the actions that stay inside the shell: rofi already covers the rest.
    //
    // Only `name` and `desc` are visible: `id` is what runAction() dispatches and
    // `keys` are the words you TYPE to find the action, which are not seen.
    // That is why `keys` does not go through tr(): the keys are not translated,
    // they ACCUMULATE. With the shell in English, `name` and `desc` already come
    // out translated and the search matches them, but someone typing "shutdown"
    // or "screenshot" would find nothing if the keys were still only in Spanish.
    // With both lists together, the search works in both languages at once and
    // without duplicating the table.
    readonly property var sysActions: [
        { kind: "cmd", id: "clip", icon: Icons.clipboard, name: "Clipboard",
          desc: "Copy history",
          keys: "clipboard cliphist copiar pegar historial copy paste history" },
        { kind: "cmd", id: "overview", icon: Icons.grid, name: "Workspace map",
          desc: "View and move windows",
          keys: "overview escritorios workspaces mapa workspace map windows grid" },
        { kind: "cmd", id: "system", icon: Icons.cpu, name: "Your computer",
          desc: "Activity, temperature and disk",
          keys: "sistema monitor cpu ram memoria disco temperatura bateria rendimiento equipo system memory disk temperature battery performance machine" },
        { kind: "cmd", id: "dnd", icon: Icons.bellOff, name: "Do not disturb",
          desc: "Silence notifications",
          keys: "dnd molestar silencio notificaciones do not disturb silence notifications mute" },
        { kind: "cmd", id: "power", icon: Icons.power, name: "Shut down / log out",
          desc: "Shut down, restart, log out",
          keys: "power apagar reiniciar salir logout suspender shutdown shut down restart reboot log out sign out suspend hibernate" }
    ]

    function searchActions(query) {
        const q = (query || "").trim().toLowerCase();
        if (q.length === 0) return root.sysActions;
        const out = [];
        for (let i = 0; i < root.sysActions.length; i++) {
            const a = root.sysActions[i];
            const hay = (a.name + " " + a.desc + " " + a.keys).toLowerCase();
            if (hay.indexOf(q) >= 0) out.push(a);
        }
        return out;
    }

    function runAction(a) {
        if (!a) return;
        // They do not close the panel: they change face. Closing and reopening at
        // the same instant makes the whole notch flicker.
        switch (a.id) {
        case "clip":     root.openLauncher("clip"); return;
        case "power":    root.panel = "power"; return;
        case "overview": Hyprland.refreshToplevels(); root.panel = "overview"; return;
        case "system":   root.panel = "system"; return;
        case "dnd":
            root.dnd = !root.dnd; root.closePanel();
            root.toast(Icons.bell, root.dnd ? "Do not disturb on"
                                            : "Do not disturb off");
            return;
        }
    }

    // ───────────────── @ open windows ──────────────────
    // It is read from Hyprland and not from Wayland's ToplevelManager because we
    // need each window's WORKSPACE, and only the compositor knows that.
    //
    // winTick exists because `Hyprland.toplevels.values` notifies when a window
    // is born or dies, but NOT when its title changes: without it, searching
    // "github" would not find the tab you have just opened in a Chrome that was
    // already running.
    property int winTick: 0
    Timer {
        id: winPoll
        interval: 90
        onTriggered: { Hyprland.refreshToplevels(); root.winTick++; }
    }
    function winRefresh() { Hyprland.refreshToplevels(); root.winTick++; }
    Connections {
        target: Hyprland
        // Only with the mode open: every refreshToplevels() is a query to
        // Hyprland's socket, and 99 % of the time this list is not being looked at.
        enabled: root.panel === "launcher" && root.launcherMode === "win"
        function onRawEvent(ev) {
            const n = String(ev.name);
            if (n.indexOf("window") >= 0 || n.indexOf("title") >= 0 || n.indexOf("workspace") >= 0)
                winPoll.restart();
        }
    }

    readonly property var winItems: {
        root.winTick;   // dependency on purpose: see the note above
        const out = [];
        const ts = Hyprland.toplevels ? [...Hyprland.toplevels.values] : [];
        for (let i = 0; i < ts.length; i++) {
            const t = ts[i];
            if (!t || !t.workspace || t.workspace.id < 1) continue;   // leave out the special ones
            const c = t.lastIpcObject;
            const cls = c ? String(c["class"] || "") : "";
            out.push({
                kind: "win",
                // CAREFUL: `address` comes WITHOUT the "0x" and Hyprland's
                // dispatchers require it. Without the prefix, focus answers "no window"
                // and nothing happens, silently. Same trap as in OverviewPanel.
                addr: (function () {
                    const s = String(t.address || "");
                    return s.startsWith("0x") ? s : "0x" + s;
                })(),
                ws: t.workspace.id,
                cls: cls,
                title: (t.title && t.title.length > 0) ? String(t.title) : cls,
                icon: root.iconForClass(cls),
                tl: t
            });
        }
        out.sort((a, b) => a.ws - b.ws || a.title.localeCompare(b.title));
        return out;
    }

    // The .desktop is almost never named like the window class
    // ("org.gnome.Nautilus" vs "nautilus"), so Quickshell's heuristic lookup
    // does the work; if it finds nothing, the lower-case class is usually a
    // valid icon name in the theme.
    function iconForClass(cls) {
        if (!cls) return "";
        try {
            const e = DesktopEntries.heuristicLookup(cls);
            if (e && e.icon) return e.icon;
        } catch (err) {}
        return cls.toLowerCase();
    }

    function searchWins(query) {
        const q = (query || "").trim().toLowerCase();
        if (q.length === 0) return root.winItems;
        const out = [];
        for (let i = 0; i < root.winItems.length; i++) {
            const w = root.winItems[i];
            if ((w.title + " " + w.cls + " " + w.ws).toLowerCase().indexOf(q) >= 0) out.push(w);
        }
        return out;
    }

    // Close FIRST and ask for focus AFTERWARDS, with 60 ms in between. Closing
    // the panel releases the HyprlandFocusGrab and Hyprland gives focus back to
    // the window that had it before; if our request goes at the same instant it
    // is not guaranteed who arrives last, and if the give-back wins you stay
    // where you were — exactly what you have just asked not to happen. It is the
    // same remedy (and the same figure) that OverviewPanel uses when jumping to
    // a window.
    property string winPending: ""
    Timer {
        id: winFocusDefer
        interval: 60
        onTriggered: {
            if (root.winPending === "") return;
            Hyprland.dispatch('hl.dsp.focus({ window = "address:' + root.winPending + '" })');
            root.winPending = "";
        }
    }
    function focusWindow(w) {
        if (!w) return;
        root.winPending = w.addr;
        root.closePanel();
        winFocusDefer.restart();
    }

    // ═════════════════════════ launcher calculator ══════════════════════════
    // Allowed names. Any other word in the expression rules it out:
    // that way "7zip" or "firefox 2" do not trigger the calculator.
    readonly property var calcWords: ["sqrt", "abs", "sin", "cos", "tan", "asin", "acos", "atan",
        "log", "log2", "log10", "exp", "round", "floor", "ceil", "min", "max", "pow", "pi", "e"]

    function calcEval(q) {
        let e = (q || "").trim();
        if (e.startsWith("=")) e = e.slice(1);      // "=" forces calculator mode
        if (e.length === 0) return null;
        if (!/\d/.test(e)) return null;                    // no numbers, no sum
        if (!/[+\-*\/^%()]/.test(e)) return null;           // no operator either: "5" is not a sum

        // expression characters only, and letters only inside known names
        if (!/^[0-9\s+\-*\/^%().,×÷a-zA-Z]+$/.test(e)) return null;
        const words = e.match(/[a-zA-Z]+/g) || [];
        for (let i = 0; i < words.length; i++)
            if (root.calcWords.indexOf(words[i].toLowerCase()) < 0) return null;

        // friendly syntax -> JavaScript
        let x = e.replace(/×/g, "*").replace(/÷/g, "/").replace(/\^/g, "**");
        x = x.replace(/(\d),(\d)/g, "$1.$2");               // decimal comma
        x = x.replace(/\bpi\b/gi, "Math.PI").replace(/\be\b/gi, "Math.E");
        x = x.replace(/\b(sqrt|abs|sin|cos|tan|asin|acos|atan|log2|log10|log|exp|round|floor|ceil|min|max|pow)\b/gi,
                      function (m) { return "Math." + m.toLowerCase(); });
        try {
            const v = Function('"use strict"; return (' + x + ')')();
            if (typeof v !== "number" || !isFinite(v)) return null;
            return v;
        } catch (err) {
            return null;
        }
    }

    // No floating-point noise: 0.1+0.2 must give 0.3, not 0.30000000000000004
    function calcFormat(v) {
        if (v === null || v === undefined) return "";
        const r = Math.round(v * 1e10) / 1e10;
        if (Number.isInteger(r) && Math.abs(r) < 1e15) return String(r);
        return String(parseFloat(r.toPrecision(12)));
    }

    function copyText(t) {
        Quickshell.clipboardText = String(t);
        root.toast("󰆏", Appearance.fmt("Copied: {0}", t));
    }

    // Brief notice inside the notch. Here it IS needed: copying to the clipboard
    // has no other sign that it happened.
    property string toastIcon: ""
    property string toastText: ""
    function toast(icon, text) {
        root.toastIcon = icon;
        root.toastText = text;
        root.flash("toast");
    }

    // Launch history: each launch counts 1 and fades with a 30-day half-life,
    // so apps you stopped using sink. Saved in Config's state file.
    function launchScore(id) {
        const r = Config.launches[id];
        return r ? r.n * Math.pow(0.5, (Date.now() - r.t) / 2592000000) : 0;
    }
    function recordLaunch(id) {
        if (!id) return;
        const next = Object.assign({}, Config.launches);
        next[id] = { n: root.launchScore(id) + 1, t: Date.now() };
        Config.launches = next;
        Config.save();
    }

    function launchApp(app) {
        if (!app) return;
        root.closePanel();
        app.execute();
        if (Config.learnLauncher) root.recordLaunch(app.id);
    }

    // ════════════════════════ launcher favourites ═════════════════════════
    // They are stored by the .desktop entry's `id`, which is constant, and NOT by
    // name: renaming the app or changing the desktop language must not lose you
    // the favourite. An id that no longer exists (app uninstalled) is ignored
    // when resolving, so the list cleans itself up without any notice.
    readonly property var favApps: {
        const out = [];
        const ids = Config.favApps;
        for (let i = 0; i < ids.length; i++) {
            const a = root.appById(ids[i]);
            if (a) out.push(a);
        }
        return out;
    }

    function appById(id) {
        const vs = root.allApps;
        for (let i = 0; i < vs.length; i++) if (vs[i].id === id) return vs[i];
        return null;
    }

    function isFav(app) { return !!app && Config.favApps.indexOf(app.id) >= 0; }

    function toggleFav(app) {
        if (!app) return;
        // slice() and not in-place mutation: changing the list from inside does not
        // fire the property change, so it neither repaints nor saves the file.
        const ids = Config.favApps.slice();
        const i = ids.indexOf(app.id);
        if (i >= 0) ids.splice(i, 1); else ids.push(app.id);
        Config.favApps = ids;
        Config.save();
    }
    function moveFav(from, to) {
        const ids = Config.favApps.slice();
        if (from < 0 || from >= ids.length) return;
        let t = Math.max(0, Math.min(ids.length, to));
        if (t > from) t -= 1;
        if (t === from) return;
        ids.splice(t, 0, ids.splice(from, 1)[0]);
        Config.favApps = ids;
        Config.save();
    }
}
