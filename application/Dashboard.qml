pragma ComponentBehavior: Bound
import QtQuick
import MediSyncAdmin
import "./Patients"
import "./Hospitals"

Item {
    id: root
    signal loggedOut
    Component.onCompleted: root.forceActiveFocus()

    property string viewState: "menu"
    property int selectedIndex: -1
    property int openIndex: -1
    property bool sectionContentExpanded: false

    readonly property var menuItems: [
        {
            key: "patients",
            label: "Patients",
            description: "Verify and manage patient accounts",
            icon: "assets/icons/patient.svg",
            accent: Theme.secondaryColor,
            background: "assets/backgrounds/patients.png"
        },
        {
            key: "hospitals",
            label: "Hospitals",
            description: "Register and Manage hospitals and its doctors",
            icon: "assets/icons/hospital.svg",
            accent: Theme.tertiaryColor,
            background: "assets/backgrounds/hospitals.png"
        },
        {
            key: "notifications",
            label: "Notifications",
            description: "View all the notifications..",
            icon: "assets/icons/notification.svg",
            accent: Theme.primaryColor,
            background: "assets/backgrounds/hospitals.png"
        },
        {
            key: "logout",
            label: "Logout",
            description: "Sign out of this admin session",
            icon: "assets/icons/exit.svg",
            accent: Theme.errorColor,
            background: "assets/backgrounds/patients.png"
        }
    ]

    readonly property var currentItem: root.selectedIndex >= 0 ? root.menuItems[root.selectedIndex] : root.menuItems[0]

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

    focus: true
    Keys.onRightPressed: if (root.viewState === "menu") {
        if (root.selectedIndex < 0)
            root.selectedIndex = 0;
        else if (root.selectedIndex < root.menuItems.length - 1)
            root.selectedIndex += 1;
        Sfx.playMove();
    }
    Keys.onLeftPressed: if (root.viewState === "menu" && root.selectedIndex > 0) {
        root.selectedIndex -= 1;
        Sfx.playMove();
    }
    Keys.onDownPressed: if (root.viewState === "menu" && root.selectedIndex < 0) {
        root.selectedIndex = 0;
        Sfx.playMove();
    }
    Keys.onReturnPressed: if (root.viewState === "menu") {
        Sfx.playEnter();
        root.openSelected();
    }
    Keys.onEscapePressed: if (root.viewState === "open") {
        Sfx.playMove();
        root.closeToMenu();
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.backgroundColor
    }

    Image {
        id: backgroundImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        source: root.currentItem.background
        visible: status === Image.Ready
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.viewState === "open" ? 0.55 : 0.35
        visible: backgroundImage.status === Image.Ready

        Behavior on opacity {
            NumberAnimation {
                duration: 220
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: root.viewState === "menu"
        opacity: root.viewState === "menu" ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
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
                if (key === "patients")
                    return patientsComponent;
                if (key === "hospitals")
                    return hospitalsComponent;
                if (key === "notifications") {
                    return notificationsComponent;
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
        Component {
            id: notificationsComponent
            NotificationCenter {}
        }
    }
}
