@echo OFF
REM Simple one-click batch file for executing Release builds on all Buildyard
REM projects using the Visual Studio 2008 aka vc9 compiler. Note that cmake.exe,
REM git.exe and svn.exe must be part of %PATH%.

REM load environment for Visual Studio 2008
set PWD=%~dp0
CALL "%VS90COMNTOOLS%"\vsvars32.bat

REM do initial configuration if required
IF not exist build_vc9 (
  mkdir build_vc9
  cd /D build_vc9
  cmake .. -G "Visual Studio 9 2008"
) ELSE (
  cd /D build_vc9
  cmake ..
)

REM build Release configuration and use all local CPU cores
msbuild Buildyard.sln /p:Configuration=Release /m /verbosity:detailed /t:ALL_BUILD
cd /D %PWD%
pause
