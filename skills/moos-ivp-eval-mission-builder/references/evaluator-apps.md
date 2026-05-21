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
  flag = BHV_WARNING_SEEN=false
  flag = BHV_ERROR_SEEN=false
  flag = MISSION_TIMEOUT=false

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

Use one clear verdict-time lead condition and a small set of pass conditions.
The lead should mean "the stimulus has run long enough to judge the outcome,"
not merely "the mission started." For moving missions, prefer a timeout-backed
lead so non-completion becomes a mission-owned `grade=fail` instead of a missing
result.

```text
ProcessConfig = pMissionEval
{
  AppTick   = 4
  CommsTick = 4

  mailflag = @BHV_WARNING#BHV_WARNING_SEEN=true
  mailflag = @BHV_ERROR#BHV_ERROR_SEEN=true

  lead_condition = (WPT_DONE = true) or (MISSION_TIMEOUT = true)
  pass_condition = WPT_DONE = true
  pass_condition = WPT_HIT = true
  pass_condition = CYCLE_HIT = true
  pass_condition = WAYPOINT_END = true
  pass_condition = BHV_ERROR_SEEN = false
  pass_condition = MISSION_TIMEOUT = false

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
  report_column = bhv_warning=$[BHV_WARNING_SEEN]
  report_column = bhv_error=$[BHV_ERROR_SEEN]
  report_column = timeout=$[MISSION_TIMEOUT]
  report_column = mhash=$[MHASH_SHORT]
}
```

`zlaunch.sh` should still treat a missing `grade=` as an infrastructure failure,
but the better mission design is to report `grade=fail` for expected
non-completion paths such as timeout, no arrival, or no app response.

For behavior-specific evals, consider grading unexpected `BHV_WARNING` as a
failure with `pass_condition = BHV_WARNING_SEEN = false`. Do not add that pass
condition blindly to ordinary moving examples: some otherwise healthy missions
may post warnings from inactive or auxiliary behaviors. Report the warning field
first, then decide whether it belongs in the verdict for that scenario.

Keep the mission timeout comfortably below wrapper `--max_time`, normally by at
least 5-10 wall-clock seconds after time warp effects and process startup. A
mission timeout at 110 seconds with `--max_time=120` is acceptable for a compact
example, but generated missions should parameterize or document the margin when
copying the pattern.

Use `prereport_column` for stable prefix fields that should appear before the
verdict, such as `form=` and `mmod=` in app-level evals. Use `report_column` for
the verdict and measured facts that are part of the result evidence.

If the report contains `mhash=$[MHASH_SHORT]`, make sure `pMissionHash` is
launched in the generated mode being tested. Do not validate only the template;
inspect the actual `targ_shoreside.moos` for `--gui` and `--nogui` variants.

## Bridging Graded Variables

If `pMissionEval` runs shoreside and the graded value is posted on the vehicle,
bridge it explicitly.

Vehicle broker:

```text
bridge = src=WPT_DONE
bridge = src=WPT_HIT
bridge = src=CYCLE_HIT
bridge = src=WAYPOINT_END
bridge = src=BHV_WARNING
bridge = src=BHV_ERROR
```

Shoreside broker:

```text
qbridge = WPT_DONE, WPT_HIT, CYCLE_HIT, WAYPOINT_END
qbridge = WPT_STAT, WPT_INDEX, CYCLE_INDEX, WPT_DIST_TO_NEXT
qbridge = BHV_WARNING, BHV_ERROR
```

For multi-vehicle missions, `required_nodes` or equivalent readiness conditions
must match the expected live vehicle count, or be parameterized from launch
variables. A copied `required_nodes = 1` is wrong for two-vehicle/contact
missions.

When the app under test publishes a structured payload, prefer adding a helper
app or mission-local normalization that posts a simple boolean or scalar for
`pMissionEval`.
