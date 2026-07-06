pragma ComponentBehavior: Bound
import QtQuick
import MediSyncAdmin

Item {
    id: root

    property var patient: null
    readonly property bool hasCitizenshipPhoto: !!(root.patient && root.patient.citizenship_photo_url)

    Text {
        visible: root.patient === null
        anchors.centerIn: parent
        text: "Select a patient to review"
        font.pixelSize: 16
        color: Theme.onSurfaceVariant
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 40
        visible: root.patient !== null
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
                    text: "Patient Review"
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.primaryFixedDim
                    font.letterSpacing: 1.5
                }

                Text {
                    text: root.patient ? (root.patient.name ?? "") : ""
                    font.pixelSize: 34
                    font.bold: true
                    color: Theme.onSurface
                }

                Text {
                    text: root.patient ? ("Patient ID: " + String(root.patient.id)) : ""
                    font.pixelSize: 13
                    color: Theme.onSurfaceVariant
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
                        model: root.patient ? [
                            {
                                label: "Phone",
                                value: root.patient.phone
                            },
                            {
                                label: "Address",
                                value: root.patient.address
                            },
                            {
                                label: "Date of birth",
                                value: root.patient.date_of_birth
                            },
                            {
                                label: "Gender",
                                value: root.patient.gender
                            },
                            {
                                label: "Blood group",
                                value: root.patient.blood_group
                            },
                            {
                                label: "Emergency contact",
                                value: root.patient.emergency_contact
                            },
                            {
                                label: "Citizenship no.",
                                value: root.patient.citizenship_number
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
                                text: (fieldItem.modelData.value ?? "") !== "" ? String(fieldItem.modelData.value) : "—"
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
                spacing: 14
                visible: root.hasCitizenshipPhoto

                Text {
                    text: "Citizenship photo"
                    font.pixelSize: 16
                    font.bold: true
                    color: Theme.onSurface
                }

                Rectangle {
                    id: photoFrame
                    width: Math.min(420, parent.width)
                    height: 260
                    color: Theme.surfaceContainerHighest
                    radius: 20
                    clip: true
                    border.width: 1
                    border.color: Theme.outlineVariant

                    Image {
                        id: citizenshipImage
                        anchors.fill: parent
                        anchors.margins: 2
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        source: root.hasCitizenshipPhoto ? "image://authimg/" + root.patient.citizenship_photo_url : ""
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: citizenshipImage.status === Image.Loading
                        text: "Loading…"
                        font.pixelSize: 13
                        color: Theme.onSurfaceVariant
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: citizenshipImage.status === Image.Error
                        text: "Could not load image"
                        font.pixelSize: 13
                        color: Theme.errorColor
                    }

                    MouseArea {
                        id: zoomArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                        cursorShape: Qt.CrossCursor
                    }

                    Rectangle {
                        id: lens
                        width: 170
                        height: 170
                        radius: width / 2
                        clip: true
                        border.width: 2
                        border.color: Theme.primaryColor
                        color: Theme.surfaceContainerHighest
                        visible: zoomArea.containsMouse && citizenshipImage.status === Image.Ready

                        readonly property real localX: zoomArea.mouseX - citizenshipImage.x
                        readonly property real localY: zoomArea.mouseY - citizenshipImage.y
                        readonly property real offsetX: (citizenshipImage.width - citizenshipImage.paintedWidth) / 2
                        readonly property real offsetY: (citizenshipImage.height - citizenshipImage.paintedHeight) / 2
                        readonly property real fx: citizenshipImage.paintedWidth > 0 ? Math.min(Math.max((lens.localX - lens.offsetX) / citizenshipImage.paintedWidth, 0), 1) : 0
                        readonly property real fy: citizenshipImage.paintedHeight > 0 ? Math.min(Math.max((lens.localY - lens.offsetY) / citizenshipImage.paintedHeight, 0), 1) : 0
                        readonly property real zoomFactor: 2.5

                        x: Math.min(Math.max(zoomArea.mouseX - width / 2, 0), photoFrame.width - width)
                        y: Math.min(Math.max(zoomArea.mouseY - height / 2, 0), photoFrame.height - height)

                        Image {
                            id: zoomedImage
                            source: citizenshipImage.source
                            width: citizenshipImage.paintedWidth * lens.zoomFactor
                            height: citizenshipImage.paintedHeight * lens.zoomFactor
                            x: lens.width / 2 - lens.fx * width
                            y: lens.height / 2 - lens.fy * height
                            smooth: true
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 16
                visible: root.patient !== null

                Text {
                    text: "Finalize"
                    font.pixelSize: 16
                    font.bold: true
                    color: Theme.onSurface
                }

                Item {
                    id: slideToVerify
                    width: Math.min(420, parent.width)
                    height: 68

                    property bool confirmed: false
                    property bool dragging: false
                    readonly property real trackMargin: 6
                    readonly property real thumbWidth: 58
                    readonly property int snapDuration: 260
                    readonly property real maxX: slideToVerify.width - slideToVerify.thumbWidth - slideToVerify.trackMargin
                    readonly property real progress: Math.max(0, Math.min(1, (thumb.x - slideToVerify.trackMargin) / Math.max(1, slideToVerify.maxX - slideToVerify.trackMargin)))

                    function reset() {
                        slideToVerify.confirmed = false;
                        thumb.x = slideToVerify.trackMargin;
                    }

                    onVisibleChanged: if (visible)
                        slideToVerify.reset()

                    Connections {
                        target: root
                        function onPatientChanged() {
                            slideToVerify.reset();
                        }
                    }

                    Rectangle {
                        id: track
                        anchors.fill: parent
                        radius: height / 2
                        color: Theme.surfaceContainerHighest
                        border.width: 1
                        border.color: Theme.outlineVariant
                    }

                    Rectangle {
                        id: fill
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: slideToVerify.trackMargin
                        width: Math.max(0, thumb.x - slideToVerify.trackMargin + slideToVerify.thumbWidth / 2)
                        radius: height / 2
                        color: Theme.primaryContainerColor
                        opacity: 0.55
                    }

                    Text {
                        anchors.centerIn: parent
                        text: slideToVerify.confirmed ? "Verified" : "Slide to verify patient"
                        font.pixelSize: 15
                        font.bold: true
                        color: Theme.onSurfaceVariant
                        opacity: slideToVerify.confirmed ? 1 : Math.max(0, 1 - slideToVerify.progress * 1.6)

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Item {
                        id: thumb
                        width: slideToVerify.thumbWidth
                        height: parent.height - slideToVerify.trackMargin * 2
                        y: slideToVerify.trackMargin
                        x: slideToVerify.trackMargin

                        Behavior on x {
                            enabled: !slideToVerify.dragging
                            NumberAnimation {
                                duration: slideToVerify.snapDuration
                                easing.type: Easing.OutCubic
                            }
                        }

                        ShapeCanvas {
                            anchors.fill: parent
                            color: Theme.primaryColor
                            borderWidth: slideToVerify.dragging ? 3 : 1
                            borderColor: Theme.primaryFixedColor
                            roundedPolygon: slideToVerify.confirmed ? GetMShapes.get(19) : (slideToVerify.dragging ? GetMShapes.get(26) : GetMShapes.get(8))
                            animation: NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: slideToVerify.confirmed ? "✓" : "›"
                            font.pixelSize: 22
                            font.bold: true
                            color: Theme.onPrimary
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !slideToVerify.confirmed
                            cursorShape: Qt.PointingHandCursor
                            drag.target: thumb
                            drag.axis: Drag.XAxis
                            drag.minimumX: slideToVerify.trackMargin
                            drag.maximumX: slideToVerify.maxX

                            onPressed: slideToVerify.dragging = true
                            onReleased: {
                                slideToVerify.dragging = false;
                                if (thumb.x >= slideToVerify.maxX * 0.9) {
                                    thumb.x = slideToVerify.maxX;
                                    slideToVerify.confirmed = true;
                                    Sfx.playEnter();
                                    if (root.patient) {
                                        ApiClient.post("/patients/" + root.patient.id + "/verify", "verifyPatient:" + root.patient.id);
                                    }
                                } else {
                                    thumb.x = slideToVerify.trackMargin;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
