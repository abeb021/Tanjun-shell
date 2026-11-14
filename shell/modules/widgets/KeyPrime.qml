// Keyboard focus for a surface that appears over the desktop.
//
// Behind this are three facts about how layer surfaces get keys:
//
// 1. The keyboard interactivity mode (`keyboardFocus`) is committed at polish,
//    and it is only re-sent when the value changed. Asking the compositor for a
//    mode is therefore one shot, not a request that can be repeated.
// 2. `OnDemand` gives focus when the pointer presses the surface, but that press
//    is what performs the assignment. Shortcuts that only exist while the
//    surface has focus do not fire on that press, so the first click on a panel
//    that had lost focus used to land on a surface with no key context.
// 3. Handing the compositor `Exclusive` the instant a panel opens is the only
//    way to be sure keys go there, but it grabs them before the shell has
//    drawn anything. Holding it past the first frame takes keys away from a
//    terminal that was being typed in.
//
// So the owner goes Exclusive first, and relaxes to OnDemand after `primeDelay`
// — and only once it is on screen. On top of that the focus target is set right
// away and again a moment later (`focusDelay`), so typing works even when the
// surface already had focus and the compositor sends nothing new.
import QtQuick
import Quickshell.Wayland
import "../../services"

Item {
    id: root
    visible: false
    width: 0
    height: 0

    required property bool open
    property bool primed: false
    property bool holdExclusive: false
    // The item that should actually have QML keyboard focus, e.g. the panel
    // body or a search field.
    property Item focusTarget: null
    property int primeDelay: 75
    property int focusDelay: 60

    readonly property int mode: {
        if (!open)
            return WlrKeyboardFocus.None;
        if (holdExclusive || !Compositor.grabFocus)
            return WlrKeyboardFocus.Exclusive;
        return primed ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive;
    }

    onOpenChanged: {
        primed = false;
        primeTimer.stop();
        focusTimer.stop();
        if (!open)
            return;
        primeTimer.restart();
        take();
        focusTimer.restart();
    }

    onFocusTargetChanged: {
        if (open)
            take();
    }

    function take() {
        if (!open || !focusTarget)
            return;
        if (!focusTarget.activeFocus)
            focusTarget.forceActiveFocus();
    }

    Timer {
        id: primeTimer
        interval: root.primeDelay
        onTriggered: if (root.open)
            root.primed = true;
    }

    // The surface needs the frame it opens on to be committed before focus
    // inside it means anything; a delayed second pass covers both that and the
    // case where `mode` changed between the two passes.
    Timer {
        id: focusTimer
        interval: root.focusDelay
        onTriggered: root.take()
    }
}
