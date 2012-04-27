# can't autopain on Windows without too much hassle
# can't build universal on OS X
if(MSVC OR APPLE)
  return()
endif()

set(HWLOC_VERSION 1.4.0)
#set(HWLOC_REPO_URL http://svn.open-mpi.org/svn/hwloc/tags/hwloc-1.4.0/)
set(HWLOC_REPO_URL https://github.com/marwan-abdellah/HWLOC)
set(HWLOC_REPO_TYPE GIT)
set(HWLOC_SOURCE "${CMAKE_SOURCE_DIR}/src/hwloc")
set(HWLOC_NOPACKAGE ON)
set(HWLOC_EXTRA
  PATCH_COMMAND cd ${HWLOC_SOURCE} && autoreconf -i
  CONFIGURE_COMMAND ${HWLOC_SOURCE}/configure  "--prefix=${CMAKE_CURRENT_BINARY_DIR}/install"
)
