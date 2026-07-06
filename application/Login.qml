pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import MediSyncAdmin

Item {
    id: root
    signal loginSucceeded

    property bool busy: false
    property string stage: "email"
    property string currentEmail: ""
    property bool showFailure: false
    property string statusMessage: ""

    readonly property var glyphs: ["雷", "龍", "火", "水", "風", "月", "星", "夢", "侍", "魂", "剣", "神"]
    readonly property bool emailValid: emailField.text.indexOf("@") > 0 && emailField.text.trim().length > 2

    function letterFor(email) {
        return email && email.length > 0 ? email.charAt(0).toUpperCase() : "?";
    }

    function submitEmail() {
        if (!root.emailValid) {
            shakeAnimation.start();
            Sfx.playBack();
            return;
        }
        root.currentEmail = emailField.text.trim();
        root.stage = "password";
        passwordInput.text = "";
        passwordFocusTimer.start();
        Sfx.playChangePane();
    }

    function backToEmail() {
        if (root.busy)
            return;
        passwordInput.text = "";
        root.statusMessage = "";
        root.showFailure = false;
        root.stage = "email";
        emailFocusTimer.start();
        Sfx.playBack();
    }

    focus: true
    Component.onCompleted: {
        root.forceActiveFocus();
        emailField.forceActiveFocus();

        ApiClient.loginFinished.connect(function (success, message) {
            root.busy = false;
            root.statusMessage = message;
            if (success) {
                root.loginSucceeded();
            } else {
                root.showFailure = true;
                passwordInput.text = "";
                shakeAnimation.start();
                Sfx.playBack();
                failureResetTimer.restart();
                passwordInput.forceActiveFocus();
            }
        });
    }

    Timer {
        id: failureResetTimer
        interval: 1200
        onTriggered: root.showFailure = false
    }

    Timer {
        id: passwordFocusTimer
        interval: 180
        onTriggered: passwordInput.forceActiveFocus()
    }

    Timer {
        id: emailFocusTimer
        interval: 180
        onTriggered: emailField.forceActiveFocus()
    }

    Text {
        id: appTitle
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 44
        }
        text: "MediSync Admin"
        font.pixelSize: 40
        font.bold: true
        color: Theme.onSurface
        opacity: root.stage === "password" ? 0.95 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }
    }

    Item {
        id: emailStage
        anchors.fill: parent
        opacity: root.stage === "email" ? 1 : 0
        enabled: root.stage === "email"
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        Column {
            anchors.centerIn: parent
            width: 340
            spacing: 28

            Column {
                width: parent.width
                spacing: 6

                Text {
                    text: "Welcome back"
                    font.pixelSize: 20
                    font.bold: true
                    color: Theme.onSurface
                }
                Text {
                    text: "Sign in with your admin email"
                    font.pixelSize: 13
                    color: Theme.onSurfaceVariant
                }
            }

            Rectangle {
                id: emailCard
                width: parent.width
                height: 52
                radius: 12
                color: Theme.surfaceContainerHigh
                border.width: emailField.activeFocus ? 2 : 1
                border.color: root.showFailure ? Theme.errorColor : (emailField.activeFocus ? Theme.primaryColor : Theme.outlineVariant)

                Behavior on border.color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "＠"
                        font.pixelSize: 16
                        color: emailField.activeFocus ? Theme.primaryColor : Theme.onSurfaceVariant

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                    }

                    TextField {
                        id: emailField
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 26
                        height: parent.height
                        font.pixelSize: 16
                        color: Theme.onSurface
                        placeholderText: "you@hospital.org"
                        placeholderTextColor: Theme.onSurfaceVariant
                        selectByMouse: true
                        selectionColor: Theme.primaryColor
                        background: Item {}
                        leftPadding: 0
                        rightPadding: 0
                        topPadding: 0
                        bottomPadding: 0
                        verticalAlignment: TextInput.AlignVCenter
                        Keys.onReturnPressed: root.submitEmail()
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 46
                radius: 12
                color: root.emailValid ? Theme.primaryColor : Theme.surfaceContainerHigh
                opacity: emailField.text.length > 0 ? 1.0 : 0.6

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "Continue"
                    font.pixelSize: 14
                    font.bold: true
                    color: root.emailValid ? Theme.onPrimary : Theme.onSurfaceVariant
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.submitEmail()
                }
            }
        }

        Text {
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin: 32
            }
            text: "Enter to continue"
            font.pixelSize: 13
            color: Theme.onSurfaceVariant
            opacity: 0.7
        }
    }

    Item {
        id: passwordStage
        anchors.fill: parent
        opacity: root.stage === "password" ? 1 : 0
        enabled: root.stage === "password"
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        Text {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: 128
            }
            text: root.currentEmail
            font.pixelSize: 22
            font.bold: true
            color: Theme.onSurfaceVariant
        }

        Item {
            id: avatarShake
            anchors.centerIn: parent
            width: 200
            height: 200

            SequentialAnimation {
                id: shakeAnimation
                NumberAnimation {
                    target: avatarShake
                    property: "x"
                    to: -10
                    duration: 45
                }
                NumberAnimation {
                    target: avatarShake
                    property: "x"
                    to: 10
                    duration: 90
                }
                NumberAnimation {
                    target: avatarShake
                    property: "x"
                    to: -6
                    duration: 90
                }
                NumberAnimation {
                    target: avatarShake
                    property: "x"
                    to: 0
                    duration: 60
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 20
                height: parent.height + 20
                radius: width / 2
                color: "transparent"
                border.color: root.showFailure ? Theme.errorColor : Theme.primaryFixedDim
                border.width: 1
                opacity: 0.3
            }

            Repeater {
                model: passwordInput.text.length

                delegate: Item {
                    id: orbitChar
                    required property int index

                    readonly property real orbitRadius: 118 + (orbitChar.index % 2) * 12
                    readonly property real baseAngle: orbitChar.index * 360 / Math.max(passwordInput.text.length, 1)

                    property real rotationOffset: 0

                    x: 100 + Math.cos((baseAngle + rotationOffset) * Math.PI / 180) * orbitRadius - 12
                    y: 100 + Math.sin((baseAngle + rotationOffset) * Math.PI / 180) * orbitRadius - 12
                    width: 24
                    height: 24
                    opacity: 0

                    Text {
                        anchors.centerIn: parent
                        text: root.glyphs[orbitChar.index % root.glyphs.length]
                        font.pixelSize: orbitChar.index % 2 === 0 ? 18 : 16
                        color: root.showFailure ? Theme.errorColor : Theme.primaryFixedDim
                        style: Text.Outline
                        styleColor: Theme.backgroundColor
                        opacity: orbitChar.index % 2 === 0 ? 0.75 : 0.45
                    }

                    Component.onCompleted: orbitChar.opacity = 1

                    NumberAnimation on rotationOffset {
                        from: 0
                        to: orbitChar.index % 2 === 0 ? 360 : -360
                        duration: 18000 + orbitChar.index * 500
                        loops: Animation.Infinite
                        running: true
                        easing.type: Easing.Linear
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 400
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            ShapeCanvas {
                id: avatarShapeCanvas
                anchors.fill: parent
                roundedPolygon: GetMShapes.get(19)
                color: root.showFailure ? Theme.errorColor : Theme.primaryContainerColor
                borderWidth: 3
                borderColor: root.showFailure ? Theme.errorColor : Theme.primaryFixedColor

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: root.letterFor(root.currentEmail)
                    font.pixelSize: 64
                    font.weight: Font.Light
                    color: root.showFailure ? Theme.onError : Theme.onPrimaryContainer
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: passwordInput.forceActiveFocus()
                }
            }
        }

        TextInput {
            id: passwordInput
            visible: false
            enabled: !root.busy
            echoMode: TextInput.Password

            onAccepted: {
                if (passwordInput.text.length === 0 || root.busy)
                    return;
                root.busy = true;
                root.statusMessage = "";
                root.showFailure = false;
                Sfx.playEnter();
                ApiClient.login(root.currentEmail, passwordInput.text);
            }

            Keys.onEscapePressed: root.backToEmail()
        }

        Text {
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin: 56
            }
            text: root.busy ? "Logging in..." : (root.statusMessage.length > 0 ? root.statusMessage : "Press Enter to login")
            font.pixelSize: 14
            font.weight: Font.Light
            color: root.showFailure ? Theme.errorColor : Theme.primaryFixedDim
            opacity: passwordInput.text.length > 0 || root.busy || root.statusMessage.length > 0 ? 0.85 : 0.4

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
        }

        Text {
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin: 28
            }
            text: "Esc to edit email"
            font.pixelSize: 13
            color: Theme.onSurfaceVariant
            opacity: 0.6
        }
    }
}
