# Copyright (c) 2014, Bogdan Cristea and LTE Engineering Software,
# Kitware, Inc., Insight Software Consortium.  All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# Updated by Alex Stewart (alexs.mac@gmail.com)
#
# *****************************************************************************
#      Now maintained by Alexander Widerberg (widerbergaren [at] gmail.com)
#                      under the BSD-Clause-3 licence
# *****************************************************************************
#
#                           INFORMATION / HELP
#
# The following variables control the behaviour of this toolchain:
#
# IOS_PLATFORM: OS (default), SIMULATOR, SIMULATOR64, TVOS or SIMULATOR_TVOS
#    OS = Build for iOS.
#    SIMULATOR = Build for x86 iPhone simulator.
#    SIMULATOR64 = Build for x64 iPhone simulator.
#    TVOS = Build for Apple tvOS.
#    SIMULATOR_TVOS = Build for x64 Apple TV Simulator.
#    WATCHOS = Build for Apple watchOS.
#    SIMULATOR_WATCHOS = Build for x86 watchOS Simulator.
#    SIMULATOR64_WATCHOS = Build for x64 watchOS Simulator.
# IOS_DEPLOYMENT_TARGET: Minimum version for deployment target.
# CMAKE_OSX_SYSROOT: Path to the iOS SDK to use. By default this is
#    automatically determined from IOS_PLATFORM and xcodebuild, but can also be
#    manually specified (although this should not be required).
# CMAKE_IOS_DEVELOPER_ROOT: Path to the Developer directory for the iOS
#    platform being compiled for. By default this is automatically determined
#    from CMAKE_OSX_SYSROOT, but can also be manually specified (although this
#    should not be required).
# ENABLE_BITCODE: (ON / OFF) Enables or disables bitcode support. Default: ON.
# ENABLE_ARC: (ON / OFF) Enables or disables ARC support. Default: ON.
# IOS_ARCH: (armv7 armv7s armv7k arm64 i386 x86_64) If specified, will override the
#    default architectures for the given IOS_PLATFORM. Default architectures:
#    OS = armv7 armv7s arm64
#    SIMULATOR = i386
#    SIMULATOR64 = x86_64
#    TVOS = arm64
#    SIMULATOR_TVOS = x86_64
#    WATCHOS = armv7k
#    SIMULATOR_WATCHOS = i386
#    SIMULATOR64_WATCHOS = x86_64
#
# Copyright 2018, Alexander Saprykin <saprykin.spb@gmail.com>
#

# Get the Xcode version being used.
execute_process (COMMAND xcodebuild -version OUTPUT_VARIABLE XCODE_VERSION
                                             ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE
)

string (REGEX MATCH "Xcode [0-9\\.]+" XCODE_VERSION "${XCODE_VERSION}")
string (REGEX REPLACE "Xcode ([0-9\\.]+)" "\\1" XCODE_VERSION "${XCODE_VERSION}")

message (STATUS "Building with Xcode version: ${XCODE_VERSION}")

# Default to building for iOS if not specified otherwise, and we cannot
# determine the platform from the CMAKE_OSX_ARCHITECTURES variable. The use
# of CMAKE_OSX_ARCHITECTURES is such that try_compile() projects can correctly
# determine the value of IOS_PLATFORM from the root project, as
# CMAKE_OSX_ARCHITECTURES is propagated to them by CMake.

if (NOT DEFINED IOS_PLATFORM)
        if (CMAKE_OSX_ARCHITECTURES)
                if (CMAKE_OSX_ARCHITECTURES MATCHES ".*arm.*")
                        set (IOS_PLATFORM "OS")
                elseif (CMAKE_OSX_ARCHITECTURES MATCHES "i386")
                        set (IOS_PLATFORM "SIMULATOR")
                elseif (CMAKE_OSX_ARCHITECTURES MATCHES "x86_64")
                        set (IOS_PLATFORM "SIMULATOR64")
                endif()
        endif()

        if (NOT IOS_PLATFORM)
                set (IOS_PLATFORM "OS")
        endif()
endif()

set (IOS_PLATFORM ${IOS_PLATFORM} CACHE STRING "Type of iOS platform for which to build.")

