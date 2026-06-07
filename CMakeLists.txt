#
# Skia for Friction
#
# https://friction.graphics
# https://github.com/friction2d/skia
# https://codeberg.org/friction/skia
#
# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) Ole-André Rodlie and contributors
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

option(SKIA_STATIC "Build static library for Linux/macOS (mostly for Friction SDK)" OFF)
option(SKIA_USE_SYSTEM_LIBS "Use system libraries for skia" ON)
option(SKIA_SYNC_EXTERNAL "Sync skia external software (mostly for Friction SDK)" OFF)

option(LINUX_DEPLOY "Linux Deploy (only for Friction SDK)" OFF)
option(MAC_DEPLOY "Mac Deploy (only for Friction SDK)" OFF)

option(INSTALL_DOCS "Install documentation" ON)
option(INSTALL_HEADERS "Install development headers" ON)

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
            ${SKIA_BUILD_DIR}/lib${PROJECT_NAME}.so
            ${SKIA_BUILD_DIR}/lib${PROJECT_NAME}.so.${PROJECT_VERSION_MAJOR}
            ${SKIA_BUILD_DIR}/lib${PROJECT_NAME}.so.${PROJECT_VERSION}
            DESTINATION
            ${CMAKE_INSTALL_LIBDIR}
        )
        if(INSTALL_DOCS)
            install(
                FILES
                ${CMAKE_CURRENT_SOURCE_DIR}/README.md
                ${CMAKE_CURRENT_SOURCE_DIR}/LICENSE
                DESTINATION
                "${CMAKE_INSTALL_DOCDIR}-${PROJECT_VERSION}"
            )
        endif()
        if(INSTALL_HEADERS)
            # TODO: some headers might be missing for macOS/Windows, only tested on Linux
            set(HEADER_DEST_ROOT "${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}")
            install(FILES
                include/config/SkUserConfig.h
                DESTINATION "${HEADER_DEST_ROOT}/config"
            )
            install(FILES
                include/core/SkBitmap.h
                include/core/SkBlendMode.h
                include/core/SkBlurTypes.h
                include/core/SkCanvas.h
                include/core/SkClipOp.h
                include/core/SkColorFilter.h
                include/core/SkColor.h
                include/core/SkColorSpace.h
                include/core/SkContourMeasure.h
                include/core/SkCoverageMode.h
                include/core/SkData.h
                include/core/SkEncodedImageFormat.h
                include/core/SkFilterQuality.h
                include/core/SkFlattenable.h
                include/core/SkFontArguments.h
                include/core/SkFont.h
                include/core/SkFontMetrics.h
                include/core/SkFontParameters.h
                include/core/SkFontStyle.h
                include/core/SkFontTypes.h
                include/core/SkImageEncoder.h
                include/core/SkImageFilter.h
                include/core/SkImage.h
                include/core/SkImageInfo.h
                include/core/SkM44.h
                include/core/SkMaskFilter.h
                include/core/SkMath.h
                include/core/SkMatrix.h
                include/core/SkPaint.h
                include/core/SkPathEffect.h
                include/core/SkPath.h
                include/core/SkPathMeasure.h
                include/core/SkPathTypes.h
                include/core/SkPicture.h
                include/core/SkPixelRef.h
                include/core/SkPixmap.h
                include/core/SkPoint.h
                include/core/SkRasterHandleAllocator.h
                include/core/SkRect.h
                include/core/SkRefCnt.h
                include/core/SkRRect.h
                include/core/SkScalar.h
                include/core/SkShader.h
                include/core/SkSize.h
                include/core/SkStream.h
                include/core/SkString.h
                include/core/SkStrokeRec.h
                include/core/SkSurface.h
                include/core/SkSurfaceProps.h
                include/core/SkTileMode.h
                include/core/SkTypeface.h
                include/core/SkTypes.h
                include/core/SkUnPreMultiply.h
                DESTINATION "${HEADER_DEST_ROOT}/core"
            )
            install(FILES
                include/effects/SkBlurImageFilter.h
                include/effects/SkDashPathEffect.h
                include/effects/SkDiscretePathEffect.h
                include/effects/SkDropShadowImageFilter.h
                include/effects/SkGradientShader.h
                include/effects/SkImageFilters.h
                DESTINATION "${HEADER_DEST_ROOT}/effects"
            )
            install(FILES
                include/gpu/GrBackendSurface.h
                include/gpu/GrConfig.h
                include/gpu/GrContext.h
                include/gpu/GrContextOptions.h
                include/gpu/GrDriverBugWorkaroundsAutogen.h
                include/gpu/GrDriverBugWorkarounds.h
                include/gpu/GrTypes.h
                DESTINATION "${HEADER_DEST_ROOT}/gpu"
            )
            install(FILES
                include/gpu/gl/GrGLConfig.h
                include/gpu/gl/GrGLExtensions.h
                include/gpu/gl/GrGLFunctions.h
                include/gpu/gl/GrGLInterface.h
                include/gpu/gl/GrGLTypes.h
                DESTINATION "${HEADER_DEST_ROOT}/gpu/gl"
            )
            install(FILES
                include/gpu/mock/GrMockTypes.h 
                DESTINATION "${HEADER_DEST_ROOT}/gpu/mock"
            )
            install(FILES
                include/gpu/vk/GrVkTypes.h
                include/gpu/vk/GrVkVulkan.h
                DESTINATION "${HEADER_DEST_ROOT}/gpu/vk"
            )
            install(FILES
                include/pathops/SkPathOps.h 
                DESTINATION "${HEADER_DEST_ROOT}/pathops"
            )
            install(FILES
                include/private/GrContext_Base.h
                include/private/GrGLTypesPriv.h
                include/private/GrImageContext.h
                include/private/GrRecordingContext.h
                include/private/GrSharedEnums.h
                include/private/GrSingleOwner.h
                include/private/GrTypesPriv.h
                include/private/GrVkTypesPriv.h
                include/private/SkDeque.h
                include/private/SkFixed.h
                include/private/SkFloatBits.h
                include/private/SkFloatingPoint.h
                include/private/SkIDChangeListener.h
                include/private/SkImageInfoPriv.h
                include/private/SkMacros.h
                include/private/SkMalloc.h
                include/private/SkMutex.h
                include/private/SkNx.h
                include/private/SkNx_neon.h
                include/private/SkNx_sse.h
                include/private/SkOnce.h
                include/private/SkPathRef.h
                include/private/SkSafe32.h
                include/private/SkSafe_math.h
                include/private/SkSemaphore.h
                include/private/SkTArray.h
                include/private/SkTDArray.h
                include/private/SkTemplates.h
                include/private/SkTFitsIn.h
                include/private/SkThreadAnnotations.h
                include/private/SkThreadID.h
                include/private/SkTLogic.h
                include/private/SkTo.h
                include/private/SkWeakRefCnt.h
                DESTINATION "${HEADER_DEST_ROOT}/private"
            )
            install(FILES
                include/third_party/skcms/skcms.h
                DESTINATION "${HEADER_DEST_ROOT}/third_party/skcms"
            )
            install(FILES
                include/third_party/vulkan/vulkan/vk_platform.h
                include/third_party/vulkan/vulkan/vulkan_core.h
                DESTINATION "${HEADER_DEST_ROOT}/third_party/vulkan/vulkan"
            )
            install(FILES
                include/utils/SkBase64.h
                include/utils/SkParsePath.h
                include/utils/SkRandom.h
                include/utils/SkTextUtils.h
                DESTINATION "${HEADER_DEST_ROOT}/utils"
            )
        endif()
    endif()
endif()

# TODO: fix this workaround
if(WIN32)
    add_custom_command(TARGET skialib POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy ${SKIA_BUILD_DIR}/skia.dll.lib ${SKIA_BUILD_DIR}/skia.lib)
endif()

# TODO: needs testing
# find_package(SkiaFriction REQUIRED)
# target_link_libraries(app PRIVATE SkiaFriction::SkiaFriction)

include(CMakePackageConfigHelpers)

set(CMAKECONFIG_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/cmake/SkiaFriction")

write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/SkiaFrictionConfigVersion.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/SkiaFrictionConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/SkiaFrictionConfig.cmake"
    @ONLY
)

install(
    FILES
    "${CMAKE_CURRENT_BINARY_DIR}/SkiaFrictionConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/SkiaFrictionConfigVersion.cmake"
    DESTINATION
    "${CMAKECONFIG_INSTALL_DIR}"
)
