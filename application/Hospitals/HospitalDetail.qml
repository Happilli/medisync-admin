pragma ComponentBehavior: Bound
import QtQuick
import MediSyncAdmin

Item {
    id: root

    property var hospital: null

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
        visible: root.hospital !== null
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
                                text: (fieldItem.modelData.value ?? "") !== "" ? String(fieldItem.modelData.value) : "—"
                                font.pixelSize: 16
                                color: Theme.onSurface
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }
    }
}
