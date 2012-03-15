
set(BOOST_SOURCE "${CMAKE_SOURCE_DIR}/src/Boost")
set(BOOST_VERSION 1.42.0)
set(BOOST_REPO_URL http://svn.boost.org/svn/boost/tags/release/Boost_1_49_0)
set(BOOST_REPO_TYPE SVN)
set(BOOST_EXTRA
  CONFIGURE_COMMAND cd ${BOOST_SOURCE} && ./bootstrap.sh "--prefix=${CMAKE_CURRENT_BINARY_DIR}/install" --with-libraries=serialization,system,regex,date_time
  BUILD_COMMAND cd ${BOOST_SOURCE} && ./b2 -j8
  INSTALL_COMMAND cd ${BOOST_SOURCE} && ./b2 install
)
