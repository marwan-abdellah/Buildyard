
set(BOOST_VERSION 1.41.0)
set(BOOST_REPO_URL https://git.gitorious.org/~eile/boost/eile-boost.git)
set(BOOST_REPO_TAG cmake-release)
set(BOOST_SOURCE "${CMAKE_SOURCE_DIR}/src/Boost")
set(BOOST_OPTIONAL ON)
# set(BOOST_FORCE_BUILD ON)
set(BOOST_CMAKE_ARGS "-DCMAKE_OSX_ARCHITECTURES:STRING=i386!x86_64" "-DBUILD_PROJECTS:STRING=serialization!system!regex!date_time")
