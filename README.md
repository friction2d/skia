# Skia for Friction

Fork of skia for use with [Friction](https://friction.graphics/). This is a complete 2D graphic library for drawing Text, Geometries, and Images.

## Linux/macOS

### Requirements

* ninja
* python3
* cmake
* clang
* expat
* freetype
* fontconfig
* libjpeg-turbo
* libpng
* libwebp
* zlib

### Options *(default values are shown)*

* `-DSKIA_STATIC=OFF` *(build a static .a library, not available for Windows)*
* `-DSKIA_USE_SYSTEM_LIBS=ON` *(Use system libraries where possible)*
* `-DSKIA_SYNC_EXTERNAL=OFF` *(Get third-party sources, if using git and not using system libraries)*
* `-DINSTALL_DOCS=ON` *(Add README and LICENSE during install)*
* `-DINSTALL_HEADERS=ON` *(Add headers during install)*
* `-DSKIA_USE_EGL=ON` *(Use EGL on Linux/BSD, GLX is deprecated)*

### Build and install

```
git submodule update -i --recursive
mkdir build && cd build
cmake -G Ninja \
-DCMAKE_INSTALL_PREFIX=/usr \
-DCMAKE_CXX_COMPILER=clang++ \
-DCMAKE_C_COMPILER=clang ..
cmake --build .
```

```
cmake --install .
```

Add optional `--prefix=/some/path` to install to a different location.

```
├── include
│   └── skia-friction/...
├── lib
│   └── x86_64-linux-gnu
│       ├── libskia-friction.so -> libskia-friction.so.1.0.x
│       ├── libskia-friction.so.1 -> libskia-friction.so.1.0.x
│       └── libskia-friction.so.1.0.x
└── share
    └── doc
        └── skia-friction-1.0.x
            ├── LICENSE
            └── README.md
```

## Windows

### Requirements

* CMake, Python 3 and Ninja in PATH
* LLVM (Installed to Program Files, v15+ recommended)
* Visual Studio (Build Tools) 2017
  * To support 2022+ we need to break compat with 2017, since Friction is using 2017 we will not upgrade yet

### Build

```
cmake -A x64 -DSKIA_USE_SYSTEM_LIBS=OFF -DSKIA_SYNC_EXTERNAL=ON ..
cmake --build .
```

* `SKIA_SYNC_EXTERNAL=ON` requires git in PATH, not needed if using source tarball
