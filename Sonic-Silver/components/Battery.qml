/*
 *   Copyright 2016 Kai Uwe Broulik <kde@privat.broulik.de>
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
 
import QtQuick 2.2

import org.kde.plasma.private.battery as BatteryControl
import org.kde.plasma.workspace.components 2.0 as PW
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

Row {
    spacing: Kirigami.Units.smallSpacing
    visible: batteryControl.hasCumulative

    BatteryControl.BatteryControlModel {
        id: batteryControl
    }

    PW.BatteryIcon {
        id: battery
        hasBattery: batteryControl.hasBatteries
        percent: batteryControl.percent
        pluggedIn: batteryControl.pluggedIn

        height: batteryLabel.height
        width: height
    }

    PlasmaComponents.Label {
        id: batteryLabel
        height: undefined
        text: i18nd("plasma_lookandfeel_org.kde.lookandfeel","%1%", battery.percent)
        Accessible.name: i18nd("plasma_lookandfeel_org.kde.lookandfeel","Battery at %1%", battery.percent)
    }
}
