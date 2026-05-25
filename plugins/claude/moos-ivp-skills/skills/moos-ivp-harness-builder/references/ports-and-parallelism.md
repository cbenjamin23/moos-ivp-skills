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
`30000`, only as an explicit override when CI or local parallel work may collide
with ordinary missions in the `9000` range.

## Wave Execution

Wave execution is a batch barrier model:

1. Start up to `--jobs=N` cases.
2. Wait for every case in the wave.
3. Teardown the wave's mission copies.
4. Start the next wave.

Do not reuse slot ports by default. Unique case blocks give clearer diagnostics
and reduce risk from lingering MOOSDB or pShare clients.

Do not run two harness batches at the same time if their MOOSDB or pShare port
blocks can overlap. This includes serial and wave runs that both rely on the
same default `PORT_BASE`.

## Stem Contract

The stem mission launch path must accept and propagate forwarded ports. A
harness is not isolated if `launch.sh` accepts `--port_base` but generated
targets silently keep default ports.

Minimum forwarded arguments for a one-vehicle stem:

```text
--shore_mport=<port>
--veh_mport=<port>
--shore_pshare=<port>
--veh_pshare=<port>
--mmod=<stem-variation-label>
```

Check `targ_shoreside.moos` and `targ_<vehicle>.moos` inside preserved workdirs
before trusting a wave run.

## `--case` Trap

Some harnesses run `--case=<name>` through the shared stem directory for quick
debugging, while grouped runs use temp copies and isolated port blocks. Do not
use a single `--case` run as proof that wave port isolation works. Validate a
small grouped run with `--keep_workdirs` when isolation matters.

If a harness drives `uMayFinish` directly instead of using the stem's
`zlaunch.sh`, give each live case a unique `uMayFinish` alias. Reusing the
default client name across fast sequential cases can create misleading client
conflicts.
