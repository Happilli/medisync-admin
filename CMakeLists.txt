cmake_minimum_required(VERSION 3.20)
project(medisyncadmin)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Network QuickEffects)

qt_standard_project_setup()

qt_add_executable(medisyncadmin
    Main.cpp
)

set_source_files_properties(application/Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

set_source_files_properties(application/Shapes/GetMShapes.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

file(GLOB_RECURSE JS_ABS CONFIGURE_DEPENDS
 "${CMAKE_CURRENT_SOURCE_DIR}/application/Shapes/*.js")

file(GLOB_RECURSE QML_ABS CONFIGURE_DEPENDS
 "${CMAKE_CURRENT_SOURCE_DIR}/application/*.qml")

file(GLOB_RECURSE ASSET_FILES_ABS CONFIGURE_DEPENDS
 "${CMAKE_CURRENT_SOURCE_DIR}/application/assets/*")

set(ASSET_FILES "")
foreach(_abs_path ${ASSET_FILES_ABS})
    file(RELATIVE_PATH _rel_path "${CMAKE_CURRENT_SOURCE_DIR}" "${_abs_path}")
    list(APPEND ASSET_FILES "${_rel_path}")

endforeach()
set(ALL_QML_MODULE_FILES_ABS ${JS_ABS} ${QML_ABS})

set(ALL_QML_MODULE_FILES "")
foreach(_abs_path ${ALL_QML_MODULE_FILES_ABS})
    file(RELATIVE_PATH _rel_path "${CMAKE_CURRENT_SOURCE_DIR}" "${_abs_path}")
    list(APPEND ALL_QML_MODULE_FILES "${_rel_path}")
endforeach()
qt_add_qml_module(medisyncadmin
    URI MediSyncAdmin
    VERSION 1.0
    QML_FILES
       ${ALL_QML_MODULE_FILES}

    RESOURCES
       ${ASSET_FILES}

    SOURCES
        ApiClient.cpp
        ApiClient.hpp
        SessionManager.cpp
        SessionManager.hpp
        ConfigManager.cpp
        ConfigManager.hpp
        AuthImageProvider.cpp
        AuthImageProvider.hpp
)

target_link_libraries(medisyncadmin PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Network
    Qt6::QuickEffects
)
