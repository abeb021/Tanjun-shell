import QtQuick
import "../../services"

Text {
    id: root
    property string role: ""
    property int px: 0
    property bool sub: false
    property bool icon: false
    property string family: ""

    readonly property string resolved: icon ? "icon" : (role.length ? role : (sub ? "caption" : "body"))
    readonly property int size: {
        if (px > 0)
            return px;
        if (resolved === "display")
            return Theme.typeDisplay;
        if (resolved === "title")
            return Theme.typeTitle;
        if (resolved === "seal")
            return Theme.typeSeal;
        if (resolved === "caption")
            return Theme.typeCaption;
        if (resolved === "head")
            return Theme.captionPx;
        return Theme.typeBody;
    }

    color: {
        if (resolved === "head")
            return Theme.caption;
        if (resolved === "seal")
            return Theme.accent;
        if (sub || resolved === "caption")
            return Theme.fgSub;
        return Theme.fg;
    }
    font.family: family.length ? family : (resolved === "seal" ? Theme.fontJp : (resolved === "icon" ? Theme.fontIcons : Theme.fontUi))
    font.pixelSize: size
    font.weight: resolved === "display" ? Font.Light : (resolved === "caption" || resolved === "head" ? Font.Normal : Font.Medium)
    font.letterSpacing: resolved === "display" ? -1.2 : (resolved === "head" ? Theme.captionTracking : 0)
    horizontalAlignment: resolved === "icon" ? Text.AlignHCenter : Text.AlignLeft
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideNone
}
