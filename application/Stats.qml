pragma ComponentBehavior: Bound
import QtQuick
import MediSyncAdmin

Item {
    id: root

    property var funnelData: null
    property bool loading: false
    property string loadError: ""
    property int activeIndex: 0

    readonly property var allStats: root.funnelData ? [
        {
            label: "Patients registered",
            value: root.funnelData.patients.registered,
            shape: 4
        },
        {
            label: "Patients submitted docs",
            value: root.funnelData.patients.submitted_docs,
            shape: 12
        },
        {
            label: "Patients verified",
            value: root.funnelData.patients.verified,
            shape: 19
        },
        {
            label: "Doctors registered",
            value: root.funnelData.doctors.registered,
            shape: 8
        },
        {
            label: "Doctors verified",
            value: root.funnelData.doctors.verified,
            shape: 22
        }
    ] : []

    readonly property var accentCycle: [Theme.primaryColor, Theme.secondaryColor, Theme.tertiaryColor, Theme.primaryFixedDim, Theme.tertiaryColor]

    readonly property var currentStat: root.allStats.length > 0 ? root.allStats[root.activeIndex % root.allStats.length] : null
    readonly property color currentAccent: root.accentCycle[root.activeIndex % root.accentCycle.length]

    implicitWidth: 480
    implicitHeight: 520

    Component.onCompleted: root.refresh()

    function refresh() {
        root.loading = true;
        root.loadError = "";
        ApiClient.get("/admin/stats/verification-funnel", "verificationFunnel");
    }

    Connections {
        target: ApiClient
        function onRequestFinished(requestId, success, data, message) {
            if (requestId !== "verificationFunnel") {
                return;
            }
            root.loading = false;
            if (success) {
                root.funnelData = data;
                root.activeIndex = 0;
            } else {
                root.loadError = message;
            }
        }
    }

    Timer {
        interval: 2600
        running: root.allStats.length > 0
        repeat: true
        onTriggered: root.activeIndex = (root.activeIndex + 1) % root.allStats.length
    }

    Text {
        visible: root.loading
        anchors.centerIn: parent
        text: "Syncing..."
        font.pixelSize: 16
        color: Theme.onSurfaceVariant
    }
    Text {
        visible: !root.loading && root.loadError.length > 0
        anchors.centerIn: parent
        text: root.loadError
        font.pixelSize: 16
        color: Theme.errorColor
    }

    Item {
        id: card
        width: 440
        height: 440
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40
        rotation: -6
        opacity: 0.55
        visible: !root.loading && root.currentStat !== null

        ShapeCanvas {
            anchors.fill: parent
            color: root.currentAccent
            borderWidth: 0
            roundedPolygon: root.currentStat ? GetMShapes.get(root.currentStat.shape) : GetMShapes.get(0)
            animation: NumberAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }
            Behavior on color {
                ColorAnimation {
                    duration: 400
                }
            }
        }

        Column {
            anchors.centerIn: parent
            width: parent.width - 60
            spacing: 12

            Text {
                id: valueText
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.currentStat ? String(root.currentStat.value) : ""
                font.pixelSize: 104
                font.bold: true
                color: Theme.onPrimary

                Behavior on text {
                    SequentialAnimation {
                        NumberAnimation {
                            target: valueText
                            property: "opacity"
                            to: 0
                            duration: 150
                        }
                        PropertyAction {}
                        NumberAnimation {
                            target: valueText
                            property: "opacity"
                            to: 1
                            duration: 150
                        }
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.currentStat ? root.currentStat.label : ""
                font.pixelSize: 20
                font.bold: true
                color: Theme.onPrimary
                wrapMode: Text.WordWrap
            }
        }
    }
}
