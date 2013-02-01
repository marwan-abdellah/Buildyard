
# Copyright (c) 2013 Stefan.Eilemann@epfl.ch

# write configure command for autoconf-based projects
function(USE_EXTERNAL_AUTOCONF name)
  string(TOUPPER ${name} NAME)
  set(${NAME}_CONFIGURE_CMD
    ${CMAKE_BINARY_DIR}/${name}/${name}_configure_cmd.cmake)
  file(WRITE ${${NAME}_CONFIGURE_CMD}
    "if(NOT EXISTS ${${NAME}_SOURCE}/configure)\n"
    "  execute_process(COMMAND autoreconf -i WORKING_DIRECTORY ${${NAME}_SOURCE})\n"
    "endif()\n"
    "if(NOT EXISTS ${CMAKE_BINARY_DIR}/${name}/config.status)\n"
    "  execute_process(COMMAND ./configure --prefix=${CMAKE_CURRENT_BINARY_DIR}/install CPPFLAGS=-I${CMAKE_CURRENT_BINARY_DIR}/install/include LDFLAGS=-L${CMAKE_CURRENT_BINARY_DIR}/install/lib\n"
    "    WORKING_DIRECTORY ${${NAME}_SOURCE})\n"
    "  execute_process(COMMAND ${CMAKE_COMMAND} -E touch ${CMAKE_BINARY_DIR}/${name}/config.status)\n"
    "endif()\n"
    )
endfunction()
