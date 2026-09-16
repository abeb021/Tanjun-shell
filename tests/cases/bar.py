from __future__ import annotations

from lib import SHELL, read


def register(s) -> None:
    bar = read(SHELL / "modules" / "bar" / "Bar.qml")
    for name in (
        "LogoBtn",
        "Workspaces",
        "ClockBtn",
        "LayoutBtn",
        "AudioBtn",
        "NetBtn",
        "NotifyBtn",
        "BatteryBtn",
        "TrayBtn",
        "TrayPop",
        "Sidebar",
    ):
        s.has(f"bar {name}", bar, name)
    s.has("bar namespace", bar, 'WlrLayershell.namespace: "tanjun-bar"')
    s.has("bar top layer", bar, "WlrLayer.Top")
    s.has("bar theme bg", bar, "Theme.bg")
    s.has("bar tray popout", bar, 'name: "tray"')

    ws = read(SHELL / "modules" / "bar" / "Workspaces.qml")
    s.has("ws click activate", ws, "Compositor.activateWorkspace(wsId)")
    s.has("ws right move", ws, "Compositor.moveToWorkspace(wsId)")
    s.has("ws wheel cycle", ws, "Compositor.cycleWorkspace")
    s.has("ws persistent 3", ws, "i <= 3")
    s.has("ws ten desks", ws, "i <= 10")
    s.has("ws focused", ws, "Compositor.focusedWorkspaceId")

    audio = read(SHELL / "modules" / "bar" / "AudioBtn.qml")
    s.has("audio popout", audio, 'popoutName: "audio"')
    s.has("audio wheel", audio, "onWheeled")
    s.has("audio mute right", audio, "onRightClicked")

    clock = read(SHELL / "modules" / "bar" / "ClockBtn.qml")
    s.has("clock popout", clock, 'popoutName: "clock"')
    s.has("clock wheel", clock, "onWheeled")

    bat = read(SHELL / "modules" / "bar" / "BatteryBtn.qml")
    s.has("battery popout", bat, 'popoutName: "battery"')
    s.has("battery wheel", bat, "onWheeled")

    net = read(SHELL / "modules" / "bar" / "NetBtn.qml")
    s.has("net popout", net, 'popoutName: "network"')

    note = read(SHELL / "modules" / "bar" / "NotifyBtn.qml")
    s.has("notify popout", note, 'popoutName: "notify"')

    logo = read(SHELL / "modules" / "bar" / "LogoBtn.qml")
    s.has("logo drawer", logo, "drawer: true")
    s.has("logo seal", logo, "単")

    lay = read(SHELL / "modules" / "bar" / "LayoutBtn.qml")
    s.has("layout cycle", lay, "Layout.cycle()")

    btn = read(SHELL / "modules" / "widgets" / "BarButton.qml")
    s.has("button left", btn, "Qt.LeftButton")
    s.has("button right", btn, "Qt.RightButton")
    s.has("button middle", btn, "Qt.MiddleButton")
    s.has("button wheel", btn, "onWheel")
    s.has("button popout toggle", btn, "ShellState.togglePopout")
