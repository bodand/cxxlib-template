## @Project.Name@ project
#
# Copyright (c) @Date.Year@ @Git.Config{user.name}@
#
# Licensed under the BSD 3-Clause license.
# For more information see the provided LICENSE.txt file.
#
## Purpose
#
# This file manages all the project source files and packages them into
# an object library for easier management.
#
## Defines
#
# Targets:
# - "@Project.Target@Sources" INTERFACE
# - "@Project.Name@::@Project.Target@Sources" ALIAS
# Vars:
# - "${${PROJECT_NAME}_TARGET}_SOURCES" = "@Project.Target@Sources"

## Libray Target ###############################################################
add_library("@Project.Target@Sources" OBJECT
            "dummy.cxx"
            )
add_library("@Project.Name@::@Project.Target@Sources" ALIAS "@Project.Target@Sources")

set("${${PROJECT_NAME}_TARGET}_SOURCES" "@Project.Target@Sources")
set("${${PROJECT_NAME}_TARGET}_SOURCES" "@Project.Target@Sources" PARENT_SCOPE)

target_link_libraries("${${${PROJECT_NAME}_TARGET}_SOURCES}"
                      PRIVATE
                      "${${${PROJECT_NAME}_TARGET}_HEADERS}"
                      "${${${PROJECT_NAME}_TARGET}_SETTINGS}"
                      @Project.Target@Warnings
                      @Project.Target@Dependencies
                      )

## Installation ################################################################
install(TARGETS "${${${PROJECT_NAME}_TARGET}_SOURCES}"
        EXPORT "${PROJECT_NAME}Targets"
        )
