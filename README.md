# Buildyard

Buildyard facilitates the build and development of multiple, dependent
projects from installed packages, git or svn repositories.

## Using

For Windows, use cmake to build a Visual Studio Solution. For all other
platforms, execute 'make' which invokes cmake and builds all debug
targets of all projects. Alternatively use 'make [Project]' to build a
single project and all its dependencies.

For development, cd into src/[Project] and work there as usual. The
default make target will build the (pre-configured) project without
considering any dependencies. 'make [Project]' will build the project
considering all dependencies.

## Configuration

The ExternalProject CMake module is the foundation for a simplified
per-project configuration file. Each project has a config/name.cmake
configuration file, which contains the following variables:

* NAME\_VERSION: the required version of the project
* NAME\_DEPENDS: optional name list of dependencies
* NAME\_REPO\_TYPE: optional, git or svn. Default is git
* NAME\_REPO\_URL: git or svn repository URL
* NAME\_REPO\_TAG: The svn revision or git tag to use to build the project
* NAME\_ROOT\_VAR: optional CMake variable name for the project root,
  as required by the project find script. Default is  NAME\_ROOT

## Extending

The top-level CMakeLists reads all .cmake files from all config*
directories, and use them as a project. This allows extending the base
configuration with custom projects from other sources.

## TODO

* Local overrides, e.g., to specify a user fork repository
