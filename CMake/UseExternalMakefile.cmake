
# Copyright (c) 2012 Stefan Eilemann <Stefan.Eilemann@epfl.ch>

# remove / update_src / add in-source Makefile
function(USE_EXTERNAL_MAKEFILE name)
  string(TOUPPER ${name} NAME)
  set(_makefile "${${NAME}_SOURCE}/Makefile")
  set(_gnumakefile "${${NAME}_SOURCE}/GNUmakefile")
  set(_scriptdir ${CMAKE_CURRENT_BINARY_DIR}/${name})

  # Remove our old file before updating
  file(WRITE ${_scriptdir}/rmMakefile.cmake
    "if(EXISTS \"${_makefile}\")
       file(READ \"${_makefile}\" _makefile_contents)
       if(_makefile_contents MATCHES \"MAGIC_IS_BUILDYARD_MAKEFILE\")
         file(REMOVE \"${_makefile}\")
       endif()
     endif()
     if(EXISTS \"${_gnumakefile}\")
       file(READ \"${_gnumakefile}\" _gnumakefile_contents)
       if(_gnumakefile_contents MATCHES \"MAGIC_IS_BUILDYARD_GNUMAKEFILE\")
         file(REMOVE \"${_gnumakefile}\")
       endif()
     endif()")

  ExternalProject_Add_Step(${name} rmMakefile
    COMMENT "Removing in-source Makefile"
    COMMAND ${CMAKE_COMMAND} -P ${_scriptdir}/rmMakefile.cmake
    DEPENDEES mkdir DEPENDERS download ALWAYS 1
    )

  # Move our Makefile in place if no other exists
  file(WRITE ${_scriptdir}/cpMakefile.cmake
    "if(NOT EXISTS \"${_makefile}\")
       set(name ${name})
       set(CMAKE_SOURCE_DIR ${${NAME}_SOURCE})
       configure_file(${CMAKE_SOURCE_DIR}/CMake/Makefile.in \"${_makefile}\"
         @ONLY)
     elseif(NOT EXISTS \"${_gnumakefile}\")
       set(name ${name})
       set(CMAKE_SOURCE_DIR ${${NAME}_SOURCE})
       configure_file(${CMAKE_SOURCE_DIR}/CMake/Makefile.in \"${_gnumakefile}\"
         @ONLY)
     endif()")

  ExternalProject_Add_Step(${name} Makefile
    COMMENT "Adding in-source Makefile"
    COMMAND ${CMAKE_COMMAND} -DBUILDYARD:PATH=${CMAKE_SOURCE_DIR} -P ${_scriptdir}/cpMakefile.cmake
    DEPENDEES configure DEPENDERS build ALWAYS 1
    )
endfunction()
