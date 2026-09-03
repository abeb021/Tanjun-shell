pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property bool ready: false

    readonly property int peek: 90
    readonly property int fast: 140
    readonly property int pop: 220
    readonly property int panel: 280
    readonly property int osdHold: 1400

    readonly property int easeOut: Easing.OutCubic
    readonly property int easeIn: Easing.InCubic

    readonly property real popFrom: 0.92
    readonly property real panelFrom: 0.97
    readonly property real osdFrom: 0.94

    Component.onCompleted: ready = true
}
