# SPDX-License-Identifier: Apache-2.0
#
# Cross-platform replacement for the old Makefile. It is invoked from
# tools/CMakeLists.txt by the Android Gradle Plugin's CMake build.

if(NOT DEFINED GO_SRC OR NOT DEFINED OUTPUT_DIR OR NOT DEFINED ANDROID_ABI)
    message(FATAL_ERROR "build-go.cmake requires GO_SRC, OUTPUT_DIR and ANDROID_ABI")
endif()

find_program(GO_EXECUTABLE NAMES go)
if(NOT GO_EXECUTABLE)
    message(FATAL_ERROR "Go toolchain not found. Install Go 1.25+ or add it to PATH.")
endif()

if(ANDROID_ABI STREQUAL "armeabi-v7a")
    set(GOARCH "arm")
    set(GOARM "7")
elseif(ANDROID_ABI STREQUAL "arm64-v8a")
    set(GOARCH "arm64")
    set(GOARM "")
elseif(ANDROID_ABI STREQUAL "x86")
    set(GOARCH "386")
    set(GOARM "")
elseif(ANDROID_ABI STREQUAL "x86_64")
    set(GOARCH "amd64")
    set(GOARM "")
else()
    message(FATAL_ERROR "Unsupported Android ABI: ${ANDROID_ABI}")
endif()

if(NOT DEFINED ANDROID_API OR "${ANDROID_API}" STREQUAL "" OR ANDROID_API LESS 19)
    set(ANDROID_API "19")
endif()

if(NOT DEFINED TARGET_TRIPLE OR "${TARGET_TRIPLE}" STREQUAL "")
    if(ANDROID_ABI STREQUAL "armeabi-v7a")
        set(TARGET_TRIPLE "armv7a-linux-androideabi${ANDROID_API}")
    elseif(ANDROID_ABI STREQUAL "arm64-v8a")
        set(TARGET_TRIPLE "aarch64-linux-android${ANDROID_API}")
    elseif(ANDROID_ABI STREQUAL "x86")
        set(TARGET_TRIPLE "i686-linux-android${ANDROID_API}")
    else()
        set(TARGET_TRIPLE "x86_64-linux-android${ANDROID_API}")
    endif()
endif()

if(NOT DEFINED SYSROOT OR SYSROOT STREQUAL "")
    message(FATAL_ERROR "SYSROOT is not set; cannot cross-compile cgo")
endif()

set(OUTPUT "${OUTPUT_DIR}/libwg-go.so")
file(MAKE_DIRECTORY "${OUTPUT_DIR}")

# Keep all Go scratch data inside the Gradle build tree. This avoids relying on
# %TEMP%, which may be non-writable in sandboxed/CI environments.
set(GO_TMP "${OUTPUT_DIR}/go-tmp")
set(GO_CACHE "${OUTPUT_DIR}/go-cache")
set(GO_PATH "${OUTPUT_DIR}/go-path")
set(GO_MOD_CACHE "${GO_PATH}/pkg/mod")
file(MAKE_DIRECTORY "${GO_TMP}" "${GO_CACHE}" "${GO_MOD_CACHE}")

execute_process(
    COMMAND "${GO_EXECUTABLE}" env GOROOT
    OUTPUT_VARIABLE GOROOT
    OUTPUT_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE GOROOT_RESULT
)
if(NOT GOROOT_RESULT EQUAL 0 OR GOROOT STREQUAL "")
    message(FATAL_ERROR "Unable to query GOROOT with ${GO_EXECUTABLE}")
endif()