# Determine the platform name and architectures for use in xcodebuild commands
# from the specified IOS_PLATFORM name.

if (IOS_PLATFORM STREQUAL "OS")
        set (XCODE_IOS_PLATFORM "iphoneos")

        if (NOT IOS_ARCH)
                set (IOS_ARCH "armv7;armv7s;arm64")
        endif()
elseif (IOS_PLATFORM STREQUAL "SIMULATOR")
        set (XCODE_IOS_PLATFORM "iphonesimulator")
        set (ENABLE_BITCODE OFF)

        if (NOT IOS_ARCH)
                set (IOS_ARCH "i386")
        endif()
elseif (IOS_PLATFORM STREQUAL "SIMULATOR64")
        set (XCODE_IOS_PLATFORM "iphonesimulator")
        set (ENABLE_BITCODE OFF)

        if (NOT IOS_ARCH)
                set (IOS_ARCH "x86_64")
        endif()
elseif (IOS_PLATFORM STREQUAL "TVOS")
        set (XCODE_IOS_PLATFORM "appletvos")

        if (NOT IOS_ARCH)
                set (IOS_ARCH "arm64")
        endif()
elseif (IOS_PLATFORM STREQUAL "SIMULATOR_TVOS")
        set (XCODE_IOS_PLATFORM "appletvsimulator")
        set (ENABLE_BITCODE OFF)

        if (NOT IOS_ARCH)
                set (IOS_ARCH "x86_64")
        endif()
elseif (IOS_PLATFORM STREQUAL "WATCHOS")
        set (XCODE_IOS_PLATFORM "watchos")

        if (NOT IOS_ARCH)
                set (IOS_ARCH "armv7k")
        endif()
elseif (IOS_PLATFORM STREQUAL "SIMULATOR_WATCHOS")
        set (XCODE_IOS_PLATFORM "watchsimulator")
        set (ENABLE_BITCODE OFF)

        if (NOT IOS_ARCH)
                set (IOS_ARCH "i386")
        endif()
elseif (IOS_PLATFORM STREQUAL "SIMULATOR64_WATCHOS")
        set (XCODE_IOS_PLATFORM "watchsimulator")
        set (ENABLE_BITCODE OFF)

        if (NOT IOS_ARCH)
                set (IOS_ARCH "x86_64")
        endif()
else()
        message (FATAL_ERROR "Invalid IOS_PLATFORM: ${IOS_PLATFORM}")
endif()

message (STATUS "Configuring iOS build for platform: ${IOS_PLATFORM}, architecture(s): ${IOS_ARCH}")

# If user did not specify the SDK root to use, then query xcodebuild for it.

if (NOT CMAKE_OSX_SYSROOT)
        execute_process (COMMAND xcodebuild -version -sdk ${XCODE_IOS_PLATFORM} Path
                         OUTPUT_VARIABLE CMAKE_OSX_SYSROOT
                         ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE
        )

        message (STATUS "Using SDK: ${CMAKE_OSX_SYSROOT} for platform: ${IOS_PLATFORM}")
endif()

if (NOT EXISTS ${CMAKE_OSX_SYSROOT})
        message(FATAL_ERROR "Invalid CMAKE_OSX_SYSROOT: ${CMAKE_OSX_SYSROOT} does not exist.")
endif()

# Specify minimum version of deployment target.

if (NOT DEFINED IOS_DEPLOYMENT_TARGET)
        if (IOS_PLATFORM MATCHES ".*WATCHOS")
                set (IOS_DEPLOYMENT_TARGET "2.0" CACHE STRING "Minimum watchOS version to build for." )
        else()
                set (IOS_DEPLOYMENT_TARGET "8.0" CACHE STRING "Minimum iOS version to build for." )
        endif()

        message (STATUS "Using the default min-version since IOS_DEPLOYMENT_TARGET not provided.")
endif()

