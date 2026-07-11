pragma ComponentBehavior: Bound
import QtQuick
import MediSyncAdmin

Item {
    id: root

    property var hospital: null
    property int selectedDoctorId: -1

    property var doctorsList: []
    property bool loadingDoctors: false
    property string doctorsError: ""

    readonly property var accentPalette: [Theme.primaryColor, Theme.secondaryColor, Theme.tertiaryColor, Theme.primaryFixedDim]

    function accentFor(key) {
        let hash = 0;
        for (let i = 0; i < key.length; i++)
            hash = (hash * 31 + key.charCodeAt(i)) >>> 0;
        return root.accentPalette[hash % root.accentPalette.length];
    }

    function refreshDoctors() {
        if (root.hospital === null)
            return;
        root.loadingDoctors = true;
        root.doctorsError = "";
        root.doctorsList = [];
        ApiClient.get("/hospitals/" + root.hospital.id + "/doctors", "hospitalDoctors:" + root.hospital.id);
    }

    onHospitalChanged: {
        root.selectedDoctorId = -1;
        root.refreshDoctors();
    }

    Connections {
        target: ApiClient
        function onRequestFinished(requestId, success, data, message) {
            if (root.hospital && requestId === "hospitalDoctors:" + root.hospital.id) {
                root.loadingDoctors = false;
                root.doctorsList = success ? (data ?? []) : [];
                if (!success) {
                    root.doctorsError = message;
                }
            } else if (requestId.indexOf("verifyDoctor:") === 0 && success) {
                root.refreshDoctors();
            } else if (root.hospital && requestId === "deleteHospital:" + root.hospital.id && success) {
                root.hospital = null;
            }
        }
    }

    Text {
        visible: root.hospital === null
        anchors.centerIn: parent
        text: "Select a hospital to review"
        font.pixelSize: 16
        color: Theme.onSurfaceVariant
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 40
        visible: root.hospital !== null && root.selectedDoctorId < 0
        contentWidth: width
        contentHeight: detailColumn.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: detailColumn
            width: parent.width
            spacing: 36

            Column {
                width: parent.width
                spacing: 6

                Text {
                    text: "Hospital Review"
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.primaryFixedDim
                    font.letterSpacing: 1.5
                }
                Text {
                    text: root.hospital ? (root.hospital.name ?? "") : ""
                    font.pixelSize: 34
                    font.bold: true
                    color: Theme.onSurface
                }
                Text {
                    text: root.hospital ? ("Hospital ID: " + String(root.hospital.id)) : ""
                    font.pixelSize: 13
                    color: Theme.onSurfaceVariant
                }
                Row {
                    spacing: 8
                    visible: root.hospital !== null
                    Rectangle {
                        radius: 8
                        width: statusText.width + 16
                        height: statusText.height + 8
                        color: (root.hospital && root.hospital.is_active) ? Theme.primaryContainerColor : Theme.errorContainerColor
                        Text {
                            id: statusText
                            anchors.centerIn: parent
                            text: (root.hospital && root.hospital.is_active) ? "Active" : "Inactive"
                            font.pixelSize: 12
                            font.bold: true
                            color: (root.hospital && root.hospital.is_active) ? Theme.onPrimaryContainer : Theme.onErrorContainer
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: infoGrid.height + 48
                radius: 20
                color: Theme.surfaceContainerLow
                border.width: 1
                border.color: Theme.outlineVariant

                Grid {
                    id: infoGrid
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 24
                    columns: 2
                    columnSpacing: 32
                    rowSpacing: 24

                    Repeater {
                        model: root.hospital ? [
                            {
                                label: "Phone",
                                value: root.hospital.phone
                            },
                            {
                                label: "Address",
                                value: root.hospital.address
                            },
                            {
                                label: "Registration number",
                                value: root.hospital.registration_number
                            },
                            {
                                label: "Website",
                                value: root.hospital.website
                            },
                            {
                                label: "Description",
                                value: root.hospital.description
                            }
                        ] : []

                        delegate: Column {
                            id: fieldItem
                            required property var modelData
                            width: (infoGrid.width - infoGrid.columnSpacing) / 2
                            spacing: 4

                            Text {
                                text: fieldItem.modelData.label
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.onSurfaceVariant
                            }
                            Text {
                                width: parent.width
                                text: (fieldItem.modelData.value ?? "") !== "" ? String(fieldItem.modelData.value) : "-"
                                font.pixelSize: 16
                                color: Theme.onSurface
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 16

                Text {
                    text: "Doctors"
                    font.pixelSize: 16
                    font.bold: true
                    color: Theme.onSurface
                }

                Text {
                    visible: root.loadingDoctors
                    text: "Syncing..."
                    font.pixelSize: 12
                    color: Theme.onSurfaceVariant
                }
                Text {
                    visible: !root.loadingDoctors && root.doctorsError.length > 0
                    text: root.doctorsError
                    color: Theme.errorColor
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
                Text {
                    visible: !root.loadingDoctors && root.doctorsError.length === 0 && root.doctorsList.length === 0
                    text: "No doctors registered under this hospital."
                    color: Theme.onSurfaceVariant
                    font.pixelSize: 13
                }

                Flow {
                    width: parent.width
                    spacing: 12

                    Repeater {
                        model: root.doctorsList

                        delegate: Rectangle {
                            id: docCard
                            required property var modelData

                            readonly property color accent: root.accentFor((docCard.modelData.id ?? docCard.modelData.name ?? "x") + "")
                            readonly property string photoUrl: docCard.modelData.profile_pic_url ?? ""

                            width: 180
                            height: 64
                            radius: 12
                            color: Theme.surfaceContainerHigh
                            border.width: 1
                            border.color: docCard.modelData.is_verified ? Theme.outlineVariant : Theme.errorColor

                            Row {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                Item {
                                    width: 40
                                    height: 40
                                    anchors.verticalCenter: parent.verticalCenter
                                    ShapeCanvas {
                                        anchors.fill: parent
                                        color: docCard.accent
                                        borderWidth: 2
                                        borderColor: Theme.secondaryFixedColor
                                        roundedPolygon: GetMShapes.get(20)
                                        imageSource: docCard.photoUrl.length > 0 ? (Config.baseUrl + docCard.photoUrl) : ""
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        visible: docCard.photoUrl.length === 0
                                        text: (docCard.modelData.name ?? "?").charAt(0).toUpperCase()
                                        font.pixelSize: 15
                                        font.bold: true
                                        color: Theme.onPrimary
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 50
                                    spacing: 2

                                    Text {
                                        width: parent.width
                                        text: docCard.modelData.name ?? ""
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.onSurface
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: docCard.modelData.is_verified ? "Verified" : "Pending"
                                        font.pixelSize: 11
                                        color: docCard.modelData.is_verified ? Theme.primaryFixedDim : Theme.errorColor
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedDoctorId = docCard.modelData.id
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 16
                visible: root.hospital !== null

                Text {
                    text: "Danger zone"
                    font.pixelSize: 16
                    font.bold: true
                    color: Theme.errorColor
                }

                Text {
                    width: parent.width
                    text: "Deleting a hospital permanently removes it and every doctor registered under it. This cannot be undone."
                    font.pixelSize: 13
                    color: Theme.onSurfaceVariant
                    wrapMode: Text.WordWrap
                }

                Item {
                    id: slideToDelete
                    width: Math.min(420, parent.width)
                    height: 68

                    property bool confirmed: false
                    property bool dragging: false
                    readonly property real trackMargin: 6
                    readonly property real thumbWidth: 58
                    readonly property real maxX: slideToDelete.width - slideToDelete.thumbWidth - slideToDelete.trackMargin
                    readonly property real progress: Math.max(0, Math.min(1, (deleteThumb.x - slideToDelete.trackMargin) / Math.max(1, slideToDelete.maxX - slideToDelete.trackMargin)))

                    function reset() {
                        slideToDelete.confirmed = false;
                        deleteThumb.x = slideToDelete.trackMargin;
                    }

                    Connections {
                        target: root
                        function onHospitalChanged() {
                            slideToDelete.reset();
                        }
                    }

                    Rectangle {
                        id: deleteTrack
                        anchors.fill: parent
                        radius: height / 2
                        color: Theme.surfaceContainerHighest
                        border.width: 1
                        border.color: Theme.errorColor
                    }
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: slideToDelete.trackMargin
                        width: Math.max(0, deleteThumb.x - slideToDelete.trackMargin + slideToDelete.thumbWidth / 2)
                        radius: height / 2
                        color: Theme.errorContainerColor
                        opacity: 0.55
                    }
                    Text {
                        anchors.centerIn: parent
                        text: slideToDelete.confirmed ? "Deleting..." : "Slide to permanently delete hospital"
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.errorColor
                        opacity: slideToDelete.confirmed ? 1 : Math.max(0, 1 - slideToDelete.progress * 1.6)
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Item {
                        id: deleteThumb
                        width: slideToDelete.thumbWidth
                        height: parent.height - slideToDelete.trackMargin * 2
                        y: slideToDelete.trackMargin
                        x: slideToDelete.trackMargin

                        Behavior on x {
                            enabled: !slideToDelete.dragging
                            NumberAnimation {
                                duration: 260
                                easing.type: Easing.OutCubic
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: Theme.errorColor
                            border.width: slideToDelete.dragging ? 3 : 1
                            border.color: Theme.onErrorContainer
                        }
                        Text {
                            anchors.centerIn: parent
                            text: slideToDelete.confirmed ? "✓" : "›"
                            font.pixelSize: 22
                            font.bold: true
                            color: Theme.onError
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !slideToDelete.confirmed
                            cursorShape: Qt.PointingHandCursor
                            drag.target: deleteThumb
                            drag.axis: Drag.XAxis
                            drag.minimumX: slideToDelete.trackMargin
                            drag.maximumX: slideToDelete.maxX

                            onPressed: slideToDelete.dragging = true
                            onReleased: {
                                slideToDelete.dragging = false;
                                if (deleteThumb.x >= slideToDelete.maxX * 0.9) {
                                    deleteThumb.x = slideToDelete.maxX;
                                    slideToDelete.confirmed = true;
                                    Sfx.playBack();
                                    ApiClient.del("/hospitals/" + root.hospital.id, "deleteHospital:" + root.hospital.id);
                                } else {
                                    deleteThumb.x = slideToDelete.trackMargin;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    DoctorDetail {
        anchors.fill: parent
        visible: root.selectedDoctorId >= 0
        hospitalId: root.hospital ? root.hospital.id : -1
        doctorId: root.selectedDoctorId
        onBackRequested: root.selectedDoctorId = -1
    }
}
