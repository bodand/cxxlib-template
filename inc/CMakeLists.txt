## @Project.Name@ project
# 
# Copyright (c) @Date.Year@ @Git.Config{user.name}@
#
# Licensed under the BSD 3-Clause license.
# For more information see the provided LICENSE.txt file.
#
## Purpose
#
# This file manages all the project include files, and creates them into a
# target for easy consumption by the sources, and during install.
# 
## Defines
# 
# Targets:
# - "@Project.Target@Headers" INTERFACE
# - "@Project.Name@::@Project.Target@Headers" ALIAS
# Vars:
# - "${${PROJECT_NAME}_TARGET}_HEADERS" = "@Project.Target@Headers"

## Libray Target ###############################################################
add_library("@Project.Target@Headers" INTERFACE
            ## ...headers... ##
            )
add_library("@Project.Name@::@Project.Target@Headers" ALIAS "@Project.Target@Headers")
set("${${PROJECT_NAME}_TARGET}_HEADERS" "@Project.Target@Headers")

## Installation ################################################################
install(TARGETS "${${${PROJECT_NAME}_TARGET}_HEADERS}"
        EXPORT "${PROJECT_NAME}Targets"
        INCLUDES DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
        )

get_target_property(__INSTALL_HDR_SRCS 
                    "${${${PROJECT_NAME}_TARGET}_HEADERS}" 
                    INTERFACE_SOURCES
                    )
install(FILES
	${__INSTALL_HDR_SRCS}
        DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
        )