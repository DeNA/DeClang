# DeClang

<sub>[日本語はこちら](https://github.com/DeNA/DeClang/blob/swift/release/5.5/README_JP.md)</sub>

## Introduction

DeClang is an anti-hacking compiler based on LLVM project and extended the OSS project ollvm (https://github.com/obfuscator-llvm/obfuscator).

We open sourced some of the obfuscation features of DeClang for now. Some other features might be open sourced in the future.

![難読化](https://user-images.githubusercontent.com/1781263/97404801-02c20780-193a-11eb-9a28-1870375e03fe.png "難読化")

DeClang is a compiler based anti-hack solution and has a lot of advantages over packer based solution. For the detailed comparison, please refer to the following document.
https://www.slideshare.net/dena_tech/declang-clang-dena-techcon-2020

## Supported Architecture

Supported host architecture

- x64 macOS
- x64 Linux
- x64 Windows

Supported target architecture

- arm / arm64 ELF (Android)
- arm / arm64 Mach-O (iPhone)
- x86 / x64 ELF (Linux)
- x86 / x64 Mach-O (macOS)

## Build

```
$ git clone https://github.com/DeNA/DeClang
$ cd DeClang/script
$ bash build.sh
...
$ bash build_tools.sh
...
$ bash release.sh v1.0.0
...
```
Then you have a Release-v1.0.0 folder in the root directory of DeClang. 

If you are building DeClang on Windows, you have to install MYSYS2 and run
the above script in MYSYS2 shell. Also, Visual Studio 2017 is required for build.

## Installation & Setup

- Define DECLANG_HOME environment variable
  ```
  export DECLANG_HOME=/path/to/declang_home/
  ```

- Copy Release folder to $DECLAHG_HOME
  - If you built DeClang by yourself
    - Copy Release-v1.0.0 to $DECLANG_HOME/.DeClang. 
    ```
    mv Release-v1.0.0 $DECLANG_HOME/.DeClang
    ```
  - If you downloaded pre-built binary from Releases page.
    - Decompress the zip file and copy the Release folder to $DECLANG_HOME/.DeClang.
    ```
    mv Release/ $DECLANG_HOME/.DeClang
    ```

- Setup DeClang for android-ndk:
  ```
  bash $DECLANG_HOME/.DeClang/script/ndk_setup.sh {/path/to/ndk_root}
  ```
  Recover the original NDK:
  ```
  bash $DECLANG_HOME/.DeClang/script/ndk_unset.sh {/path/to/ndk_root}
  ```


- Setup DeClang for Xcode:
  ```
  bash $DECLANG_HOME/.DeClang/script/xcode_setup.sh -x {/path/to/Xcode.app} -p {/path/to/xcodeproject.xcodeproj}
  ```
  Recover the original xcode project file:
  ```
  bash $DECLANG_HOME/.DeClang/script/xcode_unset.sh {/path/to/xcodeproject.xcodeproj}
  ```


- Setup DeClang for WebGL Build of Unity:
  ```
  bash $DECLANG_HOME/.DeClang/script/webgl_setup.sh {/path/to/unity_webgl_support}
  ```
  Recover the original WebGLSupport directory:
  ```
  bash $DECLANG_HOME/.DeClang/script/webgl_unset.sh {/path/to/unity_webgl_support}
  ```

- Now you can build your project using your usual build pipeline.

## Pre-Built Binaries

- Release-Linux-*-ubuntu22.04.zip
  - C/C++ compiler for Ubuntu 22.04
- Release-MacArm-*.zip
  - C/C++/ObjC compiler for AppleSilicon Mac
- Release-MacIntel-*.zip
  - C/C++/ObjC compiler for Intel Mac
- Release-Win-*.zip
  - C/C++ compiler for Windows
- Release-Swift-Toolchain-*.zip
  - Swift compiler for AppleSilicon/Intel Mac
  - How to Insatll
    1. Run `tar -xzf swift-LOCAL-*-a-osx.tar.gz -C ~/` to deploy
    2. Open Xcode and select Xcode->Toolchains->Local Swift Development Snapshot
    3. Edit your ~/.DeClang/config.pre.json and run `~/.DeClang/gen_config.sh`
    4. Build your application in xcode

## Configuration

- Edit config.pre.json in $DECLANG_HOME/.DeClang/ folder:
  ```
  vi $DECLANG_HOME/.DeClang/config.pre.json
  ```
  | key | description | value type |
  | -- | -- | ------------- |
  | build_seed | default seed to be used by obfuscation | string |
  | overall_obfuscation | strength of simple obfuscation for overall code | integer 0-100 (default 0) |
  | flatten[name] | function name to be flatten-obfuscated | regex string |
  | flatten[seed] | seed to be used by flatten-obfuscation | 16-digit hexadecimal string |
  | flatten[split_level] | level to split Basic Block for flatten-obfuscation | integer (default 1)|
  | enable_obfuscation | enable/disable flatten-obfuscation | integer 0-1 (default 1) |

- Generate config.json from config.pre.json:
  ```
  $DECLANG_HOME/.DeClang/gen_config.sh -path $DECLANG_HOME/.DeClang/ -seed {your seed}
  ```
  "seed" can be any string. You should change "seed" for each build.

## Unity Support

If you are building your Unity project using command line then set the DECLANG_HOME in command line is sufficient.
But if you are building a Unity project using GUI, you should set the DECLANG_HOME environment variable in your build script:
```
System.Environment.SetEnvironmentVariable("DECLANG_HOME", "/path/to/DeClang/");
```

## Notes

- If you do not set DECLANG_HOME, DeClang will use the default directory `~/.DeClang/`
- Note that usually DeClang for NDK and DeClang for Xcode might not be compatitable with each other so when you install & setup DeClang 
for different architecture please make sure you are using the correct DeClang version.
- When building the Android library using Gradle, run `ndk_setup.sh` according to the `ndkVersion` listed in build.gradle.
Also, please enable the optimization by mentioning `set(CMAKE_CXX_FLAGS_RELEASE "-O2") ` in the CMakefile.txt file.
If DeClang does not enable optimization, the process will not be passed to LLVM Pass, which performs obfuscation.
