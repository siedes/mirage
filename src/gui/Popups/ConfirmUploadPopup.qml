// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../Base/Buttons"

HColumnPopup {
    id: popup

    property string userId
    property string roomId
    property string roomName
    property string filePath

    readonly property string fileName: filePath.split("/").slice(-1)[0]


    contentWidthLimit: theme.controls.popup.defaultWidth * 1.25

    page.footer: AutoDirectionLayout {
        ApplyButton {
            id: uploadButton
            text: qsTr("Send")
            icon.name: "confirm-uploading-file"
            onClicked: {
                py.callClientCoro(
                    popup.userId, "send_file", [popup.roomId, filePath],
                )
                popup.close()
            }
        }

        CancelButton {
            id: cancelButton
            onClicked: popup.close()
        }
    }

    onOpened: uploadButton.forceActiveFocus()

    SummaryLabel {
        text:
            qsTr("Send %1 to %2?")
            .arg(utils.htmlColorize(fileName, theme.colors.accentText))
            .arg(utils.htmlColorize(roomName, theme.colors.accentText))

        textFormat: Text.StyledText
    }

    HImage {
        source:
            popup.filePath.startsWith("file://") ?
            popup.filePath :
            "file://" + popup.filePath

        visible: status !== Image.Error
        sourceSize.width: popup.contentWidthLimit

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight:
            status === Image.Ready ?
            width / (implicitWidth / implicitHeight) :
            96 * theme.uiScale  // for spinner

        Behavior on Layout.preferredHeight { HNumberAnimation {} }
    }
}
