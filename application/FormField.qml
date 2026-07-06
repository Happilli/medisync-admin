import QtQuick
import QtQuick.Controls.Basic
import MediSyncAdmin

Column {
    id: root

    property string label: ""
    property string icon: ""
    property alias text: fieldInput.text
    property alias echoMode: fieldInput.echoMode
    property int shapeIndex: 0
    property real fieldHeight: 48
    property real iconBoxSize: 28
    property real iconSize: 14
    property real labelFontSize: 12
    property real inputFontSize: 15

    readonly property bool isFilled: fieldInput.text.trim().length > 0

    spacing: 6

    Text {
        text: root.label
        font.pixelSize: root.labelFontSize
        font.bold: true
        color: Theme.onSurfaceVariant
    }

    Rectangle {
        width: parent.width
        height: root.fieldHeight
        radius: 12
        color: Theme.surfaceContainerHigh
        border.width: fieldInput.activeFocus ? 2 : (root.isFilled ? 2 : 1)
        border.color: fieldInput.activeFocus ? Theme.primaryColor : (root.isFilled ? Theme.tertiaryColor : Theme.outlineVariant)

        Behavior on border.color {
            ColorAnimation {
                duration: 150
            }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 16
            spacing: 10

            Item {
                visible: root.icon.length > 0
                width: visible ? root.iconBoxSize : 0
                height: root.iconBoxSize
                anchors.verticalCenter: parent.verticalCenter

                ShapeCanvas {
                    anchors.fill: parent
                    color: fieldInput.activeFocus ? Theme.primaryColor : (root.isFilled ? Theme.tertiaryColor : Theme.surfaceContainerHighest)
                    borderWidth: 0
                    roundedPolygon: GetMShapes.get(root.shapeIndex)

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                Icon {
                    anchors.centerIn: parent
                    iconSize: root.iconSize
                    source: root.icon
                    visible: !root.isFilled || fieldInput.activeFocus
                    color: fieldInput.activeFocus ? Theme.onPrimary : Theme.onSurfaceVariant

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.isFilled && !fieldInput.activeFocus
                    text: "✓"
                    font.pixelSize: root.iconSize
                    font.bold: true
                    color: Theme.onTertiary

                    opacity: visible ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                }
            }

            TextField {
                id: fieldInput
                width: parent.width - (root.icon.length > 0 ? (root.iconBoxSize + 10) : 0)
                height: parent.height
                anchors.verticalCenter: parent.verticalCenter
                verticalAlignment: TextInput.AlignVCenter
                font.pixelSize: root.inputFontSize
                color: Theme.onSurface
                selectByMouse: true
                selectionColor: Theme.primaryColor
                background: Item {}
                leftPadding: 0
                rightPadding: 0
                topPadding: 0
                bottomPadding: 0
            }
        }
    }
}
