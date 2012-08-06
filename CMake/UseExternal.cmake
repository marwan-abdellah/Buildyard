
# Copyright (c) 2012 Stefan Eilemann <Stefan.Eilemann@epfl.ch>

include(ExternalProject)
find_package(Git REQUIRED)
include(UseExternalClone)
include(UseExternalMakefile)
include(UseExternalDeps)

set_property(GLOBAL PROPERTY USE_FOLDERS ON)
file(REMOVE ${CMAKE_BINARY_DIR}/projects.make)

set(USE_EXTERNAL_SUBTARGETS update build buildonly configure test testonly
  install package download deps Makefile stat clean)
foreach(subtarget ${USE_EXTERNAL_SUBTARGETS})
  add_custom_target(${subtarget}s)
  set_target_properties(${subtarget}s PROPERTIES FOLDER "00_Meta")
endforeach()
add_custom_target(AllProjects)
set_target_properties(AllProjects PROPERTIES FOLDER "00_Main")

add_custom_target(Buildyard-stat
  COMMAND ${GIT_EXECUTABLE} status -s --untracked-files=no
  COMMENT "Buildyard Status:"
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
  )
set_target_properties(Buildyard-stat PROPERTIES EXCLUDE_FROM_ALL ON)
add_dependencies(stats Buildyard-stat)


# overwrite git clone script generation to avoid excessive cloning
# renames existing origin and adds user URL as new origin (git only)
function(USE_EXTERNAL_CHANGE_ORIGIN name ORIGIN_URL USER_URL ORIGIN_RENAME)
  if(ORIGIN_URL AND USER_URL)
    string(TOUPPER ${name} NAME)
    set(CHANGE_ORIGIN ${GIT_EXECUTABLE} remote set-url origin "${USER_URL}")
    set(RM_REMOTE ${GIT_EXECUTABLE} remote rm ${ORIGIN_RENAME} || ${GIT_EXECUTABLE} status) #workaround to ignore remote rm return value
    set(ADD_REMOTE ${GIT_EXECUTABLE} remote add ${ORIGIN_RENAME} "${ORIGIN_URL}")

    ExternalProject_Add_Step(${name} change_origin
      COMMAND ${CHANGE_ORIGIN}
      COMMAND ${RM_REMOTE}
      COMMAND ${ADD_REMOTE}
      WORKING_DIRECTORY "${${NAME}_SOURCE}"
      DEPENDERS build
      DEPENDEES download
      ALWAYS 1
    )
  endif()
endfunction()


function(USE_EXTERNAL_GATHER_ARGS name)
  # sets ${NAME}_ARGS on return, to be passed to CMake
  string(TOUPPER ${name} NAME)

  set(ARGS)
  set(DEPENDS)
  set(${UPPER_NAME}_ARGS)

  # recurse to get dependency roots
  foreach(proj ${${NAME}_DEPENDS})
    use_external_gather_args(${proj})
    string(TOUPPER ${proj} PROJ)
    set(ARGS ${ARGS} ${${PROJ}_ARGS})
  endforeach()

  get_target_property(_check ${name} _EP_IS_EXTERNAL_PROJECT)
  if(NOT _check EQUAL 1) # installed package
    set(${NAME}_ARGS ${ARGS} PARENT_SCOPE) # return value
    return()
  endif()

  # self root '-DFOO_ROOT=<path>'
  set(INSTALL_PATH "${CMAKE_CURRENT_BINARY_DIR}/install")
  if("${${NAME}_ROOT_VAR}" STREQUAL "")
    set(ARGS ${ARGS} "-D${NAME}_ROOT=${INSTALL_PATH}")
  else()
    set(ARGS ${ARGS} "-D${${NAME}_ROOT_VAR}=${INSTALL_PATH}")
  endif()

  set(${NAME}_ARGS ${ARGS} PARENT_SCOPE) # return value
endfunction()


function(USE_EXTERNAL_BUILDONLY name)
  ExternalProject_Get_Property(${name} binary_dir)

  get_property(cmd_set TARGET ${name} PROPERTY _EP_INSTALL_COMMAND SET)
  if(cmd_set)
    get_property(cmd TARGET ${name} PROPERTY _EP_INSTALL_COMMAND)
  else()
    _ep_get_build_command(${name} INSTALL cmd)
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
  add_custom_target(${name}-testonly
    COMMAND ${cmd}
    COMMENT "Testing ${name}"
    WORKING_DIRECTORY ${binary_dir}
    )
