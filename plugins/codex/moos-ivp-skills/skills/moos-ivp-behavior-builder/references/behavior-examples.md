# Representative Behavior Examples

Use these examples from the resolved `MOOS_IVP_ROOT` as reference only.

## Generator

- `scripts/GenBehavior`: creates the basic dynamic behavior source pair and `createBehavior` export.

## Simple Objective Behaviors

- `ivp/src/lib_behaviors-marine/BHV_ConstantSpeed`
  - Good for `setParam`, `subDomain("speed")`, `ZAIC_PEAK`, info-buffer read, warning patterns.
- `ivp/src/lib_behaviors-marine/BHV_HeadingBias`
  - Useful heading/course reference.

## State-Rich Behaviors

- `ivp/src/lib_behaviors-marine/BHV_Waypoint`
  - Good for many config params, `addInfoVars`, visual hints, stateful navigation logic.
- `ivp/src/lib_behaviors-marine/BHV_Timer`
  - Good for behavior-level timing and posting.

## Contact Behaviors

- `ivp/src/lib_behaviors/IvPContactBehavior`
  - Base class for contact-aware behaviors.
- `ivp/src/lib_behaviors-marine/BHV_Trail`
  - Contact behavior example.

## Build/Loading Source

- `ivp/src/lib_helmivp/BFactoryDynamic.cpp`
  - Shows dynamic loader naming rules.
- `ivp/src/lib_helmivp/BehaviorSet.cpp`
  - Shows `IVP_BEHAVIOR_DIRS` loading.
- `ivp/src/pHelmIvP/HelmIvP.cpp`
  - Shows `ivp_behavior_dir` config handling.
