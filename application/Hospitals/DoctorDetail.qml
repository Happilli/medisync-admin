pragma ComponentBehavior: Bound
import QtQuick
import MediSyncAdmin
import QtQuick.Effects

FocusScope {
    id: root

    signal backRequested

    property int hospitalId: -1
    property int doctorId: -1
    property var doctorData: null
    property bool loading: false
    property string loadError: ""

    readonly property bool hasLicensePhoto: !!(root.doctorData && root.doctorData.license_photo_url)

    focus: true

    onDoctorIdChanged: root.fetchDoctor()
    onVisibleChanged: if (root.visible) {
        root.fetchDoctor();
        root.forceActiveFocus();
    }

    Keys.onEscapePressed: root.backRequested()

    function fetchDoctor() {
        if (root.hospitalId < 0 || root.doctorId < 0) {
            return;
        }
        root.loading = true;
        root.loadError = "";
        root.doctorData = null;
        ApiClient.get("/hospitals/" + root.hospitalId + "/doctors/" + root.doctorId, "doctorDetail:" + root.doctorId);
    }

    Connections {
        target: ApiClient
        function onRequestFinished(requestId, success, data, message) {
            if (requestId === "doctorDetail:" + root.doctorId) {
                root.loading = false;
                if (success) {
                    root.doctorData = data;
                } else {
                    root.loadError = message;
                }
            } else if (requestId === "verifyDoctor:" + root.doctorId) {
                if (success) {
                    root.backRequested();
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surfaceContainer
    }

    Text {
        visible: root.loading
        anchors.centerIn: parent
        text: "Loading…"
        font.pixelSize: 14
        color: Theme.onSurfaceVariant
    }
    Text {
        visible: !root.loading && root.loadError.length > 0
        anchors.centerIn: parent
        text: root.loadError
        font.pixelSize: 14
        color: Theme.errorColor
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 40
        visible: !root.loading && root.doctorData !== null
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
                    text: "Doctor Review"
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.primaryFixedDim
                    font.letterSpacing: 1.5
                }
                Text {
                    text: root.doctorData ? (root.doctorData.name ?? "") : ""
                    font.pixelSize: 34
                    font.bold: true
                    color: Theme.onSurface
                }
                Text {
                    text: root.doctorData ? ("Doctor ID: " + String(root.doctorData.id)) : ""
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
                        model: root.doctorData ? [
                            {
                                label: "Phone",
                                value: root.doctorData.phone
                            },
                            {
                                label: "Department",
                                value: root.doctorData.department
                            },
                            {
                                label: "Speciality",
                                value: root.doctorData.speciality
                            },
                            {
                                label: "Address",
                                value: root.doctorData.address
                            },
                            {
                                label: "Years experience",
                                value: root.doctorData.years_experience
                            },
                            {
                                label: "License number",
                                value: root.doctorData.license_number
                            },
                            {
                                label: "Bio",
                                value: root.doctorData.bio
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
                spacing: 14
                visible: root.hasLicensePhoto

                Text {
                    text: "License photo"
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
                        id: licenseImage
                        anchors.fill: parent
                        anchors.margins: 2
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        source: root.hasLicensePhoto ? "image://authimg/" + root.doctorData.license_photo_url : ""
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: licenseImage.status === Image.Loading
                        text: "Loading…"
                        font.pixelSize: 13
                        color: Theme.onSurfaceVariant
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: licenseImage.status === Image.Error
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
                        clip: false
                        color: Theme.surfaceContainerHighest
                        visible: zoomArea.containsMouse && licenseImage.status === Image.Ready

                        readonly property real localX: zoomArea.mouseX - licenseImage.x
                        readonly property real localY: zoomArea.mouseY - licenseImage.y
                        readonly property real offsetX: (licenseImage.width - licenseImage.paintedWidth) / 2
                        readonly property real offsetY: (licenseImage.height - licenseImage.paintedHeight) / 2
                        readonly property real fx: licenseImage.paintedWidth > 0 ? Math.min(Math.max((lens.localX - lens.offsetX) / licenseImage.paintedWidth, 0), 1) : 0
                        readonly property real fy: licenseImage.paintedHeight > 0 ? Math.min(Math.max((lens.localY - lens.offsetY) / licenseImage.paintedHeight, 0), 1) : 0
                        readonly property real zoomFactor: 2.5

                        x: Math.min(Math.max(zoomArea.mouseX - width / 2, 0), photoFrame.width - width)
                        y: Math.min(Math.max(zoomArea.mouseY - height / 2, 0), photoFrame.height - height)

                        Item {
                            id: lensContent
                            anchors.fill: parent
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource: lensMask
                            }

                            Image {
                                id: zoomedImage
                                source: licenseImage.source
                                width: licenseImage.paintedWidth * lens.zoomFactor
                                height: licenseImage.paintedHeight * lens.zoomFactor
                                x: lens.width / 2 - lens.fx * width
                                y: lens.height / 2 - lens.fy * height
                                smooth: true
                            }
                        }

                        Rectangle {
                            id: lensMask
                            anchors.fill: parent
                            radius: width / 2
                            visible: false
                            layer.enabled: true
                        }
                    }
                }
            }
            Column {
                width: parent.width
                spacing: 16
                visible: root.doctorData !== null && !root.doctorData.is_verified

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
                    readonly property real maxX: slideToVerify.width - slideToVerify.thumbWidth - slideToVerify.trackMargin
                    readonly property real progress: Math.max(0, Math.min(1, (thumb.x - slideToVerify.trackMargin) / Math.max(1, slideToVerify.maxX - slideToVerify.trackMargin)))

                    function reset() {
                        slideToVerify.confirmed = false;
                        thumb.x = slideToVerify.trackMargin;
                    }

                    Connections {
                        target: root
                        function onDoctorIdChanged() {
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
                        text: slideToVerify.confirmed ? "Verified" : "Slide to verify doctor"
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
                                duration: 260
                                easing.type: Easing.OutCubic
                            }
                        }

                        ShapeCanvas {
                            anchors.fill: parent
                            color: Theme.primaryColor
                            borderWidth: slideToVerify.dragging ? 3 : 1
                            borderColor: Theme.primaryFixedColor
                            roundedPolygon: slideToVerify.confirmed ? GetMShapes.get(19) : (slideToVerify.dragging ? GetMShapes.get(22) : GetMShapes.get(8))
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
                                    ApiClient.patch("/hospitals/" + root.hospitalId + "/doctors/" + root.doctorId + "/verify", "verifyDoctor:" + root.doctorId);
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
