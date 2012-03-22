
# Copyright (c) 2012 Stefan Eilemann <Stefan.Eilemann@epfl.ch>

include(ExternalProject)
find_package(Git REQUIRED)
find_package(Subversion REQUIRED)

# overwrite git clone script generation to avoid excessive cloning
function(_ep_write_gitclone_script script_filename source_dir git_EXECUTABLE git_repository git_tag src_name work_dir)
  file(WRITE ${script_filename}
"if(\"${git_tag}\" STREQUAL \"\")
  message(FATAL_ERROR \"Tag for git checkout should not be empty.\")
endif()
if(IS_DIRECTORY \"${work_dir}/${src_name}/.git\")
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
    COMMAND \"${git_EXECUTABLE}\" clone \"${git_repository}\" \"${src_name}\"
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
function(_ep_change_origin NAME ORIGIN_URL USER_URL ORIGIN_RENAME)
  if(ORIGIN_URL AND USER_URL AND ORIGIN_RENAME)
    set(ADD_USER_REMOTE ${GIT_EXECUTABLE} remote set-url origin "${USER_URL}")
    set(CHANGE_ORIGIN_REMOTE ${GIT_EXECUTABLE} remote rm ${ORIGIN_RENAME} ||
                             ${GIT_EXECUTABLE} remote add ${ORIGIN_RENAME} "${ORIGIN_URL}")

    ExternalProject_Add_Step(${NAME} change_origin_remote
      COMMAND ${CHANGE_ORIGIN_REMOTE}
      WORKING_DIRECTORY "${SOURCE_DIR}"
      DEPENDS "${DEPENDS}"
      DEPENDEES download
    )
    ExternalProject_Add_Step(${NAME} add_user_remote
      COMMAND ${ADD_USER_REMOTE}
      WORKING_DIRECTORY "${SOURCE_DIR}"
      DEPENDS "${DEPENDS}"
      DEPENDEES change_origin_remote
    )    
  endif()
endfunction()


function(USE_EXTERNAL_GATHER_ARGS NAME)
  # sets ${UPPER_NAME}_ARGS on return, to be passed to CMake
  string(TOUPPER ${NAME} UPPER_NAME)

  # recurse to get dependency roots
  set(DEPENDS)
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

  add_custom_target(${NAME}-buildonly
    COMMAND ${cmd}
    COMMENT "Building ${NAME}"
    WORKING_DIRECTORY ${binary_dir}
    )
  set_target_properties(${NAME}-buildonly PROPERTIES EXCLUDE_FROM_ALL ON)
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
    message(STATUS "  ${NAME}: installed in ${${UPPER_NAME}_INCLUDE_DIRS}"
      "${${NAME}_INCLUDE_DIRS}")
    set(${NAME}_FOUND 1 PARENT_SCOPE)
    return()
  endif()

  unset(${NAME}_INCLUDE_DIR CACHE)        # some find_package (boost) don't
  unset(${UPPER_NAME}_INCLUDE_DIR CACHE)  # properly unset and recheck the
  unset(${NAME}_INCLUDE_DIRS CACHE)       # version on subsequent runs if it
  unset(${UPPER_NAME}_INCLUDE_DIRS CACHE) # failed
  unset(${NAME}_LIBRARY_DIRS CACHE)
  unset(${UPPER_NAME}_LIBRARy_DIRS CACHE)

  if("${${UPPER_NAME}_REPO_URL}" STREQUAL "")
    message(STATUS
      "Missing dependency ${NAME}: No source repository, fix ${NAME}.cmake?")
    set(${NAME}_FOUND 1 PARENT_SCOPE) # ugh: removes dependency
    return()
  endif()

  # pull in dependent projects first
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

  if(REPO_TYPE STREQUAL "GIT")
    set(REPO_TAG GIT_TAG)
    # pull fails if tag is a SHA hash, use git status to set exit value to true
    set(UPDATE_CMD ${GIT_EXECUTABLE} pull || ${GIT_EXECUTABLE} status
      ALWAYS TRUE)     
  elseif(REPO_TYPE STREQUAL "SVN")
    set(REPO_TAG SVN_REVISION)
  else()
    message(FATAL_ERROR "Unknown repository type ${REPO_TYPE}")
  endif()

  set(INSTALL_PATH "${CMAKE_CURRENT_BINARY_DIR}/install")
  set(SOURCE_DIR "${CMAKE_SOURCE_DIR}/src/${NAME}")
  use_external_gather_args(${NAME})
  set(ARGS -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
           -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PATH}
           ${${UPPER_NAME}_ARGS})

  message(STATUS "  ${NAME}: building from ${${UPPER_NAME}_REPO_URL}:"
    "${${UPPER_NAME}_REPO_TAG}")
  ExternalProject_Add(${NAME}
    PREFIX "${CMAKE_CURRENT_BINARY_DIR}/${NAME}"
    BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/${NAME}"
    SOURCE_DIR "${SOURCE_DIR}"
    INSTALL_DIR "${INSTALL_PATH}"
    DEPENDS "${DEPENDS}"
    ${REPO_TYPE}_REPOSITORY ${${UPPER_NAME}_REPO_URL}
    ${REPO_TAG} ${${UPPER_NAME}_REPO_TAG}
    UPDATE_COMMAND "${UPDATE_CMD}"
    CMAKE_ARGS ${ARGS}
    ${${UPPER_NAME}_EXTRA}
    STEP_TARGETS update build buildonly configure test install
    )
  use_external_buildonly(${NAME})
  
  if(REPO_TYPE STREQUAL "GIT")
    set(REPO_ORIGIN_URL ${${UPPER_NAME}_REPO_URL})
    set(REPO_USER_URL ${${UPPER_NAME}_USER_URL})
    set(REPO_ORIGIN_RENAME ${${UPPER_NAME}_ORIGIN_RENAME})
    _ep_change_origin(${NAME} "${REPO_ORIGIN_URL}" "${REPO_USER_URL}" "${REPO_ORIGIN_RENAME}")
  endif()

  # add optional package target
  get_property(cmd_set TARGET ${NAME} PROPERTY _EP_BUILD_COMMAND SET)
  if(cmd_set)
    get_property(cmd TARGET ${NAME} PROPERTY _EP_BUILD_COMMAND)
  else()
    _ep_get_build_command(${NAME} BUILD cmd)
  endif()

  add_custom_target(${NAME}-package
    COMMAND ${cmd} package
    DEPENDS ${NAME}
    COMMENT "Building package"
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${NAME}"
    )
  set_target_properties(${NAME}-package PROPERTIES EXCLUDE_FROM_ALL ON)

  if("${UPPER_NAME}_ROOT_VAR" STREQUAL "")
    set(${UPPER_NAME}_ROOT "${INSTALL_PATH}" PARENT_SCOPE)
  else()
    set(${${UPPER_NAME}_ROOT_VAR} "${INSTALL_PATH}" PARENT_SCOPE)
  endif()

  # setup forwarding makefile
  if(NOT EXISTS "${SOURCE_DIR}/Makefile")
    configure_file(CMake/Makefile.in "${SOURCE_DIR}/Makefile" @ONLY)
  endif()
endfunction()
