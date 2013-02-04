
# Copyright (c) 2013 Stefan.Eilemann@epfl.ch

# write configure command for autoconf-based projects
function(USE_EXTERNAL_AUTOCONF name)
  string(TOUPPER ${name} NAME)
  set(${NAME}_CONFIGURE_CMD
    ${CMAKE_BINARY_DIR}/${name}/${name}_configure_cmd.cmake)
  if(NOT ${NAME}_CONFIGURE_DIR)
    set(${NAME}_CONFIGURE_DIR ${CMAKE_BINARY_DIR}/${name})
  endif()
  file(WRITE ${${NAME}_CONFIGURE_CMD}
    "if(NOT EXISTS ${${NAME}_SOURCE}/configure)\n"
    "  execute_process(COMMAND autoreconf -i \n"
    "    WORKING_DIRECTORY ${${NAME}_SOURCE})\n"
    "endif()\n"
    "if(NOT EXISTS ${CMAKE_BINARY_DIR}/${name}/config.status)\n"
    "  execute_process(COMMAND ${${NAME}_SOURCE}/configure --prefix=${CMAKE_CURRENT_BINARY_DIR}/install CPPFLAGS=-I${CMAKE_CURRENT_BINARY_DIR}/install/include LDFLAGS=-L${CMAKE_CURRENT_BINARY_DIR}/install/lib\n"
    "    WORKING_DIRECTORY ${${NAME}_CONFIGURE_DIR})\n"
    "  execute_process(COMMAND ${CMAKE_COMMAND} -E touch ${CMAKE_BINARY_DIR}/${name}/config.status)\n"
    "endif()\n"
    )
endfunction()
