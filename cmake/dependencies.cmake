## @Project.Name@ project
#
# Copyright (c) @Date.Year@ @Git.Config{user.name}@
#
# Licensed under the BSD 3-Clause license.
# For more information see the provided LICENSE.txt file.
#
## Purpose
#
# This is the CMake file that manages dependencies that can be
# handled by CMake itself.
#
## Defines
#
# Target:
# - @Project.Name@Dependencies

## Download GetDependency ######################################################
if (NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/cmake/GetDependency.cmake")
    message("[${PROJECT_NAME}] Downloading GetDependency")
    file(DOWNLOAD
         "https://raw.githubusercontent.com/bodand/GetDependency/master/cmake/GetDependency.cmake"
         "${CMAKE_CURRENT_SOURCE_DIR}/cmake/GetDependency.cmake"
         )
endif ()
include(GetDependency)

## Create the dependency target ################################################
add_library(@Project.Name@Dependencies INTERFACE)
add_library(@Project.Name@LeakedDependencies INTERFACE)
add_library(@Project.Name@TestDependencies INTERFACE)

## Get dependencies ############################################################
message(CHECK_START "[${PROJECT_NAME}] Setting up dependencies")
if ("${${${PROJECT_NAME}_OPTION}_BUILD_TESTS}")
    set(_DEP_COUNT 2)
else ()
    set(_DEP_COUNT 1)
endif ()

## {fmt} ##
message(CHECK_START "[${PROJECT_NAME}] '{fmt}' (1/${_DEP_COUNT})")
set(FMT_INSTALL ON CACHE BOOL "." FORCE)
list(APPEND CMAKE_MESSAGE_INDENT "  ")
GetDependency(fmt
              REPOSITORY_URL https://github.com/fmtlib/fmt.git
              VERSION 7.0.3
              REMOTE_ONLY
              )
list(POP_BACK CMAKE_MESSAGE_INDENT)
target_link_libraries(@Project.Name@Dependencies
                      INTERFACE
                      fmt::fmt
                      )
message(CHECK_PASS "done")

if ("${${${PROJECT_NAME}_OPTION}_BUILD_TESTS}")
    message(CHECK_START "[${PROJECT_NAME}] 'Catch2' (2/${_DEP_COUNT})")
    list(APPEND CMAKE_MESSAGE_INDENT "  ")
    GetDependency(
            Catch2
            REPOSITORY_URL https://github.com/catchorg/Catch2.git
            VERSION v2.12.1
    )
    list(POP_BACK CMAKE_MESSAGE_INDENT)
    target_link_libraries(@Project.Name@TestDependencies
                          INTERFACE
                          Catch2::Catch2
                          )
    message(CHECK_PASS "done")
endif ()

message(CHECK_PASS "done")

## Installation ################################################################
install(TARGETS "@Project.Name@Dependencies" "@Project.Name@LeakedDependencies"
        EXPORT "${PROJECT_NAME}Targets"
        )
