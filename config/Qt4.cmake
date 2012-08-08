set(QT4_VERSION 4.6)
# Building from Qt from source is not that trivial and not necessary for most
# systems as pre-build packages can be used, even for Windows:
# http://qt.nokia.com/downloads/
#set(QT4_REPO_URL git://gitorious.org/qt/qt.git)
set(QT4_REPO_TAG ${QT4_VERSION})
set(QT4_SOURCE "${CMAKE_SOURCE_DIR}/src/qt")
set(QT4_OPTIONAL ON)
