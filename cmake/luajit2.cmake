set(LUAJIT_SOURCE_ROOT ${CMAKE_SOURCE_DIR}/luajit-2.1/src)
set(LUAJIT_INSTALL_ROOT ${CMAKE_BINARY_DIR}/lj2)

set(LUAJIT_LIB_BASE_NAME "luajit")
set(LUAJIT_LIB_SUFFIX "")
set(LUAJIT_LIB_PREFIX "")
if (WIN32)
    if (CYGWIN OR MINGW)
        set(LUAJIT_LIB_SUFFIX ".a")
        set(LUAJIT_LIB_PREFIX "lib")
    else()
        set(LUAJIT_LIB_BASE_NAME "lua51")
        set(LUAJIT_LIB_SUFFIX ".lib")
    endif()
else ()
    set(LUAJIT_LIB_SUFFIX ".a")
    set(LUAJIT_LIB_PREFIX "lib")
endif()
set(LUAJIT_LIB_NAME "${LUAJIT_LIB_PREFIX}${LUAJIT_LIB_BASE_NAME}${LUAJIT_LIB_SUFFIX}")
set(LUAJIT_LIB_PATH ${LUAJIT_INSTALL_ROOT}/${LUAJIT_LIB_NAME})

# Setup LuaJIT compile flags `XCFLAGS` according to options
set(LUAJIT_XCFLAGS )
if (NOT LJ_GC64)
    set(LUAJIT_XCFLAGS "${LUAJIT_XCFLAGS} -DLUAJIT_DISABLE_GC64")
endif ()
if (LJ_ENABLE_LUA52COMPAT)
    set(LUAJIT_XCFLAGS "${LUAJIT_XCFLAGS} -DLUAJIT_ENABLE_LUA52COMPAT")
endif ()

if (WIN32 AND NOT CYGWIN)
    # LuaJIT compiler options (other than LUAJIT_DISABLE_GC64) using Makefile are not supported.
    if (CMAKE_GENERATOR MATCHES "Visual Studio")
        if (CMAKE_GENERATOR_PLATFORM STREQUAL "Win32")
            set(LUAJIT_BUILD_SCRIPT_PATH ${CMAKE_SOURCE_DIR}/make_luajit2_windows_x86.bat)
        elseif (CMAKE_GENERATOR_PLATFORM STREQUAL "x64")
            set(LUAJIT_BUILD_SCRIPT_PATH ${CMAKE_SOURCE_DIR}/make_luajit2_windows_x64.bat)
        else ()
            message(FATAL_ERROR "Platforms supported for Visual Studio generator: x64, Win32. Provided: ${CMAKE_GENERATOR_PLATFORM}")
        endif ()
        add_custom_command(
            OUTPUT ${LUAJIT_LIB_PATH}
            COMMAND cmd /C ${LUAJIT_BUILD_SCRIPT_PATH} $<$<NOT:$<BOOL:${LJ_GC64}>>:nogc64> $<$<CONFIG:Debug>:debug>
            COMMAND ${CMAKE_COMMAND} -E copy ${LUAJIT_SOURCE_ROOT}/lua51.lib ${LUAJIT_LIB_PATH}
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            COMMENT "Building LuaJIT for Windows (${CMAKE_GENERATOR_PLATFORM})..."
        )
    elseif (MINGW)
        if ($ENV{MSYSTEM} STREQUAL "MINGW32")
            set(MINGW32 TRUE)
        endif ()
        add_custom_command(
            OUTPUT ${LUAJIT_LIB_PATH}
            COMMAND mingw32-make clean
            COMMAND mingw32-make 
                $<$<EQUAL:${CMAKE_SIZEOF_VOID_P},4>:CC="gcc -m32">
                CCDEBUG="$<$<CONFIG:Debug>: -g>"
                XCFLAGS=${LUAJIT_XCFLAGS}
                BUILDMODE=static
            COMMAND ${CMAKE_COMMAND} -E copy ${LUAJIT_SOURCE_ROOT}/libluajit.a ${LUAJIT_LIB_PATH}
            WORKING_DIRECTORY ${LUAJIT_SOURCE_ROOT}
            COMMENT "Building LuaJIT for Windows ($<IF:$<BOOL:${MINGW32}>,x86,x86_64>) on $ENV{MSYSTEM}..."
        )
    endif ()
