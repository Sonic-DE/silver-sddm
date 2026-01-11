import QtQuick 2.2
import QtQuick.Layouts 1.2
import QtQuick.Controls
// import QtQuick.Controls.Styles 1.4

TextField {
    placeholderTextColor: config.color
    color: config.color
    font.pointSize: config.fontSize
    font.family: config.font
    width: parent.width     
    background: Rectangle {
        color: "#fff"
        opacity: 0.1
        radius: 8
        anchors.fill: parent
    }
}
