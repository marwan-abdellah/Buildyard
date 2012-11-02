
# Copyright (c) 2012 Stefan Eilemann <Stefan.Eilemann@epfl.ch>
# Does a use_external(..) for each config*/*.cmake project.

include(UseExternal)
include(CreateDependencyGraph)

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

      if(NOT EXISTS "${READ_CONFIG_DIR_DEPENDS_DIR}/.git")
        execute_process(
          COMMAND "${GIT_EXECUTABLE}" clone "${READ_CONFIG_DIR_DEPENDS_REPO}"
            "${READ_CONFIG_DIR_DEPENDS_DIR}"
          WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}")
        execute_process(
          COMMAND "${GIT_EXECUTABLE}" checkout "${READ_CONFIG_DIR_DEPENDS_TAG}"
          WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/${READ_CONFIG_DIR_DEPENDS_DIR}"
          )
      endif()

      read_config_dir(${READ_CONFIG_DIR_DEPENDS_DIR})
    endwhile()

    file(GLOB _files "${DIR}/*.cmake")
    foreach(_config ${_files})
      include(${_config})
    endforeach()
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
add_custom_target(update)

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

    if(NOT _dir STREQUAL "config")
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
  endif()
endforeach()
