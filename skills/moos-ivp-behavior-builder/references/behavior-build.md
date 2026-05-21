# Behavior Build and Loading Reference

## Generator

Create and enter the behavior library source directory before running the generator:

```bash
mkdir -p src/lib_behaviors-user
cd src/lib_behaviors-user
$MOOS_IVP_ROOT/scripts/GenBehavior Pulse "Author Name"
```

This appends to `BHV_Pulse.h` and `BHV_Pulse.cpp`. Use a clean directory or remove stale generated files first. It does not update CMake.

## Minimal External Project CMake

If a user project has no CMake skeleton, create one outside core MOOS-IvP:

```cmake
cmake_minimum_required(VERSION 3.16)
project(MOOSUserBehaviors)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(MOOS_IVP_ROOT "$ENV{MOOS_IVP_ROOT}" CACHE PATH "MOOS-IvP checkout")

include_directories("${MOOS_IVP_ROOT}/include/ivp")
link_directories("${MOOS_IVP_ROOT}/lib")

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/lib")

add_subdirectory(src/lib_behaviors-user)
```

## Behavior Library CMake

Use one shared library per behavior by default. Follow a different convention only in an established project that already builds and loads behaviors that way:

```cmake
if(${WIN32})
  set(SYSTEM_LIBS wsock32)
else()
  set(SYSTEM_LIBS m pthread)
endif()

add_library(BHV_Pulse SHARED
  BHV_Pulse.cpp)

target_link_libraries(BHV_Pulse
  helmivp
  behaviors
  ivpbuild
  logic
  ivpcore
  bhvutil
  mbutil
  geometry
  ${SYSTEM_LIBS})
```

Keep `geometry` in the default link set; `IvPBehavior` itself depends on geometry utilities. Add extra `.cpp` files for AOFs or helper classes.

Library roles:

- `behaviors`: `IvPBehavior`, `IvPContactBehavior`, behavior base support
- `helmivp`: helm behavior loading and behavior-set support
- `ivpbuild`: ZAICs, Reflector, IvP function builders
- `ivpcore`: core IvP data structures
- `bhvutil`: behavior helper classes and AOF support
- `geometry`: angle utilities, `PlatModel`, `XY*` geometry, CPA utilities
- `mbutil`: parsing, validation, string and formatting helpers

Before adding local helper code, search `${MOOS_IVP_ROOT}/include/ivp` and representative behaviors for an existing utility.

## Helm Loading

The dynamic loader looks for `libBHV_*.dylib` on macOS and `libBHV_*.so` on Linux. `add_library(BHV_Pulse SHARED ...)` produces the right name on Unix-like systems.

Make the library visible to the helm. For persistent personal projects, prefer
the user's shell convention by appending the project `lib` directory to
`IVP_BEHAVIOR_DIRS`, commonly in `.bashrc`:

```bash
IVP_BEHAVIOR_DIRS+=:~/my-moos-project/lib
export IVP_BEHAVIOR_DIRS
```

For one shell session, use:

```bash
export IVP_BEHAVIOR_DIRS="${IVP_BEHAVIOR_DIRS}:/path/to/project/lib"
```

For isolated tests, avoid inheriting unrelated behavior directories:

```bash
export IVP_BEHAVIOR_DIRS="/path/to/project/lib"
```

Use a mission-local `ivp_behavior_dir` line only when the user explicitly wants
a self-contained mission, non-interactive execution cannot assume shell setup,
or an existing mission already uses this convention:

```text
ivp_behavior_dir = ../../lib
```

Relative mission paths are resolved relative to the mission file context used
by the helm. Do not edit shell startup files unless the user asks for
persistent integration.

For runtime load checks, make sure the helm process name matches the mission block:

```bash
PATH=$MOOS_IVP_ROOT/bin:$PATH pHelmIvP mission.moos
```

If launching by absolute path, pass `--alias=pHelmIvP`; otherwise MOOS may use the full path as the app name and skip `ProcessConfig = pHelmIvP`.

Treat the load check as successful only when the helm reports concrete loader success, for example:

```text
About to load behavior library: BHV_Pulse ... SUCCESS
BehaviorSet: all_builds_ok: true
```

## Build Commands

```bash
cmake -S . -B build
cmake --build build
ls lib/libBHV_Pulse.*
```

Before runtime loading, verify the dynamic factory symbol exists:

```bash
nm -gU lib/libBHV_Pulse.dylib | rg 'createBehavior'
nm -D lib/libBHV_Pulse.so | rg 'createBehavior'
```

Use the macOS or Linux command as appropriate.

## Runtime Load Check

`pHelmIvP` needs a live MOOSDB before it reaches behavior loading. Start a
minimal mission with `pAntler`, or start `MOOSDB` on the intended port before
running a direct helm process. Running `pHelmIvP` alone may block on connection
and never exercise dynamic loading.
