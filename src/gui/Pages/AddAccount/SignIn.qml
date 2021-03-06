// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HBox {
    id: signInBox
    clickButtonOnEnter: "apply"

    onFocusChanged: idField.field.forceActiveFocus()

    buttonModel: [
        {
            name: "apply",
            text: qsTr("Sign in"),
            enabled: canSignIn,
            iconName: "sign-in",
            loading: loginFuture !== null,
            disableWhileLoading: false,
        },
        { name: "cancel", text: qsTr("Cancel"), iconName: "cancel"},
    ]

    buttonCallbacks: ({
        apply: button => {
            if (loginFuture) loginFuture.cancel()

            signInTimeout.restart()

            errorMessage.text = ""

            const args = [
                idField.field.text.trim(), passwordField.field.text,
                undefined, serverField.field.text.trim(),
            ]

            loginFuture = py.callCoro("login_client", args, userId => {
                signInTimeout.stop()
                errorMessage.text = ""
                loginFuture       = null

                py.callCoro(
                    rememberAccount.checked ?
                    "saved_accounts.add": "saved_accounts.delete",

                    [userId]
                )

                pageLoader.showPage(
                    "AccountSettings/AccountSettings", {userId}
                )

            }, (type, args, error, traceback, uuid) => {
                loginFuture = null
                signInTimeout.stop()

                let txt = qsTr(
                    "Invalid request, login type or unknown error: %1",
                ).arg(type)

                type === "MatrixForbidden" ?
                txt = qsTr("Invalid username or password") :

                type === "MatrixUserDeactivated" ?
                txt = qsTr("This account was deactivated") :

                utils.showError(type, traceback, uuid)

                errorMessage.text = txt
            })
        },

        cancel: button => {
            if (! loginFuture) return

            signInTimeout.stop()
            loginFuture.cancel()
            loginFuture    = null
        }
    })


    property var loginFuture: null

    property string signInWith: "username"

    readonly property bool canSignIn:
        serverField.field.text.trim() && idField.field.text.trim() &&
        passwordField.field.text && ! serverField.field.error


    Timer {
        id: signInTimeout
        interval: 30 * 1000
        onTriggered: {
            errorMessage.text =
                serverField.knownServerChosen ?

                qsTr("This server seems unavailable. Verify your inter" +
                     "net connection or try again in a few minutes.") :

                 qsTr("This server seems unavailable. Verify the " +
                      "entered URL, your internet connection or try " +
                      "again in a few minutes.")
        }
    }

    HRowLayout {
        visible: false  // TODO
        spacing: theme.spacing * 1.25
        Layout.alignment: Qt.AlignHCenter

        Layout.topMargin: theme.spacing
        Layout.bottomMargin: Layout.topMargin

        Repeater {
            model: ["username", "email", "phone"]

            HButton {
                icon.name: modelData
                circle: true
                checked: signInWith === modelData
                enabled: modelData === "username"
                autoExclusive: true
                onClicked: signInWith = modelData
            }
        }
    }

    HLabeledTextField {
        id: idField
        label.text: qsTr(
            signInWith === "email" ? "Email:" :
            signInWith === "phone" ? "Phone:" :
            "Username:"
        )

        Layout.fillWidth: true
    }

    HLabeledTextField {
        id: passwordField
        label.text: qsTr("Password:")
        field.echoMode: HTextField.Password

        Layout.fillWidth: true
    }

    HLabeledTextField {
        id: serverField
        label.text: qsTr("Homeserver:")
        field.text: "https://matrix.org"
        field.error: ! /.+:\/\/.+/.test(cleanText)

        Layout.fillWidth: true


        readonly property string cleanText: field.text.toLowerCase().trim()

        // 2019-11-11 https://www.hello-matrix.net/public_servers.php
        readonly property var knownServers: [
            "https://matrix.org",
            "https://chat.weho.st",
            "https://tchncs.de",
            "https://chat.privacytools.io",
            "https://hackerspaces.be",
            "https://matrix.allmende.io",
            "https://feneas.org",
            "https://junta.pl",
            "https://perthchat.org",
            "https://matrix.tedomum.net",
            "https://converser.eu",
            "https://ru-matrix.org",
            "https://matrix.sibnsk.net",
            "https://alternanet.fr",
        ]

        readonly property bool knownServerChosen:
            knownServers.includes(cleanText)
    }

    HCheckBox {
        id: rememberAccount
        checked: true
        text: qsTr("Remember my account")
        subtitle.text: qsTr(
            "An access token will be stored on this device to " +
            "automatically sign you in."
        )

        Layout.fillWidth: true
        Layout.topMargin: theme.spacing / 2
        Layout.bottomMargin: Layout.topMargin
    }

    HLabel {
        id: errorMessage
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        color: theme.colors.errorText

        visible: Layout.maximumHeight > 0
        Layout.maximumHeight: text ? implicitHeight : 0
        Behavior on Layout.maximumHeight { HNumberAnimation {} }

        Layout.fillWidth: true
    }
}
