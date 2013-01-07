
# Copyright (c) 2012 Stefan Eilemann <Stefan.Eilemann@epfl.ch>

cmake_minimum_required(VERSION 2.8 FATAL_ERROR)
project(Buildyard)

set(VERSION_MAJOR "1")
set(VERSION_MINOR "6")
set(VERSION_PATCH "0")
set(RELEASE_VERSION 0) # OFF or ABI version

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/CMake)

include(Common)
include(ReadConfigs)
include(GitTargets)
