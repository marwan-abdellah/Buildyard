# Buildyard

## Introduction

Buildyard facilitates the build and development of multiple, dependent
projects from installed packages, git or svn repositories. The following
projects are currently available, with optional dependencies drawn as
dotted bubbles:

![Depency Graph](http://eyescale.github.com/images/all.png)

## Presentation

[Presentation.pdf](https://github.com/BlueBrain/Buildyard/blob/master/doc/Presentation.pdf?raw=true)

## Using

### Visual Studio

Use cmake to build a Visual Studio Solution. Build this solution at
least once to download and install all dependencies. Do not use
'Build->Build Solution', but build the project 'ALL_BUILD' or
'00_Main->AllProjects' instead. The solution contains sub-targets without
proper depencies, which will cause build failures.

For development, open [build]/[Project]/[Project].sln and work there as
usual. This solution will build the (pre-configured) project without
considering any dependencies. Use the [build]/Buildyard.sln target to
build a project considering all dependencies.

### Others

Execute 'make' or 'make [Project]', which invokes cmake and builds debug
versions of all or the specified project.

For development, cd into src/[Project] and work there as usual. The
default make target will build the (pre-configured) project without
considering any dependencies. 'make [Project]' will build the project
considering all dependencies.

Custom CMake binary directories are supported and can be used through
the top-level make using 'make BUILD=[directory]' or 'export
BUILD=[directory]; make'.

## Configuration

The ExternalProject CMake module is the foundation for a simplified
per-project configuration file. Each project has a config/name.cmake
configuration file, which contains the following variables:

* NAME\_VERSION: the required version of the project
* NAME\_DEPENDS: list of dependencies, OPTIONAL and REQUIRED keywords
  are recognized. Projects with missing required dependencies will not
  be configured.
* NAME\_DEPENDEE\_COMPONENTS: list of COMPONENTS for find_package.
* NAME\_REPO\_TYPE: optional, git, git-svn or svn. Default is git.
* NAME\_REPO\_URL: git or svn repository URL.
* NAME\_REPO\_TAG: The svn revision or git tag to use to build the project
* NAME\_ROOT\_VAR: optional CMake variable name for the project root,
  as required by the project find script. Default is NAME\_ROOT.
* NAME\_TAIL\_REVISION: The oldest revision a git-svn repository should
  be cloned with.
* NAME\_CMAKE\_ARGS Additional CMake arguments for the configure
  step. The character '!' can be used to separate list items.

## Extending

The top-level CMakeLists reads all .cmake files from all config*
directories, and use them as a project. This allows extending the base
configuration with custom projects from other sources.

## Options
### Local overrides

For customizing the shipped configurations one can override and extend those
configurations with a config.local/name.cmake configuration. Additional options
are available there to specify a user fork for instance. Note that this options
are only valid for git repositories:

* NAME\_USER\_URL: the URL of the new origin for the project
* NAME\_ORIGIN\_NAME: the new remote name of the original origin
  (optional, default 'root')

### Force build from source

Setting NAME\_FORCE\_BUILD to ON will disable finding installed versions
of the project, causing the project to be always build from source.

## Targets

Below are the targets in addition to the standard targets of
ExternalProject.cmake:

### NAME-buildonly

Builds only the the given project without considering dependencies,
update and configure steps.

### NAME-projects

Builds all non-optional dependees of the given project, useful for
testing downstream projects after API changes.

### NAME-deps

Builds all dependencies of the given project.

### stats

Runs 'SCM status' on all projects.
