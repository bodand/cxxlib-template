## @Project.Name@ project
# 
# Copyright (c) @Date.Year@ @Git.Config{user.name}@
#
# Licensed under the BSD 3-Clause license.
# For more information see the provided LICENSE.txt file.
#
## Purpose
#
# Provides some utiltities for CMake usage

## NameOption(OptionValue Options StringValue)
#
# Assigns a string value from the list of two elements passed as Options
# depending of the truthyness of the value passed as OptionValue
# and returns in through StringValue
function(NameOption OptionValue Options _StringValue)
    if (OptionValue)
        list(GET Options 0 Val)
    else ()
        list(GET Options 1 Val)
    endif ()
    set("${_StringValue}" "${Val}" PARENT_SCOPE)
endfunction()
