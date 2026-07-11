pragma ComponentBehavior: Bound
import QtQuick
import MediSyncAdmin

FocusScope {
    id: root

    property bool focusRequested: false
    property var patientsList: []
    property bool loadingList: false
    property string listError: ""
    property int selectedPatientId: -1

    readonly property var accentPalette: [Theme.primaryColor, Theme.secondaryColor, Theme.tertiaryColor, Theme.primaryFixedDim]

    Component.onCompleted: {
        if (root.patientsList.length === 0 && !root.loadingList)
            root.refreshPatients();
    }

    onFocusRequestedChanged: if (root.focusRequested)
        root.forceActiveFocus()

    function accentFor(key) {
        let hash = 0;
        for (let i = 0; i < key.length; i++)
            hash = (hash * 31 + key.charCodeAt(i)) >>> 0;
        return root.accentPalette[hash % root.accentPalette.length];
    }

    function refreshPatients() {
        root.loadingList = true;
        root.listError = "";
        ApiClient.get("/patients/", "allPatients");
    }

    focus: true

    Keys.onDownPressed: event => {
        if (root.patientsList.length > 0) {
            const idx = root.patientsList.findIndex(p => p.id === root.selectedPatientId);
            const next = idx < 0 ? 0 : Math.min(idx + 1, root.patientsList.length - 1);
            root.selectedPatientId = root.patientsList[next].id;
            Sfx.playMove();
        }
        event.accepted = true;
    }
    Keys.onUpPressed: event => {
        if (root.patientsList.length > 0) {
            const idx = root.patientsList.findIndex(p => p.id === root.selectedPatientId);
            const prev = idx <= 0 ? 0 : idx - 1;
            root.selectedPatientId = root.patientsList[prev].id;
            Sfx.playMove();
        }
        event.accepted = true;
    }

    Connections {
        target: ApiClient
        function onRequestFinished(requestId, success, data, message) {
            if (requestId === "allPatients") {
                root.loadingList = false;
                root.patientsList = success ? (data ?? []) : [];
                if (!success)
                    root.listError = message;
                if (root.patientsList.length > 0 && root.selectedPatientId < 0)
                    root.selectedPatientId = root.patientsList[0].id;
            } else if (requestId.indexOf("verifyPatient:") === 0 && success) {
                root.refreshPatients();
            } else if (requestId.indexOf("deletePatient:") === 0 && success) {
                root.selectedPatientId = -1;
                root.refreshPatients();
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
            radius: 20
            color: Theme.surfaceContainerLow

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                    visible: root.loadingList
                    text: "Syncing..."
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
                    visible: !root.loadingList && root.listError.length === 0 && root.patientsList.length === 0
                    text: "No patients found."
                    color: Theme.onSurfaceVariant
                    font.pixelSize: 13
                }

                ListView {
                    id: patientListView
                    width: parent.width
                    height: parent.height - 40
                    clip: true
                    spacing: 4
                    model: root.patientsList
                    currentIndex: root.patientsList.findIndex(p => p.id === root.selectedPatientId)
                    highlightMoveDuration: 120
                    cacheBuffer: 150

                    onCurrentIndexChanged: patientListView.positionViewAtIndex(patientListView.currentIndex, ListView.Contain)

                    delegate: Rectangle {
                        id: rowDelegate
                        required property var modelData
                        required property int index

                        readonly property bool isSelected: root.selectedPatientId === rowDelegate.modelData.id
                        readonly property color accent: root.accentFor((rowDelegate.modelData.id ?? rowDelegate.modelData.name ?? "x") + "")
                        readonly property string photoUrl: rowDelegate.modelData.profile_pic_url ?? ""

                        width: patientListView.width
                        height: 56
                        radius: 12
                        color: "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 10

                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                iconSize: 16
                                source: "assets/icons/selectedarrow.svg"
                                color: rowDelegate.accent
                                opacity: rowDelegate.isSelected ? 1 : 0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 140
                                    }
                                }
                            }

                            Item {
                                id: avatarSlot
                                width: 40
                                height: 40
                                anchors.verticalCenter: parent.verticalCenter
                                Rectangle {
                                    anchors.fill: parent
                                    radius: width / 2
                                    color: rowDelegate.accent
                                    border.width: 2
                                    border.color: rowDelegate.isSelected ? Theme.primaryFixedColor : Theme.secondaryFixedColor
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        visible: rowDelegate.photoUrl.length > 0
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        source: rowDelegate.photoUrl.length > 0 ? (Config.baseUrl + rowDelegate.photoUrl) : ""
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

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: patientListView.width - 96
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: rowDelegate.modelData.name ?? ""
                                    font.pixelSize: 14
                                    font.bold: rowDelegate.isSelected
                                    color: Theme.onSurface
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: rowDelegate.modelData.is_verified ? "Verified" : "Pending"
                                    font.pixelSize: 11
                                    color: rowDelegate.modelData.is_verified ? Theme.primaryFixedDim : Theme.errorColor
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedPatientId = rowDelegate.modelData.id;
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
            patientId: root.selectedPatientId
        }
    }
}
