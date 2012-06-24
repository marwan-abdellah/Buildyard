REM Simple one-click batch file for executing Release builds on all Buildyard
REM projects using the Visual Studio 2010 aka vc10 compiler. Note that
REM cmake.exe, git.exe and svn.exe must be part of %PATH%.

REM load environment for Visual Studio 2010
set PWD=%~dp0
echo %PWD%
cd /D %VS100COMNTOOLS%
CALL vsvars32.bat
cd /D %PWD%

REM do initial configuration if required
IF not exist build_vc10 (
  mkdir build_vc10
  cd build_vc10
  cmake .. -G "Visual Studio 10"
) ELSE (
  cd build_vc10
)

REM build Release configuration and use all local CPU cores
msbuild /p:Configuration=Release /m ALL_BUILD.vcxproj
cd /D %PWD%
pause
