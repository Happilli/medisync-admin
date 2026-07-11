pragma ComponentBehavior: Bound
import QtQuick
import MediSyncAdmin

FocusScope {
    id: root
    signal backRequested
    property var notificationsList: []
    property bool loading: false
    property string loadError: ""
    property bool unreadOnly: true

    focus: true

    onVisibleChanged: if (root.visible) {
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
        if (!root.notificationsList.some(n => !n.is_read)) {
            return;
        }
        ApiClient.patch("/notifications/read-all", "markAllRead");
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

    Column {
        anchors.fill: parent
        spacing: 12

        Item {
            width: parent.width
            height: Math.max(titleColumn.height)

            Column {
                id: titleColumn
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Row {
                    spacing: 8
                    Text {
                        text: "Notifications"
                        font.pixelSize: 18
                        font.bold: true
                        color: Theme.onSurface
                    }
                    Rectangle {
                        visible: root.notificationsList.filter(n => !n.is_read).length > 0
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 9
                        height: 18
                        width: unreadCountText.width + 14
                        color: Theme.errorColor

                        Text {
                            id: unreadCountText
                            anchors.centerIn: parent
                            text: root.notificationsList.filter(n => !n.is_read).length + " new"
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.onError
                        }
                    }
                }
            }
        }

        Row {
            width: parent.width
            spacing: 8

            Rectangle {
                width: 104
                height: 30
                radius: 15
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
                    font.pixelSize: 11
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
                visible: root.notificationsList.some(n => !n.is_read)
                width: 104
                height: 30
                radius: 15
                color: Theme.surfaceContainerHighest
                border.width: 1
                border.color: Theme.outlineVariant

                Text {
                    anchors.centerIn: parent
                    text: "Mark all read"
                    font.pixelSize: 11
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

        Item {
            width: parent.width
            height: parent.height - y

            Text {
                visible: root.loading
                anchors.centerIn: parent
                text: "Syncing..."
                font.pixelSize: 12
                color: Theme.onSurfaceVariant
            }
            Text {
                visible: !root.loading && root.loadError.length > 0
                anchors.centerIn: parent
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: root.loadError
                font.pixelSize: 12
                color: Theme.errorColor
            }
            Column {
                visible: !root.loading && root.loadError.length === 0 && root.notificationsList.length === 0
                anchors.centerIn: parent
                spacing: 8
                Item {
                    width: 52
                    height: 52
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
                        iconSize: 20
                        source: "assets/icons/patient.svg"
                        color: Theme.onSurfaceVariant
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.unreadOnly ? "You're all caught up" : "No notifications"
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.onSurfaceVariant
                }
            }

            ListView {
                id: notifListView
                anchors.fill: parent
                visible: !root.loading && root.notificationsList.length > 0
                clip: true
                spacing: 8
                model: root.notificationsList
                boundsBehavior: Flickable.StopAtBounds

                add: Transition {
                    NumberAnimation {
                        properties: "opacity"
                        from: 0
                        to: 1
                        duration: 220
                    }
                    NumberAnimation {
                        properties: "y"
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }
                remove: Transition {
                    NumberAnimation {
                        properties: "opacity"
                        to: 0
                        duration: 160
                    }
                }
                displaced: Transition {
                    NumberAnimation {
                        properties: "y"
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }
                move: Transition {
                    NumberAnimation {
                        properties: "y"
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                delegate: Rectangle {
                    id: notifCard
                    required property var modelData

                    readonly property color accent: root.accentForType(notifCard.modelData.type ?? "system")
                    readonly property bool isUnread: !notifCard.modelData.is_read

                    width: notifListView.width
                    height: cardContent.height + 20
                    radius: 14
                    color: notifCard.isUnread ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow
                    border.width: 1
                    border.color: notifCard.isUnread ? notifCard.accent : Theme.outlineVariant
                    opacity: notifCard.isUnread ? 1 : 0.7

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }

                    Row {
                        id: cardContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 10

                        Item {
                            width: 32
                            height: 32
                            anchors.top: parent.top

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: notifCard.accent
                            }
                            Icon {
                                anchors.centerIn: parent
                                iconSize: 14
                                source: root.iconForType(notifCard.modelData.type ?? "system")
                                color: Theme.onPrimary
                            }
                            Rectangle {
                                visible: notifCard.isUnread
                                width: 9
                                height: 9
                                radius: 4.5
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
                            width: parent.width - 32 - 10
                            spacing: 3

                            Item {
                                width: parent.width
                                height: Math.max(titleText.height, notifCard.isUnread ? 22 : 0)

                                Text {
                                    id: titleText
                                    anchors.left: parent.left
                                    anchors.right: notifCard.isUnread ? markReadBtn.left : parent.right
                                    anchors.rightMargin: notifCard.isUnread ? 8 : 0
                                    text: notifCard.modelData.title ?? ""
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.onSurface
                                    wrapMode: Text.WordWrap
                                }

                                Rectangle {
                                    id: markReadBtn
                                    visible: notifCard.isUnread
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    width: 58
                                    height: 22
                                    radius: 11
                                    color: notifCard.accent

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Mark read"
                                        font.pixelSize: 9
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

                            Text {
                                width: parent.width
                                text: notifCard.modelData.message ?? ""
                                font.pixelSize: 11
                                color: Theme.onSurfaceVariant
                                wrapMode: Text.WordWrap
                                lineHeight: 1.2
                            }
                            Text {
                                text: (notifCard.modelData.created_at ?? "").toString().replace("T", "-")
                                font.pixelSize: 9
                                color: Theme.onSurfaceVariant
                                opacity: 0.6
                            }
                        }
                    }
                }
            }
        }
    }
}
