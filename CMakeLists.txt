## @Project.Name@ project
# 
# Copyright (c) @Date.Year@ @Git.Config{user.name}@
#
# Licensed under the BSD 3-Clause license.
# For more information see the provided LICENSE.txt file.
#
## Purpose
#
# This is the main CMake file for building and providing distribution
# of the library.

## CMake shenanigans
cmake_minimum_required(VERSION 3.14)
list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")

## Policies ####################################################################
cmake_policy(SET CMP0048 NEW) # project sets VERSION vars
cmake_policy(SET CMP0091 NEW) # MSVC does not set the runtime library in CMAKE_<LANG>_FLAGS
cmake_policy(SET CMP0092 NEW) # MSVC does not set the default /W3 in CMAKE_<LANG>_FLAGS
cmake_policy(SET CMP0009 NEW) # Do not follow symlinks in GLOB_RECURSE
cmake_policy(SET CMP0110 NEW) # Allows spaces in CTest names

## Project #####################################################################
project("@Project.Name@"
        VERSION "@Project.Version//0.1.0@"
        DESCRIPTION "@Project.Description@"
        LANGUAGES CXX
        )

## Modules #####################################################################
## stdlib ##
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
include(InstallRequiredSystemLibraries)
## project ##
include(utils)
include(warnings)     # target: @Project.Name@Warnings
include(dependencies) # target: @Project.Name@Dependencies

## Project configuration #######################################################

## Project option name ##
string(TOUPPER "${PROJECT_NAME}" "${PROJECT_NAME}_OPTION")

## Check if main project ##
if (CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    set("${PROJECT_NAME}_MAIN" On)
else ()
    set("${PROJECT_NAME}_MAIN" Off)
endif ()

## Options ##
option("${${PROJECT_NAME}_OPTION}_BUILD_TESTS"
       "Build the ${PROJECT_NAME} test suite [Off as dependency]" 
       "${${PROJECT_NAME}_MAIN}"
       )
option("${${PROJECT_NAME}_OPTION}_BUILD_DOCS"
       "Build the ${PROJECT_NAME} documentation (Requires: 'Doxygen') [Off]" 
       Off
       )
option("${${PROJECT_NAME}_OPTION}_BUILD_STATIC"
       "Build ${PROJECT_NAME} as a static library instead of a shared one [Off]"
       Off
       )

NameOption("${${PROJECT_NAME}_BUILD_STATIC}" "SHARED;STATIC" "${PROJECT_NAME}_TARGET_TYPE")
message(STATUS "[${PROJECT_NAME}] Building ${PROJECT_NAME} as ${${PROJECT_NAME}_TARGET_TYPE} library")

## Debug flags ##
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -D_GLIBCXX_DEBUG")

## Library target ##############################################################
## Main target name ##
set("${PROJECT_NAME}_TARGET" "@Project.Target@")

## Create header target ##
add_subdirectory(inc)
# Targets:
# - "@Project.Target@Headers" INTERFACE
# - "@Project.Name@::@Project.Target@Headers" ALIAS
# Vars:
# - "${${PROJECT_NAME}_TARGET}_HEADERS" = "@Project.Target@Headers"

## Create source target ##
add_subdirectory(src)
# Targets:
# - "@Project.Target@Sources" INTERFACE
# - "@Project.Name@::@Project.Target@Sources" ALIAS
# Vars:
# - "${${PROJECT_NAME}_TARGET}_OBJECTS" = "@Project.Target@Objects"

## Settings target ##
add_library("@Project.Target@Settings" INTERFACE)
add_library("@Project.Name@::@Project.Target@Settings" ALIAS "@Project.Target@Settings")
set("${${PROJECT_NAME}_TARGET}_SETTINGS" = "@Project.Target@Settings")

## Entity export semantics ##
if ("${${PROJECT_NAME}_OPTION}_BUILD_SHARED")
    target_compile_definitions("${${${PROJECT_NAME}_TARGET}_SETTINGS}"
                               INTERFACE
                               "${${PROJECT_NAME}_TARGET}_STATIC"
                               )
else ()
    target_compile_options("${${${PROJECT_NAME}_TARGET}_SETTINGS}" 
                           INTERFACE
                           $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-fvisibility=hidden>
                           )
endif ()

## Require C++20 ##
target_compile_features("${${${PROJECT_NAME}_TARGET}_SETTINGS}"
                        INTERFACE
                        cxx_std_20
                        )

## Create final library ##
add_library("@Project.Target@")
add_library("@Project.Name@::@Project.Target@" ALIAS "@Project.Target@")

target_link_libraries("@Project.Target@"
                      PUBLIC
                      "${${${PROJECT_NAME}_TARGET}_HEADERS}"
                      PRIVATE
                      "${${${PROJECT_NAME}_TARGET}_SETTINGS}"
                      "${${${PROJECT_NAME}_TARGET}_SOURCES}"
                      "${${${PROJECT_NAME}_TARGET}_WARNINGS}"
                      "${${${PROJECT_NAME}_TARGET}_DEPENDENCIES}"
                      )

## Optional targets ############################################################

## Enable tests ##
if ("${${PROJECT_NAME}_OPTION}_BUILD_TESTS")
    include(CTest)

    message(STATUS "[${PROJECT_NAME}] Building tests")

    add_subdirectory(test)
endif ()

## Build docs ##
if ("${${PROJECT_NAME}_OPTION}_BUILD_DOCS")
    message(STATUS "[${PROJECT_NAME}] Building docs")

    add_subdirectory(docs)
endif ()

## Install targets #############################################################

install(TARGETS "${${PROJECT_NAME}_TARGET}"
        EXPORT "${PROJECT_NAME}Targets"
        LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
        INCLUDES DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
        )

write_basic_package_version_file(
        "${PROJECT_NAME}ConfigVersion.cmake"
        VERSION "${PROJECT_VERSION}"
        COMPATIBILITY SameMajorVersion
)

install(EXPORT "${PROJECT_NAME}Targets"
        FILE "${PROJECT_NAME}Targets.cmake"
        NAMESPACE @Project.Name@::
        DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}"
        )

configure_file("${CMAKE_CURRENT_SOURCE_DIR}/cmake/${PROJECT_NAME}Config.cmake.in"
               "${PROJECT_NAME}Config.cmake"
               @ONLY
               )

install(FILES
        "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
        DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}"
        )
