
# Copyright (c) 2012 Stefan Eilemann <Stefan.Eilemann@epfl.ch>

include(ExternalProject)
find_package(Git REQUIRED)
find_package(Subversion REQUIRED)
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

set(USE_EXTERNAL_SUBTARGETS update build buildonly configure test install
  package doxygen download)
foreach(subtarget ${USE_EXTERNAL_SUBTARGETS})
  add_custom_target(${subtarget}s)
  set_target_properties(${subtarget}s PROPERTIES FOLDER "00_Meta")
endforeach()
add_custom_target(AllProjects)
set_target_properties(AllProjects PROPERTIES FOLDER "00_Main")

# overwrite git clone script generation to avoid excessive cloning
function(_ep_write_gitclone_script script_filename source_dir git_EXECUTABLE git_repository git_tag src_name work_dir)
  file(WRITE ${script_filename}
"if(\"${git_tag}\" STREQUAL \"\")
  message(FATAL_ERROR \"Tag for git checkout should not be empty.\")
endif()
if(IS_DIRECTORY \"${work_dir}/${src_name}/.git\")
  execute_process(
    COMMAND \"${git_EXECUTABLE}\" fetch
    WORKING_DIRECTORY \"${work_dir}/${src_name}\"
    )
  execute_process(
    COMMAND \"${git_EXECUTABLE}\" checkout ${git_tag}
    WORKING_DIRECTORY \"${work_dir}/${src_name}\"
    RESULT_VARIABLE error_code
    )
  if(error_code)
    message(FATAL_ERROR \"Failed to checkout ${git_tag} in '${source_dir}'\")
  endif()
else()
  execute_process(
    COMMAND \${CMAKE_COMMAND} -E remove_directory \"${source_dir}\"
    RESULT_VARIABLE error_code
    )
  if(error_code)
    message(FATAL_ERROR \"Failed to remove directory: '${source_dir}'\")
  endif()

  execute_process(
    COMMAND \"${git_EXECUTABLE}\" ${GIT_SVN} clone \"${git_repository}\" \"${src_name}\"
    WORKING_DIRECTORY \"${work_dir}\"
    RESULT_VARIABLE error_code
    )
  if(error_code)
    message(FATAL_ERROR \"Failed to clone repository: '${git_repository}'\")
  endif()

  execute_process(
    COMMAND \"${git_EXECUTABLE}\" checkout ${git_tag}
    WORKING_DIRECTORY \"${work_dir}/${src_name}\"
    RESULT_VARIABLE error_code
    )
  if(error_code)
    message(FATAL_ERROR \"Failed to checkout tag: '${git_tag}'\")
  endif()
endif()

execute_process(
  COMMAND \"${git_EXECUTABLE}\" submodule init
  WORKING_DIRECTORY \"${work_dir}/${src_name}\"
  RESULT_VARIABLE error_code
  )
if(error_code)
  message(FATAL_ERROR \"Failed to init submodules in: '${work_dir}/${src_name}'\")
endif()

execute_process(
  COMMAND \"${git_EXECUTABLE}\" submodule update --recursive
  WORKING_DIRECTORY \"${work_dir}/${src_name}\"
  RESULT_VARIABLE error_code
  )
if(error_code)
  message(FATAL_ERROR \"Failed to update submodules in: '${work_dir}/${src_name}'\")
endif()

"
)
endfunction(_ep_write_gitclone_script)

# renames existing origin and adds user URL as new origin (git only)
function(USE_EXTERNAL_CHANGE_ORIGIN NAME ORIGIN_URL USER_URL ORIGIN_RENAME)
  if(NOT ORIGIN_RENAME)
    set(ORIGIN_RENAME "root")
  endif()
  if(ORIGIN_URL AND USER_URL)
    set(CHANGE_ORIGIN ${GIT_EXECUTABLE} remote set-url origin "${USER_URL}")
    set(RM_REMOTE ${GIT_EXECUTABLE} remote rm ${ORIGIN_RENAME} || ${GIT_EXECUTABLE} status) #workaround to ignore remote rm return value
    set(ADD_REMOTE ${GIT_EXECUTABLE} remote add ${ORIGIN_RENAME} "${ORIGIN_URL}")

    ExternalProject_Add_Step(${NAME} change_origin
      COMMAND ${CHANGE_ORIGIN}
      COMMAND ${RM_REMOTE}
      COMMAND ${ADD_REMOTE}
      WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/src/${NAME}"
      DEPENDERS build
      DEPENDEES download
      ALWAYS 1
    )
  endif()
endfunction()


function(USE_EXTERNAL_GATHER_ARGS NAME)
  # sets ${UPPER_NAME}_ARGS on return, to be passed to CMake
  string(TOUPPER ${NAME} UPPER_NAME)

  set(ARGS)
  set(DEPENDS)
  set(${UPPER_NAME}_ARGS)

  # recurse to get dependency roots
  foreach(PROJ ${${UPPER_NAME}_DEPENDS})
    use_external_gather_args(${PROJ})
    string(TOUPPER ${PROJ} UPPER_PROJ)
    set(ARGS ${ARGS} ${${UPPER_PROJ}_ARGS})
  endforeach()

  get_target_property(_check ${NAME} _EP_IS_EXTERNAL_PROJECT)
  if(NOT _check EQUAL 1) # installed package
    set(${UPPER_NAME}_ARGS ${ARGS} PARENT_SCOPE) # return value
    return()
  endif()

  # self root '-DFOO_ROOT=<path>'
  set(INSTALL_PATH "${CMAKE_CURRENT_BINARY_DIR}/install")
  if("${${UPPER_NAME}_ROOT_VAR}" STREQUAL "")
    set(ARGS ${ARGS} "-D${UPPER_NAME}_ROOT=${INSTALL_PATH}")
  else()
    set(ARGS ${ARGS} "-D${${UPPER_NAME}_ROOT_VAR}=${INSTALL_PATH}")
  endif()

  set(${UPPER_NAME}_ARGS ${ARGS} PARENT_SCOPE) # return value
endfunction()


function(USE_EXTERNAL_BUILDONLY name)
  ExternalProject_Get_Property(${name} binary_dir)

  get_property(cmd_set TARGET ${name} PROPERTY _EP_BUILD_COMMAND SET)
  if(cmd_set)
    get_property(cmd TARGET ${name} PROPERTY _EP_BUILD_COMMAND)
  else()
    _ep_get_build_command(${name} BUILD cmd)
  endif()

  get_property(log TARGET ${name} PROPERTY _EP_LOG_BUILD)
  if(log)
    set(log LOG 1)
  else()
    set(log "")
  endif()

  add_custom_target(${name}-buildonly
    COMMAND ${cmd}
    COMMENT "Building ${name}"
    WORKING_DIRECTORY ${binary_dir}
    )
  set_target_properties(${name}-buildonly PROPERTIES EXCLUDE_FROM_ALL ON)
endfunction()

function(_ep_add_test_command name)
  ExternalProject_Get_Property(${name} binary_dir)

  get_property(cmd_set TARGET ${name} PROPERTY _EP_TEST_COMMAND SET)
  if(cmd_set)
    get_property(cmd TARGET ${name} PROPERTY _EP_TEST_COMMAND)
  else()
    _ep_get_build_command(${name} TEST cmd)
  endif()

  string(REGEX REPLACE "^(.*/)cmake([^/]*)$" "\\1ctest\\2" cmd "${cmd}")
  add_custom_target(${name}-test
    COMMAND ${cmd}
    COMMENT "Testing ${name}"
    WORKING_DIRECTORY ${binary_dir}
    DEPENDS ${name}
    )
endfunction()


function(USE_EXTERNAL_MAKEFILE NAME)
  set(_makefile "${${UPPER_NAME}_SOURCE}/Makefile")
  set(_scriptdir ${CMAKE_CURRENT_BINARY_DIR}/${NAME})

  # Remove our old file before updating
  file(WRITE ${_scriptdir}/rmMakefile.cmake
    "if(EXISTS \"${_makefile}\")
       file(READ \"${_makefile}\" _makefile_contents)
       if(_makefile_contents MATCHES \"MAGIC_IS_BUILDYARD_MAKEFILE\")
         file(REMOVE \"${_makefile}\")
       endif()
     endif()")

  ExternalProject_Add_Step(${NAME} rmMakefile
    COMMENT "Removing in-source Makefile"
    COMMAND ${CMAKE_COMMAND} -P ${_scriptdir}/rmMakefile.cmake
    DEPENDEES mkdir DEPENDERS download ALWAYS 1
    )

  # Move our Makefile in place if no other exists
  file(WRITE ${_scriptdir}/cpMakefile.cmake
    "if(NOT EXISTS \"${_makefile}\")
       set(NAME ${NAME})
       set(CMAKE_SOURCE_DIR ${CMAKE_SOURCE_DIR})
       configure_file(${CMAKE_SOURCE_DIR}/CMake/Makefile.in \"${_makefile}\"
         @ONLY)
     endif()")

  ExternalProject_Add_Step(${NAME} cpMakefile
    COMMENT "Adding in-source Makefile"
    COMMAND ${CMAKE_COMMAND} -P ${_scriptdir}/cpMakefile.cmake
    DEPENDEES configure DEPENDERS build ALWAYS 1
    )
endfunction()


function(USE_EXTERNAL NAME)
  # Searches for an external project.
  #  Sets NAME_ROOT to the installation directory when not found using
  #  find_package().
  # * First searches using find_package taking into account:
  # ** NAME_ROOT CMake and environment variables
  # ** .../share/NAME/CMake
  # ** Version is read from optional $NAME.cmake
  # * If no pre-installed package is found, use ExternalProject to get dependency
  # ** External project settings are read from $NAME.cmake

  get_target_property(_check ${NAME} _EP_IS_EXTERNAL_PROJECT)
  if(_check EQUAL 1) # already used
    return()
  endif()

  string(SUBSTRING ${NAME} 0 2 SHORT_NAME)
  string(TOUPPER ${SHORT_NAME} SHORT_NAME)
  string(TOUPPER ${NAME} UPPER_NAME)
  set(ROOT ${UPPER_NAME}_ROOT)
  set(ENVROOT $ENV{${ROOT}})
  set(SHORT_ROOT ${SHORT_NAME}_ROOT)
  set(SHORT_ENVROOT $ENV{${SHORT_ROOT}})

  # CMake module search path
  if(${${SHORT_ROOT}})
    list(APPEND CMAKE_MODULE_PATH "${${SHORT_ROOT}}/share/${NAME}/CMake")
  endif()
  if(NOT "${SHORT_ENVROOT}" STREQUAL "")
    list(APPEND CMAKE_MODULE_PATH "${SHORT_ENVROOT}/share/${NAME}/CMake")
  endif()
  if(${${ROOT}})
    list(APPEND CMAKE_MODULE_PATH "${${ROOT}}/share/${NAME}/CMake")
  endif()
  if(NOT "${ENVROOT}" STREQUAL "")
    list(APPEND CMAKE_MODULE_PATH "${ENVROOT}/share/${NAME}/CMake")
  endif()

  list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/${NAME}/CMake")
  list(APPEND CMAKE_MODULE_PATH "${CMAKE_INSTALL_PREFIX}/share/${NAME}/CMake")
  list(APPEND CMAKE_MODULE_PATH /usr/share/${NAME}/CMake)
  list(APPEND CMAKE_MODULE_PATH /usr/local/share/${NAME}/CMake)

  # try find_package
  if(${NAME}_FOUND) # Opt: already found, be quiet and propagate upwards
    set(${NAME}_FOUND 1 PARENT_SCOPE)
    return()
  endif()

  find_package(${NAME} ${${UPPER_NAME}_VERSION} QUIET)
  if(${UPPER_NAME}_FOUND)
    set(${NAME}_FOUND 1) # compat with Foo_FOUND and FOO_FOUND usage
  endif()
  if(${NAME}_FOUND)
    message(STATUS "${USE_EXTERNAL_INDENT}${NAME}: installed in "
      "${${UPPER_NAME}_INCLUDE_DIRS}${${NAME}_INCLUDE_DIRS}")
    set(${NAME}_FOUND 1 PARENT_SCOPE)
    return()
  endif()

  unset(${NAME}_INCLUDE_DIR CACHE)        # some find_package (boost) don't
  unset(${UPPER_NAME}_INCLUDE_DIR CACHE)  # properly unset and recheck the
  unset(${NAME}_INCLUDE_DIRS CACHE)       # version on subsequent runs if it
  unset(${UPPER_NAME}_INCLUDE_DIRS CACHE) # failed
  unset(${NAME}_LIBRARY_DIRS CACHE)
  unset(${UPPER_NAME}_LIBRARy_DIRS CACHE)

  message(STATUS "${USE_EXTERNAL_INDENT}${NAME}: building from "
    "${${UPPER_NAME}_REPO_URL}:${${UPPER_NAME}_REPO_TAG}")
  set(USE_EXTERNAL_INDENT "${USE_EXTERNAL_INDENT}  ")

  if("${${UPPER_NAME}_REPO_URL}" STREQUAL "")
    message(STATUS
      "Missing dependency ${NAME}: No source repository, fix ${NAME}.cmake?")
    set(${NAME}_FOUND 1 PARENT_SCOPE) # ugh: removes dependency
    return()
  endif()

  # pull in dependent projects first
  set(DEPENDS)
  foreach(_dep ${${UPPER_NAME}_DEPENDS})
    get_target_property(_dep_check ${_dep} _EP_IS_EXTERNAL_PROJECT)
    if(NOT _dep_check EQUAL 1)
      use_external(${_dep})
    endif()
    if(${_dep}_FOUND)
      set(${_dep}_FOUND 1 PARENT_SCOPE)
    else()
      list(APPEND DEPENDS ${_dep})
    endif()
  endforeach()

  # External Project
  set(UPDATE_CMD)
  set(REPO_TYPE ${${UPPER_NAME}_REPO_TYPE})
  if(NOT REPO_TYPE)
    set(REPO_TYPE git)
  endif()
  string(TOUPPER ${REPO_TYPE} REPO_TYPE)
  if(REPO_TYPE STREQUAL "GIT-SVN")
    set(REPO_TYPE GIT)
    set(REPO_TAG GIT_TAG)
    set(GIT_SVN "svn")
    # svn rebase fails with local modifications, ignore
    set(UPDATE_CMD ${GIT_EXECUTABLE} svn rebase || ${GIT_EXECUTABLE} status
      ALWAYS TRUE)
  elseif(REPO_TYPE STREQUAL "GIT")
    set(REPO_TAG GIT_TAG)
    # pull fails if tag is a SHA hash, use git status to set exit value to true
    set(UPDATE_CMD ${GIT_EXECUTABLE} pull || ${GIT_EXECUTABLE} status
      ALWAYS TRUE)
  elseif(REPO_TYPE STREQUAL "SVN")
    set(REPO_TAG SVN_REVISION)
  else()
    message(FATAL_ERROR "Unknown repository type ${REPO_TYPE}")
  endif()

  if(NOT ${UPPER_NAME}_SOURCE)
    set(${UPPER_NAME}_SOURCE "${CMAKE_SOURCE_DIR}/src/${NAME}")
  endif()

  set(INSTALL_PATH "${CMAKE_CURRENT_BINARY_DIR}/install")
  use_external_gather_args(${NAME})
  set(ARGS -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
           -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PATH}
           ${${UPPER_NAME}_ARGS})

  ExternalProject_Add(${NAME}
    PREFIX "${CMAKE_CURRENT_BINARY_DIR}/${NAME}"
    BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/${NAME}"
    SOURCE_DIR "${${UPPER_NAME}_SOURCE}"
    INSTALL_DIR "${INSTALL_PATH}"
    DEPENDS "${DEPENDS}"
    ${REPO_TYPE}_REPOSITORY ${${UPPER_NAME}_REPO_URL}
    ${REPO_TAG} ${${UPPER_NAME}_REPO_TAG}
    UPDATE_COMMAND ${UPDATE_CMD}
    CMAKE_ARGS ${ARGS}
    TEST_BEFORE_INSTALL 1
    ${${UPPER_NAME}_EXTRA}
    STEP_TARGETS ${USE_EXTERNAL_SUBTARGETS}
    )
  use_external_buildonly(${NAME})

  if(REPO_TYPE STREQUAL "GIT")
    set(REPO_ORIGIN_URL ${${UPPER_NAME}_REPO_URL})
    set(REPO_USER_URL ${${UPPER_NAME}_USER_URL})
    set(REPO_ORIGIN_NAME ${${UPPER_NAME}_ORIGIN_NAME})
    use_external_change_origin(${NAME} "${REPO_ORIGIN_URL}" "${REPO_USER_URL}"
      "${REPO_ORIGIN_NAME}")
    unset(${REPO_ORIGIN_URL} CACHE)
    unset(${REPO_USER_URL} CACHE)
    unset(${REPO_ORIGIN_NAME} CACHE)
  endif()

  # add optional targets: package, doxygen
  get_property(cmd_set TARGET ${NAME} PROPERTY _EP_BUILD_COMMAND SET)
  if(cmd_set)
    get_property(cmd TARGET ${NAME} PROPERTY _EP_BUILD_COMMAND)
  else()
    _ep_get_build_command(${NAME} BUILD cmd)
  endif()

  if(NOT APPLE)
    set(fakeroot fakeroot)
  endif()

  add_custom_target(${NAME}-package
    COMMAND ${fakeroot} ${cmd} package
    DEPENDS ${NAME}
    COMMENT "Building package"
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${NAME}"
    )
  set_target_properties(${NAME}-package PROPERTIES EXCLUDE_FROM_ALL ON)

  add_custom_target(${NAME}-doxygen
    COMMAND ${cmd} doxygen
    DEPENDS ${NAME}
    COMMENT "Running doxygen"
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${NAME}"
    )
  set_target_properties(${NAME}-doxygen PROPERTIES EXCLUDE_FROM_ALL ON)

  add_custom_target(${NAME}-deps
    DEPENDS ${DEPENDS}
    COMMENT "Building ${NAME} dependencies"
    )
  set_target_properties(${NAME}-deps PROPERTIES EXCLUDE_FROM_ALL ON)

  # make optional if requested
  if(${${UPPER_NAME}_OPTIONAL})
    set_target_properties(${NAME} PROPERTIES EXCLUDE_FROM_ALL ON)
    foreach(subtarget ${USE_EXTERNAL_SUBTARGETS})
      set_target_properties(${NAME}-${subtarget} PROPERTIES EXCLUDE_FROM_ALL ON)
    endforeach()
  else()
    # add to meta sub-targets
    foreach(subtarget ${USE_EXTERNAL_SUBTARGETS})
      string(TOUPPER ${subtarget} UPPER_SUBTARGET)
      if(NOT ${UPPER_NAME}_NO${UPPER_SUBTARGET})
        add_dependencies(${subtarget}s ${NAME}-${subtarget})
      endif()
    endforeach()
    add_dependencies(AllProjects ${NAME})
  endif()

  set_target_properties(${NAME} PROPERTIES FOLDER "00_Main")
  foreach(subtarget ${USE_EXTERNAL_SUBTARGETS})
    set_target_properties(${NAME}-${subtarget} PROPERTIES FOLDER ${NAME})
  endforeach()

  if("${UPPER_NAME}_ROOT_VAR" STREQUAL "")
    set(${UPPER_NAME}_ROOT "${INSTALL_PATH}" PARENT_SCOPE)
  else()
    set(${${UPPER_NAME}_ROOT_VAR} "${INSTALL_PATH}" PARENT_SCOPE)
  endif()

  use_external_makefile(${NAME})
endfunction()
