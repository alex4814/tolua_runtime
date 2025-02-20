@rem Script to build tolua for Windows arm64.
@rem Copyright (C) 2025 Rython Fu.

@setlocal enabledelayedexpansion

@set GENERATOR="Visual Studio 17 2022"
@set ARCH=arm64
@set CMAKE_ARCH=ARM64
@set CONFIG=Release
@set BUILD_DIR=.\Build\windows\%ARCH%
@set INSTALL_DIR=.\Plugins\Windows\%ARCH%

@cmake ^
  -G %GENERATOR% ^
  -A %CMAKE_ARCH% ^
  -B "%BUILD_DIR%"

@cmake ^
  --build "%BUILD_DIR%" ^
  --config %CONFIG%

md "%INSTALL_DIR%"
copy /y "%BUILD_DIR%\%CONFIG%\tolua.dll" "%INSTALL_DIR%"