elseif (ANDROID)
    # https://cmake.org/cmake/help/latest/manual/cmake-toolchains.7.html#cross-compiling-for-android
    # https://developer.android.com/ndk/guides/cmake#command-line
    # IMPORTANT: Caution: CMake has its own built-in NDK support which has behavior differences compared to 
    # the NDK's CMake toolchain file. Android does not support or test the built-in workflow. We recommend 
    # using our toolchain file.
    if (NOT ANDROID_NDK)
        if (DEFINED ENV{ANDROID_NDK_HOME})
            set(ANDROID_NDK $ENV{ANDROID_NDK_HOME})
        else ()
            message(FATAL_ERROR "ANDROID_NDK is not set.")
        endif ()
    endif ()

    if (NOT (ANDROID_ABI STREQUAL "arm64-v8a"))
        message(FATAL_ERROR "ANDROID_ABI is not arm64-v8a.")
    endif ()

    # https://stackoverflow.com/a/47896799/3614952
    set(MAKE_SHELL_CMD 0)
    set(MINGW64 $ENV{MSYSTEM} STREQUAL "MINGW64")
    if (CMAKE_HOST_UNIX OR MINGW64)
        string(TOLOWER ${CMAKE_HOST_SYSTEM_NAME} HOST_SYSTEM_NAME_LOWER)
        set(NDK_BIN_DIR ${ANDROID_NDK}/toolchains/llvm/prebuilt/${HOST_SYSTEM_NAME_LOWER}-x86_64/bin)
        set(NDK_CROSS ${NDK_BIN_DIR}/aarch64-linux-android-)
        set(NDK_CC ${NDK_BIN_DIR}/aarch64-linux-android${ANDROID_PLATFORM}-clang)
        set(NDK_AR ${NDK_BIN_DIR}/llvm-ar)
        set(NDK_STRIP ${NDK_BIN_DIR}/llvm-strip)
    elseif (CMAKE_HOST_WIN32)
        set(NDK_BIN_DIR ${ANDROID_NDK}\\toolchains\\llvm\\prebuilt\\windows-x86_64\\bin)
        set(NDK_CROSS ${NDK_BIN_DIR}\\aarch64-linux-android-)
        set(NDK_CC ${NDK_BIN_DIR}\\aarch64-linux-android${ANDROID_PLATFORM}-clang.cmd)
        set(NDK_AR ${NDK_BIN_DIR}\\llvm-ar.exe)
        set(NDK_STRIP ${NDK_BIN_DIR}\\llvm-strip.exe)
        set(MAKE_SHELL_CMD 1)
    endif ()

    # https://stackoverflow.com/questions/70594767/cmake-appends-backslash-to-command-added-by-add-custom-target
    set(NDK_DYNAMIC_CC ${NDK_CC} "-fPIC")
    set(NDK_TARGET_AR ${NDK_AR} "rcus")
    add_custom_command(
        OUTPUT ${LUAJIT_LIB_PATH}
        COMMAND make 
            $<${MAKE_SHELL_CMD}:SHELL=cmd>
            TARGET_SYS=Linux
            clean
        COMMAND make 
            $<${MAKE_SHELL_CMD}:SHELL=cmd>
            CROSS=${NDK_CROSS}
            STATIC_CC=${NDK_CC}
            DYNAMIC_CC="${NDK_DYNAMIC_CC}"
            CCDEBUG="$<$<CONFIG:Debug>: -g>"
            XCFLAGS=${LUAJIT_XCFLAGS}
            TARGET_LD=${NDK_CC}
            TARGET_AR="${NDK_TARGET_AR}"
            TARGET_STRIP=${NDK_STRIP}
            TARGET_SYS=Linux
        COMMAND ${CMAKE_COMMAND} -E copy ${LUAJIT_SOURCE_ROOT}/libluajit.a ${LUAJIT_LIB_PATH}
        WORKING_DIRECTORY ${LUAJIT_SOURCE_ROOT}
        COMMENT "Building LuaJIT for Android (${ANDROID_ABI})"
    )
elseif (CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    if (CMAKE_OSX_ARCHITECTURES STREQUAL "x86_64;arm64")
        set(LUAJIT_BUILD_SCRIPT_PATH ${CMAKE_SOURCE_DIR}/make_luajit2_osx_universal.sh)
    else ()
        message(FATAL_ERROR "Only universal (x86_64;arm64) is supported.")
    endif ()
    add_custom_command(
        OUTPUT ${LUAJIT_LIB_PATH}
        COMMAND ${CMAKE_COMMAND} -E env MACOSX_DEPLOYMENT_TARGET=${DEPLOYMENT_TARGET} LUAJIT_XCFLAGS=${LUAJIT_XCFLAGS}
                ${LUAJIT_BUILD_SCRIPT_PATH} $<$<CONFIG:Debug>:--debug>
        COMMAND ${CMAKE_COMMAND} -E copy ${LUAJIT_SOURCE_ROOT}/libluajit.a ${LUAJIT_LIB_PATH}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        COMMENT "Building LuaJIT for macOS (${CMAKE_OSX_ARCHITECTURES})"
    )
elseif (IOS)
    if (CMAKE_OSX_ARCHITECTURES STREQUAL "arm64")
        set(LUAJIT_BUILD_SCRIPT_PATH ${CMAKE_SOURCE_DIR}/make_luajit2_ios_arm64.sh)
    else ()
        message(FATAL_ERROR "Only arm64 is supported.")
    endif ()
    add_custom_command(
        OUTPUT ${LUAJIT_LIB_PATH}
        COMMAND /bin/sh -c "env -i LUAJIT_XCFLAGS='${LUAJIT_XCFLAGS}' ${LUAJIT_BUILD_SCRIPT_PATH} $<$<CONFIG:Debug>:--debug> --ios-deployment-target ${DEPLOYMENT_TARGET}"
        COMMAND ${CMAKE_COMMAND} -E copy ${LUAJIT_SOURCE_ROOT}/libluajit.a ${LUAJIT_LIB_PATH}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        COMMENT "Building LuaJIT for iOS (${CMAKE_OSX_ARCHITECTURES})"
    )
endif ()

add_custom_target(luajit2_build DEPENDS ${LUAJIT_LIB_PATH})
