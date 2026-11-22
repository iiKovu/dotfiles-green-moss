import QtQuick

// Frame-driven spring (SpringAnimation steps at 62fps)
QtObject {
    id: s
    property real to: 0
    property real value: 0
    property real velocity: 0
    property real spring: Appearance.sprTight
    property real damping: Appearance.dmpTight
    property real epsilon: Appearance.eppPx
    property int delay: 0

    property bool _ready: false
    Component.onCompleted: { value = to; _ready = true; }
    onToChanged: if (_ready) Qt.callLater(s._kick)

    function _kick() {
        if (s.delay > 0) {
            frames.running = false;
            wait.interval = s.delay;
            wait.restart();
        } else {
            wait.stop();
            frames.running = true;
        }
    }

    function _step(dt) {
        const f = Math.min(dt * 1000, 32) / 16;
        s.velocity += (s.spring * (s.to - s.value) - s.damping * s.velocity) * f;
        let v = s.value + s.velocity * 0.016 * f;
        if (Math.abs(s.velocity) < s.epsilon && Math.abs(s.to - v) < s.epsilon) {
            s.velocity = 0;
            v = s.to;
            frames.running = false;
        }
        s.value = v;
    }

    property Timer _wait: Timer { id: wait; onTriggered: frames.running = true }
    property FrameAnimation _frames: FrameAnimation { id: frames; onTriggered: s._step(frameTime) }
}
