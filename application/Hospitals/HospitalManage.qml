pragma ComponentBehavior: Bound
import QtQuick
import MediSyncAdmin

FocusScope {
    id: root

    property bool focusRequested: false
    property var hospitalsList: []
    property bool loadingList: false
    property string listError: ""
    property int selectedIndex: -1

    readonly property var accentPalette: [Theme.primaryColor, Theme.secondaryColor, Theme.tertiaryColor, Theme.primaryFixedDim]
    readonly property var selectedHospital: root.selectedIndex >= 0 && root.selectedIndex < root.hospitalsList.length ? root.hospitalsList[root.selectedIndex] : null

    Component.onCompleted: {
        if (root.hospitalsList.length === 0 && !root.loadingList)
            root.refreshHospitals();
    }

    onFocusRequestedChanged: if (root.focusRequested)
        root.forceActiveFocus()

    function accentFor(key) {
        let hash = 0;
        for (let i = 0; i < key.length; i++)
            hash = (hash * 31 + key.charCodeAt(i)) >>> 0;
        return root.accentPalette[hash % root.accentPalette.length];
    }

    function refreshHospitals() {
        root.loadingList = true;
        root.listError = "";
        ApiClient.get("/hospitals/", "allHospitals");
    }

    focus: true

    Keys.onDownPressed: event => {
        if (root.hospitalsList.length > 0) {
            root.selectedIndex = Math.min(root.selectedIndex + 1, root.hospitalsList.length - 1);
            Sfx.playMove();
        }
        event.accepted = true;
    }
    Keys.onUpPressed: event => {
        if (root.hospitalsList.length > 0) {
            root.selectedIndex = root.selectedIndex <= 0 ? 0 : root.selectedIndex - 1;
            Sfx.playMove();
        }
        event.accepted = true;
    }

    Connections {
        target: ApiClient
        function onRequestFinished(requestId, success, data, message) {
            if (requestId === "allHospitals") {
                root.loadingList = false;
                root.hospitalsList = success ? (data ?? []) : [];
                if (!success)
                    root.listError = message;
                if (root.hospitalsList.length > 0 && root.selectedIndex < 0)
                    root.selectedIndex = 0;
            } else if (requestId.indexOf("deleteHospital:") === 0 && success) {
                root.selectedIndex = -1;
                root.refreshHospitals();
            }
        }
    }
    Row {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: listPane
            radius: 20
            width: root.focusRequested ? 260 : parent.width
            height: parent.height
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
                    visible: !root.loadingList && root.listError.length === 0 && root.hospitalsList.length === 0
                    text: "No hospitals found."
                    color: Theme.onSurfaceVariant
                    font.pixelSize: 13
                }

                ListView {
                    id: hospitalListView
                    width: parent.width
                    height: parent.height - 40
                    clip: true
                    spacing: 4
                    model: root.hospitalsList
                    currentIndex: root.selectedIndex
                    highlightMoveDuration: 120
                    cacheBuffer: 400

                    onCurrentIndexChanged: hospitalListView.positionViewAtIndex(hospitalListView.currentIndex, ListView.Contain)

                    delegate: Rectangle {
                        id: rowDelegate
                        required property var modelData
                        required property int index

                        readonly property bool isSelected: root.selectedIndex === rowDelegate.index
                        readonly property color accent: root.accentFor((rowDelegate.modelData.id ?? rowDelegate.modelData.name ?? "x") + "")
                        readonly property string imageUrl: rowDelegate.modelData.image_url ?? ""

                        width: hospitalListView.width
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
                                width: 40
                                height: 40
                                anchors.verticalCenter: parent.verticalCenter
                                ShapeCanvas {
                                    anchors.fill: parent
                                    color: rowDelegate.accent
                                    borderWidth: 2
                                    borderColor: rowDelegate.isSelected ? Theme.primaryFixedColor : Theme.secondaryFixedColor
                                    roundedPolygon: rowDelegate.isSelected ? GetMShapes.get(2) : GetMShapes.get(20)
                                    imageSource: rowDelegate.imageUrl.length > 0 ? (Config.baseUrl + rowDelegate.imageUrl) : ""
                                    animation: NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: rowDelegate.imageUrl.length === 0
                                    text: (rowDelegate.modelData.name ?? "?").charAt(0).toUpperCase()
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: Theme.onPrimary
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: hospitalListView.width - 70
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

        HospitalDetail {
            width: root.focusRequested ? parent.width - listPane.width : 0
            height: parent.height
            clip: true
            visible: root.focusRequested
            hospital: root.selectedHospital
        }
    }
}
