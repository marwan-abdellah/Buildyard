
# Copyright (c) 2012 Stefan Eilemann <Stefan.Eilemann@epfl.ch>
# Does a use_external(..) for each config*/*.cmake project.

include(UseExternal)
include(CreateDependencyGraph)
include(GitTargets)
if(APPLE)
  find_program(TAR_EXE gnutar)
else()
  find_program(TAR_EXE tar)
endif()

macro(READ_CONFIG_DIR DIR)
  get_property(READ_CONFIG_DIR_DONE GLOBAL PROPERTY READ_CONFIG_DIR_${DIR})
  if(NOT READ_CONFIG_DIR_DONE)
    message(STATUS "Reading ${DIR}")
    set_property(GLOBAL PROPERTY READ_CONFIG_DIR_${DIR} ON)

    set(READ_CONFIG_DIR_DEPENDS)
    if(EXISTS ${DIR}/depends.txt)
      file(READ ${DIR}/depends.txt READ_CONFIG_DIR_DEPENDS)
      string(REGEX REPLACE "[ \n]" ";" READ_CONFIG_DIR_DEPENDS
        "${READ_CONFIG_DIR_DEPENDS}")
    endif()

    list(LENGTH READ_CONFIG_DIR_DEPENDS READ_CONFIG_DIR_DEPENDS_LEFT)
    while(READ_CONFIG_DIR_DEPENDS_LEFT GREATER 2)
      list(GET READ_CONFIG_DIR_DEPENDS 0 READ_CONFIG_DIR_DEPENDS_DIR)
      list(GET READ_CONFIG_DIR_DEPENDS 1 READ_CONFIG_DIR_DEPENDS_REPO)
      list(GET READ_CONFIG_DIR_DEPENDS 2 READ_CONFIG_DIR_DEPENDS_TAG)
      list(REMOVE_AT READ_CONFIG_DIR_DEPENDS 0 1 2)
      list(LENGTH READ_CONFIG_DIR_DEPENDS READ_CONFIG_DIR_DEPENDS_LEFT)
      set(READ_CONFIG_DIR_DEPENDS_DIR
        "${CMAKE_SOURCE_DIR}/${READ_CONFIG_DIR_DEPENDS_DIR}")

      message(STATUS
        "Using ${READ_CONFIG_DIR_DEPENDS_REPO}:${READ_CONFIG_DIR_DEPENDS_TAG}"
        " for ${READ_CONFIG_DIR_DEPENDS_DIR}")
      if(NOT IS_DIRECTORY "${READ_CONFIG_DIR_DEPENDS_DIR}")
        execute_process(
          COMMAND "${GIT_EXECUTABLE}" clone "${READ_CONFIG_DIR_DEPENDS_REPO}"
            "${READ_CONFIG_DIR_DEPENDS_DIR}"
          WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}")
      endif()
      execute_process(
        COMMAND "${GIT_EXECUTABLE}" checkout -q "${READ_CONFIG_DIR_DEPENDS_TAG}"
        WORKING_DIRECTORY "${READ_CONFIG_DIR_DEPENDS_DIR}"
        )

      read_config_dir(${READ_CONFIG_DIR_DEPENDS_DIR})
    endwhile()

    file(GLOB _files "${DIR}/*.cmake")
    set(_localFiles)
    if(EXISTS "${DIR}/depends.txt")
      set(_localFiles "${DIR}/depends.txt")
      string(REPLACE "${CMAKE_SOURCE_DIR}/" "" _localFiles ${_localFiles})
    endif()
    foreach(_config ${_files})
      include(${_config})
      string(REPLACE "${CMAKE_SOURCE_DIR}/" "" _config ${_config})
      list(APPEND _localFiles ${_config})
    endforeach()

    if(TAR_EXE)
      string(REGEX REPLACE ".*\\.([a-zA-Z0-9]+)$" "\\1" DIRID ${DIR})
      if(NOT "${DIR}" STREQUAL "${DIRID}")
        add_custom_target(tarball-${DIRID}
          COMMAND ${TAR_EXE} rf ${TARBALL} --transform 's:^:${CMAKE_PROJECT_NAME}-${VERSION}/:' -C "${CMAKE_SOURCE_DIR}" ${_localFiles}
          COMMENT "Adding ${DIRID}"
          DEPENDS tarball-${TARBALL_CHAIN})
        set(TARBALL_CHAIN ${DIRID})
      endif()
    endif()
  endif()
