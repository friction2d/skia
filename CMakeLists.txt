#
# Friction - https://friction.graphics
#
# Copyright (c) Ole-André Rodlie and contributors
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

cmake_minimum_required(VERSION 3.12)
project(skia-friction VERSION 1.0.5 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(ExternalProject)
include(ProcessorCount)

ProcessorCount(N)

if(NOT APPLE)
    if(UNIX AND NOT CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        message(FATAL_ERROR "Only Clang is supported.")
    elseif(WIN32 AND NOT CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        message(FATAL_ERROR "Only MSVC is supported.")
    endif()
endif()

if(WIN32)
    find_program(PYTHON_EXECUTABLE python.exe)
else()
    find_program(PYTHON_EXECUTABLE NAMES python3 python)
endif()

if(WIN32)
    find_program(NINJA_EXECUTABLE ninja.exe)
else()
    find_program(NINJA_EXECUTABLE NAMES ninja-build ninja)
endif()

if(NOT PYTHON_EXECUTABLE)
    message(FATAL_ERROR "Python executable not found.")
endif()
if(NOT NINJA_EXECUTABLE)
    message(FATAL_ERROR "Ninja executable not found.")
endif()

option(SKIA_STATIC "Build static skia library for Linux/macOS" OFF)
option(SKIA_USE_SYSTEM_LIBS "Use system libraries for skia" ON)
option(SKIA_SYNC_EXTERNAL "Sync skia external software" OFF)

option(LINUX_DEPLOY "Linux Deploy (only for Friction SDK)" OFF)
option(MAC_DEPLOY "Mac Deploy (only for Friction SDK)" OFF)

option(INSTALL_DOCS "Install documentation" ON)

if(UNIX AND NOT APPLE)
    option(SKIA_USE_EGL "Use EGL in skia" ON)
endif()

set(SKIA_SRC "${CMAKE_CURRENT_SOURCE_DIR}")
set(SKIA_BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}/skia-build")

if(APPLE)
    set(SKIA_USE_SYSTEM_LIBS OFF)
endif()

if(${SKIA_USE_SYSTEM_LIBS} AND UNIX)
    set(SKIA_ENABLE_EXTERNAL "true")
else()
    set(SKIA_ENABLE_EXTERNAL "false")
endif()

if(WIN32)
    set(SKIA_ARGS_EXTRA --ide=vs)
    set(SKIA_BUILD_CMD msbuild all.sln)
    if(${SKIA_SYNC_EXTERNAL})
        set(SKIA_UPDATE_CMD ${PYTHON_EXECUTABLE} "tools\\git-sync-deps")
    else()
        set(SKIA_UPDATE_CMD :)
    endif()
    set(SKIA_ARGS "target_os=\"windows\" host_os=\"win\" current_os=\"win\" target_cpu=\"x64\" is_component_build=true")
    set(SKIA_ARGS "${SKIA_ARGS} clang_win=\"C:\\Program Files\\LLVM\" cc=\"clang-cl\" cxx=\"clang-cl\"")
    set(SKIA_ARGS "${SKIA_ARGS} extra_cflags=[\"-Wno-error\",\"/MD\",\"/O2\"]")
else()
    set(SKIA_BUILD_CMD ${NINJA_EXECUTABLE} -j${N})
    if(${SKIA_USE_SYSTEM_LIBS})
        set(SKIA_UPDATE_CMD true)
    else()
        if(${SKIA_SYNC_EXTERNAL})
            set(SKIA_UPDATE_CMD ${PYTHON_EXECUTABLE} "tools/git-sync-deps")
        else()
            set(SKIA_UPDATE_CMD true)
        endif()
    endif()
    set(SKIA_ARGS "ar=\"${CMAKE_AR}\" cc=\"${CMAKE_C_COMPILER}\" cxx=\"${CMAKE_CXX_COMPILER}\"")
    if(${SKIA_STATIC})
        set(SKIA_ARGS "${SKIA_ARGS} is_component_build=false")
    else()
        set(SKIA_ARGS "${SKIA_ARGS} is_component_build=true")
    endif()
    if(UNIX AND NOT APPLE)
        if(${SKIA_USE_EGL})
            set(SKIA_ARGS "${SKIA_ARGS} skia_use_egl=true")
        endif()
        if (${LINUX_DEPLOY})
            set(SKIA_ARGS "${SKIA_ARGS} extra_cflags=[\"-Wno-error\"]")
        else()
            set(SKIA_ARGS "${SKIA_ARGS} extra_cflags=[\"-Wno-error\", \"-Wno-psabi\"]")
        endif()
    endif()
    if(APPLE)
        set(SKIA_UPDATE_CMD ${PYTHON_EXECUTABLE} "tools/git-sync-deps")
        set(SKIA_ARGS "${SKIA_ARGS} target_cpu=\"${CMAKE_HOST_SYSTEM_PROCESSOR}\"")
        if(${MAC_DEPLOY})
            set(SKIA_ARGS "${SKIA_ARGS} extra_cflags=[\"-Wno-error\", \"-Wno-psabi\", \"-mmacosx-version-min=11.0\"]")
            set(SKIA_ARGS "${SKIA_ARGS} extra_cflags_cc=[\"-frtti\", \"-mmacosx-version-min=11.0\"]")
        else()
            set(SKIA_ARGS "${SKIA_ARGS} extra_cflags=[\"-Wno-error\", \"-Wno-psabi\"]")
            set(SKIA_ARGS "${SKIA_ARGS} extra_cflags_cc=[\"-frtti\"]")
        endif()
    endif()
endif()

set(SKIA_ARGS "${SKIA_ARGS} is_official_build=true is_debug=false")
set(SKIA_ARGS "${SKIA_ARGS} skia_enable_skshaper=false skia_enable_skottie=false")
set(SKIA_ARGS "${SKIA_ARGS} skia_enable_pdf=false skia_enable_tools=false skia_use_dng_sdk=false")
set(SKIA_ARGS "${SKIA_ARGS} skia_use_system_expat=${SKIA_ENABLE_EXTERNAL}")
set(SKIA_ARGS "${SKIA_ARGS} skia_use_system_libjpeg_turbo=${SKIA_ENABLE_EXTERNAL}")
set(SKIA_ARGS "${SKIA_ARGS} skia_use_system_libpng=${SKIA_ENABLE_EXTERNAL}")
set(SKIA_ARGS "${SKIA_ARGS} skia_use_system_libwebp=${SKIA_ENABLE_EXTERNAL}")
set(SKIA_ARGS "${SKIA_ARGS} skia_use_libgifcodec=false")
if(WIN32 OR NOT ${SKIA_USE_SYSTEM_LIBS})
    if(APPLE)
        set(SKIA_ARGS "${SKIA_ARGS} skia_use_system_zlib=true")
    else()
        set(SKIA_ARGS "${SKIA_ARGS} skia_use_system_zlib=${SKIA_ENABLE_EXTERNAL}")
    endif()
endif()
if(UNIX AND NOT APPLE)
    set(SKIA_ARGS "${SKIA_ARGS} skia_use_system_freetype2=${SKIA_ENABLE_EXTERNAL}")
endif()

ExternalProject_Add(
    gn
    SOURCE_DIR ${SKIA_SRC}/gn-src
    BINARY_DIR ${SKIA_BUILD_DIR}/gn
    DOWNLOAD_COMMAND :
    UPDATE_COMMAND :
    CONFIGURE_COMMAND ${PYTHON_EXECUTABLE} ${SKIA_SRC}/gn-src/build/gen.py --out-path ${SKIA_BUILD_DIR}/gn
    BUILD_COMMAND ${NINJA_EXECUTABLE} -j${N} -C ${SKIA_BUILD_DIR}/gn
    INSTALL_COMMAND :
    USES_TERMINAL_UPDATE true
    USES_TERMINAL_CONFIGURE true
    USES_TERMINAL_BUILD true
)

if(WIN32)
    set(GN_BIN_PATH ${SKIA_BUILD_DIR}/gn/gn.exe)
else()
    set(GN_BIN_PATH ${SKIA_BUILD_DIR}/gn/gn)
endif()

ExternalProject_Add(
    skialib
    SOURCE_DIR ${SKIA_SRC}
    BINARY_DIR ${SKIA_BUILD_DIR}
    DOWNLOAD_COMMAND :
    UPDATE_COMMAND ${SKIA_UPDATE_CMD}
    PATCH_COMMAND :
    CONFIGURE_COMMAND ${GN_BIN_PATH} gen --root=${SKIA_SRC} ${SKIA_BUILD_DIR} "--args=${SKIA_ARGS}" ${SKIA_ARGS_EXTRA}
    BUILD_COMMAND ${SKIA_BUILD_CMD}
    INSTALL_COMMAND :
    USES_TERMINAL_UPDATE true
    USES_TERMINAL_CONFIGURE true
    USES_TERMINAL_BUILD true
)

add_dependencies(skialib gn)

if(NOT SKIA_STATIC)
    if(UNIX AND NOT APPLE)
        include(GNUInstallDirs)
        install(
            FILES
            ${SKIA_BUILD_DIR}/libskia-friction.so
            ${SKIA_BUILD_DIR}/libskia-friction.so.${PROJECT_VERSION_MAJOR}
            ${SKIA_BUILD_DIR}/libskia-friction.so.${PROJECT_VERSION}
            DESTINATION
            ${CMAKE_INSTALL_LIBDIR}
        )
        if(INSTALL_DOCS)
            install(
                FILES
                ${CMAKE_CURRENT_SOURCE_DIR}/README.md
                ${CMAKE_CURRENT_SOURCE_DIR}/LICENSE
                ${CMAKE_CURRENT_SOURCE_DIR}/RELEASE_NOTES.txt
                DESTINATION
                "${CMAKE_INSTALL_DOCDIR}-${PROJECT_VERSION}"
            )
        endif()
    endif()
endif()

if(WIN32)
    add_custom_command(TARGET skialib POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy ${SKIA_BUILD_DIR}/skia.dll.lib ${SKIA_BUILD_DIR}/skia.lib)
endif()
