set(QWT_VERSION 5.2)
set(QWT_DEPENDS REQUIRED Qt4)
set(QWT_REPO_URL https://qwt.svn.sourceforge.net/svnroot/qwt/tags/qwt-5.2.2)
set(QWT_REPO_TYPE svn)
set(QWT_SOURCE "${CMAKE_SOURCE_DIR}/src/qwt")
set(QWT_OPTIONAL ON)

if(NOT MSVC)
  return()
endif()

# Important note: before the qmake step you may want to do following changes in
# ${QWT_SOURCE}/qwtconfig.pri:
# - set INSTALLBASE to the install directory inside the Buildyard build folder
# - change CONFIG from debug to release
# - disable building of QwtDesigner (not building at least with VS2010, Qwt 5.2
#   and Qt 4.8)
set(QWT_EXTRA
  SVN_TRUST_CERT 1
  CONFIGURE_COMMAND cd ${QWT_SOURCE} && qmake qwt.pro
  BUILD_COMMAND cd ${QWT_SOURCE} && nmake
  INSTALL_COMMAND cd ${QWT_SOURCE} && nmake install
)
