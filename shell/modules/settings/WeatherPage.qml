import QtQuick
import "../widgets"
import "../../services"

Column {
    id: page
    width: parent.width
    spacing: 18
    property string draft: Config.services.weatherCity

    SetHead {
        title: "CITY"
        desc: "wttr.in. Empty uses this machine's IP."
    }

    SetField {
        placeholder: "Moscow"
        action: "SAVE"
        text: page.draft
        onEdited: v => page.draft = v
        onAccepted: page.save()
        onTriggered: page.save()
    }

    Row {
        width: parent.width
        spacing: 10
        HudPick {
            width: 160
            label: "MOSCOW"
            current: Config.services.weatherCity === "Moscow"
            onClicked: {
                page.draft = "Moscow";
                page.save();
                Qt.callLater(() => page.draft = Config.services.weatherCity);
            }
        }
    }

    function save() {
        Config.services.weatherCity = page.draft.trim();
        Config.writeSparse();
    }
}
