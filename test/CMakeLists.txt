## @Project.Name@ project
# 
# Copyright (c) @Date.Year@ @Git.Config{user.name}@
#
# Licensed under the BSD 3-Clause license.
# For more information see the provided LICENSE.txt file.
#
## Purpose
#
# This is the main CMake file for managing the tests

## Catch CMake support #########################################################
include("${CMAKE_BINARY_DIR}/_deps/catch2-src/contrib/Catch.cmake")
# note: one day, this will break

## Create project
set(TESTED_PROJECT_NAME ${PROJECT_NAME})
project(${TESTED_PROJECT_NAME}_Test CXX)

## Create target ###############################################################
add_executable(${TESTED_PROJECT_NAME}_test
               test.main.cxx
               )

## Link dependencies ###########################################################
target_link_libraries(${TESTED_PROJECT_NAME}_test
                      PUBLIC
                      "${${${TESTED_PROJECT_NAME}_TARGET}_HEADERS}"
                      PRIVATE
                      "${${${TESTED_PROJECT_NAME}_TARGET}_SETTINGS}"
                      "${${${TESTED_PROJECT_NAME}_TARGET}_SOURCES}"
                      "@Project.Name@Warnings"
                      "@Project.Name@Dependencies"
                      "@Project.Name@TestDependencies"
                      )

## Own include dirs ############################################################
target_include_directories(${TESTED_PROJECT_NAME}_test PRIVATE
                           ${CMAKE_SOURCE_DIR}/src
                           )

## Register Catch tests to CTest ###############################################
catch_discover_tests(${TESTED_PROJECT_NAME}_test)

## Copy shared objects #########################################################
if (NOT ${${TESTED_PROJECT_NAME}_OPTION}_BUILD_STATIC)
    add_custom_command(TARGET ${TESTED_PROJECT_NAME}_test POST_BUILD
                       COMMENT "Copying ${TESTED_PROJECT_NAME} shared objects"
                       COMMAND "${CMAKE_COMMAND}" -E copy "$<TARGET_FILE:${${TESTED_PROJECT_NAME}_TARGET}>" "$<TARGET_FILE_DIR:${TESTED_PROJECT_NAME}_test>"
                       )
endif ()
