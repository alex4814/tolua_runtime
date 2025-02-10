ToLua Runtime
=============
Maintained ToLua runtime for Unity games using ToLua.


Motivation
----------
- Mainly to update outdated libraries.
- Upgrade build script or toolchains for each platforms.


Build
-----
CMake 3.14+ is required to build `tolua` and cross-compiling.

> NOTE: Every predefiend build script would install the target library to *Plugins*
> folder, which could be placed on any subfolder in *Assets*, according to the 
> [disccusion](https://discussions.unity.com/t/plugins-folder-inside-a-unity-package-does-it-have-to-be-on-the-root-folder-or-not/934638/2)
> for newer version of Unity.

### Windows (x86, x86_64)
When targeting Windows, MSVC is preferred ~~over MinGW or CYGWIN~~.

Visual Studio 2017+ should work (Tested for Visual Studio 2022)

```bat
> .\build_tolua_windows_x86.bat
> .\build_tolua_windows_x64.bat
```

### Android (arm64)
To build for Android, you need to install the Android NDK and Ninja.

Set environment variable `ANDROID_NDK_HOME` to the path of the NDK,
e.g. `export ANDROID_NDK_HOME=/path/to/android-ndk-r27c` on UNIX-like systems, or
pass `-DANDROID_NDK=/path/to/android-ndk-r27c` to CMake command.

#### Cross-compiling on Windows
`make` and `gcc` are required. 

Using [Scoop](https://scoop.sh/) or other package managers to install `gcc` and `make`.
```bat
> scoop install make
> scoop install gcc
> set ANDROID_NDK_HOME=/path/to/android-ndk-r27c && .\build_tolua_android_arm64.bat
```

#### Cross-compiling on macOS and Linux
```bash
$ export ANDROID_NDK_HOME=/path/to/android-ndk-r27c && ./build_tolua_android_arm64.sh
```

### macOS (universal)
Xcode is needed for macOS.

```bash
$ ./build_tolua_osx_universal.sh
```

### Legacy
NDK 版本:android-ndk-r10e 默认安装到 D:/android-ndk-r10e<br>
https://dl.google.com/android/repository/android-ndk-r10e-windows-x86_64.zip<br>
Msys2配置说明<br>
https://github.com/topameng/tolua_runtime/wiki<br>
配置好的Msys2下载<br>
https://pan.baidu.com/s/1c2JzvDQ<br>


Libraries
---------
LuaJIT is updated to (current) latest v2.1 branch (commit at 2025-01-13 16:22:22)

|                              | Version   | Notes                         |
| ---------------------------- | --------- | ----------------------------- |
| [openresty/lua-cjson][1]     | v2.1.0.14 | Moved from [mpx/lua-cjson][2] |
| [lunarmodules/luasocket][3]  | v3.1.0    | original v3.0-rc1             |
| [topameng/protoc-gen-lua][4] |           |                               |
| [struct][5]                  | v1.8      | original v1.4                 |
| [alex4814/lpeg-luajit][6]    | v1.1.0    | original v0.10                |

[1]: https://github.com/openresty/lua-cjson/tree/2.1.0.14
[2]: https://github.com/mpx/lua-cjson
[3]: https://github.com/lunarmodules/luasocket/tree/v3.1.0
[4]: https://github.com/topameng/protoc-gen-lua
[5]: http://www.inf.puc-rio.br/~roberto/struct/
[6]: https://github.com/alex4814/lpeg-luajit