if (NOT IOS_DEPLOYMENT_TARGET VERSION_LESS 11.0 AND NOT IOS_PLATFORM MATCHES ".*WATCHOS")
    # iOS 11 does not support 32-bit (armv7*).
    foreach (ARCH ${IOS_ARCH})
        if (ARCH MATCHES "armv7.*")
            message (STATUS "iOS architecture removed: ${ARCH} is not supported by "
                            "the minimum deployment iOS version ${IOS_DEPLOYMENT_TARGET}."
            )
        else()
            list (APPEND VALID_IOS_ARCH ${ARCH})
        endif()
    endforeach()
    
    set (IOS_ARCH ${VALID_IOS_ARCH})
endif()

# Use bitcode or not

if (NOT DEFINED ENABLE_BITCODE)
        # Unless specified, enable bitcode support by default
        set (ENABLE_BITCODE ON CACHE BOOL "Wheter or not to enable bitcode")
        message (STATUS "Enabling bitcode support by default.")
endif()

# Use ARC or not

if (NOT DEFINED ENABLE_ARC)
        # Unless specified, enable ARC support by default
        set (ENABLE_ARC ON CACHE BOOL "Wheter or not to enable ARC")
        message (STATUS "Enabling ARC support by default.")
endif()

# Get the SDK version information.

execute_process (COMMAND xcodebuild -sdk ${CMAKE_OSX_SYSROOT} -version SDKVersion
                 OUTPUT_VARIABLE IOS_SDK_VERSION
                 ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE
)

# Find the Developer root for the specific iOS platform being compiled for
# from CMAKE_OSX_SYSROOT. Should be ../../ from SDK specified in
# CMAKE_OSX_SYSROOT. There does not appear to be a direct way to obtain
# this information from xcrun or xcodebuild.

if (NOT CMAKE_IOS_DEVELOPER_ROOT)
        get_filename_component (IOS_PLATFORM_SDK_DIR ${CMAKE_OSX_SYSROOT} PATH)
        get_filename_component (CMAKE_IOS_DEVELOPER_ROOT ${IOS_PLATFORM_SDK_DIR} PATH)
endif()

if (NOT EXISTS ${CMAKE_IOS_DEVELOPER_ROOT})
        message (FATAL_ERROR "Invalid CMAKE_IOS_DEVELOPER_ROOT: ${CMAKE_IOS_DEVELOPER_ROOT} does not exist.")
endif()

# Find the C & C++ compilers for the specified SDK.

