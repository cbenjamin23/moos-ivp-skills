# Timing And Benchmarking

Treat timing as an operational property of the harness, not as proof that the
mission logic is correct.

## Max-Time Slack

For fast threshold or geometry cases, keep enough `--max_time` slack that
`uMayFinish` is not the accidental bottleneck. Raise the ceiling before
inventing a new completion contract. In normal harnesses, `--max_time` is a
run-time override forwarded to the stem mission's `zlaunch.sh`, not a
harness-side grading rule.

If a case produces no `grade=`, distinguish between:

- the mission never reached the lead condition
- the mission reached the lead condition and failed
- the harness timed out before the stem could report

## Wall Clock Vs MOOS Time

When reporting runtime, distinguish wall-clock time from MOOS time. For
automation and developer feedback, wall-clock runtime is usually the metric that
matters.

## Benchmark Shape

A small repeatable sweep over `--jobs` values is usually enough:

```text
warp=<N>
jobs=1,2,4
port_base=<fresh base>
cases=<same matrix>
machine=<short note>
```

Keep concise timing summaries in a clearly named location such as
`time_benchmarking/`. Avoid committing bulky raw launcher logs by default.

## Sleep And Cleanup Tuning

When trimming launch-path sleeps or cleanup waits, validate the active stem and
harness directly. Do not assume a reduction is safe repo-wide or in upstream
launchers.
