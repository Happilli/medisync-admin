pragma ComponentBehavior: Bound
import QtQuick
import MediSyncAdmin

FocusScope {
    id: root
    signal backRequested
    signal expansionChanged(bool expanded)

    property int selectedIndex: 0
    property string viewState: "menu"

    readonly property var menuItems: [
        {
            key: "verification",
            label: "Manage Patients",
            accent: Theme.secondaryColor
        },
        {
            key: "back",
            label: "Back",
            accent: Theme.onSurfaceVariant
        }
    ]

    focus: true
    Component.onCompleted: root.forceActiveFocus()

    onViewStateChanged: {
        root.expansionChanged(root.viewState === "content");
        if (root.viewState !== "content")
            root.forceActiveFocus();
    }

    Keys.onUpPressed: if (root.viewState === "menu" && root.selectedIndex > 0) {
        root.selectedIndex -= 1;
        Sfx.playMove();
    }
    Keys.onDownPressed: if (root.viewState === "menu" && root.selectedIndex < root.menuItems.length - 1) {
        root.selectedIndex += 1;
        Sfx.playMove();
    }
    Keys.onLeftPressed: if (root.viewState === "content") {
        root.viewState = "menu";
        Sfx.playBack();
    }
    Keys.onReturnPressed: {
        if (root.viewState !== "menu")
            return;
        const key = root.menuItems[root.selectedIndex].key;
        if (key === "back") {
            Sfx.playBack();
            root.backRequested();
        } else if (key === "verification") {
            Sfx.playChangePane();
            root.viewState = "content";
        }
    }
    Keys.onEscapePressed: event => {
        if (root.viewState === "content") {
            root.viewState = "menu";
            Sfx.playBack();
            event.accepted = true;
        } else {
            event.accepted = false;
        }
    }

    Item {
        id: container
        anchors.fill: parent
        clip: true

        Item {
            id: sidebarWrap
            width: 200
            height: parent.height
            x: root.viewState === "menu" ? 0 : -240

            Behavior on x {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }

            Column {
                anchors.fill: parent
                spacing: 8

                Repeater {
                    model: root.menuItems

                    delegate: Item {
                        id: sidebarItem
                        required property var modelData
                        required property int index
                        readonly property bool isSelected: root.selectedIndex === sidebarItem.index
                        readonly property bool isBack: sidebarItem.modelData.key === "back"

                        width: sidebarWrap.width
                        height: 52

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10

                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                iconSize: 16
                                source: "assets/icons/selectedarrow.svg"
                                color: sidebarItem.modelData.accent
                                opacity: sidebarItem.isSelected ? 1 : 0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 140
                                    }
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: sidebarItem.modelData.label
                                font.pixelSize: 20
                                color: sidebarItem.isSelected ? sidebarItem.modelData.accent : Theme.onSurfaceVariant

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 140
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedIndex = sidebarItem.index;
                                root.forceActiveFocus();
                                if (sidebarItem.isBack) {
                                    Sfx.playBack();
                                    root.backRequested();
                                } else {
                                    Sfx.playChangePane();
                                    root.viewState = "content";
                                }
                            }
                        }
                    }
                }
            }
        }

        Loader {
            id: contentLoader
            height: parent.height
            x: root.viewState === "menu" ? 228 : 0
            width: root.viewState === "menu" ? parent.width - 228 : parent.width
            enabled: root.viewState === "content"
            sourceComponent: verificationComponent

            Behavior on x {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on width {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }
        }

        Binding {
            target: contentLoader.item
            property: "focusRequested"
            value: root.viewState === "content"
            when: contentLoader.item !== null
        }
    }

    Component {
        id: verificationComponent
        PatientVerification {}
    }
}
