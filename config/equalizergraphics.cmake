if(MSVC)
  return()
endif()

set(EQUALIZERGRAPHICS_OPTIONAL true)
set(EQUALIZERGRAPHICS_DEPENDS Equalizer)
set(EQUALIZERGRAPHICS_REPO_URL https://github.com/Eyescale/equalizergraphics.com.git)
set(EQUALIZERGRAPHICS_REPO_TAG master)
set(EQUALIZERGRAPHICS_SOURCE "${CMAKE_SOURCE_DIR}/src/equalizergraphics")

set(EQUALIZERGRAPHICS_EXTRA
  CONFIGURE_COMMAND true
  BUILD_COMMAND cd ${EQUALIZERGRAPHICS_SOURCE} && make -j8
  INSTALL_COMMAND cd ${EQUALIZERGRAPHICS_SOURCE} && make -j8 install
)