
# Copyright (c) 2012 Stefan Eilemann <Stefan.Eilemann@epfl.ch>
# Does a use_external(..) for each config*/*.cmake project.

include(UseExternal)

file(GLOB _dirs "${CMAKE_SOURCE_DIR}/config*")
foreach(_dir ${_dirs})
  if(IS_DIRECTORY "${_dir}")
    message(STATUS "Configuring ${_dir}")
    list(APPEND CMAKE_MODULE_PATH "${_dir}")
    file(GLOB _configs "${_dir}/*.cmake")
    foreach(_config ${_configs})
      string(REPLACE "${_dir}/" "" _config ${_config})
      string(REPLACE ".cmake" "" _config ${_config})
      message(STATUS "  Using ${_config}")
      use_external(${_config})
    endforeach()
  endif()
endforeach()
