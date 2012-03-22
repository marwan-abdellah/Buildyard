
set(BOOST_SOURCE "${CMAKE_SOURCE_DIR}/src/Boost")
set(BOOST_VERSION 1.42.0)
set(BOOST_REPO_URL http://svn.boost.org/svn/boost/tags/release/Boost_1_49_0)
set(BOOST_REPO_TYPE SVN)

if(MSVC)
  set(BOOTSTRAP cd ${BOOST_SOURCE} && bootstrap.bat "--prefix=${CMAKE_CURRENT_BINARY_DIR}/install" --with-libraries=serialization,system,regex,date_time)
  set(BTWO b2 --without-mpi)
else()
  set(BOOTSTRAP cd ${BOOST_SOURCE} && ./bootstrap.sh "--prefix=${CMAKE_CURRENT_BINARY_DIR}/install" --with-libraries=serialization,system,regex,date_time)
  set(BTWO ./b2)
endif()

set(BOOST_EXTRA
  CONFIGURE_COMMAND ${BOOTSTRAP}
  BUILD_COMMAND cd ${BOOST_SOURCE} && ${BTWO} -j8
  INSTALL_COMMAND cd ${BOOST_SOURCE} && ${BTWO} install
)
