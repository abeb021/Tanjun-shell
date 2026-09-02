import QtQuick
import Quickshell
import "../../services"

Text {
    property int px: Theme.fontPx
    property bool sub: false
    property bool icon: false
    property string family: icon ? Theme.fontIcons : Theme.fontUi
    color: sub ? Theme.fgSub : Theme.fg
    font.family: family
    font.pixelSize: px
    font.weight: Font.Medium
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
}
