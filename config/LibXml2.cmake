
set(LIBXML2_VERSION 2.7)
set(LIBXML2_REPO_URL git://git.gnome.org/libxml2)
set(LIBXML2_REPO_TAG master)
set(LIBXML2_SOURCE "${CMAKE_SOURCE_DIR}/src/libxml2")

if(NOT MSVC)
  return()
endif()

set(LIBXML2_PREFIXPATH)
file(TO_NATIVE_PATH ${CMAKE_CURRENT_BINARY_DIR}/install LIBXML2_PREFIXPATH)
set(LIBXML2_EXTRA
  CONFIGURE_COMMAND cd ${LIBXML2_SOURCE}/win32 && cscript configure.js compiler=msvc prefix=${LIBXML2_PREFIXPATH} debug=no iconv=no
  BUILD_COMMAND cd ${LIBXML2_SOURCE}/win32 && nmake /f Makefile.msvc
  INSTALL_COMMAND cd ${LIBXML2_SOURCE}/win32 && nmake /f Makefile.msvc install
)
