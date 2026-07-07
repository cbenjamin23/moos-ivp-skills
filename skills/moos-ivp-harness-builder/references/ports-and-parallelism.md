# Ports And Parallelism

Parallel harness runs need independent mission copies and independent ports.

## Recommended Port Block

For ordinary one-or-more-vehicle behavior harnesses:

```bash
PORT_BASE=9000
PORT_STRIDE=30
PSHARE_OFFSET=$((PORT_STRIDE / 2))
case_base=$((PORT_BASE + case_idx * PORT_STRIDE))

shore_mport=$((case_base + 0))
veh_mport_i=$((case_base + 1 + i))

shore_pshare=$((case_base + PSHARE_OFFSET))
veh_pshare_i=$((case_base + PSHARE_OFFSET + 1 + i))
```

With this midpoint layout, the maximum ordinary vehicle count is
`PSHARE_OFFSET - 1`. With `PORT_STRIDE=30`, `PSHARE_OFFSET=15`, so one case can
carry a shoreside plus up to 14 vehicles before MOOSDB and pShare offsets would
overlap. Use a larger stride before exceeding that limit or before adding apps
with extra listening ports.

## Why Blocks Matter

If `PORT_BASE=9000`, `PORT_STRIDE=30`, and `PSHARE_OFFSET=15`, case index 0
uses:

```text
shoreside MOOSDB: 9000
vehicle MOOSDB:   9001
shoreside pShare: 9015
vehicle pShare:   9016
```

Case index 1 uses:

```text
shoreside MOOSDB: 9030
vehicle MOOSDB:   9031
shoreside pShare: 9045
vehicle pShare:   9046
```

That spacing keeps simultaneously running cases from sharing listeners.

Use `9000` as the ordinary generated default. For local collision checks, pick
a fresh unused `9000`-range base such as `9600`. Use a higher base, such as
`30000`, only as an explicit override when automation or local parallel work may
collide with ordinary missions in the `9000` range.

## Rolling Execution

New generated harnesses should use work-conserving rolling execution when they
expose `--jobs`:

1. Start up to `--jobs=N` cases.
2. Wait for the next active case to finish with `wait -p <pidvar> -n`.
3. Record that case's result row and tear down its mission copy.
4. Immediately start the next pending case if one remains.

This requires Bash 5.1+ for `wait -p` and reliable PID-to-case bookkeeping. Add
an explicit version guard near the top of generated `zlaunch.sh`, with a clear
message for macOS users who are still on Apple `/bin/bash` 3.2. Batch-barrier
waves are acceptable as a legacy fallback when a project intentionally targets
Bash 3.2, but they are not the preferred default for new generated harnesses.

Do not reuse slot ports by default. Unique case blocks give clearer diagnostics
and reduce risk from lingering MOOSDB or pShare clients.

Do not run two harness invocations at the same time if their MOOSDB or pShare
port blocks can overlap. This includes serial and rolling runs that both rely on
the same default `PORT_BASE`.

## Stem Contract

The stem mission launch path must accept and propagate forwarded ports. A
harness is not isolated if `launch.sh` accepts `--port_base` but generated
targets silently keep default ports.

Minimum forwarded port arguments for a one-vehicle stem:

```text
--shore_mport=<port>
--veh_mport=<port>
--shore_pshare=<port>
--veh_pshare=<port>
```

Check `targ_shoreside.moos` and `targ_<vehicle>.moos` inside preserved workdirs
before trusting a rolling run.

## `--case` Trap

Some legacy harnesses run `--case=<name>` through the shared stem directory for
quick debugging, while parallel runs use temp copies and isolated port blocks.
Do not use a single `--case` run as proof that rolling port isolation works.
Validate a small `--jobs=2` run with `--keep_workdirs` when isolation matters.

If a harness drives `uMayFinish` directly instead of using the stem's
`zlaunch.sh`, give each live case a unique `uMayFinish` alias. Reusing the
default client name across fast sequential cases can create misleading client
conflicts.