# Go uses CLOCK_MONOTONIC for nanotime; on mobile devices CLOCK_BOOTTIME is
# preferable because it keeps counting while the device is suspended. Apply the
# same runtime patch the upstream Makefile applied, but without requiring
# patch(1): build a modified copy and pass it to the compiler via -overlay.
if(GOARCH STREQUAL "arm")
    set(RUNTIME_SRC "${GOROOT}/src/runtime/sys_linux_arm.s")
    if(EXISTS "${RUNTIME_SRC}")
        file(READ "${RUNTIME_SRC}" RUNTIME_TEXT)
        string(REPLACE "#define CLOCK_MONOTONIC\t1" "#define CLOCK_BOOTTIME\t7" RUNTIME_TEXT "${RUNTIME_TEXT}")
        string(REPLACE "MOVW\t\$CLOCK_MONOTONIC, R0" "MOVW\t\$CLOCK_BOOTTIME, R0" RUNTIME_TEXT "${RUNTIME_TEXT}")
        file(WRITE "${OUTPUT_DIR}/sys_linux_arm.s" "${RUNTIME_TEXT}")

        string(REPLACE "\\" "/" GOROOT_OVERLAY "${RUNTIME_SRC}")
        string(REPLACE "\\" "/" LOCAL_OVERLAY "${OUTPUT_DIR}/sys_linux_arm.s")
        file(WRITE "${OUTPUT_DIR}/go-overlay.json"
            "{\"Replace\":{\"${GOROOT_OVERLAY}\":\"${LOCAL_OVERLAY}\"}}")
        set(OVERLAY_FLAG "-overlay=${OUTPUT_DIR}/go-overlay.json")
    endif()
endif()

# The upstream Makefile replaced -mthumb with -marm for cgo; keep that behavior
# because the Go linker's ARM stubs are assembled for ARM mode.
set(CGO_CFLAGS "${CFLAGS}")
if(GOARCH STREQUAL "arm")
    string(REPLACE "-mthumb" "-marm" CGO_CFLAGS "${CGO_CFLAGS}")
endif()
set(CGO_CFLAGS "--target=${TARGET_TRIPLE} --sysroot=${SYSROOT} ${CGO_CFLAGS}")
set(CGO_LDFLAGS "--target=${TARGET_TRIPLE} --sysroot=${SYSROOT} ${LDFLAGS} -Wl,--build-id=none -Wl,-soname=libwg-go.so")
set(GO_LDFLAGS "-X github.com/amnezia-vpn/amneziawg-go/v3/ipc.socketDirectory=/data/data/${ANDROID_PACKAGE_NAME}/cache/amneziawg -buildid=")

execute_process(
    COMMAND ${CMAKE_COMMAND} -E env
        "GOOS=android"
        "GOARCH=${GOARCH}"
        "GOARM=${GOARM}"
        "GOTOOLCHAIN=local"
        "CGO_ENABLED=1"
        "CC=${CC}"
        "CGO_CFLAGS=${CGO_CFLAGS}"
        "CGO_LDFLAGS=${CGO_LDFLAGS}"
        "GOFLAGS=${OVERLAY_FLAG}"
        "GOTMPDIR=${GO_TMP}"
        "GOCACHE=${GO_CACHE}"
        "GOPATH=${GO_PATH}"
        "GOMODCACHE=${GO_MOD_CACHE}"
        "TMP=${GO_TMP}"
        "TEMP=${GO_TMP}"
        "${GO_EXECUTABLE}" build
            -tags=linux
            -trimpath
            -buildvcs=false
            "-ldflags=${GO_LDFLAGS}"
            -o "${OUTPUT}"
            -buildmode=c-shared
    WORKING_DIRECTORY "${GO_SRC}"
    RESULT_VARIABLE BUILD_RESULT
    OUTPUT_VARIABLE BUILD_STDOUT
    ERROR_VARIABLE BUILD_STDERR
)

if(NOT BUILD_RESULT EQUAL 0)
    message(FATAL_ERROR "amneziawg-go build failed (${BUILD_RESULT})\n${BUILD_STDOUT}\n${BUILD_STDERR}")
endif()

if(NOT EXISTS "${OUTPUT}")
    message(FATAL_ERROR "amneziawg-go build did not produce ${OUTPUT}")
endif()

message(STATUS "Built ${OUTPUT} for ${ANDROID_ABI} (${TARGET})")
