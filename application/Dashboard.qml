pragma ComponentBehavior: Bound
import QtQuick
import MediSyncAdmin
import "./Patients"
import "./Hospitals"

Item {
    id: root
    signal loggedOut

    property string viewState: "menu"
    property int selectedIndex: -1
    property int openIndex: -1
    property bool sectionContentExpanded: false
    property bool notificationsOpen: false

    readonly property var menuItems: [
        {
            key: "patients",
            label: "Patients",
            description: "Verify and manage patient accounts",
            icon: "assets/icons/patient.svg",
            accent: Theme.secondaryColor
        },
        {
            key: "hospitals",
            label: "Hospitals",
            description: "Register and Manage hospitals and its doctors",
            icon: "assets/icons/hospital.svg",
            accent: Theme.tertiaryColor
        },
        {
            key: "logout",
            label: "Logout",
            description: "Sign out of this admin session",
            icon: "assets/icons/exit.svg",
            accent: Theme.errorColor
        }
    ]

    readonly property int unreadCount: notifPopoutContent.notificationsList.filter(n => !n.is_read).length
    readonly property bool keysBlocked: root.notificationsOpen

    focus: true
    Component.onCompleted: root.forceActiveFocus()

    function openSelected() {
        if (root.selectedIndex < 0)
            return;
        const item = root.menuItems[root.selectedIndex];
        if (item.key === "logout") {
            root.doLogout();
            return;
        }
        root.openIndex = root.selectedIndex;
        root.viewState = "open";
        Sfx.playChangePane();
    }

    function closeToMenu() {
        root.viewState = "menu";
        root.openIndex = -1;
        root.sectionContentExpanded = false;
        root.forceActiveFocus();
    }

    function doLogout() {
        SessionManager.clearSession();
        root.loggedOut();
    }

    Keys.onRightPressed: {
        if (root.viewState !== "menu" || root.keysBlocked) {
            return;
        }
        if (root.selectedIndex < 0) {
            root.selectedIndex = 0;
        } else if (root.selectedIndex < root.menuItems.length - 1) {
            root.selectedIndex += 1;
        }
        Sfx.playMove();
    }
    Keys.onLeftPressed: {
        if (root.viewState !== "menu" || root.selectedIndex <= 0 || root.keysBlocked) {
            return;
        }
        root.selectedIndex -= 1;
        Sfx.playMove();
    }
    Keys.onDownPressed: {
        if (root.viewState !== "menu" || root.selectedIndex >= 0 || root.keysBlocked) {
            return;
        }
        root.selectedIndex = 0;
        Sfx.playMove();
    }
    Keys.onReturnPressed: {
        if (root.viewState !== "menu" || root.keysBlocked) {
            return;
        }
        Sfx.playEnter();
        root.openSelected();
    }
    Keys.onEscapePressed: {
        if (root.notificationsOpen) {
            Sfx.playMove();
            root.notificationsOpen = false;
        } else if (root.viewState === "open") {
            Sfx.playMove();
            root.closeToMenu();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.backgroundColor
    }

    Item {
        id: menuView
        anchors.fill: parent
        visible: root.viewState === "menu"
        opacity: root.viewState === "menu" ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        Stats {
            id: statsSection
            anchors.centerIn: parent
        }

        Row {
            id: cardRow
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 40
            spacing: 28

            Repeater {
                model: root.menuItems

                delegate: Item {
                    id: cardDelegate
                    required property var modelData
                    required property int index

                    readonly property bool isSelected: root.selectedIndex === cardDelegate.index

                    width: 200
                    height: 260

                    Rectangle {
                        id: card
                        anchors.centerIn: parent
                        width: 180
                        height: 240
                        radius: 14
                        color: Theme.surfaceContainerHigh
                        border.width: cardDelegate.isSelected ? 3 : 1
                        border.color: cardDelegate.isSelected ? cardDelegate.modelData.accent : Theme.outlineVariant
                        scale: cardDelegate.isSelected ? 1.08 : 0.92

                        Behavior on scale {
                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on border.color {
                            ColorAnimation {
                                duration: 180
                            }
                        }

                        Icon {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.margins: 14
                            iconSize: 22
                            source: cardDelegate.modelData.icon
                            color: cardDelegate.modelData.accent
                        }

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 32
                            text: cardDelegate.modelData.label
                            font.pixelSize: 18
                            font.bold: true
                            color: Theme.onSurface
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 16
                            text: cardDelegate.modelData.description
                            font.pixelSize: 12
                            color: Theme.onSurfaceVariant
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedIndex = cardDelegate.index;
                            root.openSelected();
                        }
                    }
                }
            }
        }
    }

    Item {
        id: sectionView
        anchors.fill: parent
        visible: root.viewState === "open"
        opacity: root.viewState === "open" ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.backgroundColor
        }

        Loader {
            id: sectionLoader
            anchors.fill: parent
            anchors.margins: 10
            anchors.topMargin: 10
            sourceComponent: {
                if (root.openIndex < 0) {
                    return null;
                }
                const key = root.menuItems[root.openIndex].key;
                if (key === "patients") {
                    return patientsComponent;
                }
                if (key === "hospitals") {
                    return hospitalsComponent;
                }
                return null;
            }

            Behavior on anchors.margins {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on anchors.topMargin {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }
        }

        Connections {
            target: sectionLoader.item
            ignoreUnknownSignals: true
            function onBackRequested() {
                root.closeToMenu();
            }
            function onExpansionChanged(expanded) {
                root.sectionContentExpanded = expanded;
            }
        }

        Component {
            id: patientsComponent
            Patient {}
        }
        Component {
            id: hospitalsComponent
            Hospital {}
        }
    }

    MouseArea {
        anchors.fill: parent
        visible: root.notificationsOpen
        z: 90
        onClicked: root.notificationsOpen = false
    }

    Rectangle {
        id: notificationPopout
        visible: opacity > 0.01
        opacity: root.notificationsOpen ? 1 : 0
        z: 100
        anchors.bottom: notifTrigger.top
        anchors.right: parent.right
        anchors.bottomMargin: 12
        anchors.rightMargin: 28
        width: 380
        height: Math.min(560, notifPopoutContent.notificationsList.length === 0 ? 220 : 128 + Math.min(notifPopoutContent.notificationsList.length, 5) * 72 + (Math.min(notifPopoutContent.notificationsList.length, 5) - 1) * 8)
        radius: 20
        color: Theme.surfaceContainer
        clip: true
        transformOrigin: Item.Bottom
        scale: root.notificationsOpen ? 1 : 0.85

        Behavior on height {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        NotificationCenter {
            id: notifPopoutContent
            anchors.fill: parent
            anchors.margins: 18
            onBackRequested: root.notificationsOpen = false
        }
    }

    Rectangle {
        id: notifTrigger
        width: 52
        height: 52
        radius: 26
        z: 95
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 28
        color: root.notificationsOpen ? Theme.primaryColor : Theme.surfaceContainerHigh
        border.width: 1
        border.color: root.notificationsOpen ? Theme.primaryColor : Theme.outlineVariant
        scale: notifTriggerArea.containsMouse ? 1.06 : 1.0

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        Icon {
            anchors.centerIn: parent
            iconSize: 22
            source: "assets/icons/notification.svg"
            color: root.notificationsOpen ? Theme.onPrimary : Theme.onSurfaceVariant
        }

        Rectangle {
            visible: root.unreadCount > 0 && !root.notificationsOpen
            width: 12
            height: 12
            radius: 6
            color: Theme.errorColor
            border.width: 2
            border.color: Theme.backgroundColor
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: -1
        }

        MouseArea {
            id: notifTriggerArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Sfx.playChangePane();
                root.notificationsOpen = !root.notificationsOpen;
            }
        }
    }
}
