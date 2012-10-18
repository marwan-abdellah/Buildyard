
set(HDF5_VERSION 1.8)
set(HDF5_REPO_URL http://www.hdfgroup.org/ftp/HDF5/current/src/hdf5-1.8.9.tar.gz)
set(HDF5_REPO_TYPE FILE)
set(HDF5_SOURCE "${CMAKE_SOURCE_DIR}/src/hdf5")
set(HDF5_OPTIONAL ON)

if(CMAKE_VERSION VERSION_GREATER 2.8.5)
  file(DOWNLOAD
    http://www.hdfgroup.org/ftp/HDF5/current/src/cmake_patch.txt
    ${CMAKE_BINARY_DIR}/HDF5/cmake_patch.txt
    )
  set(HDF5_CMAKE_ARGS -DBUILD_SHARED_LIBS=ON -DHDF5_BUILD_CPP_LIB=ON -DHDF5_BUILD_HL_LIB=ON)
  set(HDF5_EXTRA
    PATCH_COMMAND cd "${CMAKE_SOURCE_DIR}/src/hdf5" && patch < ${CMAKE_BINARY_DIR}/HDF5/cmake_patch.txt
  )
else()
  set(HDF5_EXTRA
    CONFIGURE_COMMAND ${HDF5_SOURCE}/configure --enable-cxx --without-h5dump --disable-h5dump "--prefix=${CMAKE_CURRENT_BINARY_DIR}/install"
  )
endif()
