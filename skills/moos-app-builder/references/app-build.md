# MOOS App Build Reference

## Generator

Run the generator from the project source directory:

```bash
$MOOS_IVP_ROOT/scripts/GenMOOSApp_AppCasting Odometry p "Author Name"
```

This creates `pOdometry/` with an app-local `CMakeLists.txt`. It does not update the parent project build.

## Parent CMake

If the project already has a parent `src/CMakeLists.txt`, add:

```cmake
ADD_SUBDIRECTORY(pOdometry)
```

Match local casing and section placement.

If no project CMake exists, create a minimal external-project skeleton rather than editing core MOOS-IvP:

```cmake
cmake_minimum_required(VERSION 3.16)
project(MOOSUserApps)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(MOOS_IVP_ROOT "$ENV{MOOS_IVP_ROOT}" CACHE PATH "MOOS-IvP checkout")

find_package(MOOS 10.0 REQUIRED PATHS
  "${MOOS_IVP_ROOT}/build/MOOS/MOOSCore"
  "${MOOS_IVP_ROOT}/build/MOOS"
  "${MOOS_IVP_ROOT}/MOOS"
  "${MOOS_IVP_ROOT}/MOOS_Jul0519"
  "${MOOS_IVP_ROOT}/MOOS_Jul2724"
)

include_directories(
  ${MOOS_INCLUDE_DIRS}
  "${MOOS_IVP_ROOT}/include/ivp"
)

link_directories("${MOOS_IVP_ROOT}/lib")

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/bin")

add_subdirectory(src)
```

If `MOOS_IVP_ROOT` is not exported in the shell, either substitute the resolved
absolute checkout path in the cache default or configure with:

```bash
cmake -S . -B build -DMOOS_IVP_ROOT=/path/to/moos-ivp
```

Then `src/CMakeLists.txt` can contain app subdirectories:

```cmake
add_subdirectory(pOdometry)
```

For a persistent personal project, the app binary normally becomes available by adding the project `bin` directory to the shell `PATH`, matching the `.bashrc` pattern:

```bash
PATH=$PATH:~/my-moos-project/bin
export PATH
```

Do not edit shell startup files unless the user asks for persistent integration.

## App Libraries

Generator defaults are usually enough for a simple AppCasting app:

```cmake
TARGET_LINK_LIBRARIES(pOdometry
  ${MOOS_LIBRARIES}
  apputil
  mbutil
  m
  pthread)
```

Add libraries only when used:

- `mbutil`: string parsing, numeric validation, formatting, common utilities
- `apputil`: AppCasting tables/reports and app utility support
- `geometry`: `XYPoint`, `XYPolygon`, `XYSegList`, angle/range/extrapolation utilities
- `contacts`: `NodeRecord`, contact parsing utilities; link `geometry` with `contacts` when using `NodeRecordUtils`
- `logic`: logic conditions
- `ufield`, `obstacles`, etc. only for their specific classes

Before adding local helper code, search `${MOOS_IVP_ROOT}/include/ivp` and nearby app examples for an existing utility class or parser.

On macOS/Linux portability, prefer a `SYSTEM_LIBS` block if the local project already uses one.

If the app calls `MOOSTime()`, include the MOOS utility header used by local
examples, commonly:

```cpp
#include "MOOS/libMOOS/Utils/MOOSUtilityFunctions.h"
```

Prefer the include form already used by nearby apps in the resolved checkout.

## Mission Config Snippet

When the user asks only for app source, a `ProcessConfig = <AppName>` example in
`_Info.cpp` is enough. When the user asks for a runnable sample mission, include
both the app `ProcessConfig` and the launcher context that starts it, such as a
minimal `ProcessConfig = ANTLER` block or the existing mission's launcher
pattern.

## Build Commands

Use the project build style if present. For a minimal scratch project:

```bash
cmake -S . -B build
cmake --build build
./bin/pOdometry --help
./bin/pOdometry --example
./bin/pOdometry --interface
```
