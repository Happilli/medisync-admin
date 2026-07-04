import QtQuick
import MediSyncAdmin

Item {
    id: root
    signal loggedOut

    function capitalize(s) {
        return s.length > 0 ? s.charAt(0).toUpperCase() + s.slice(1) : s;
    }

    Column {
        anchors.centerIn: parent
        spacing: 24
        width: 340

        Text {
            text: "Hello, " + root.capitalize(SessionManager.role())
            font.pixelSize: 28
            font.bold: true
            color: Theme.onSurface
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: SessionManager.email()
            font.pixelSize: 14
            color: Theme.onSurfaceVariant
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Rectangle {
            width: 160
            height: 46
            radius: 12
            color: Theme.errorContainerColor
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                anchors.centerIn: parent
                text: "Log out"
                font.pixelSize: 14
                font.bold: true
                color: Theme.onErrorContainer
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    SessionManager.clearSession();
                    root.loggedOut();
                }
            }
        }
    }
}
