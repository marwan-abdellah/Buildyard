# CMake Projects

CMake projects facilitates the build and development of multiple,
dependent projects from installed packages, git or svn repositories. It uses the
ExternalProject CMake module with a simplified per-project configuration
file. Each project has a config/name.cmake configuration file, which
contains the following variables:

* NAME\_VERSION: the required version of the project
* NAME\_DEPENDS: optional name list of dependencies
* NAME\_REPO\_TYPE: optional, git or svn. Default is git
* NAME\_REPO\_URL: git or svn repository URL
* NAME\_REPO\_TAG: The svn revision or git tag to use to build the project
* NAME\_ROOT\_VAR: optional CMake variable name for the project root,
  as required by the project find script. Default is  NAME\_ROOT