if (NOT CMAKE_C_COMPILER)
        execute_process (COMMAND xcrun -sdk ${CMAKE_OSX_SYSROOT} -find clang
                         OUTPUT_VARIABLE CMAKE_C_COMPILER
                         ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
        message (STATUS "Using C compiler: ${CMAKE_C_COMPILER}")
endif()

if (NOT CMAKE_CXX_COMPILER)
        execute_process (COMMAND xcrun -sdk ${CMAKE_OSX_SYSROOT} -find clang++
                         OUTPUT_VARIABLE CMAKE_CXX_COMPILER
                         ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
        message (STATUS "Using CXX compiler: ${CMAKE_CXX_COMPILER}")
endif()

# Find (Apple's) libtool.

execute_process (COMMAND xcrun -sdk ${CMAKE_OSX_SYSROOT} -find libtool
                 OUTPUT_VARIABLE IOS_LIBTOOL
                 ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
message (STATUS "Using libtool: ${IOS_LIBTOOL}")

# Configure libtool to be used instead of ar + ranlib to build static libraries.
# This is required on Xcode 7+, but should also work on previous versions of
# Xcode.

set (CMAKE_C_CREATE_STATIC_LIBRARY "${IOS_LIBTOOL} -static -o <TARGET> <LINK_FLAGS> <OBJECTS>")
set (CMAKE_CXX_CREATE_STATIC_LIBRARY "${IOS_LIBTOOL} -static -o <TARGET> <LINK_FLAGS> <OBJECTS>")

# Standard settings.

set (CMAKE_SYSTEM_NAME Darwin CACHE INTERNAL "")
set (CMAKE_SYSTEM_VERSION ${IOS_SDK_VERSION} CACHE INTERNAL "")
set (UNIX TRUE CACHE BOOL "")
set (APPLE TRUE CACHE BOOL "")
set (IOS TRUE CACHE BOOL "")
set (CMAKE_AR ar CACHE FILEPATH "" FORCE)
set (CMAKE_RANLIB ranlib CACHE FILEPATH "" FORCE)

# Force unset of OS X-specific deployment target (otherwise autopopulated),
# required as of cmake 2.8.10.

set (CMAKE_OSX_DEPLOYMENT_TARGET "" CACHE STRING "Must be empty for iOS builds." FORCE)

# Set the architectures for which to build.

set (CMAKE_OSX_ARCHITECTURES ${IOS_ARCH} CACHE STRING "Build architecture for iOS")

# All iOS/Darwin specific settings - some may be redundant.

set (CMAKE_SHARED_LIBRARY_PREFIX "lib")
set (CMAKE_SHARED_LIBRARY_SUFFIX ".dylib")
set (CMAKE_SHARED_MODULE_PREFIX "lib")
set (CMAKE_SHARED_MODULE_SUFFIX ".so")
set (CMAKE_MODULE_EXISTS 1)
set (CMAKE_DL_LIBS "")

set (CMAKE_C_OSX_COMPATIBILITY_VERSION_FLAG "-compatibility_version ")
set (CMAKE_C_OSX_CURRENT_VERSION_FLAG "-current_version ")
set (CMAKE_CXX_OSX_COMPATIBILITY_VERSION_FLAG "${CMAKE_C_OSX_COMPATIBILITY_VERSION_FLAG}")
set (CMAKE_CXX_OSX_CURRENT_VERSION_FLAG "${CMAKE_C_OSX_CURRENT_VERSION_FLAG}")

message (STATUS "Building for minimum OS version: ${IOS_DEPLOYMENT_TARGET} (SDK version: ${IOS_SDK_VERSION})")

# Note that only Xcode 7+ supports the newer more specific:
# -m${XCODE_IOS_PLATFORM}-version-min flags, older versions of Xcode use:
# -m(ios/ios-simulator)-version-min instead.
if (IOS_PLATFORM STREQUAL "OS")
        if (XCODE_VERSION VERSION_LESS 7.0)
                set (XCODE_IOS_PLATFORM_VERSION_FLAGS "-mios-version-min=${IOS_DEPLOYMENT_TARGET}")
        else()
                # Xcode 7.0+ uses flags we can build directly from XCODE_IOS_PLATFORM.
                set (XCODE_IOS_PLATFORM_VERSION_FLAGS "-m${XCODE_IOS_PLATFORM}-version-min=${IOS_DEPLOYMENT_TARGET}")
        endif()
elseif (IOS_PLATFORM STREQUAL "TVOS")
        set (XCODE_IOS_PLATFORM_VERSION_FLAGS "-mtvos-version-min=${IOS_DEPLOYMENT_TARGET}")
elseif (IOS_PLATFORM STREQUAL "SIMULATOR_TVOS")
        set (XCODE_IOS_PLATFORM_VERSION_FLAGS "-mtvos-simulator-version-min=${IOS_DEPLOYMENT_TARGET}")
elseif (IOS_PLATFORM STREQUAL "WATCHOS")
        set (XCODE_IOS_PLATFORM_VERSION_FLAGS "-mwatchos-version-min=${IOS_DEPLOYMENT_TARGET}")
elseif (IOS_PLATFORM STREQUAL "SIMULATOR_WATCHOS" OR IOS_PLATFORM STREQUAL "SIMULATOR64_WATCHOS")
        set (XCODE_IOS_PLATFORM_VERSION_FLAGS "-mwatchos-simulator-version-min=${IOS_DEPLOYMENT_TARGET}")
else()
        # SIMULATOR or SIMULATOR64 both use -mios-simulator-version-min.
        set (XCODE_IOS_PLATFORM_VERSION_FLAGS "-mios-simulator-version-min=${IOS_DEPLOYMENT_TARGET}")
endif()

message (STATUS "Version flags set to: ${XCODE_IOS_PLATFORM_VERSION_FLAGS}")

if (ENABLE_BITCODE)
        set (BITCODE "-fembed-bitcode")
        message (STATUS "Enabling bitcode support.")
else()
        set (BITCODE "")
        message (STATUS "Disabling bitcode support.")
endif()

if (ENABLE_ARC)
        set (FOBJC_ARC "-fobjc-arc")
        message (STATUS "Enabling ARC support.")
else()
        set (FOBJC_ARC "-fno-objc-arc")
        message (STATUS "Disabling ARC support.")
endif()

set (CMAKE_C_FLAGS "${XCODE_IOS_PLATFORM_VERSION_FLAGS} ${BITCODE} -fobjc-abi-version=2 ${FOBJC_ARC} ${C_FLAGS}")
set (CMAKE_CXX_FLAGS "${XCODE_IOS_PLATFORM_VERSION_FLAGS} ${BITCODE} -fobjc-abi-version=2 ${FOBJC_ARC} ${CXX_FLAGS}")
set (CMAKE_C_LINK_FLAGS "${XCODE_IOS_PLATFORM_VERSION_FLAGS} -Wl,-search_paths_first ${C_LINK_FLAGS}")
set (CMAKE_CXX_LINK_FLAGS "${XCODE_IOS_PLATFORM_VERSION_FLAGS}  -Wl,-search_paths_first ${CXX_LINK_FLAGS}")

# In order to ensure that the updated compiler flags are used in try_compile()
# tests, we have to forcibly set them in the CMake cache, not merely set them
# in the local scope.

list (APPEND VARS_TO_FORCE_IN_CACHE
        CMAKE_C_FLAGS
        CMAKE_CXX_FLAGS
        CMAKE_C_LINK_FLAGS
        CMAKE_CXX_LINK_FLAGS
)

foreach (VAR_TO_FORCE ${VARS_TO_FORCE_IN_CACHE})
        set (${VAR_TO_FORCE} "${${VAR_TO_FORCE}}" CACHE STRING "" FORCE)
endforeach()

set (CMAKE_PLATFORM_HAS_INSTALLNAME 1)

set (CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS "-dynamiclib")
set (CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS "-dynamiclib")
set (CMAKE_SHARED_MODULE_CREATE_C_FLAGS "-bundle")
set (CMAKE_SHARED_MODULE_CREATE_CXX_FLAGS "-bundle")
set (CMAKE_SHARED_MODULE_LOADER_C_FLAG "-Wl,-bundle_loader,")
set (CMAKE_SHARED_MODULE_LOADER_CXX_FLAG "-Wl,-bundle_loader,")
set (CMAKE_FIND_LIBRARY_SUFFIXES ".dylib" ".so" ".a")

# Hack: If a new CMake (which uses CMAKE_INSTALL_NAME_TOOL) runs on an old
# build tree (where install_name_tool was hardcoded) and where
# CMAKE_INSTALL_NAME_TOOL isn't in the cache and still CMake didn't fail in
# CMakeFindBinUtils.cmake (because it isn't rerun) hardcode
# CMAKE_INSTALL_NAME_TOOL here to install_name_tool, so it behaves as it did
# before, Alex.

if (NOT DEFINED CMAKE_INSTALL_NAME_TOOL)
        find_program (CMAKE_INSTALL_NAME_TOOL install_name_tool)
endif (NOT DEFINED CMAKE_INSTALL_NAME_TOOL)

# Set the find root to the iOS developer roots and to user defined paths.
set (CMAKE_FIND_ROOT_PATH ${CMAKE_IOS_DEVELOPER_ROOT}
          ${CMAKE_OSX_SYSROOT}
          ${CMAKE_PREFIX_PATH}
     CACHE string "iOS find search path root" FORCE
)

# Default to searching for frameworks first.

set (CMAKE_FIND_FRAMEWORK FIRST)

# Set up the default search directories for frameworks.

set (CMAKE_SYSTEM_FRAMEWORK_PATH
        ${CMAKE_OSX_SYSROOT}/System/Library/Frameworks
        ${CMAKE_OSX_SYSROOT}/System/Library/PrivateFrameworks
        ${CMAKE_OSX_SYSROOT}/Developer/Library/Frameworks
)

# Only search the specified iOS SDK, not the remainder of the host filesystem.

set (CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY)
set (CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set (CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
