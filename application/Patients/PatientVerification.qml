pragma ComponentBehavior: Bound
import QtQuick
import MediSyncAdmin

FocusScope {
    id: root

    property var pendingPatients: []
    property bool loadingList: false
    property string listError: ""
    property int expandedIndex: -1
    property bool focusRequested: false

    readonly property var accentPalette: [Theme.primaryColor, Theme.secondaryColor, Theme.tertiaryColor, Theme.primaryFixedDim]

    onFocusRequestedChanged: if (root.focusRequested)
        root.forceActiveFocus()

    function accentFor(key) {
        let hash = 0;
        for (let i = 0; i < key.length; i++)
            hash = (hash * 31 + key.charCodeAt(i)) >>> 0;
        return root.accentPalette[hash % root.accentPalette.length];
    }

    function refreshPendingPatients() {
        root.loadingList = true;
        root.listError = "";
        root.expandedIndex = -1;
        ApiClient.get("/patients/pending", "pendingPatients");
    }

    function centerOf(index) {
        const item = patientRepeater.itemAt(index);
        if (!item)
            return null;
        return {
            x: item.x + item.width / 2,
            y: item.y + item.height / 2
        };
    }

    function findNeighbor(fromIndex, direction) {
        const from = root.centerOf(fromIndex);
        if (!from)
            return -1;

        let best = -1;
        let bestScore = Infinity;

        for (let i = 0; i < root.pendingPatients.length; i++) {
            if (i === fromIndex)
                continue;
            const c = root.centerOf(i);
            if (!c)
                continue;

            const dx = c.x - from.x;
            const dy = c.y - from.y;
            let score = -1;

            if (direction === "right" && dx > 1)
                score = dx + Math.abs(dy) * 3;
            else if (direction === "left" && dx < -1)
                score = -dx + Math.abs(dy) * 3;
            else if (direction === "down" && dy > 1)
                score = dy + Math.abs(dx) * 3;
            else if (direction === "up" && dy < -1)
                score = -dy + Math.abs(dx) * 3;

            if (score >= 0 && score < bestScore) {
                bestScore = score;
                best = i;
            }
        }

        return best;
    }

    function moveSelection(direction) {
        if (root.pendingPatients.length === 0)
            return;

        if (root.expandedIndex < 0) {
            root.expandedIndex = 0;
            return;
        }

        const next = root.findNeighbor(root.expandedIndex, direction);
        if (next >= 0)
            root.expandedIndex = next;
    }

    focus: true

    Keys.onRightPressed: root.moveSelection("right")
    Keys.onLeftPressed: root.moveSelection("left")
    Keys.onDownPressed: root.moveSelection("down")
    Keys.onUpPressed: root.moveSelection("up")

    Keys.onEscapePressed: event => {
        if (root.expandedIndex >= 0) {
            root.expandedIndex = -1;
            event.accepted = true;
        } else {
            event.accepted = false;
        }
    }

    Connections {
        target: ApiClient
        function onRequestFinished(requestId, success, data, message) {
            if (requestId === "pendingPatients") {
                root.loadingList = false;
                root.pendingPatients = success ? (data ?? []) : [];
                if (!success)
                    root.listError = message;
                root.expandedIndex = -1;
            } else if (requestId.indexOf("verifyPatient:") === 0) {
                if (success) {
                    root.expandedIndex = -1;
                    root.refreshPendingPatients();
                } else {
                    root.listError = message;
                }
            }
        }
    }

    Component.onCompleted: {
        root.refreshPendingPatients();
    }

    Text {
        visible: root.loadingList
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Syncing…"
        font.pixelSize: 12
        color: Theme.onSurfaceVariant
    }

    Rectangle {
        visible: root.listError.length > 0
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: 380
        height: errText.implicitHeight + 20
        radius: 10
        color: Theme.errorContainerColor

        Text {
            id: errText
            anchors.centerIn: parent
            width: parent.width - 24
            text: root.listError
            color: Theme.onErrorContainer
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Column {
        visible: !root.loadingList && root.listError.length === 0 && root.pendingPatients.length === 0
        anchors.centerIn: parent
        spacing: 8
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "No pending patients."
            color: Theme.onSurfaceVariant
            font.pixelSize: 14
        }
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: avatarFlow.height
        clip: true

        Flow {
            id: avatarFlow
            width: parent.width
            spacing: 26
            topPadding: 8

            Repeater {
                id: patientRepeater
                model: root.pendingPatients

                delegate: Item {
                    id: avatarDelegate
                    required property var modelData
                    required property int index
                    readonly property var patient: avatarDelegate.modelData ?? {}
                    readonly property color accent: root.accentFor((avatarDelegate.patient.id ?? avatarDelegate.patient.name ?? "x") + "")
                    readonly property bool isExpanded: root.expandedIndex === avatarDelegate.index

                    property real letterOpacity: 1
                    property real detailOpacity: 0
                    property bool contentSettled: true

                    width: isExpanded ? 340 : 108
                    height: isExpanded ? 220 : 108
                    clip: true

                    Behavior on width {
                        NumberAnimation {
                            duration: 260
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on height {
                        NumberAnimation {
                            duration: 260
                            easing.type: Easing.OutCubic
                        }
                    }

                    function morphContent() {
                        const hideProp = avatarDelegate.isExpanded ? "letterOpacity" : "detailOpacity";
                        const showProp = avatarDelegate.isExpanded ? "detailOpacity" : "letterOpacity";
                        contentFadeOut.target = avatarDelegate;
                        contentFadeOut.property = hideProp;
                        contentFadeIn.target = avatarDelegate;
                        contentFadeIn.property = showProp;
                        contentMorphSeq.restart();
                    }

                    onIsExpandedChanged: avatarDelegate.morphContent()

                    SequentialAnimation {
                        id: contentMorphSeq
                        onStarted: avatarDelegate.contentSettled = false
                        onStopped: avatarDelegate.contentSettled = true

                        NumberAnimation {
                            id: contentFadeOut
                            to: 0
                            duration: 90
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            id: contentFadeIn
                            to: 1
                            duration: 170
                            easing.type: Easing.OutCubic
                        }
                    }

                    Item {
                        id: shapeSquare
                        z: 0
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height)
                        height: width

                        ShapeCanvas {
                            anchors.fill: parent
                            color: avatarDelegate.accent
                            borderWidth: avatarDelegate.isExpanded ? 0 : 2
                            borderColor: Theme.surfaceContainerHighest
                            roundedPolygon: avatarDelegate.isExpanded ? GetMShapes.get(1) : GetMShapes.get(20)

                            animation: NumberAnimation {
                                duration: 260
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Text {
                        z: 2
                        anchors.centerIn: parent
                        text: (avatarDelegate.patient.name ?? "?").charAt(0).toUpperCase()
                        font.pixelSize: 32
                        font.bold: true
                        color: Theme.onPrimary
                        opacity: avatarDelegate.letterOpacity
                        visible: opacity > 0.01
                    }

                    Column {
                        id: detailColumn
                        z: 2
                        anchors.centerIn: parent
                        width: Math.min(avatarDelegate.width - 40, 220)
                        spacing: 8
                        clip: true
                        opacity: avatarDelegate.detailOpacity
                        enabled: avatarDelegate.isExpanded && avatarDelegate.contentSettled
                        visible: opacity > 0.01

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: avatarDelegate.patient.name ?? ""
                            font.pixelSize: 17
                            font.bold: true
                            color: Theme.onPrimary
                            elide: Text.ElideRight
                        }

                        Column {
                            width: parent.width
                            spacing: 2

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: avatarDelegate.patient.phone ?? "no phone"
                                font.pixelSize: 12
                                color: Theme.onPrimary
                                opacity: 0.85
                                elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: avatarDelegate.patient.citizenship_number ?? "no citizenship no."
                                font.pixelSize: 12
                                color: Theme.onPrimary
                                opacity: 0.85
                                elide: Text.ElideRight
                            }
                        }

                        Item {
                            width: parent.width
                            height: 38

                            Rectangle {
                                anchors.centerIn: parent
                                width: 130
                                height: 38
                                radius: 19
                                color: Theme.onPrimary
                                opacity: (verifyMouse.pressed && verifyMouse.enabled) ? 0.75 : 0.95
                                scale: (verifyMouse.pressed && verifyMouse.enabled) ? 0.95 : 1.0

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 100
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 100
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text {
                                        text: "Verify"
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: avatarDelegate.accent
                                    }
                                }

                                MouseArea {
                                    id: verifyMouse
                                    anchors.fill: parent
                                    enabled: avatarDelegate.isExpanded && avatarDelegate.contentSettled
                                    hoverEnabled: avatarDelegate.contentSettled
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const p = avatarDelegate.patient;
                                        ApiClient.post("/patients/" + p.id + "/verify", "verifyPatient:" + p.id);
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        z: -1
                        anchors.centerIn: shapeSquare
                        width: shapeSquare.width
                        height: shapeSquare.height
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.expandedIndex = avatarDelegate.isExpanded ? -1 : avatarDelegate.index;
                            root.forceActiveFocus();
                        }
                    }
                }
            }
        }
    }
}
