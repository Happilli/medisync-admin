pragma ComponentBehavior: Bound
import QtQuick
import MediSyncAdmin

FocusScope {
    id: root

    property bool focusRequested: false
    property bool busy: false
    property bool succeeded: false
    property string statusMessage: ""
    property bool statusIsError: false

    onFocusRequestedChanged: if (root.focusRequested)
        root.forceActiveFocus()

    Component.onCompleted: {
        ApiClient.requestFinished.connect(function (requestId, success, data, message) {
            if (requestId !== "createHospital") {
                return;
            }
            root.busy = false;
            if (success) {
                root.succeeded = true;
                root.statusIsError = false;
                root.statusMessage = data && data.message ? data.message : "Hospital created successfully.";
                Sfx.playEnter();
            } else {
                root.statusIsError = true;
                root.statusMessage = message;
            }
        });
    }

    function resetForm() {
        nameField.text = "";
        emailField.text = "";
        passwordField.text = "";
        addressField.text = "";
        phoneField.text = "";
        registrationField.text = "";
        websiteField.text = "";
        descriptionField.text = "";
        root.succeeded = false;
        root.statusMessage = "";
        root.statusIsError = false;
    }

    readonly property bool formValid: nameField.text.trim().length > 0 && registrationField.text.trim().length > 0 && addressField.text.trim().length > 0 && phoneField.text.trim().length > 0 && emailField.text.indexOf("@") > 0 && passwordField.text.length >= 6

    function submit() {
        if (root.busy || !root.formValid) {
            return;
        }
        root.busy = true;
        root.statusIsError = false;
        root.statusMessage = "";
        ApiClient.post("/hospitals/register", "createHospital", {
            email: emailField.text.trim(),
            password: passwordField.text,
            name: nameField.text.trim(),
            address: addressField.text.trim(),
            phone: phoneField.text.trim(),
            registration_number: registrationField.text.trim(),
            website: websiteField.text.trim(),
            description: descriptionField.text.trim()
        });
    }

    Rectangle {
        radius: 20
        anchors.fill: parent
        color: Theme.surfaceContainer
    }

    Item {
        anchors.centerIn: parent
        width: Math.min(728, parent.width - 84)
        height: root.succeeded ? successColumn.height : mainColumn.height

        Column {
            id: mainColumn
            width: parent.width
            spacing: 36
            visible: !root.succeeded

            Column {
                width: parent.width
                spacing: 5

                Text {
                    text: "New hospital"
                    font.pixelSize: 36
                    font.bold: true
                    color: Theme.onSurface
                }
                Text {
                    text: "Fill in the details below to register a hospital"
                    font.pixelSize: 17
                    color: Theme.onSurfaceVariant
                }
            }

            Column {
                width: parent.width
                spacing: 21

                FormField {
                    id: nameField
                    width: parent.width
                    label: "Hospital name"
                    icon: "assets/icons/hospital.svg"
                    shapeIndex: 4
                    fieldHeight: 62
                    iconBoxSize: 36
                    iconSize: 18
                    labelFontSize: 16
                    inputFontSize: 20
                }

                Row {
                    width: parent.width
                    spacing: 21
                    FormField {
                        id: registrationField
                        width: (parent.width - 21) / 2
                        label: "Registration number"
                        icon: "assets/icons/registration.svg"
                        shapeIndex: 12
                        fieldHeight: 62
                        iconBoxSize: 36
                        iconSize: 18
                        labelFontSize: 16
                        inputFontSize: 20
                    }
                    FormField {
                        id: phoneField
                        width: (parent.width - 21) / 2
                        label: "Phone"
                        icon: "assets/icons/phone.svg"
                        shapeIndex: 5
                        fieldHeight: 62
                        iconBoxSize: 36
                        iconSize: 18
                        labelFontSize: 16
                        inputFontSize: 20
                    }
                }

                FormField {
                    id: addressField
                    width: parent.width
                    label: "Address"
                    icon: "assets/icons/address.svg"
                    shapeIndex: 18
                    fieldHeight: 62
                    iconBoxSize: 36
                    iconSize: 18
                    labelFontSize: 16
                    inputFontSize: 20
                }

                FormField {
                    id: websiteField
                    width: parent.width
                    label: "Website (optional)"
                    icon: "assets/icons/website.svg"
                    shapeIndex: 31
                    fieldHeight: 62
                    iconBoxSize: 36
                    iconSize: 18
                    labelFontSize: 16
                    inputFontSize: 20
                }

                Row {
                    width: parent.width
                    spacing: 21
                    FormField {
                        id: emailField
                        width: (parent.width - 21) / 2
                        label: "Login email"
                        icon: "assets/icons/email.svg"
                        shapeIndex: 15
                        fieldHeight: 62
                        iconBoxSize: 36
                        iconSize: 18
                        labelFontSize: 16
                        inputFontSize: 20
                    }
                    FormField {
                        id: passwordField
                        width: (parent.width - 21) / 2
                        label: "Login password"
                        icon: "assets/icons/password.svg"
                        echoMode: TextInput.Password
                        shapeIndex: 33
                        fieldHeight: 62
                        iconBoxSize: 36
                        iconSize: 18
                        labelFontSize: 16
                        inputFontSize: 20
                    }
                }

                FormField {
                    id: descriptionField
                    width: parent.width
                    label: "Description (optional)"
                    icon: "assets/icons/description.svg"
                    shapeIndex: 22
                    fieldHeight: 62
                    iconBoxSize: 36
                    iconSize: 18
                    labelFontSize: 16
                    inputFontSize: 20
                }
            }

            Text {
                visible: root.statusIsError && root.statusMessage.length > 0
                width: parent.width
                text: root.statusMessage
                font.pixelSize: 17
                color: Theme.errorColor
                wrapMode: Text.WordWrap
            }

            Row {
                width: parent.width
                layoutDirection: Qt.RightToLeft

                Rectangle {
                    width: 234
                    height: 62
                    radius: 12
                    color: (root.busy || !root.formValid) ? Theme.surfaceContainerHigh : Theme.primaryColor
                    opacity: (root.busy || !root.formValid) ? 0.7 : 1

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.busy ? "Creating..." : "Create Hospital"
                        font.pixelSize: 18
                        font.bold: true
                        color: (root.busy || !root.formValid) ? Theme.onSurfaceVariant : Theme.onPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.busy && root.formValid
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Sfx.playEnter();
                            root.submit();
                        }
                    }
                }
            }
        }

        Column {
            id: successColumn
            width: parent.width
            spacing: 31
            visible: root.succeeded

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 125
                height: 125
                radius: 62
                color: Theme.primaryContainerColor
                border.width: 3
                border.color: Theme.primaryFixedColor

                Text {
                    anchors.centerIn: parent
                    text: "✓"
                    font.pixelSize: 52
                    font.bold: true
                    color: Theme.onPrimaryContainer
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Hospital created"
                font.pixelSize: 29
                font.bold: true
                color: Theme.onSurface
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(546, parent.width)
                horizontalAlignment: Text.AlignHCenter
                text: root.statusMessage
                font.pixelSize: 17
                color: Theme.onSurfaceVariant
                wrapMode: Text.WordWrap
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 260
                height: 60
                radius: 12
                color: Theme.primaryColor

                Text {
                    anchors.centerIn: parent
                    text: "Add another hospital"
                    font.pixelSize: 18
                    font.bold: true
                    color: Theme.onPrimary
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Sfx.playChangePane();
                        root.resetForm();
                    }
                }
            }
        }
    }
}
