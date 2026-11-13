import QtQuick

// Wheel scrolling for a Flickable, with a step the shell controls.
//
// A plain Flickable follows the wheel at Qt's own pace, which is slow on a mouse
// and uneven on a touchpad, and it only sees the event if nothing above the
// content swallows it. This sits on top of the flickable and passes every button
// through, so clicks and drags still reach it, but moves the content itself: one
// notch of a mouse wheel is `notchStep` pixels, a precise wheel or touchpad is
// followed with `pixelFactor`.
MouseArea {
    id: root

    property Flickable flick: null
    property real notchStep: 150
    property real pixelFactor: 2.0

    acceptedButtons: Qt.NoButton

    onWheel: wheel => {
        const f = root.flick;
        if (!f)
            return;
        let dy = 0;
        if (wheel.pixelDelta.y !== 0)
            dy = -wheel.pixelDelta.y * root.pixelFactor;
        else if (wheel.angleDelta.y !== 0)
            dy = -wheel.angleDelta.y / 120 * root.notchStep;
        if (dy === 0)
            return;
        if (typeof f.cancelFlick === "function")
            f.cancelFlick();
        const max = Math.max(0, f.contentHeight - f.height);
        f.contentY = Math.max(0, Math.min(max, f.contentY + dy));
        wheel.accepted = true;
    }
}
