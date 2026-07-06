pragma ComponentBehavior: Bound
import QtQuick
import MediSyncAdmin

FocusScope {
    id: root

    property var pendingPatients: []
    property bool loadingList: false
    property string listError: ""
    property int selectedIndex: -1
    property bool focusRequested: false

    readonly property var accentPalette: [Theme.primaryColor, Theme.secondaryColor, Theme.tertiaryColor, Theme.primaryFixedDim]
    readonly property var selectedPatient: root.selectedIndex >= 0 && root.selectedIndex < root.pendingPatients.length ? root.pendingPatients[root.selectedIndex] : null

    Component.onCompleted: {
        if (root.pendingPatients.length === 0 && !root.loadingList)
            root.refreshPendingPatients();
    }

    onFocusRequestedChanged: {
        if (root.focusRequested)
            root.forceActiveFocus();
    }

    function accentFor(key) {
        let hash = 0;
        for (let i = 0; i < key.length; i++)
            hash = (hash * 31 + key.charCodeAt(i)) >>> 0;
        return root.accentPalette[hash % root.accentPalette.length];
    }

    function refreshPendingPatients() {
        root.loadingList = true;
        root.listError = "";
        root.selectedIndex = -1;
        ApiClient.get("/patients/pending", "pendingPatients");
    }

    focus: true

    Keys.onDownPressed: event => {
        if (root.pendingPatients.length > 0)
            root.selectedIndex = Math.min(root.selectedIndex + 1, root.pendingPatients.length - 1);
        event.accepted = true;
    }
    Keys.onUpPressed: event => {
        if (root.pendingPatients.length > 0)
            root.selectedIndex = root.selectedIndex <= 0 ? 0 : root.selectedIndex - 1;
        event.accepted = true;
    }

    Connections {
        target: ApiClient
        function onRequestFinished(requestId, success, data, message) {
            if (requestId === "pendingPatients") {
                root.loadingList = false;
                root.pendingPatients = success ? (data ?? []) : [];
                if (!success)
                    root.listError = message;
                if (root.pendingPatients.length > 0)
                    root.selectedIndex = 0;
            } else if (requestId.indexOf("verifyPatient:") === 0) {
                if (success) {
                    root.refreshPendingPatients();
                } else {
                    root.listError = message;
                }
            }
        }
    }

    Row {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: listPane
            width: root.focusRequested ? 260 : parent.width
            height: parent.height
            color: Theme.surfaceContainerLow

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                    visible: root.loadingList
                    text: "Syncing…"
                    font.pixelSize: 12
                    color: Theme.onSurfaceVariant
                }

                Text {
                    visible: !root.loadingList && root.listError.length > 0
                    width: parent.width
                    text: root.listError
                    color: Theme.errorColor
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }

                Text {
                    visible: !root.loadingList && root.listError.length === 0 && root.pendingPatients.length === 0
                    text: "No pending patients."
                    color: Theme.onSurfaceVariant
                    font.pixelSize: 13
                }

                ListView {
                    id: patientListView
                    width: parent.width
                    height: parent.height - 40
                    clip: true
                    spacing: 4
                    model: root.pendingPatients
                    currentIndex: root.selectedIndex
                    highlightMoveDuration: 120
                    cacheBuffer: 400

                    onCurrentIndexChanged: patientListView.positionViewAtIndex(patientListView.currentIndex, ListView.Contain)

                    delegate: Rectangle {
                        id: rowDelegate
                        required property var modelData
                        required property int index

                        readonly property bool isSelected: root.selectedIndex === rowDelegate.index
                        readonly property color accent: root.accentFor((rowDelegate.modelData.id ?? rowDelegate.modelData.name ?? "x") + "")
                        readonly property string photoUrl: rowDelegate.modelData.profile_pic_url ?? ""

                        width: patientListView.width
                        height: 56
                        radius: 12
                        color: isSelected ? Theme.secondaryContainerColor : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
                        }

                        Row {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 10

                            Item {
                                id: avatarSlot
                                width: 40
                                height: 40
                                anchors.verticalCenter: parent.verticalCenter
                                ShapeCanvas {
                                    id: avatarShape
                                    anchors.fill: parent
                                    color: rowDelegate.accent
                                    borderWidth: 2
                                    borderColor: rowDelegate.isSelected ? Theme.primaryFixedColor : Theme.secondaryFixedColor
                                    roundedPolygon: rowDelegate.isSelected ? GetMShapes.get(2) : GetMShapes.get(20)
                                    imageSource: rowDelegate.photoUrl.length > 0 ? (Config.baseUrl + rowDelegate.photoUrl) : ""
                                    animation: NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: rowDelegate.photoUrl.length === 0
                                    text: (rowDelegate.modelData.name ?? "?").charAt(0).toUpperCase()
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: Theme.onPrimary
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: patientListView.width - 70
                                text: rowDelegate.modelData.name ?? ""
                                font.pixelSize: 14
                                font.bold: rowDelegate.isSelected
                                color: Theme.onSurface
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedIndex = rowDelegate.index;
                                root.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }

        PatientDetail {
            width: root.focusRequested ? parent.width - listPane.width : 0
            height: parent.height
            clip: true
            visible: root.focusRequested
            patient: root.selectedPatient
        }
    }
}
