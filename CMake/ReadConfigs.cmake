
# Copyright (c) 2012 Stefan Eilemann <Stefan.Eilemann@epfl.ch>
# Does a use_external(..) for each config*/*.cmake project.

include(UseExternal)

set(_configs)
file(GLOB _dirs "${CMAKE_SOURCE_DIR}/config*")
foreach(_dir ${_dirs})
  if(IS_DIRECTORY "${_dir}")
    message(STATUS "Configuring ${_dir}")
    file(GLOB _files "${_dir}/*.cmake")
    foreach(_config ${_files})
      include(${_config})
      string(REPLACE "${_dir}/" "" _config ${_config})
      string(REPLACE ".cmake" "" _config ${_config})
      list(APPEND _configs ${_config})
    endforeach()
  endif()
endforeach()

foreach(_config ${_configs})
  use_external(${_config})
endforeach()
