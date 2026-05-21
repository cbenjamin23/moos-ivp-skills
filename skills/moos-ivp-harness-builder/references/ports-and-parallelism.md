# Ports And Parallelism

Parallel harness runs need independent mission copies and independent ports.

## Recommended Port Block

For one- or two-vehicle behavior harnesses:

```bash
PORT_STRIDE=30
case_base=$((PORT_BASE + case_idx * PORT_STRIDE))

shore_mport=$((case_base + 0))
veh_mport=$((case_base + 1))
shore_pshare=$((case_base + 10))
veh_pshare=$((case_base + 11))
```

Use a larger stride for more vehicles or apps with extra listening ports.

## Why Blocks Matter

If `PORT_BASE=30000` and `PORT_STRIDE=30`, case index 0 uses:

```text
shoreside MOOSDB: 30000
vehicle MOOSDB:   30001
shoreside pShare: 30010
vehicle pShare:   30011
```

Case index 1 uses:

```text
shoreside MOOSDB: 30030
vehicle MOOSDB:   30031
shoreside pShare: 30040
vehicle pShare:   30041
```

That spacing keeps simultaneously running cases from sharing listeners.

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
--mmod=<case-token>
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
