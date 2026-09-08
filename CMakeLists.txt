cmake_minimum_required(VERSION 3.16)

project(silver-sddm LANGUAGES NONE)

find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${ECM_MODULE_PATH})

set(QT_MAJOR_VERSION 6)

include(KDEInstallDirs6)
include(KDECMakeSettings)

install(DIRECTORY Sonic-Silver DESTINATION ${KDE_INSTALL_DATADIR}/sddm/themes)
install(DIRECTORY Sonic-Silver-Light DESTINATION ${KDE_INSTALL_DATADIR}/sddm/themes)
