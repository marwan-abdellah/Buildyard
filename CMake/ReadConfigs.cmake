
# Copyright (c) 2012 Stefan Eilemann <Stefan.Eilemann@epfl.ch>
# Does a use_external(..) for each config*/*.cmake project.

include(UseExternal)
include(CreateDependencyGraph)

macro(READ_CONFIG_DIR DIR)
  get_property(READ_CONFIG_DIR_DONE GLOBAL PROPERTY READ_CONFIG_DIR_${DIR})
  if(READ_CONFIG_DIR_DONE)
    return()
  endif()
  set_property(GLOBAL PROPERTY READ_CONFIG_DIR_${DIR} ON)

  set(READ_CONFIG_DIR_DEPENDS "")
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

    if(NOT EXISTS "${READ_CONFIG_DIR_DEPENDS_DIR}/.git")
      execute_process(
        COMMAND ${CMAKE_COMMAND} -E remove_directory
          "${READ_CONFIG_DIR_DEPENDS_DIR}"
        COMMAND "${GIT_EXECUTABLE}" clone "${READ_CONFIG_DIR_DEPENDS_REPO}"
          "${READ_CONFIG_DIR_DEPENDS_DIR}"
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}")
      execute_process(
        COMMAND "${GIT_EXECUTABLE}" checkout "${READ_CONFIG_DIR_DEPENDS_TAG}"
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/${READ_CONFIG_DIR_DEPENDS_DIR}")
    endif()

    read_config_dir(${READ_CONFIG_DIR_DEPENDS_DIR})
  endwhile()

  file(GLOB _files "${DIR}/*.cmake")
  foreach(_config ${_files})
    include(${_config})
  endforeach()
endmacro()

set(_configs)
file(GLOB _dirs "${CMAKE_SOURCE_DIR}/config*")
foreach(_dir ${_dirs})
  if(IS_DIRECTORY "${_dir}" AND NOT "${_dir}" MATCHES "config.local$")
    read_config_dir("${_dir}")
  endif()
endforeach()

if(IS_DIRECTORY ${CMAKE_SOURCE_DIR}/config.local)
  message(STATUS "Applying local override configuration from config.local")
  file(GLOB _files "config.local/*.cmake")
  foreach(_config ${_files})
    include(${_config})
  endforeach()
endif()

set(_configdone)
file(GLOB _dirs "${CMAKE_SOURCE_DIR}/config*")
foreach(_dir ${_dirs})
  if(IS_DIRECTORY "${_dir}" AND NOT "${_dir}" MATCHES "config.local$")
    message(STATUS "Loading ${_dir}")
    if(_dir STREQUAL "${CMAKE_SOURCE_DIR}/config")
      set(_dest "${CMAKE_SOURCE_DIR}/src/eyescale/images")
    else()
      set(_dest "${_dir}")
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
        create_dependency_graph(${_dir} ${_dest} ${_config})

        string(TOUPPER ${_config} _CONFIG)
        set(${_CONFIG}_CONFIGFILE "${_configfile}")
        use_external(${_config})
      endif()
    endforeach()
    create_dependency_graph_end(${_dir} ${_dest})

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
