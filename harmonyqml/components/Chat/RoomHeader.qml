import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../Base"

HRectangle {
    property string displayName: ""
    property string topic: ""

    property alias buttonsImplicitWidth: viewButtons.implicitWidth

    property bool collapseButtons: width < 400

    id: roomHeader
    color: HStyle.chat.roomHeader.background

    HRowLayout {
        id: row
        spacing: 8
        anchors.fill: parent

        HAvatar {
            id: avatar
            name: displayName
            dimension: roomHeader.height
            Layout.alignment: Qt.AlignTop
        }

        HLabel {
            id: roomName
            text: displayName
            font.pixelSize: HStyle.fontSize.big
            elide: Text.ElideRight
            maximumLineCount: 1

            Layout.maximumWidth: Math.max(
                0,
                row.width - Layout.leftMargin * 2 - avatar.width -
                viewButtons.width -
                (expandButton.visible ? expandButton.width : 0)
            )
        }

        HLabel {
            id: roomTopic
            text: topic
            font.pixelSize: HStyle.fontSize.small
            elide: Text.ElideRight
            maximumLineCount: 1

            Layout.maximumWidth: Math.max(
                0,
                row.width - row.totalSpacing - avatar.width -
                roomName.width - viewButtons.width -
                (expandButton.visible ? expandButton.width : 0)
            )
        }

        HSpacer {}

        Row {
            id: viewButtons
            Layout.preferredWidth: collapseButtons ? 0 : implicitWidth

            HButton {
                iconName: "room_view_members"
            }

            HButton {
                iconName: "room_view_files"
            }

            HButton {
                iconName: "room_view_notifications"
            }

            HButton {
                iconName: "room_view_history"
            }

            HButton {
                iconName: "room_view_settings"
            }

            Behavior on Layout.preferredWidth {
                NumberAnimation { id: buttonsAnimation; duration: 120 }
            }
        }
    }

    HButton {
        id: expandButton
        z: 1
        anchors.right: parent.right
        opacity: collapseButtons ? 1 : 0
        visible: opacity > 0
        iconName: "reduced_room_buttons"

        Behavior on opacity {
            NumberAnimation { duration: buttonsAnimation.duration * 2 }
        }
    }
}
