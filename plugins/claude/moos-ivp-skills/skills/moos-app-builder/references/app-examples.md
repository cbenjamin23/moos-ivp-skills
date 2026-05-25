# Representative MOOS App Examples

Use these examples from the resolved `MOOS_IVP_ROOT` as reference only.

## Generator

- `scripts/GenMOOSApp_AppCasting`: default scaffold for new AppCasting apps.
- `ivp/src/app_gen_moos_app`: do not rely on this as the generator; its current `generate()` implementation is stub-like.

## AppCasting Examples

- `ivp/src/uFldGenericSensor`
  - Good for config parsing, mail handlers, AppCasting, geometry/contact libraries, periodic summaries.
- `ivp/src/uTimerScript`
  - Rich config parsing and timed events.
- `ivp/src/pMissionEval`
  - Good for compact AppCasting reports and mission-evaluation style outputs.

## Things To Copy Carefully

- Inspect these apps as references. Copy one as the starting point only when the user explicitly asks or when it is obviously the nearest local-project base.
- Metadata header boxes should match the user's project, not upstream names.
- App-local CMake libraries should reflect actual includes/classes used.
- Do not copy mission-specific variable names unless the new app really participates in the same protocol.
