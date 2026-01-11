/*
 *   Copyright 2016 David Edmundson <davidedmundson@kde.org>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2 or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.15

import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasma5support 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents

import Qt5Compat.GraphicalEffects
import org.kde.kirigami 2.20 as Kirigami
import QtQuick 2.15
import QtQuick.Window 2.15

import org.kde.breeze.components

import "components"
import "components/animation"

Item {
    id: root

    // If we're using software rendering, draw outlines instead of shadows
    // See https://bugs.kde.org/show_bug.cgi?id=398317
    readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software

    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
    Kirigami.Theme.inherit: false

    width: 1600
    height: 900

    property string notificationMessage
    property string clock_color: "#fff"

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    PlasmaCore.DataSource {
        id: keystateSource
        engine: "keystate"
        connectedSources: "Caps Lock"
    }

    Image {
        id: wallpaper
        height: parent.height
        width: parent.width
        source: config.background || config.Background
        asynchronous: true
        cache: true
        clip: true
    }

    RejectPasswordAnimation {
        id: rejectPasswordAnimation
        target: mainStack
    }

    MouseArea {
        id: loginScreenRoot
        anchors.fill: parent

        property bool uiVisible: true
        property bool blockUI: mainStack.depth > 1 || userListComponent.mainPasswordBox.text.length > 0 || inputPanel.keyboardActive || config.type != "image"

        hoverEnabled: true
        drag.filterChildren: true
        onPressed: uiVisible = true;
        onPositionChanged: uiVisible = true;
        onUiVisibleChanged: {
            if (blockUI) {
                fadeoutTimer.running = false;
            } else if (uiVisible) {
                fadeoutTimer.restart();
            }
        }
        onBlockUIChanged: {
            if (blockUI) {
                fadeoutTimer.running = false;
                uiVisible = true;
            } else {
                fadeoutTimer.restart();
            }
        }

        Keys.onPressed: {
            uiVisible = true;
            event.accepted = false;
        }

        //takes one full minute for the ui to disappear
        Timer {
            id: fadeoutTimer
            running: true
            interval: 60000
            onTriggered: {
                if (!loginScreenRoot.blockUI) {
                    loginScreenRoot.uiVisible = false;
                }
            }
        }

        Item {
            id: rootq
            width: Screen.width
            height: Screen.height
            // Delete all "//" to set up Classic Clock.

            // Classic Clock (Original Clock Component)
            //Clock {
            //id: oldClock
            //visible: useOldClock
            //x: parent.width * 0.70 - width / 2
            //y: parent.height / 2 - height / 2
            //}

            // New Clock (NewClock)
            Item {
                id: newClock
                visible: !useOldClock
                width: 400
                height: 200
                x: parent.width * 0.70 - width / 2
                y: parent.height / 2 - height / 2

                //Digital Clock.
                Text {
                    id: clockHour
                    text: Qt.formatDateTime(new Date(), "hh:mm")
                    color: "#ffffff"
                    font.bold: true
                    font.pointSize: 75
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                }
                Text {
                    id: clockDate
                    text: Qt.formatDateTime(new Date(), "ddd d")
                    color: "#ffffff"
                    font.bold: false
                    font.pointSize: 18
                    font.capitalization: Font.Capitalize
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: clockHour.bottom
                    anchors.topMargin: 10
                }
            }
        }

        StackView {
            id: mainStack
            anchors.left: parent.left
            height: root.height
            width: parent.width / 3

            focus: true //StackView is an implicit focus scope, so we need to give this focus so the item inside will have it

            Timer {
                //SDDM has a bug in 0.13 where even though we set the focus on the right item within the window, the window doesn't have focus
                //it is fixed in 6d5b36b28907b16280ff78995fef764bb0c573db which will be 0.14
                //we need to call "window->activate()" *After* it's been shown. We can't control that in QML so we use a shoddy timer
                //it's been this way for all Plasma 5.x without a huge problem
                running: true
                repeat: false
                interval: 200
                onTriggered: mainStack.forceActiveFocus()
            }

            initialItem: Login {
                id: userListComponent
                userListModel: userModel
                loginScreenUiVisible: loginScreenRoot.uiVisible
                userListCurrentIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
                lastUserName: userModel.lastUser

                showUserList: {
                    if ( !userListModel.hasOwnProperty("count")
                        || !userListModel.hasOwnProperty("disableAvatarsThreshold"))
                        return false

                        if ( userListModel.count == 0 ) return false

                            return userListModel.count <= userListModel.disableAvatarsThreshold && (userList.y + mainStack.y) > 0
                }

                notificationMessage: {
                    const parts = [];
                    if (keystateSource.data["Caps Lock"]["Locked"]) {
                        parts.push(i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Caps Lock is on"));
                    }
                    if (root.notificationMessage) {
                        parts.push(root.notificationMessage);
                    }
                    return parts.join(" • ");
                }

                actionItems: [
                    ActionButton {
                        iconSource: Qt.resolvedUrl("assets/suspend.svgz")
                        text: i18ndc("plasma_lookandfeel_org.kde.lookandfeel","Suspend to RAM","Sleep")
                        onClicked: sddm.suspend()
                        enabled: sddm.canSuspend
                        visible: !inputPanel.keyboardActive
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 15
                    },
                    ActionButton {
                        iconSource: Qt.resolvedUrl("assets/restart.svgz")
                        text: i18nd("plasma_lookandfeel_org.kde.lookandfeel","Restart")
                        onClicked: sddm.reboot()
                        enabled: sddm.canReboot
                        visible: !inputPanel.keyboardActive
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 15
                    },
                    ActionButton {
                        iconSource: Qt.resolvedUrl("assets/shutdown.svgz")
                        text: i18nd("plasma_lookandfeel_org.kde.lookandfeel","Shut Down")
                        onClicked: sddm.powerOff()
                        enabled: sddm.canPowerOff
                        visible: !inputPanel.keyboardActive
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 15
                    },
                    ActionButton {
                        iconSource: Qt.resolvedUrl("assets/change_user.svgz")
                        text: i18nd("plasma_lookandfeel_org.kde.lookandfeel","Switch User")
                        onClicked: mainStack.push(userPromptComponent)
                        enabled: true
                        visible: !userListComponent.showUsernamePrompt && !inputPanel.keyboardActive
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 15
                    }]

                    onLoginRequest: {
                        root.notificationMessage = ""
                        sddm.login(username, password, sessionIndex)
                    }
            }

            pushEnter: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 0
                    to:1
                    duration: 200
                }
            }
            pushExit: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 1
                    to:0
                    duration: 200
                }
            }
            popEnter: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 0
                    to:1
                    duration: 200
                }
            }
            popExit: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 1
                    to:0
                    duration: 200
                }
            }

            Behavior on opacity {
                OpacityAnimator {
                    duration: units.longDuration
                }
            }
        }

        VirtualKeyboardLoader {
            id: inputPanel

            z: 1

            screenRoot: root
            mainStack: mainStack
            mainBlock: userListComponent
            passwordField: userListComponent.mainPasswordBox
        }


        Component {
            id: userPromptComponent
            Login {
                showUsernamePrompt: true
                notificationMessage: root.notificationMessage
                loginScreenUiVisible: loginScreenRoot.uiVisible

                // using a model rather than a QObject list to avoid QTBUG-75900
                userListModel: ListModel {
                    ListElement {
                        name: ""
                        iconSource: ""
                    }
                    Component.onCompleted: {
                        // as we can't bind inside ListElement
                        setProperty(0, "name", i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Type in Username and Password"));
                        setProperty(0, "icon", Qt.resolvedUrl("faces/.face.icon"))
                    }
                }

                onLoginRequest: {
                    root.notificationMessage = ""
                    sddm.login(username, password, sessionIndex)
                }

                actionItems: [
                    ActionButton {
                        iconSource: Qt.resolvedUrl("assets/suspend.svgz")
                        text: i18ndc("plasma_lookandfeel_org.kde.lookandfeel","Suspend to RAM","Sleep")
                        onClicked: sddm.suspend()
                        enabled: sddm.canSuspend
                        visible: !inputPanel.keyboardActive
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 15
                    },
                    ActionButton {
                        iconSource: Qt.resolvedUrl("assets/restart.svgz")
                        text: i18nd("plasma_lookandfeel_org.kde.lookandfeel","Restart")
                        onClicked: sddm.reboot()
                        enabled: sddm.canReboot
                        visible: !inputPanel.keyboardActive
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 15
                    },
                    ActionButton {
                        iconSource: Qt.resolvedUrl("assets/shutdown.svgz")
                        text: i18nd("plasma_lookandfeel_org.kde.lookandfeel","Shut Down")
                        onClicked: sddm.powerOff()
                        enabled: sddm.canPowerOff
                        visible: !inputPanel.keyboardActive
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 15
                    },
                    ActionButton {
                        iconSource: "go-previous"
                        text: i18nd("plasma_lookandfeel_org.kde.lookandfeel","List Users")
                        onClicked: mainStack.pop()
                        visible: !inputPanel.keyboardActive
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 15
                    }
                ]
            }
        }

        // Rectangle {
        //     id: formBg
        //     anchors.fill: mainStack
        //     anchors.centerIn: mainStack
        //     color: "#161925"
        //     opacity: 0.4
        //     z:-1
        // }

        Item {
            id: blurContainer
            width: parent.width * 0.4
            height: parent.height
            anchors.left: parent.left
            clip: true   // Basically, this ensures that only what is inside the container is displayed and not all.
            z: -2

            ShaderEffectSource {
                id: blurArea
                sourceItem: wallpaper
                anchors.fill: parent
                sourceRect: Qt.rect(0, 0, parent.width, parent.height) // This setting ensures that only what is affected behind the background is reflected.
                visible: true
                z: -2
            }

            GaussianBlur {
                id: blur
                width: blurArea.width
                height: blurArea.height
                source: blurArea
                radius: 50 //reduced from 70 to 50%.
                samples: 50 * 2 + 1
                cached: true
                visible: true
                z: -2
            }

            Rectangle {
                width: blur.width
                height: blur.height
                color: "#3B4252"  // Nord Color background of the blur, you can change it if you want!
                opacity: 0.5      // Alpha blur background.
                anchors.fill: parent
                z: -2
            }
        }
    }

    Connections {
        target: sddm
        onLoginFailed: {
            notificationMessage = i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Login Failed")
            rejectPasswordAnimation.start()
        }
        onLoginSucceeded: {
            //note SDDM will kill the greeter at some random point after this
            //there is no certainty any transition will finish, it depends on the time it
            //takes to complete the init
            mainStack.opacity = 0
            footer.opacity = 0
        }
    }

    onNotificationMessageChanged: {
        if (notificationMessage) {
            notificationResetTimer.start();
        }
    }

    Timer {
        id: notificationResetTimer
        interval: 3000
        onTriggered: notificationMessage = ""
    }
}
