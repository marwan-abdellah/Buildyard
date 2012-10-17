
set(HDF5_VERSION 1.8.8)
set(HDF5_REPO_URL http://www.hdfgroup.org/ftp/HDF5/current/src/hdf5-1.8.9.tar.gz)
set(HDF5_REPO_TYPE FILE)
set(HDF5_SOURCE "${CMAKE_SOURCE_DIR}/src/hdf5")
set(HDF5_OPTIONAL ON)
set(HDF5_CMAKE_ARGS -DBUILD_SHARED_LIBS=ON -DHDF5_BUILD_CPP_LIB=ON -DHDF5_BUILD_HL_LIB=ON)

set(HDF5_EXTRA
  PATCH_COMMAND cd "${CMAKE_SOURCE_DIR}/src/hdf5" && wget http://www.hdfgroup.org/ftp/HDF5/current/src/cmake_patch.txt && patch < cmake_patch.txt
)
