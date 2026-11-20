import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import "../popouts"
import "../sidebar"
import "../widgets"
import "../../services"

// One window per output holds the bar and all of its menus. The bar is a strip
// item at the window's edge, every menu is a card item beside it, and opening a
// menu moves nothing but the card. Keeping them in one surface is also what makes
// the joint between the bar and an open menu seamless: there is no second window
// whose edge could show through.
Scope {
    Variants {
        model: Quickshell.screens

        Scope {
            id: desk
            required property var modelData

            PanelWindow {
                id: barWin
                screen: desk.modelData
                color: "transparent"

                readonly property bool vertical: Theme.barVertical
                readonly property string edge: Theme.barEdge
                readonly property int bar: Theme.barThickness
                // A menu is open somewhere: the whole output turns into the bar
                // surface so a click anywhere dismisses it, on every screen.
                readonly property bool menuOpen: UiMode.popout.length > 0

                WlrLayershell.namespace: "tanjun-bar"
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.keyboardFocus: menuKeys.mode

                // The window is the whole output, so the exclusive zone has to be
                // stated explicitly: Auto would reserve the entire screen.
                exclusiveZone: Theme.barThickness

                anchors {
                    top: edge !== "bottom"
                    bottom: edge !== "top"
                    left: edge !== "right"
                    right: edge !== "left"
                }

                // Three anchors: the bar's edge plus the two along it, so the
                // compositor knows which edge the exclusive zone belongs to. The
                // depth axis is the output's own size, which makes the window
                // cover the output.
                implicitWidth: vertical ? (screen ? screen.width : 1) : 1
                implicitHeight: vertical ? 1 : (screen ? screen.height : 1)

                // While nothing is open only the bar strip takes input; while a
                // menu is open the whole window does, which is what makes the
                // menu modal without a second surface behind it.
                mask: Region {
                    item: barStrip
                    Region {
                        x: 0
                        y: 0
                        width: barWin.menuOpen && barWin.screen ? barWin.screen.width : 0
                        height: barWin.menuOpen && barWin.screen ? barWin.screen.height : 0
                    }
                }

                KeyPrime {
                    id: menuKeys
                    open: barWin.menuOpen
                }

                IdleInhibitor {
                    enabled: !!(Media.player && Media.player.isPlaying)
                    window: barWin
                }

                property bool draggingBar: false
                property real dragStartX: 0
                property real dragStartY: 0

                // The drag handler reports positions relative to the strip, which
                // equals the screen only where the strip sits at the origin. Add
                // the strip's own place in the window instead of guessing from the
                // window geometry.
                function screenPoint(local) {
                    const s = barWin.screen;
                    if (!s || !local)
                        return null;
                    return {
                        x: Math.max(0, Math.min(s.width, barStrip.x + local.x)),
                        y: Math.max(0, Math.min(s.height, barStrip.y + local.y))
                    };
                }

                // The bar lands on the border the pointer is brought to: a third
                // of the screen at either end of the bar picks that side, the
                // middle third picks the border opposite the current one as soon
                // as the pointer is carried off the bar. Comparing distances all
                // the way to the far border would make the near one unbeatable,
                // which is why sideways moves used to do nothing at all.
                function pickEdge(x, y, s) {
                    const bar = Theme.barThickness;
                    const vertical = barWin.vertical;
                    const along = vertical ? y : x;
                    const span = vertical ? s.height : s.width;

                    if (along < span / 3)
                        return vertical ? "top" : "left";
                    if (along > span * 2 / 3)
                        return vertical ? "bottom" : "right";

                    const offBar = vertical
                        ? (Theme.barEdge === "left" ? x > bar : s.width - x > bar)
                        : (Theme.barEdge === "top" ? y > bar : s.height - y > bar);
                    if (!offBar)
                        return Theme.barEdge;
                    if (vertical)
                        return Theme.barEdge === "left" ? "right" : "left";
                    return Theme.barEdge === "top" ? "bottom" : "top";
                }

                function dragTo(local) {
                    const point = screenPoint(local);
                    if (!point)
                        return;
                    UiMode.barDragScreen = `${barWin.screen.name}`;
                    UiMode.barDragX = point.x;
                    UiMode.barDragY = point.y;
                    // a real drag has to happen before the bar switches border,
                    // so taking hold of it never flips it
                    const moved = Math.max(Math.abs(point.x - dragStartX), Math.abs(point.y - dragStartY));
                    if (moved >= 24)
                        UiMode.barDragEdge = pickEdge(point.x, point.y, barWin.screen);
                }

                function beginDrag(local) {
                    const point = screenPoint(local);
                    if (!point)
                        return;
                    // a menu hanging off the bar would be pinned to the old edge
                    // when the bar lands on a new one
                    UiMode.closeMenus();
                    draggingBar = true;
                    dragStartX = point.x;
                    dragStartY = point.y;
                    UiMode.barDragging = true;
                    UiMode.barDragEdge = Theme.barEdge;
                    dragTo(local);
                }

                function endDrag() {
                    if (!draggingBar)
                        return;
                    const edge = UiMode.barDragEdge;
                    draggingBar = false;
                    UiMode.barDragging = false;
                    UiMode.barDragEdge = "";
                    UiMode.barDragScreen = "";
                    if (edge.length)
                        Theme.setBarEdge(edge);
                }

                Component.onDestruction: {
                    UiMode.barDragging = false;
                    UiMode.barDragEdge = "";
                }

                // Click away closes the menu. The window already takes the whole
                // output's input while a menu is open, so the desktop under the
                // transparent part of it is not reachable — no backdrop window.
                MouseArea {
                    z: -1
                    anchors.fill: parent
                    enabled: barWin.menuOpen
                    onClicked: UiMode.closeMenus()
                }

                // The bar itself: the only part of the window that is on screen
                // when nothing is open, and the strip every menu hangs off.
                Item {
                    id: barStrip
                    x: barWin.edge === "right" ? parent.width - width : 0
                    y: barWin.edge === "bottom" ? parent.height - height : 0
                    width: barWin.vertical ? barWin.bar : parent.width
                    height: barWin.vertical ? parent.height : barWin.bar

                    Rectangle {
                        anchors.fill: parent
                        // A translucent tint: the compositor blurs what is behind
                        // the surface (layer rule `blur`), so the material is
                        // whatever actually lies under the bar.
                        color: Theme.glass ? Theme.glassSurface : Theme.bg
                    }

                    // The inner rule. When a menu is open on this output the
                    // line stops at that menu's stretch of the bar, so the card
                    // reads as the bar opening rather than sitting over a line.
                    // Two segments rather than a clipped one: a clip would also
                    // cut the card's own edges where they meet the bar.
                    //
                    // The stretch a menu covers runs along the bar — X on a
                    // horizontal bar, Y on a vertical one — and the hairline runs
                    // across it. Placed with x/y rather than anchors for the same
                    // reason the overlay punch-out is: an anchor binding that
                    // yields `undefined` does not clear the previous anchor, so
                    // moving the bar would leave the line pinned to the old edge.
                    readonly property bool cutting: UiMode.menuSpanFrom >= 0
                        && UiMode.menuSpanTo > UiMode.menuSpanFrom
                        && (!UiMode.menuSpanScreen.length || (barWin.screen && `${barWin.screen.name}` === UiMode.menuSpanScreen))
                    // A menu that runs to the screen's edge leaves no bar after it,
                    // so the rule ends at the menu instead of trailing a sliver at
                    // the corner.
                    readonly property real alongLen: barWin.vertical ? parent.height : parent.width
                    readonly property bool ruleEndsAtMenu: cutting
                        && UiMode.menuSpanTo >= alongLen - Theme.attachBorderWidth
                    // Half a physical pixel, to snap the hairline to one row at a
                    // fractional output scale.
                    readonly property real lineNudge: 2 / (barWin.screen ? barWin.screen.devicePixelRatio : 1)

                    Rectangle {
                        // Along the bar this runs to the menu; across it is the
                        // hairline (width on a vertical bar, height on a
                        // horizontal one).
                        width: barWin.vertical ? Theme.barRule : (barStrip.cutting ? Math.max(0, UiMode.menuSpanFrom) : parent.width)
                        height: barWin.vertical ? (barStrip.cutting ? Math.max(0, UiMode.menuSpanFrom) : parent.height) : Theme.barRule
                        x: barWin.vertical ? (barWin.edge === "right" ? 0 : parent.width - width) : 0
                        visible: !barStrip.cutting || !barStrip.ruleEndsAtMenu
                        // The rule sits on the strip's last row. A fractional output
                        // scale (1.2 here) puts that row on a half pixel of the
                        // physical grid, and Qt then smears the hairline over two
                        // rows. Nudging by half a physical pixel snaps it to one
                        // crisp row at any scale, where a bare 0.5 only worked at
                        // the scale it was tuned for. The nudge goes down, not up:
                        // the row has to stay flush with the card, and a menu's clip
                        // starts at the strip's edge, so anything lifted above that
                        // line leaves a gap at the corner.
                        y: barWin.vertical ? 0 : (barWin.edge === "bottom" ? 0 : parent.height - height + barStrip.lineNudge)
                        color: Theme.barLine
                    }

                    // The stretch after the menu. Positioned with x/y rather than
                    // anchors: setting any anchor would override them.
                    Rectangle {
                        visible: barStrip.cutting && !barStrip.ruleEndsAtMenu
                        width: barWin.vertical ? Theme.barRule : Math.max(0, parent.width - UiMode.menuSpanTo)
                        height: barWin.vertical ? Math.max(0, parent.height - UiMode.menuSpanTo) : Theme.barRule
                        x: barWin.vertical ? (barWin.edge === "right" ? 0 : parent.width - width) : UiMode.menuSpanTo
                        y: barWin.vertical ? UiMode.menuSpanTo : (barWin.edge === "bottom" ? 0 : parent.height - height + barStrip.lineNudge)
                        color: Theme.barLine
                    }

                    Item {
                        id: hContent
                        visible: !barWin.vertical
                        anchors.fill: parent
                        opacity: barWin.draggingBar ? 0.25 : 1

                        Behavior on opacity {
                            enabled: Motion.ready
                            NumberAnimation {
                                duration: Motion.fast
                            }
                        }

                        DragHandler {
                            target: null
                            acceptedButtons: Qt.LeftButton
                            grabPermissions: PointerHandler.CanTakeOverFromAnything

                            onActiveChanged: {
                                if (active) {
                                    barWin.beginDrag(centroid.position);
                                } else {
                                    if (barWin.draggingBar)
                                        barWin.dragTo(centroid.position);
                                    barWin.endDrag();
                                }
                            }
                            onActiveTranslationChanged: {
                                if (active)
                                    barWin.dragTo(centroid.position);
                            }
                        }

                        Row {
                            id: hLeft
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            LogoBtn {
                                id: hLogoBtn
                            }
                            Workspaces {
                                id: hWorkspaces
                                screenName: barWin.screen && barWin.screen.name ? `${barWin.screen.name}` : ""
                            }

                            // Tray items sit first on the bar, right after the
                            // desks: they are the apps' own windows into the
                            // session, so they lead the numbers instead of
                            // trailing them.
                            Repeater {
                                model: SystemTray.items
                                delegate: TrayBtn {}
                            }
                        }

                        ClockBtn {
                            id: hClockBtn
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Row {
                            id: hRight
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            LayoutBtn {
                                id: hLayoutBtn
                            }
                            StatsBtn {
                                id: hStatsBtn
                            }
                            AudioBtn {
                                id: hAudioBtn
                            }
                            NetBtn {
                                id: hNetBtn
                            }
                            NotifyBtn {
                                id: hNotifyBtn
                            }
                            BatteryBtn {
                                id: hBatteryBtn
                            }
                        }
                    }

                    Item {
                        id: vContent
                        visible: barWin.vertical
                        anchors.fill: parent
                        opacity: barWin.draggingBar ? 0.25 : 1

                        Behavior on opacity {
                            enabled: Motion.ready
                            NumberAnimation {
                                duration: Motion.fast
                            }
                        }

                        DragHandler {
                            target: null
                            acceptedButtons: Qt.LeftButton
                            grabPermissions: PointerHandler.CanTakeOverFromAnything

                            onActiveChanged: {
                                if (active) {
                                    barWin.beginDrag(centroid.position);
                                } else {
                                    if (barWin.draggingBar)
                                        barWin.dragTo(centroid.position);
                                    barWin.endDrag();
                                }
                            }
                            onActiveTranslationChanged: {
                                if (active)
                                    barWin.dragTo(centroid.position);
                            }
                        }

                        Column {
                            id: vTop
                            width: parent.width
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 2

                            LogoBtn {
                                id: vLogoBtn
                                width: parent.width
                            }
                            Workspaces {
                                id: vWorkspaces
                                vertical: true
                                width: parent.width
                                screenName: barWin.screen && barWin.screen.name ? `${barWin.screen.name}` : ""
                            }

                            // Same order as the horizontal strip: tray items
                            // follow the desks.
                            Repeater {
                                model: SystemTray.items
                                delegate: TrayBtn {
                                    width: Theme.barThickness
                                }
                            }
                        }

                        ClockBtn {
                            id: vClockBtn
                            compact: true
                            width: parent.width
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            id: vBottom
                            width: parent.width
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 2

                            LayoutBtn {
                                id: vLayoutBtn
                                width: parent.width
                            }
                            StatsBtn {
                                id: vStatsBtn
                                width: parent.width
                                compact: true
                            }
                            AudioBtn {
                                id: vAudioBtn
                                width: parent.width
                            }
                            NetBtn {
                                id: vNetBtn
                                width: parent.width
                            }
                            NotifyBtn {
                                id: vNotifyBtn
                                width: parent.width
                            }
                            BatteryBtn {
                                id: vBatteryBtn
                                width: parent.width
                                compact: true
                            }
                        }
                    }
                }

                // Menus last, so their cards are drawn over the bar strip.
                BarPop {
                    name: "clock"
                    barWindow: barWin
                    strip: barStrip
                    anchorItem: barWin.vertical ? vClockBtn : hClockBtn
                    align: Item.Top
                    source: "CalendarPop.qml"
                }

                BarPop {
                    name: "audio"
                    barWindow: barWin
                    strip: barStrip
                    anchorItem: barWin.vertical ? vAudioBtn : hAudioBtn
                    align: Item.TopRight
                    source: "AudioPop.qml"
                }

                BarPop {
                    name: "network"
                    barWindow: barWin
                    strip: barStrip
                    anchorItem: barWin.vertical ? vNetBtn : hNetBtn
                    align: Item.TopRight
                    source: "NetPop.qml"
                }

                BarPop {
                    name: "notify"
                    barWindow: barWin
                    strip: barStrip
                    anchorItem: barWin.vertical ? vNotifyBtn : hNotifyBtn
                    align: Item.TopRight
                    source: "NotifyPop.qml"
                }

                BarPop {
                    name: "battery"
                    barWindow: barWin
                    strip: barStrip
                    // The battery is the last item on the bar, so its menu runs to
                    // the screen's edge rather than the 8px inset a menu anchored
                    // to a button in the middle of the bar keeps.
                    anchorItem: barWin.vertical ? vBatteryBtn : hBatteryBtn
                    reachEdge: true
                    align: Item.TopRight
                    source: "BatteryPop.qml"
                }

                BarPop {
                    name: "tray"
                    barWindow: barWin
                    strip: barStrip
                    anchorItem: UiMode.popoutAnchor || (barWin.vertical ? vBatteryBtn : hBatteryBtn)
                    align: Item.TopRight
                    source: "TrayPop.qml"
                }

                BarPop {
                    name: "stats"
                    barWindow: barWin
                    strip: barStrip
                    anchorItem: barWin.vertical ? vStatsBtn : hStatsBtn
                    align: Item.TopRight
                    source: "StatsPop.qml"
                }
            }

            BarDragPreview {
                screenObj: barWin.screen
            }

            LazyLoader {
                id: sideLoad
                // kept loaded: the surface stays mapped so the compositor never
                // animates it
                active: true
                Sidebar {
                    barWindow: barWin
                }
            }
        }
    }
}