endmacro()

set(_configs)
file(GLOB _dirs "${CMAKE_SOURCE_DIR}/config*")

list(LENGTH _dirs _dirs_num)
if(_dirs_num LESS 2)
  message(STATUS "No configurations found, cloning Eyescale config")
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" clone https://github.com/Eyescale/config.git
      config.eyescale
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}")
  file(GLOB _dirs "${CMAKE_SOURCE_DIR}/config*")
endif()

set(TARBALL_CHAIN create)

list(SORT _dirs) # read config/ first
foreach(_dir ${_dirs})
  if(IS_DIRECTORY "${_dir}" AND NOT "${_dir}" MATCHES "config.local$")
    read_config_dir("${_dir}")
  endif()
endforeach()

if(IS_DIRECTORY ${CMAKE_SOURCE_DIR}/config.local)
  message(STATUS "Reading overrides from config.local")
  file(GLOB _files "config.local/*.cmake")
  foreach(_config ${_files})
    include(${_config})
  endforeach()
endif()

set(_configdone)
add_custom_target(update
  COMMAND ${GIT_EXECUTABLE} pull || ${GIT_EXECUTABLE} status
  COMMENT "Updating Buildyard"
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}")

if(IS_DIRECTORY "${CMAKE_SOURCE_DIR}/config.local")
  add_custom_target(config.local-update
    COMMAND ${GIT_EXECUTABLE} pull
    COMMENT "Updating config.local"
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/config.local"
    )
  add_dependencies(update config.local-update)
endif()

file(GLOB _dirs "${CMAKE_SOURCE_DIR}/config*")
foreach(_dir ${_dirs})
  if(IS_DIRECTORY "${_dir}" AND NOT "${_dir}" MATCHES "config.local$")
    message(STATUS "Configuring ${_dir}")

    string(REGEX REPLACE ".*\\.(.+)" "\\1" _group ${_dir})
    if(_group STREQUAL _dir)
      set(_group)
    else()
      string(TOUPPER ${_group} _GROUP)
      if(NOT ${_GROUP}_REPO_URL)
        set(_group)
      endif()
    endif()

    if(_group)
      set(_dest "${CMAKE_SOURCE_DIR}/src/${_group}/images")
    else()
      set(_dest "${_dir}")
    endif()

    if(_dir MATCHES "config.")
      get_filename_component(_dirName ${_dir} NAME)
      add_custom_target(${_dirName}-update
        COMMAND ${GIT_EXECUTABLE} pull
        COMMENT "Updating ${_dirName}"
        WORKING_DIRECTORY "${_dir}"
        )
      add_dependencies(update ${_dirName}-update)
    endif()

    create_dependency_graph_start(${_dir})
    file(GLOB _files "${_dir}/*.cmake")
    foreach(_configfile ${_files})
      string(REPLACE ".cmake" "" _config ${_configfile})
      get_filename_component(_config ${_config} NAME)

      set(_configfound)
      list(FIND _configdone ${_config} _configfound)
      if(_configfound EQUAL -1)
        list(APPEND _configdone ${_config})
        create_dependency_graph(${_dir} ${_dest} "${_group}" ${_config})

        string(TOUPPER ${_config} _CONFIG)
        set(${_CONFIG}_CONFIGFILE "${_configfile}")
        use_external(${_config})
      endif()
    endforeach()
    create_dependency_graph_end(${_dir} ${_dest} "${_group}")
  endif()
endforeach()

# Output configured projects:
if(BUILDING)
  list(SORT BUILDING)
  set(TEXT "Building")
  foreach(PROJECT ${BUILDING})
    set(TEXT "${TEXT} ${PROJECT}")
  endforeach()
  message(STATUS ${TEXT})
  set(BUILDING)
endif()

if(TAR_EXE)
  add_dependencies(tarball DEPENDS tarball-${TARBALL_CHAIN})
endif()
