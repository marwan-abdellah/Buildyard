
# Copyright (c) 2012 Stefan Eilemann <Stefan.Eilemann@epfl.ch>

cmake_minimum_required(VERSION 2.8 FATAL_ERROR)
project(Buildyard)

set(VERSION_MAJOR "1")
set(VERSION_MINOR "3")
set(VERSION_PATCH "5")
set(VERSION ${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH})

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib") 
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/CMake)
list(APPEND CMAKE_PREFIX_PATH ${SystemDrive}:/cygwin/bin)

include(ModulePath)
include(ReadConfigs)
include(GitTargets)
