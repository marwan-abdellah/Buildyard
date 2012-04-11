
# Copyright (c) 2012 Stefan Eilemann <Stefan.Eilemann@epfl.ch>
# Does a use_external(..) for each config*/*.cmake project.

include(UseExternal)
include(CreateDependencyGraph)

set(_configs)
file(GLOB _dirs "${CMAKE_SOURCE_DIR}/config*")
foreach(_dir ${_dirs})
  if(IS_DIRECTORY "${_dir}" AND NOT "${_dir}" MATCHES "config.local$")
    message(STATUS "Loading ${_dir}")
    file(GLOB _files "${_dir}/*.cmake")
    foreach(_config ${_files})
      include(${_config})
      string(REPLACE ".cmake" "" _config ${_config})
      list(APPEND _configs ${_config})
    endforeach()
  endif()
endforeach()

if(IS_DIRECTORY ${CMAKE_SOURCE_DIR}/config.local)
  message(STATUS "Applying local override configuration from config.local")
  file(GLOB _files "config.local/*.cmake")
  foreach(_config ${_files})
    include(${_config})
  endforeach()
endif()

foreach(_file ${_configs})
  get_filename_component(_dir ${_file} PATH)
  get_filename_component(_config ${_file} NAME)

  create_dependency_graph(${_dir} ${_config})
  use_external(${_config})
endforeach()
