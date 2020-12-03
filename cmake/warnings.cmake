## @Project.Name@ project
# 
# Copyright (c) @Date.Year@ @Git.Config{user.name}@
#
# Licensed under the BSD 3-Clause license.
# For more information see the provided LICENSE.txt file.
#
## Purpose
#
# This is the CMake file that manages compiler warnigs.
#
## Defines
#
# Target:
# - @Project.Name@Warnings

## Modules #####################################################################
include(CheckCXXCompilerFlag)

## Warning check function ######################################################
function(CheckWarningFlag OptionName CacheName)
    if (OptionName MATCHES [[^/]]) # MSVC-style args are passed as-is
        set(WarningPrefix "")
    else ()
        set(WarningPrefix "-W")
    endif ()
    check_cxx_compiler_flag("${WarningPrefix}${OptionName}" "HasWarning_${CacheName}")
    set("HAS_WARNING_${CacheName}" ${HasWarning_${CacheName}} PARENT_SCOPE)
endfunction()

set(_@Project.Name@_POSSIBLE_WARNINGS
    # default enables
    extra pedantic sign-compare error=uninitialized unused cast-qual cast-align
    abstract-vbase-init array-bounds-pointer-arithmetic assign-enum consumed
    conditional-uninitialized deprecated-implementations header-hygiene error=move
    error=documentation-deprecated-sync error=non-virtual-dtor error=infinite-recursion
    keyword-macro loop-analysis newline-eof over-aligned redundant-parens
    reserved-id-macro sign-conversion signed-enum-bitfield thread-safety
    undefined-internal-type undefined-reinterpret-cast unused-const-variable
    unneeded-internal-declaration unreachable-code-aggressive unused-variable
    unused-exception-parameter unused-parameter unused-template error=lifetime
    error=sometimes-uninitialized tautological-overlap-compare suggest-final-types
    nullability-completeness unreachable-code-loop-increment redundant-decls
    suggest-attribute=pure suggest-attribute=const suggest-attribute=cold
    suggest-final-methods duplicated-branches placement-new=2 error=trampolines
    logical-op reorder
    /w14062 /w14165 /w14191 /w14242 /we4263 /w14265 /w14287 /w14296 /we4350 /we4355
    /w14355 /w14471 /we4545 /w14546 /w14547 /w14548 /w14549 /w14557 /we4596 /w14605
    /w14668 /w14768 /w14822 /we4837 /we4928 /we4946 /we4986 /w15032 /w15039 3
    /diagnostics:caret
    # default disables
    no-unknown-pragmas no-unused-macros no-nullability-extension
    no-c++20-extensions
    # extra warnings
    ${INFO_EXTRA_WARNINGS}
    ${${${PROJECT_NAME}_OPTION}_EXTRA_WARNINGS}
    )

add_library(@Project.Name@Warnings INTERFACE)

target_compile_options(@Project.Name@Warnings 
                       INTERFACE
                       $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-Wall>
                       )

foreach (warn IN LISTS _MAKEMAKE_POSSIBLE_WARNINGS)
    string(MAKE_C_IDENTIFIER "${warn}" cwarn)
    CheckWarningFlag("${warn}" "${cwarn}")
    if (HAS_WARNING_${cwarn})
        if (warn MATCHES [[^/]]) # MSVC-style args are passed as-is
            set(WarningPrefix "")
        else ()
            set(WarningPrefix "-W")
        endif ()
        target_compile_options(@Project.Name@Warnings INTERFACE "${WarningPrefix}${warn}")
    endif ()
endforeach ()

## Installation ################################################################
install(TARGETS "@Project.Name@Warnings"
        EXPORT "${PROJECT_NAME}Targets"
        )
