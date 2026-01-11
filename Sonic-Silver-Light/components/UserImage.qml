import QtQuick 2.8
import org.kde.plasma.plasma5support 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: userImage
    property string avatarPath
    property string iconSource
    
    Item {
        id: imageSource
       
        anchors.fill: parent
       
        //Image takes priority, taking a full path to a file, if that doesn't exist we show an icon
        Image {
            id: face
            source: userImage.avatarPath
            sourceSize: Qt.size(width, width)
            fillMode: Image.PreserveAspectCrop
            anchors.fill: parent
        }

        Kirigami.Icon {
            id: faceIcon
            source: userImage.iconSource
            visible: (face.status == Image.Error || face.status == Image.Null)
            anchors.fill: parent
            anchors.margins: Kirigami.Units.gridUnit * 0.5 // because mockup says so...
           // colorGroup: PlasmaCore.ColorScope.colorGroup
        }
    

    }
    ShaderEffect {
        
        anchors.centerIn: parent
        
        width: imageSource.width
        height: imageSource.height

        supportsAtlasTextures: true

        readonly property Item source: ShaderEffectSource {
            sourceItem: imageSource
            // software rendering is just a fallback so we can accept not having a rounded avatar here
            hideSource: userImage.GraphicsInfo.api !== GraphicsInfo.Software
            live: true // otherwise the user in focus will show a blurred avatar
        }

        readonly property color colorBorder: "transparent"

        fragmentShader: "qrc:/qt/qml/org/kde/breeze/components/shaders/UserDelegate.frag.qsb"
    }
}
    
