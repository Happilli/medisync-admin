cmake_minimum_required(VERSION 3.20)
project(medisyncadmin)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Network)

qt_standard_project_setup()

qt_add_executable(medisyncadmin
    Main.cpp
)

set_source_files_properties(application/Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(medisyncadmin
    URI MediSyncAdmin
    VERSION 1.0
    QML_FILES
        application/Main.qml
        application/Login.qml
        application/Theme.qml
    SOURCES
        ApiClient.cpp
        ApiClient.hpp
        SessionManager.cpp
        SessionManager.hpp
        ConfigManager.cpp
        ConfigManager.hpp
)

target_link_libraries(medisyncadmin PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Network
)