endfunction()


function(USE_EXTERNAL name)
  # Searches for an external project.
  #  Sets NAME_ROOT to the installation directory when not found using
  #  find_package().
  # * First searches using find_package taking into account:
  # ** NAME_ROOT CMake and environment variables
  # ** .../share/name/CMake
  # ** Version is read from optional $name.cmake
  # * If no pre-installed package is found, use ExternalProject to get dependency
  # ** External project settings are read from $name.cmake

  get_target_property(_check ${name} _EP_IS_EXTERNAL_PROJECT)
  if(_check OR ${name}_CHECK) # tested, be quiet and propagate upwards
    set(${name}_CHECK 1 PARENT_SCOPE)
    set(${name}_FOUND ${${name}_FOUND} PARENT_SCOPE)
    if(name_external)
      set(${name}_FOUND 1 PARENT_SCOPE)
    endif()
    return()
  endif()

  string(SUBSTRING ${name} 0 2 SHORT_NAME)
  string(TOUPPER ${SHORT_NAME} SHORT_NAME)
  string(TOUPPER ${name} NAME)
  set(ROOT ${NAME}_ROOT)
  set(ENVROOT $ENV{${ROOT}})
  set(SHORT_ROOT ${SHORT_NAME}_ROOT)
  set(SHORT_ENVROOT $ENV{${SHORT_ROOT}})

  # CMake module search path
  if(${${SHORT_ROOT}})
    list(APPEND CMAKE_MODULE_PATH "${${SHORT_ROOT}}/share/${name}/CMake")
  endif()
  if(NOT "${SHORT_ENVROOT}" STREQUAL "")
    list(APPEND CMAKE_MODULE_PATH "${SHORT_ENVROOT}/share/${name}/CMake")
  endif()
  if(${${ROOT}})
    list(APPEND CMAKE_MODULE_PATH "${${ROOT}}/share/${name}/CMake")
  endif()
  if(NOT "${ENVROOT}" STREQUAL "")
    list(APPEND CMAKE_MODULE_PATH "${ENVROOT}/share/${name}/CMake")
  endif()

  list(APPEND CMAKE_MODULE_PATH "${CMAKE_INSTALL_PREFIX}/share/${name}/CMake")
  list(APPEND CMAKE_MODULE_PATH /usr/share/${name}/CMake)
  list(APPEND CMAKE_MODULE_PATH /usr/local/share/${name}/CMake)

  # try find_package
  set(USE_EXTERNAL_INDENT "${USE_EXTERNAL_INDENT}  ")
  if(NOT ${NAME}_FORCE_BUILD)
    find_package(${name} ${${NAME}_VERSION} QUIET)
  endif()
  if(${NAME}_FOUND)
    set(${name}_FOUND 1) # compat with Foo_FOUND and FOO_FOUND usage
  endif()
  if(${name}_FOUND)
    message(STATUS "${USE_EXTERNAL_INDENT}${name}: installed in "
      "${${NAME}_INCLUDE_DIRS}${${name}_INCLUDE_DIRS}")
    set(${name}_FOUND 1 PARENT_SCOPE)
    set(${name}_CHECK 1 PARENT_SCOPE)
    return()
  endif()

  unset(${name}_INCLUDE_DIR CACHE)  # some find_package (boost) don't properly
  unset(${NAME}_INCLUDE_DIR CACHE)  # unset and recheck the version on subsequent
  unset(${name}_INCLUDE_DIRS CACHE) # runs if it failed
  unset(${NAME}_INCLUDE_DIRS CACHE)
  unset(${name}_LIBRARY_DIRS CACHE)
  unset(${NAME}_LIBRARy_DIRS CACHE)

  if("${${NAME}_REPO_URL}" STREQUAL "")
    message(STATUS
      "${USE_EXTERNAL_INDENT}${name}: No source repo, update ${name}.cmake?")
    set(${name}_CHECK 1 PARENT_SCOPE)
    return()
  endif()

  message(STATUS
    "${USE_EXTERNAL_INDENT}${name}: use ${${NAME}_REPO_URL}:${${NAME}_REPO_TAG}")

  # pull in dependent projects first
  set(DEPENDS)
  set(MISSING)
  set(DEPMODE)
  foreach(_dep ${${NAME}_DEPENDS})
    if(${_dep} STREQUAL "OPTIONAL")
      set(DEPMODE)
    elseif(${_dep} STREQUAL "REQUIRED")
      set(DEPMODE REQUIRED)
    else()
      if(NOT ${_dep}_CHECK)
        use_external(${_dep})
      endif()
      if("${DEPMODE}" STREQUAL "REQUIRED" AND NOT ${_dep}_FOUND)
        set(MISSING "${MISSING} ${_dep}")
      endif()

      get_target_property(_dep_check ${_dep} _EP_IS_EXTERNAL_PROJECT)
      if(_dep_check EQUAL 1)
        list(APPEND DEPENDS ${_dep})
      endif()
      set(${_dep}_CHECK 1 PARENT_SCOPE)
      set(${_dep}_FOUND ${${_dep}_FOUND} PARENT_SCOPE)
    endif()
  endforeach()
  if(MISSING)
    message(STATUS "${USE_EXTERNAL_INDENT}${name}: SKIP, missing${MISSING}")
    return()
  endif()

  # External Project
  set(UPDATE_CMD)
  set(REPO_TYPE ${${NAME}_REPO_TYPE})
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
    set(REPO_ORIGIN_URL ${${NAME}_REPO_URL})
    set(REPO_USER_URL ${${NAME}_USER_URL})
    set(REPO_ORIGIN_NAME ${${NAME}_ORIGIN_NAME})
    if(REPO_ORIGIN_URL AND REPO_USER_URL)
      if(NOT REPO_ORIGIN_NAME)
        set(REPO_ORIGIN_NAME "root")
      endif()
      set(UPDATE_CMD ${GIT_EXECUTABLE} pull ${REPO_ORIGIN_NAME} master || ${GIT_EXECUTABLE} status
          ALWAYS TRUE)
    else()
      # pull fails if tag is a SHA hash, use git status to set exit value to true
      set(UPDATE_CMD ${GIT_EXECUTABLE} pull || ${GIT_EXECUTABLE} status
          ALWAYS TRUE)
    endif()
  elseif(REPO_TYPE STREQUAL "SVN")
    find_package(Subversion REQUIRED)
    set(REPO_TAG SVN_REVISION)
  else()
    message(FATAL_ERROR "Unknown repository type ${REPO_TYPE}")
  endif()

  if(NOT ${NAME}_SOURCE)
    set(${NAME}_SOURCE "${CMAKE_SOURCE_DIR}/src/${name}")
  endif()

  set(INSTALL_PATH "${CMAKE_CURRENT_BINARY_DIR}/install")
  use_external_gather_args(${name})
  set(ARGS -DBUILDYARD:BOOL=ON -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
           -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PATH}
           ${${NAME}_ARGS} ${${NAME}_CMAKE_ARGS})

  ExternalProject_Add(${name}
    LIST_SEPARATOR !
    PREFIX "${CMAKE_CURRENT_BINARY_DIR}/${name}"
    BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/${name}"
    SOURCE_DIR "${${NAME}_SOURCE}"
    INSTALL_DIR "${INSTALL_PATH}"
    DEPENDS "${DEPENDS}"
    ${REPO_TYPE}_REPOSITORY ${${NAME}_REPO_URL}
    ${REPO_TAG} ${${NAME}_REPO_TAG}
    UPDATE_COMMAND ${UPDATE_CMD}
    CMAKE_ARGS ${ARGS}
    TEST_AFTER_INSTALL 1
    ${${NAME}_EXTRA}
    STEP_TARGETS ${USE_EXTERNAL_SUBTARGETS}
    )
  use_external_buildonly(${name})
  file(APPEND ${CMAKE_BINARY_DIR}/projects.make
    "${name}-%:\n"
    "	@\$(MAKE) -C ${CMAKE_BINARY_DIR} $@\n"
    "${name}_%:\n"
    "	@\$(MAKE) -C ${CMAKE_BINARY_DIR}/${name} $*\n\n"
    )

  if(REPO_TYPE STREQUAL "GIT")
    use_external_change_origin(${name} "${REPO_ORIGIN_URL}" "${REPO_USER_URL}"
                              "${REPO_ORIGIN_NAME}")
    unset(${REPO_ORIGIN_URL} CACHE)
    unset(${REPO_USER_URL} CACHE)
    unset(${REPO_ORIGIN_NAME} CACHE)
  endif()

  # add optional targets: package, doxygen, github
  get_property(cmd_set TARGET ${name} PROPERTY _EP_BUILD_COMMAND SET)
  if(cmd_set)
    get_property(cmd TARGET ${name} PROPERTY _EP_BUILD_COMMAND)
  else()
    _ep_get_build_command(${name} BUILD cmd)
  endif()

  if(NOT APPLE)
    set(fakeroot fakeroot)
  endif()

  use_external_makefile(${name})
  use_external_deps(${name})
  add_custom_target(${name}-package
    COMMAND ${fakeroot} ${cmd} package
    COMMENT "Building package"
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${name}"
    )
  set_target_properties(${name}-package PROPERTIES EXCLUDE_FROM_ALL ON)

  get_property(cvs_repository TARGET ${name} PROPERTY _EP_CVS_REPOSITORY)
  get_property(svn_repository TARGET ${name} PROPERTY _EP_SVN_REPOSITORY)
  get_property(git_repository TARGET ${name} PROPERTY _EP_GIT_REPOSITORY)

  if(cvs_repository)
    set(cmd ${CVS_EXECUTABLE} status)
  elseif(svn_repository)
    set(cmd ${Subversion_SVN_EXECUTABLE} st -q)
  elseif(git_repository)
    set(cmd ${GIT_EXECUTABLE} status --untracked-files=no -s)
  endif()

  add_custom_target(${name}-stat
    COMMAND ${cmd}
    COMMENT "${name} Status:"
    WORKING_DIRECTORY "${${NAME}_SOURCE}"
    )
  set_target_properties(${name}-stat PROPERTIES EXCLUDE_FROM_ALL ON)

  add_custom_target(${name}-deps
    DEPENDS ${DEPENDS}
    COMMENT "Building ${name} dependencies"
    )
  set_target_properties(${name}-deps PROPERTIES EXCLUDE_FROM_ALL ON)

  add_custom_target(${name}-clean
    COMMAND ${cmd} clean
    COMMENT "Cleaning ${name}"
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${name}"
    )
  set_target_properties(${name}-clean PROPERTIES EXCLUDE_FROM_ALL ON)

  # disable tests if requested
  if(${${NAME}_NOTEST})
    set(${NAME}_NOTESTONLY ON)
  endif()

  # make optional if requested
  if(${${NAME}_OPTIONAL})
    set_target_properties(${name} PROPERTIES EXCLUDE_FROM_ALL ON)
    foreach(subtarget ${USE_EXTERNAL_SUBTARGETS})
      set_target_properties(${name}-${subtarget} PROPERTIES EXCLUDE_FROM_ALL ON)
    endforeach()
    add_dependencies(stats ${name}-stat)
  else()
    # add to meta sub-targets
    foreach(subtarget ${USE_EXTERNAL_SUBTARGETS})
      string(TOUPPER ${subtarget} UPPER_SUBTARGET)
      if(NOT ${NAME}_NO${UPPER_SUBTARGET})
        add_dependencies(${subtarget}s ${name}-${subtarget})
      endif()
    endforeach()
    add_dependencies(AllProjects ${name})
  endif()

  set_target_properties(${name} PROPERTIES FOLDER "00_Main")
  foreach(subtarget ${USE_EXTERNAL_SUBTARGETS})
    set_target_properties(${name}-${subtarget} PROPERTIES FOLDER ${name})
  endforeach()

  set(${name}_FOUND 1 PARENT_SCOPE)
  set(${name}_CHECK 1 PARENT_SCOPE)

  if("${NAME}_ROOT_VAR" STREQUAL "")
    set(${NAME}_ROOT "${INSTALL_PATH}" PARENT_SCOPE)
  else()
    set(${${NAME}_ROOT_VAR} "${INSTALL_PATH}" PARENT_SCOPE)
  endif()
endfunction()
