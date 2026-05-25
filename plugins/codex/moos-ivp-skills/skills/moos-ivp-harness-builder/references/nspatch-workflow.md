# `nspatch` Workflow

Use `nspatch` when many harness cases differ by small `.moos` or `.bhv`
fragments and share one stem mission.

## Sidecar Pattern

The harness writes explicit generated sidecar files such as:

```text
meta_shoreside.moosx
meta_vehicle.moosx
meta_vehicle.bhvx
```

Patch each sidecar from the matching stem template:

```bash
SHORE_STEM="$WORKDIR/meta_shoreside.moos"
SHORE_XFILE="$WORKDIR/meta_shoreside.moosx"
VEHICLE_STEM="$WORKDIR/meta_vehicle.moos"
VEHICLE_XFILE="$WORKDIR/meta_vehicle.moosx"
BHV_STEM="$WORKDIR/meta_vehicle.bhv"
BHV_XFILE="$WORKDIR/meta_vehicle.bhvx"

nspatch --stem="$SHORE_STEM" "$SHORE_PATCH" --targ="$SHORE_XFILE"
nspatch --stem="$VEHICLE_STEM" "$VEH_MOOS_PATCH" --targ="$VEHICLE_XFILE"
nspatch --stem="$BHV_STEM" "$BHV_PATCH" --targ="$BHV_XFILE"
```

Keep patch input extensions distinct from generated sidecar target extensions.
MOOS patch inputs are normally `.xmoos`; behavior patch inputs are normally
`.xbhv`. The generated sidecars consumed by `nsplug -x` are normally
`.moosx` and `.bhvx`.

Do not target a mission directory with one generic patch command. Patch the
specific sidecar target that the stem launcher will consume.

The stem launchers must call:

```bash
nsplug meta_vehicle.moos targ_$VNAME.moos --strict --force -x ...
nsplug meta_vehicle.bhv targ_$VNAME.bhv --strict --force -x ...
```

The `-x` flag lets sidecars participate in target generation.

## Full Block Replacement

For repeated MOOS keys such as `event`, `flag`, `bridge`, `qbridge`, or
`report_column`, prefer a full `ProcessConfig = AppName { ... }` patch over a
line patch. Repeated keys are easy to over-match with simple line edits.

For simple line patches, reason in terms of parameter names and block context.
If multiple patch files touch the same unique parameter or the same full block,
later patches win. That can be useful for layering, but it should be explicit in
the case mapping rather than an accidental consequence of filename order.

## Harness Mapping

Keep patch selection explicit:

```bash
get_case_config() {
  NO_PATCH="no"
  PATCHES=()
  case "$1" in
    baseline_pass)
      NO_PATCH="yes"
      ;;
    blocked_fail)
      PATCHES=("blocked-shoreside.xmoos" "blocked-vehicle.xbhv")
      ;;
    *)
      return 1
      ;;
  esac
}
```

The harness applies patches into the temp mission copy before launch. The stem
mission should not know the full case matrix, but it should own each case's
verdict after patches are applied. For an expected-negative patch, adjust the
stem `pMissionEval` configuration so the expected negative evidence yields
`grade=pass` and reports a useful evidence field such as
`expected=no_waypoint_completion`.

If a case intentionally has no patches, make that explicit in the case mapping.
Do not rely on an inferred missing filename to mean "no patch."
