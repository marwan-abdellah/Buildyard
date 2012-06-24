
set(XDR_VERSION 1.0)
set(XDR_REPO_URL https://github.com/marayl/openxdr.git)
set(XDR_REPO_TAG master)
set(XDR_SOURCE "${CMAKE_SOURCE_DIR}/src/openxdr")

if(NOT MSVC)
  return()
endif()

set(XDR_PREFIXPATH)
set(XDR_NATIVESOURCE)
file(TO_NATIVE_PATH ${CMAKE_CURRENT_BINARY_DIR}/install XDR_PREFIXPATH)
file(TO_NATIVE_PATH ${XDR_SOURCE} XDR_NATIVESOURCE)
set(INSTALLFILE "${CMAKE_CURRENT_BINARY_DIR}/openxdr/install.bat")
file(WRITE "${INSTALLFILE}"
  "xcopy /Y /i ${XDR_NATIVESOURCE}\\rpc\\*.h ${XDR_PREFIXPATH}\\include\\rpc \n"
  "xcopy /Y /i ${XDR_NATIVESOURCE}\\vc9\\Release\\openxdr.dll ${XDR_PREFIXPATH}\\bin\\ \n"
  "xcopy /Y /i ${XDR_NATIVESOURCE}\\vc9\\Release\\openxdr.lib ${XDR_PREFIXPATH}\\lib\\"
)
set(XDR_EXTRA
  CONFIGURE_COMMAND cd ${XDR_SOURCE}/vc9
  BUILD_COMMAND MSBuild ${XDR_SOURCE}/vc9/openxdr.sln /p:Configuration=Release
  INSTALL_COMMAND ${INSTALLFILE}
)
