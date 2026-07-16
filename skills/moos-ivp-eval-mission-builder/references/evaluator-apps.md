# Evaluator Apps

## Startup Initialization

For moving missions, prefer `pAutoPoke` to initialize the run. It is the right
place to seed deploy flags and false/default values for evaluation variables.

```text
ProcessConfig = pAutoPoke
{
  AppTick   = 2
  CommsTick = 2

  flag = DEPLOY_ALL=true
  flag = MOOS_MANUAL_OVERRIDE_ALL=false
  flag = WPT_DONE=false
  flag = WPT_HIT=false
  flag = CYCLE_HIT=false
  flag = WAYPOINT_END=false
  flag = BHV_ERROR_SEEN=false

  required_nodes = 1
}
```

Do not use `pAutoPoke` as the grader. It should prepare the mission for the
grader.

For unit-style eval missions with no vehicle or deploy lifecycle, `uTimerScript`
or the app under test may own readiness instead. The important rule is that
every graded variable has an explicit initial value or a clear producer before
`pMissionEval` can read it.

## `pMissionEval`

Use clear verdict-time lead conditions and a small set of pass conditions.
Prefer event-driven leads: evaluate when the mission-owned completion event
occurs. Use `uMayFinish` through `xlaunch.sh --max_time` as the outer
infrastructure ceiling.

Multiple `lead_condition` lines in the same aspect are valid, but they are
ANDed: all must be true before pass/fail conditions are evaluated. If a
`lead_condition` appears after pass/fail conditions, it starts the next ordered
aspect. A single condition may use textual `or`, but each operand must be
parenthesized:

```text
lead_condition = (EVENT_A = true) or (EVENT_B = true)
```

Do not use `||`; it is not a supported `LogicCondition` operator. For more
complex mission-owned state, a helper boolean may still be clearer than a
deeply nested expression.

```text
ProcessConfig = pMissionEval
{
  AppTick   = 4
  CommsTick = 4

  mailflag = @BHV_ERROR#BHV_ERROR_SEEN=true

  lead_condition = WPT_DONE = true
  pass_condition = WPT_HIT = true
  pass_condition = CYCLE_HIT = true
  pass_condition = WAYPOINT_END = true
  pass_condition = BHV_ERROR_SEEN = false

  result_flag = MISSION_EVALUATED = true
  pass_flag   = SAY_MOOS = pass
  fail_flag   = SAY_MOOS = fail

  mission_form = waypoint_eval
  mission_mod  = $(MMOD:=single_point_arrival)

  report_file   = results.txt
  report_column = grade=$[GRADE]
  report_column = form=$[MISSION_FORM]
  report_column = mmod=$[MMOD]
  report_column = eval=$[WPT_DONE]
  report_column = wpt_done=$[WPT_DONE]
  report_column = bhv_error=$[BHV_ERROR_SEEN]
  report_column = mhash=$[MHASH_SHORT]
}
```

`zlaunch.sh` should still treat a missing `grade=` as an infrastructure failure.
For the shared `xlaunch.sh`, `--max_time=<secs>` is passed to `uMayFinish`; it
is an outer ceiling, not a `pMissionEval` config value.

Use a time-driven evaluation window only when "did not complete by time T" is a
normal mission outcome that should produce mission-owned `grade=fail`:

```text
ProcessConfig = uTimerScript
{
  AppTick   = 2
  CommsTick = 2

  condition = DEPLOY_ALL = true
  event     = var=EVAL_WINDOW_DONE, val=true, time=110
}

ProcessConfig = pMissionEval
{
  lead_condition = EVAL_WINDOW_DONE = true
  pass_condition = WPT_DONE = true
  pass_condition = BHV_ERROR_SEEN = false
}
```

Keep the mission evaluation window comfortably below wrapper `--max_time`,
normally by at least 5-10 wall-clock seconds after time warp effects and process
startup. An evaluation window at 110 seconds with `--max_time=120` is acceptable
for a compact example, but generated missions should parameterize or document
the margin when copying the pattern.

Use ordered multi-aspect evaluation when a scenario has distinct phases that
should each be checked at its own event:

```text
lead_condition = SURVEY_STARTED = true
pass_condition = SENSOR_READY = true

lead_condition = SURVEY_DONE = true
pass_condition = COVERAGE_OK = true

lead_condition = RETURN_DONE = true
pass_condition = BHV_ERROR_SEEN = false
```

The later `lead_condition` lines start new ordered aspects because they appear
after pass/fail conditions. Multiple lead conditions before the first pass/fail
condition are readiness gates for the same aspect and are ANDed.

For behavior-specific evals, inspect `BHV_WARNING` during development, but do
not add a sticky warning flag or pass condition by default. Some otherwise
healthy missions may post transient or retracted warnings from inactive,
auxiliary, or still-initializing behaviors. Add a warning metric only when the
scenario is explicitly warning-intolerant and the warning signal has been
verified as stable evidence.

Use `prereport_column` for stable prefix fields that should appear before the
verdict, such as `form=` and `mmod=` in app-level evals. Use `report_column` for
the verdict and measured facts that are part of the result evidence.

If the report contains `mhash=$[MHASH_SHORT]`, make sure `pMissionHash` is
launched in the headless generated target being tested. Do not run
`pMissionHash` and `pMarineViewer` together by default: `pMissionHash` is the
headless mission-hash producer, while GUI runs normally let `pMarineViewer`
publish the mission hash. Guard `pMissionHash` behind the headless mode, or
explicitly disable the overlapping pMarineViewer hash feature if a scenario
truly needs both apps. Validate the actual `targ_shoreside.moos` for both
`--gui` and `--nogui`; do not validate only the template.

## Bridging Graded Variables

If `pMissionEval` runs shoreside and the graded value is posted on the vehicle,
bridge it explicitly.

Vehicle broker:

```text
bridge = src=WPT_DONE
bridge = src=WPT_HIT
bridge = src=CYCLE_HIT
bridge = src=WAYPOINT_END
bridge = src=BHV_ERROR
```

Shoreside broker:

```text
qbridge = WPT_DONE, WPT_HIT, CYCLE_HIT, WAYPOINT_END
qbridge = WPT_STAT, WPT_INDEX, CYCLE_INDEX, WPT_DIST_TO_NEXT
qbridge = BHV_ERROR
```

For multi-vehicle missions, `required_nodes` or equivalent readiness conditions
must match the expected live vehicle count, or be parameterized from launch
variables. A copied `required_nodes = 1` is wrong for two-vehicle/contact
missions.

When the app under test publishes a structured payload, prefer adding a helper
app or mission-local normalization that posts a simple boolean or scalar for
`pMissionEval`.
