import QtQuick
import "../../services"

Rectangle {
    property string job: "pop"

    color: (job === "plane" || job === "strip") ? Theme.bg : Theme.surface
    border.width: job === "strip" ? 0 : 1
    border.color: Theme.hairline
    radius: Theme.radius
}
