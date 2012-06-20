
# Copyright (c) 2012 Stefan Eilemann <Stefan.Eilemann@epfl.ch>

cmake_minimum_required(VERSION 2.8 FATAL_ERROR)
project(Buildyard)

set(VERSION_MAJOR "1")
set(VERSION_MINOR "3")
set(VERSION_PATCH "5")
set(RELEASE_VERSION 0) # OFF or ABI version

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/CMake)

include(Common)
include(ModulePath)
include(ReadConfigs)
include(GitTargets)
