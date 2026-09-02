pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string time: Qt.formatDateTime(clock.date, "HH:mm")
    readonly property string timeFull: Qt.formatDateTime(clock.date, "HH:mm:ss")
    readonly property string date: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
    readonly property string dateShort: Qt.formatDateTime(clock.date, "dd.MM")
    readonly property date now: clock.date

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
