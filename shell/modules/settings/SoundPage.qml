import QtQuick
import "../widgets"
import "../../services"

Column {
    width: parent.width
    spacing: 10

    Row {
        width: parent.width
        spacing: 8
        height: 28

        Rectangle {
            width: 28
            height: 28
            radius: Theme.radius
            color: Audio.muted ? Theme.wash(Theme.critical, 0.15) : Theme.wash(Theme.accent, 0.10)
            border.width: 1
            border.color: Audio.muted ? Theme.critical : Theme.hairline
            BarText {
                anchors.centerIn: parent
                text: Audio.muted ? "" : ""
                icon: true
                px: 12
                color: Audio.muted ? Theme.critical : Theme.accent
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Audio.toggleMute()
            }
        }
        BarText {
            width: 82
            anchors.verticalCenter: parent.verticalCenter
            text: " VOLUME"
            px: 11
            family: Config.defaultFontUi
            color: Audio.muted ? Theme.fgSub : Theme.fg
        }
        HudSlider {
            width: parent.width - 28 - 82 - 16
            anchors.verticalCenter: parent.verticalCenter
            value: Audio.muted ? 0 : Audio.volume
            onMoved: v => Audio.setVolume(v)
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.hairline
    }

    BarText {
        text: "OUTPUT"
        role: "head"
    }

    Repeater {
        model: Audio.sinks
        HudCard {
            required property var modelData
            width: parent.width
            height: 40
            active: Audio.isCurrent(modelData, Audio.sink)
            Row {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8
                BarText {
                    width: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: Audio.isCurrent(modelData, Audio.sink) ? "" : ""
                    icon: true
                    px: 11
                    color: Audio.isCurrent(modelData, Audio.sink) ? Theme.accent : Theme.fgSub
                }
                BarText {
                    width: parent.width - 28
                    anchors.verticalCenter: parent.verticalCenter
                    text: Audio.deviceName(modelData).toUpperCase()
                    px: 10
                    family: Config.defaultFontUi
                    color: Audio.isCurrent(modelData, Audio.sink) ? Theme.accent : Theme.fg
                    elide: Text.ElideRight
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Audio.setSink(modelData)
            }
        }
    }

    BarText {
        visible: Audio.sinks.length === 0
        text: "NO AUDIO OUTPUTS"
        px: 10
        family: Config.defaultFontUi
        color: Theme.fgSub
        font.letterSpacing: 1.5
    }

    Rectangle {
        visible: Audio.streams.length > 0
        width: parent.width
        height: 1
        color: Theme.hairline
    }

    Row {
        visible: Audio.streams.length > 0
        spacing: 10
        BarText {
            text: "PLAYING APPS"
            role: "head"
        }
        BarText {
            text: `${Audio.streams.length}`
            px: 10
            color: Theme.fgSub
            family: Config.defaultFontUi
        }
    }

    Repeater {
        model: Audio.streams
        HudCard {
            required property var modelData
            width: parent.width
            height: 48
            danger: !!(modelData.audio && modelData.audio.muted)
            Row {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 14
                spacing: 6
                Rectangle {
                    width: 28
                    height: 28
                    radius: Theme.radius
                    anchors.verticalCenter: parent.verticalCenter
                    color: (modelData.audio && modelData.audio.muted) ? Theme.wash(Theme.critical, 0.15) : Theme.wash(Theme.accent, 0.10)
                    border.width: 1
                    border.color: (modelData.audio && modelData.audio.muted) ? Theme.critical : Theme.hairline
                    BarText {
                        anchors.centerIn: parent
                        text: (modelData.audio && modelData.audio.muted) ? "" : ""
                        icon: true
                        px: 12
                        color: (modelData.audio && modelData.audio.muted) ? Theme.critical : Theme.accent
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Audio.toggleStreamMute(modelData)
                    }
                }
                BarText {
                    width: 82
                    anchors.verticalCenter: parent.verticalCenter
                    text: Audio.streamName(modelData).toUpperCase()
                    px: 11
                    family: Config.defaultFontUi
                    elide: Text.ElideRight
                    color: (modelData.audio && modelData.audio.muted) ? Theme.fgSub : Theme.fg
                }
                HudSlider {
                    width: parent.width - 28 - 82 - 12
                    anchors.verticalCenter: parent.verticalCenter
                    value: (modelData.audio && modelData.audio.muted) ? 0 : (modelData.audio ? modelData.audio.volume : 0)
                    onMoved: v => Audio.setStreamVolume(modelData, v)
                }
            }
        }
    }

    BarText {
        visible: Audio.sources.length > 0
        text: "MIC"
        role: "head"
    }
    Repeater {
        model: Audio.sources
        HudCard {
            required property var modelData
            width: parent.width
            height: 40
            active: Audio.isCurrent(modelData, Audio.source)
            Row {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8
                BarText {
                    width: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: Audio.isCurrent(modelData, Audio.source) ? "" : ""
                    icon: true
                    px: 11
                    color: Audio.isCurrent(modelData, Audio.source) ? Theme.accent : Theme.fgSub
                }
                BarText {
                    width: parent.width - 28
                    anchors.verticalCenter: parent.verticalCenter
                    text: Audio.deviceName(modelData).toUpperCase()
                    px: 10
                    family: Config.defaultFontUi
                    color: Audio.isCurrent(modelData, Audio.source) ? Theme.accent : Theme.fg
                    elide: Text.ElideRight
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Audio.setSource(modelData)
            }
        }
    }
    HudSlider {
        visible: Audio.sources.length > 0
        width: parent.width
        label: Audio.micMuted ? "MIC MUTED" : "MIC"
        icon: ""
        value: Audio.micMuted ? 0 : Audio.micVolume
        accentColor: Audio.micMuted ? Theme.critical : Theme.accent
        onMoved: v => Audio.setMicVolume(v)
    }
}
