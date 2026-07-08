pragma ComponentBehavior: Bound
import QtQuick
import MediSyncAdmin

FocusScope {
    id: root
    signal backRequested

    property var notificationsList: []
    property bool loading: false
    property string loadError: ""
    property bool unreadOnly: false

    focus: true
    Component.onCompleted: {
        root.forceActiveFocus();
        root.refresh();
    }

    Keys.onEscapePressed: root.backRequested()

    function refresh() {
        root.loading = true;
        root.loadError = "";
        const query = root.unreadOnly ? "?unread_only=true" : "";
        ApiClient.get("/notifications/me" + query, "allNotifications");
    }

    function markRead(id) {
        ApiClient.patch("/notifications/" + id + "/read", "markRead:" + id);
    }

    function markAllRead() {
        ApiClient.patch("/notifications/read-all", "markAllRead");
    }

    function shapeForType(type) {
        switch (type) {
        case "appointment_booked":
        case "appointment_confirmed":
            return 16;
        case "appointment_cancelled":
            return 30;
        case "appointment_completed":
            return 19;
        case "doctor_registered":
        case "doctor_verified":
            return 4;
        case "patient_verification_requested":
        case "patient_verified":
            return 20;
        case "prescription_created":
            return 12;
        case "consultation_created":
            return 8;
        default:
            return 0;
        }
    }

    function accentForType(type) {
        switch (type) {
        case "appointment_cancelled":
            return Theme.errorColor;
        case "doctor_registered":
        case "patient_verification_requested":
            return Theme.tertiaryColor;
        case "doctor_verified":
        case "patient_verified":
        case "appointment_confirmed":
        case "appointment_completed":
            return Theme.primaryColor;
        default:
            return Theme.secondaryColor;
        }
    }

    function iconForType(type) {
        if (type.indexOf("appointment") === 0) {
            return "assets/icons/patient.svg";
        }
        if (type.indexOf("doctor") === 0) {
            return "assets/icons/hospital.svg";
        }
        if (type.indexOf("patient") === 0) {
            return "assets/icons/patient.svg";
        }
        if (type === "prescription_created") {
            return "assets/icons/description.svg";
        }
        return "assets/icons/patient.svg";
    }

    Connections {
        target: NotificationClient
        function onNotificationReceived(notification) {
            root.refresh();
        }
    }

    Connections {
        target: ApiClient
        function onRequestFinished(requestId, success, data, message) {
            if (requestId === "allNotifications") {
                root.loading = false;
                if (success) {
                    root.notificationsList = data ?? [];
                } else {
                    root.loadError = message;
                }
            } else if (requestId.indexOf("markRead:") === 0 && success) {
                root.refresh();
            } else if (requestId === "markAllRead" && success) {
                root.refresh();
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surfaceContainer
    }

    Column {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 24

        Row {
            width: parent.width
            height: Math.max(titleColumn.height, actionRow.height)

            Column {
                id: titleColumn
                width: parent.width - actionRow.width - 16
                spacing: 6

                Text {
                    text: "Inbox"
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.primaryFixedDim
                    font.letterSpacing: 1.5
                }
                Row {
                    spacing: 12
                    Text {
                        text: "Notifications"
                        font.pixelSize: 32
                        font.bold: true
                        color: Theme.onSurface
                    }
                    Rectangle {
                        visible: root.notificationsList.filter(n => !n.is_read).length > 0
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 10
                        height: 22
                        width: unreadCountText.width + 18
                        color: Theme.errorColor

                        Text {
                            id: unreadCountText
                            anchors.centerIn: parent
                            text: root.notificationsList.filter(n => !n.is_read).length + " new"
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.onError
                        }
                    }
                }
            }

            Row {
                id: actionRow
                spacing: 10
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: 128
                    height: 38
                    radius: 19
                    color: root.unreadOnly ? Theme.primaryColor : Theme.surfaceContainerHighest
                    border.width: root.unreadOnly ? 0 : 1
                    border.color: Theme.outlineVariant

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Unread only"
                        font.pixelSize: 12
                        font.bold: true
                        color: root.unreadOnly ? Theme.onPrimary : Theme.onSurfaceVariant
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Sfx.playMove();
                            root.unreadOnly = !root.unreadOnly;
                            root.refresh();
                        }
                    }
                }

                Rectangle {
                    width: 128
                    height: 38
                    radius: 19
                    color: Theme.surfaceContainerHighest
                    border.width: 1
                    border.color: Theme.outlineVariant

                    Text {
                        anchors.centerIn: parent
                        text: "Mark all read"
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.onSurfaceVariant
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Sfx.playEnter();
                            root.markAllRead();
                        }
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: parent.height - y

            Text {
                visible: root.loading
                anchors.centerIn: parent
                text: "Syncing…"
                font.pixelSize: 13
                color: Theme.onSurfaceVariant
            }
            Text {
                visible: !root.loading && root.loadError.length > 0
                anchors.centerIn: parent
                text: root.loadError
                font.pixelSize: 13
                color: Theme.errorColor
            }
            Column {
                visible: !root.loading && root.loadError.length === 0 && root.notificationsList.length === 0
                anchors.centerIn: parent
                spacing: 10
                Item {
                    width: 72
                    height: 72
                    anchors.horizontalCenter: parent.horizontalCenter
                    ShapeCanvas {
                        anchors.fill: parent
                        color: Theme.surfaceContainerHighest
                        borderWidth: 2
                        borderColor: Theme.outlineVariant
                        roundedPolygon: GetMShapes.get(19)
                    }
                    Icon {
                        anchors.centerIn: parent
                        iconSize: 28
                        source: "assets/icons/patient.svg"
                        color: Theme.onSurfaceVariant
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "You're all caught up"
                    font.pixelSize: 15
                    font.bold: true
                    color: Theme.onSurfaceVariant
                }
            }

            Flickable {
                anchors.fill: parent
                visible: !root.loading && root.notificationsList.length > 0
                contentWidth: width
                contentHeight: listColumn.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: listColumn
                    width: parent.width
                    spacing: 12

                    Repeater {
                        model: root.notificationsList

                        delegate: Rectangle {
                            id: notifCard
                            required property var modelData

                            readonly property color accent: root.accentForType(notifCard.modelData.type ?? "system")
                            readonly property bool isUnread: !notifCard.modelData.is_read

                            width: listColumn.width
                            height: cardContent.height + 32
                            radius: 18
                            color: notifCard.isUnread ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow
                            border.width: notifCard.isUnread ? 2 : 1
                            border.color: notifCard.isUnread ? notifCard.accent : Theme.outlineVariant

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }

                            Row {
                                id: cardContent
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 16
                                spacing: 16

                                Item {
                                    width: 52
                                    height: 52
                                    anchors.top: parent.top

                                    ShapeCanvas {
                                        anchors.fill: parent
                                        color: notifCard.accent
                                        borderWidth: 0
                                        roundedPolygon: GetMShapes.get(root.shapeForType(notifCard.modelData.type ?? "system"))
                                    }
                                    Icon {
                                        anchors.centerIn: parent
                                        iconSize: 22
                                        source: root.iconForType(notifCard.modelData.type ?? "system")
                                        color: Theme.onPrimary
                                    }
                                    Rectangle {
                                        visible: notifCard.isUnread
                                        width: 14
                                        height: 14
                                        radius: 7
                                        color: Theme.errorColor
                                        border.width: 2
                                        border.color: notifCard.isUnread ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.topMargin: -2
                                        anchors.rightMargin: -2
                                    }
                                }

                                Column {
                                    width: parent.width - 52 - 16 - (notifCard.isUnread ? 116 : 0)
                                    spacing: 5

                                    Text {
                                        width: parent.width
                                        text: notifCard.modelData.title ?? ""
                                        font.pixelSize: 15
                                        font.bold: true
                                        color: Theme.onSurface
                                        wrapMode: Text.WordWrap
                                    }
                                    Text {
                                        width: parent.width
                                        text: notifCard.modelData.message ?? ""
                                        font.pixelSize: 13
                                        color: Theme.onSurfaceVariant
                                        wrapMode: Text.WordWrap
                                        lineHeight: 1.25
                                    }
                                    Text {
                                        text: (notifCard.modelData.created_at ?? "").toString().replace("T", " · ")
                                        font.pixelSize: 11
                                        color: Theme.onSurfaceVariant
                                        opacity: 0.6
                                    }
                                }

                                Rectangle {
                                    visible: notifCard.isUnread
                                    width: 100
                                    height: 36
                                    radius: 18
                                    color: notifCard.accent
                                    anchors.top: parent.top

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Mark read"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: Theme.onPrimary
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Sfx.playMove();
                                            root.markRead(notifCard.modelData.id);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
