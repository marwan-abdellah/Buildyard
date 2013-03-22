
set(BOOST_PACKAGE_VERSION 1.41.0)
set(BOOST_REPO_URL http://svn.boost.org/svn/boost/tags/release/Boost_1_53_0)
set(BOOST_REPO_TYPE SVN)
set(BOOST_SOURCE "${CMAKE_SOURCE_DIR}/src/Boost")
set(BOOST_OPTIONAL ON)
set(BOOST_CMAKE_INCLUDE "SYSTEM")

set(BOOST_BUILD_LIBRARIES serialization system regex date_time thread filesystem
                          program_options test)
find_package(PythonLibs QUIET)
if(PYTHONLIBS_FOUND)
  list(APPEND BOOST_BUILD_LIBRARIES python)
endif()

set(WITH_LIBRARIES)

if(MSVC)
  string(REGEX REPLACE "Visual Studio ([0-9]+)[ ]*[0-9]*" "msvc-\\1.0"
    TOOLSET ${CMAKE_GENERATOR})
  if(TOOLSET MATCHES "Win64")
    string(REGEX REPLACE "([0-9.]+) Win64" "\\1" TOOLSET ${TOOLSET})
    set(ADDRESS 64)
  else()
    set(ADDRESS 32)
  endif()
  set(BATFILE "${BOOST_SOURCE}/b3_${TOOLSET}.${ADDRESS}.bat")
  foreach(WITH_LIBRARY ${BOOST_BUILD_LIBRARIES})
    list(APPEND WITH_LIBRARIES " --with-${WITH_LIBRARY}")
  endforeach()
  string(REGEX REPLACE ";" " " WITH_LIBRARIES ${WITH_LIBRARIES})
  file(WRITE "${BATFILE}"
    "set VS_UNICODE_OUTPUT=\n"
    "b2 --layout=tagged toolset=${TOOLSET} address-model=${ADDRESS} ${WITH_LIBRARIES} link=shared \"--prefix=${CMAKE_CURRENT_BINARY_DIR}/install\" %1 %2 %3 %4\n"
)
  set(BOOTSTRAP cd ${BOOST_SOURCE} && bootstrap.bat)
  set(BTWO ${BATFILE})
else()
  foreach(WITH_LIBRARY ${BOOST_BUILD_LIBRARIES})
    list(APPEND WITH_LIBRARIES "${WITH_LIBRARY},")
  endforeach()
  string(REGEX REPLACE ";" " " WITH_LIBRARIES ${WITH_LIBRARIES})
  set(BOOTSTRAP cd ${BOOST_SOURCE} && ./bootstrap.sh "--prefix=${CMAKE_CURRENT_BINARY_DIR}/install" --with-libraries=${WITH_LIBRARIES})
  set(BTWO ./b2)
  if(APPLE)
    set(BTWO ${BTWO} address-model=32_64)
  elseif("$ENV{CC}}" MATCHES "xlc")
    set(BTWO ${BTWO} toolset=vacpp address-model=64 cxxflags=-qsmp=omp:noopt)
  else()
    set(BTWO ${BTWO} toolset=gcc)
  endif()
endif()

set(BOOST_EXTRA
  CONFIGURE_COMMAND ${BOOTSTRAP}
  BUILD_COMMAND cd ${BOOST_SOURCE} && ${BTWO} -j8
  INSTALL_COMMAND cd ${BOOST_SOURCE} && ${BTWO} -j8 install
)
