set(BLURON_VERSION 7.3)
set(BLURON_REPO_URL https://github.com/BlueBrain/Bluron.git)
set(BLURON_REPO_TAG master)
set(BLURON_SOURCE "${CMAKE_SOURCE_DIR}/src/nrn")
set(BLURON_OPTIONAL ON)

set(BLURON_EXTRA
  PATCH_COMMAND cd ${BLURON_SOURCE} && ./build.sh
  CONFIGURE_COMMAND ${BLURON_SOURCE}/configure --with-paranrn --without-iv --without-memacs --disable-shared --enable-static MPICC=mpicc MPICXX=mpicxx CC=mpicc CXX=mpicxx "CXXFLAGS=-g -O2" "CFLAGS=-g -O2" "LDFLAGS=-g -O2" with_readline=no java_dlopen=no linux_nrnmech=no "--prefix=${CMAKE_CURRENT_BINARY_DIR}/install"
)
