cmake_minimum_required(VERSION 3.16)

project(MarkQml VERSION 1.1.0 LANGUAGES CXX)

find_package(Qt6 REQUIRED COMPONENTS Quick)

# Optional: build against the CJK-friendly cmark-gfm fork installed at this
# prefix (for example cmark-gfm-cjk). When empty, the normal vcpkg/system
# cmark-gfm package is used.
set(CMARK_GFM_CJK_ROOT "" CACHE PATH "Install prefix of a CJK-friendly cmark-gfm fork")
if(CMARK_GFM_CJK_ROOT)
    find_path(CMARK_GFM_CJK_INCLUDE_DIR
        NAMES cmark-gfm.h
        PATHS "${CMARK_GFM_CJK_ROOT}/include"
        NO_DEFAULT_PATH)
    find_library(CMARK_GFM_CJK_LIBRARY
        NAMES cmark-gfm
        PATHS "${CMARK_GFM_CJK_ROOT}/lib" "${CMARK_GFM_CJK_ROOT}/lib64"
        NO_DEFAULT_PATH)
    find_library(CMARK_GFM_CJK_EXT_LIBRARY
        NAMES cmark-gfm-extensions
        PATHS "${CMARK_GFM_CJK_ROOT}/lib" "${CMARK_GFM_CJK_ROOT}/lib64"
        NO_DEFAULT_PATH)
    if(NOT CMARK_GFM_CJK_INCLUDE_DIR OR NOT CMARK_GFM_CJK_LIBRARY
       OR NOT CMARK_GFM_CJK_EXT_LIBRARY)
        message(FATAL_ERROR
            "CMARK_GFM_CJK_ROOT must contain include/cmark-gfm.h and "
            "lib(cmark-gfm, cmark-gfm-extensions)")
    endif()
    add_library(libcmark-gfm SHARED IMPORTED)
    set_target_properties(libcmark-gfm PROPERTIES
        IMPORTED_LOCATION "${CMARK_GFM_CJK_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${CMARK_GFM_CJK_INCLUDE_DIR}")
    add_library(libcmark-gfm-extensions SHARED IMPORTED)
    set_target_properties(libcmark-gfm-extensions PROPERTIES
        IMPORTED_LOCATION "${CMARK_GFM_CJK_EXT_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${CMARK_GFM_CJK_INCLUDE_DIR}"
        INTERFACE_LINK_LIBRARIES libcmark-gfm)
else()
    find_package(cmark-gfm CONFIG REQUIRED)
    find_package(cmark-gfm-extensions CONFIG REQUIRED)
endif()

qt_standard_project_setup(REQUIRES 6.8)

add_subdirectory(RenderMark)

include(GNUInstallDirs)

qt_add_executable(appMarkQml main.cpp)

qt_add_qml_module(appMarkQml
    URI MarkQml
    QML_FILES Main.qml
)

set_target_properties(appMarkQml PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appMarkQml PRIVATE Qt6::Quick RenderMark)

install(TARGETS appMarkQml
    BUNDLE  DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
