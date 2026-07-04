import QtQuick
import QtQuick.Window
import MediSyncAdmin

Window {
    id: appWindow
    visible: true
    width: 800
    height: 600
    title: "MediSync Admin"
    color: Theme.backgroundColor

    Login {
        anchors.fill: parent
    }
}
