
include(ExternalProject)

function(USE_EXTERNAL_GATHER_ARGS NAME)
  # sets ${UPPER_NAME}_ARGS on return, to be passed to CMake
  string(TOUPPER ${NAME} UPPER_NAME)

  # recurse to get dependency roots
  include(${NAME})
  foreach(PROJ ${${UPPER_NAME}_DEPENDS})
    use_external_gather_args(${PROJ})
    string(TOUPPER ${PROJ} UPPER_PROJ)
    set(ARGS ${ARGS} ${${UPPER_PROJ}_ARGS})
  endforeach()

  # self root '-DFOO_ROOT=<path>'
  set(INSTALL_PATH "${CMAKE_CURRENT_BINARY_DIR}/${NAME}")
  if("${UPPER_NAME}_ROOT_VAR" STREQUAL "")
    set(ARGS ${ARGS} "-D${UPPER_NAME}_ROOT=${INSTALL_PATH}")
  else()
    set(ARGS ${ARGS} "-D${${UPPER_NAME}_ROOT_VAR}=${INSTALL_PATH}")
  endif()

  set(${UPPER_NAME}_ARGS ${ARGS} PARENT_SCOPE) # return value
endfunction()

function(USE_EXTERNAL NAME)
  # Searches for an external project.
  #  Sets NAME_ROOT to the installation directory when not found using
  #  find_package().
  # * First searches using find_package taking into account:
  # ** NAME_ROOT CMake and environment variables
  # ** .../share/NAME/CMake
  # ** Version is read from optional $NAME.cmake
  # * If no pre-installed package is found, use ExternalProject to get dependency
  # ** External project settings are read from $NAME.cmake
  include(${NAME})

  string(SUBSTRING ${NAME} 0 2 SHORT_NAME)
  string(TOUPPER ${SHORT_NAME} SHORT_NAME)
  string(TOUPPER ${NAME} UPPER_NAME)
  set(ROOT ${UPPER_NAME}_ROOT)
  set(ENVROOT $ENV{${ROOT}})
  set(SHORT_ROOT ${SHORT_NAME}_ROOT)
  set(SHORT_ENVROOT $ENV{${SHORT_ROOT}})

  # CMake module search path
  if(${${SHORT_ROOT}})
    list(APPEND CMAKE_MODULE_PATH "${${SHORT_ROOT}}/share/${NAME}/CMake")
  endif()
  if(NOT "${SHORT_ENVROOT}" STREQUAL "")
    list(APPEND CMAKE_MODULE_PATH "${SHORT_ENVROOT}/share/${NAME}/CMake")
  endif()
  if(${${ROOT}})
    list(APPEND CMAKE_MODULE_PATH "${${ROOT}}/share/${NAME}/CMake")
  endif()
  if(NOT "${ENVROOT}" STREQUAL "")
    list(APPEND CMAKE_MODULE_PATH "${ENVROOT}/share/${NAME}/CMake")
  endif()

  list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/${NAME}/CMake")
  list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/../${NAME}/CMake")
  list(APPEND CMAKE_MODULE_PATH "${CMAKE_INSTALL_PREFIX}/share/${NAME}/CMake")
  list(APPEND CMAKE_MODULE_PATH /usr/share/${NAME}/CMake)
  list(APPEND CMAKE_MODULE_PATH /usr/local/share/${NAME}/CMake)

  # try find_package
  find_package(${NAME} ${${UPPER_NAME}_VERSION})
  if(${UPPER_NAME}_FOUND)
    return()
  endif()

  if("${${UPPER_NAME}_REPO_URL}" STREQUAL "")
    message(FATAL_ERROR
      "No repository information for ${NAME}, create ${NAME}.cmake?")
  endif()

  # External Project
  set(REPO_TYPE ${${UPPER_NAME}_REPO_TYPE})
  if(NOT REPO_TYPE)
    set(REPO_TYPE git)
  endif()
  string(TOUPPER ${REPO_TYPE} REPO_TYPE)

  if(REPO_TYPE STREQUAL "GIT")
    set(REPO_TAG GIT_TAG)
  elseif(REPO_TYPE STREQUAL "SVN")
    set(REPO_TAG SVN_REVISION)
  else()
    message(FATAL_ERROR "Unkown repository type ${REPO_TYPE}")
  endif()

  set(REPO_TAG_VAL ${${UPPER_NAME}_TAG})
  if(NOT REPO_TAG_VAL)
    set(REPO_TAG_VAL HEAD)
  endif()

  set(INSTALL_PATH "${CMAKE_CURRENT_BINARY_DIR}/${NAME}")
  use_external_gather_args(${NAME})
  set(ARGS -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
           -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PATH}
           ${${UPPER_NAME}_ARGS})

  ExternalProject_Add(${NAME}
    PREFIX "${CMAKE_CURRENT_BINARY_DIR}/${NAME}"
    BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/${NAME}/build"
    INSTALL_DIR "${INSTALL_PATH}"
    DEPENDS "${${UPPER_NAME}_DEPENDS}"
    ${REPO_TYPE}_REPOSITORY ${${UPPER_NAME}_REPO_URL}
    ${REPO_TAG} ${REPO_TAG_VAL}
    CMAKE_ARGS ${ARGS}
    )

  if("${UPPER_NAME}_ROOT_VAR" STREQUAL "")
    set(${UPPER_NAME}_ROOT "${INSTALL_PATH}" PARENT_SCOPE)
  else()
    set(${${UPPER_NAME}_ROOT_VAR} "${INSTALL_PATH}" PARENT_SCOPE)
  endif()

  #if(WIN32)
  #  set(${UPPER_NAME}_LIBRARY ${${UPPER_NAME}_install}/lib/vrpn${_LINK_LIBRARY_SUFFIX})
  #else()
  #  set(${UPPER_NAME}_LIBRARY ${${UPPER_NAME}_install}/lib/libvrpn.a)
  #endif()
  #set(${UPPER_NAME}_INCLUDE_DIR ${${UPPER_NAME}_install}/include)
endfunction()
