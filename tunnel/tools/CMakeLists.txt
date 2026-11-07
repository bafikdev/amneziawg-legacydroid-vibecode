# SPDX-License-Identifier: Apache-2.0
#
# Copyright © 2017-2023 WireGuard LLC. All Rights Reserved.
#
# Only the userspace Go backend is built in the legacy port. The root/kernel
# backend (libwg.so + libwg-quick.so) was removed together with AwgQuickBackend.

cmake_minimum_required(VERSION 3.22.1)
project("AmneziaWG" LANGUAGES C)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}")
add_link_options(LINKER:--build-id=none)
add_link_options(-Wl,-z,max-page-size=16384)
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-z,max-page-size=16384")

# CMAKE_SYSTEM_VERSION is unreliable in the NDK toolchain during the first
# configure pass; ANDROID_PLATFORM ("android-19") is authoritative.
if(ANDROID_PLATFORM MATCHES "^android-([0-9]+)$")
    set(ANDROID_API_LEVEL "${CMAKE_MATCH_1}")
elseif(CMAKE_SYSTEM_VERSION GREATER 1)
    set(ANDROID_API_LEVEL "${CMAKE_SYSTEM_VERSION}")
else()
    set(ANDROID_API_LEVEL "19")
endif()

# The Go toolchain is provided by the build environment (CI uses actions/setup-go).
# build-go.cmake maps the NDK ABI to GOARCH/GOARM and passes the API-19 target
# triple to cgo, so libwg-go.so never links against post-KitKat libc symbols.
add_custom_target(libwg-go.so
    COMMENT "Building amneziawg-go for ${ANDROID_ABI} (API ${ANDROID_API_LEVEL})"
    COMMAND ${CMAKE_COMMAND}
        "-DGO_SRC=${CMAKE_CURRENT_SOURCE_DIR}/libwg-go"
        "-DOUTPUT_DIR=${CMAKE_LIBRARY_OUTPUT_DIRECTORY}"
        "-DANDROID_ABI=${ANDROID_ABI}"
        "-DANDROID_API=${ANDROID_API_LEVEL}"
        "-DANDROID_PACKAGE_NAME=${ANDROID_PACKAGE_NAME}"
        "-DTARGET_TRIPLE=${CMAKE_C_COMPILER_TARGET}"
        "-DSYSROOT=${CMAKE_SYSROOT}"
        "-DCC=${CMAKE_C_COMPILER}"
        "-DCFLAGS=${CMAKE_C_FLAGS}"
        "-DLDFLAGS=${CMAKE_SHARED_LINKER_FLAGS}"
        -P "${CMAKE_CURRENT_SOURCE_DIR}/libwg-go/build-go.cmake"
    VERBATIM
)
