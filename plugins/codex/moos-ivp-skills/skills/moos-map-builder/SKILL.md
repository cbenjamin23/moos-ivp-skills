---
name: moos-map-builder
description: "Create and verify MOOS-IvP TIFF background maps with the moos-map application. Use when a user wants to select a map region visually in the local GUI; build directly from two geographic corners through the CLI; choose imagery, zoom, mission origin, or output location; recreate a map from existing bounds; or inspect and verify generated .tif, .info, and .moos files."
---

# MOOS Map Builder

## Principles

Use the public `moos-map` application as the single implementation. Do not
reimplement its map-building or verification logic inside this skill.

Address the user directly. Ask plainly for any needed choice, confirmation, or missing information without referring to this skill or its workflow.

## Route First

If the user already requested the GUI or CLI, use that route without asking
again. Otherwise ask one concise question and wait for the answer:

> Would you like to select the region visually in the GUI, or build it directly through the CLI?

- Choose the GUI for manual map browsing and visual corner selection.
- Choose the CLI for known coordinates, repeatable builds, or agent-driven
  automation.

Make this routing decision before searching the workspace, inspecting existing
map code, or looking for prior map files.

## Check the Application

Before either route, run:

```bash
command -v moos-map
moos-map --version
```

Use only the executable returned by `command -v moos-map`; do not substitute
another mapping application or activate a repository `.venv`. If it is
unavailable, ask before installing it with:

```bash
pipx install moos-map
```

If the installed command lacks an option used below, inspect
`moos-map <command> -h` before suggesting `pipx upgrade moos-map`. Ask before
upgrading.

## GUI Route

Launch:

```bash
moos-map ui
```

Keep the server process alive while the user works and report its URL. Once the
user finishes the build, ask for the TIFF path they chose and verify it with
`moos-map verify /absolute/path/to/MAP_NAME.tif --json`. Do not claim that a map
was created merely because the UI launched.

If the default port is occupied, choose a free one with `--port` and report the
exact resulting URL.

## CLI Route

### Resolve only essential inputs

- **Corners:** require two diagonally opposite WGS84 points as
  `latitude longitude` pairs. Either corner order is accepted.
- **Name:** obtain or derive a short filesystem-safe map name.
- **Origin:** add `--origin LAT_ORIGIN LON_ORIGIN` only when the user explicitly
  requests those origin coordinates. Otherwise let `moos-map` use the map
  center.
- **Optional choices:** retain Esri World Imagery, zoom 17,
  `~/moos-maps`, the `.moos` snippet, cached tiles, and output replacement as
  defaults unless the user requests otherwise.

If the user supplies only a city or place name, do not invent a rectangle or
scale. Offer the visual GUI route, or ask for the two corners or desired area.

When an existing `.info` file defines the requested map, reuse its north, south,
east, and west bounds unless the user asks to change them. Reuse its datum only
when the user explicitly asks to preserve that origin.

### Plan, confirm, and build

Run `plan` with the same corners, origin, source, zoom, and resource-limit
options intended for the build:

```bash
moos-map plan --corners LAT1 LON1 LAT2 LON2
```

Tell the user the estimated TIFF size and dimensions, then ask for confirmation
before building. After confirmation, run:

```bash
moos-map build \
  --corners LAT1 LON1 LAT2 LON2 \
  --name MAP_NAME \
  --json
```

Use `moos-map sources` only when the user wants to compare providers. Add
custom `--origin`, `--source`, `--zoom`, or `--output-dir` only when requested.
Consult `moos-map build -h` for other options rather than inventing arguments.

Preserve these defaults unless the user says otherwise:

- include the `.moos` snippet;
- replace an existing same-named bundle safely;
- reuse cached source tiles.

The build JSON includes the plan, output paths, and verification report. Treat
the CLI build as complete only when it succeeds and `verification.ok` is true;
a separate `verify` call is unnecessary for that newly built bundle.

## Verify Existing or GUI-Built Maps

For a GUI-built map, an existing map, or a direct verification request, run:

```bash
moos-map verify /absolute/path/to/MAP_NAME.tif --json
```

Treat the map as verified only when `ok` is true.

## Report

Read the CLI build's `plan` and `verification` objects, or the standalone
verification JSON, and report:

- map directory and generated `.tif`, `.info`, and optional `.moos` paths;
- TIFF dimensions and actual file size;
- source, zoom, bounds, and origin when available;
- verification warnings.

If mentioning a display-alignment estimate (you don't have to), identify it as a theoretical
display/model estimate rather than a displacement of mission navigation or
local XY.

Each default build is a bundle:

```text
<output-directory>/<map-name>/
├── <map-name>.tif
├── <map-name>.info
└── <map-name>.moos
```

Do not edit or re-encode the TIFF after verification. If the user asks to
integrate the result into a mission, use the generated `.moos` snippet and
ensure pMarineViewer can find the exact map directory; do not silently modify
mission files when the request was only to create a map.

## Failure Handling

- Report the first actionable `moos-map` error verbatim, then explain the
  corrective input or option.
- Do not silently change invalid coordinates, origin, output directory,
  source, or zoom.
