# Generated Harness Self-Tests

Run these checks before treating a new or heavily changed harness as
trustworthy. They are intentionally more adversarial than the static checker.

## Matrix Reconciliation

Compare:

- README case tokens
- `CASES` or `ALL_CASES`
- `get_case_config`

Fail on missing, extra, duplicate, or undocumented expected-negative cases. Do
not let an expected-negative case exist only as a script token.

Also probe an unknown case:

```bash
./zlaunch.sh --case=does_not_exist --port_base=<unused-base>
```

It should emit one clear failure row or diagnostic and exit nonzero. Under
`set -u`, avoid referencing unset arrays or patch variables after a failed case
lookup.

## Patch Contract

Each case should declare explicit patch targets or an explicit `no_patch`
marker. Avoid deriving patch filenames only from the case name; a missing patch
can silently become a stock-mission run.

For patch cases, assert every declared patch file exists before launching the
case. For no-patch cases, assert no stale `.moosx` or `.bhvx` sidecar survives
from an earlier case.

## Serial/Wave Parity

Run the same small selected case set two ways:

```bash
./zlaunch.sh --jobs=1 --port_base=<base-a> --keep_workdirs
./zlaunch.sh --jobs=2 --port_base=<base-b> --keep_workdirs
```

Compare normalized result fields, generated target ports, sidecar presence, and
case count. Serial and wave paths may use different mechanics, but they should
not change the intended case result.

Preserved workdirs should live under one harness-owned run root, such as
`<harness>/workdirs/<run-id>/...`. Avoid `mktemp` defaults that scatter case
directories under `/tmp` or platform-specific temp roots; that makes cleanup,
port audits, and artifact review harder.

## Port Collision And Bounds

For every preserved live case, collect all `ServerPort`, pShare listener, and
pShare route ports from generated targets. Assert:

- no two live cases share a listener
- no generated target fell back to default ports
- the stride is large enough for all communities in the case
- the highest computed port stays below 65535

Multi-community harnesses need an explicit port map for every community, not
only `shore_mport` and one `veh_mport`.

## Failure Aggregation

Inject or select multiple failing cases and one setup-error case when practical.
The harness should exit nonzero but still emit one normalized result line for
every selected case. Do not stop serial execution after the first failing case
unless the user explicitly asked for fail-fast behavior.

Also test the empty-output path: if a nonempty selected case list produces zero
case rows, the harness must exit nonzero with a clear diagnostic. Do not let a
case-loop bug return success with an empty `results.txt`.

In bash, avoid declaring and referencing local variables in the same statement,
such as `local name="$1" out="$RUN_ROOT/$name.out"`. Expand dependent paths on
later lines after the source variable is assigned. This catches a common
generated-harness failure where no per-case result files are written.

Keep generated harness scripts portable to the system Bash commonly shipped on
macOS. Avoid `mapfile`, `readarray`, associative arrays, and other Bash 4+
features unless the project explicitly controls the shell runtime.

Recommended ordinary case fields:

```text
case=<token> grade=<pass|fail> eval=<true|false> <mission evidence fields...>
```

Recommended runner-failure fields:

```text
case=<token> grade=fail reason=<launch_error|missing_result|prepare_error|missing_result_file>
```

`grade=pass` means the case passed. An expected-negative case should still
produce `grade=pass` when the expected negative evidence is observed. Preserve
legacy `case_result` rows only for compatibility checks or harnesses whose
subject is failure machinery itself.

## Sidecar Leak Check

Run patch case A followed by no-patch or different-patch case B. Assert:

- B's preserved workdir contains only intended sidecars
- the stem mission directory is clean after exit
- generated targets reflect B's patches, not A's

## Teardown Containment

Generated harness repositories should carry the copied helper at
`scripts/moos_scoped_teardown.sh`, source it from harness launchers, and call
`moos_scoped_teardown_stop_root` on each case directory or run root. If the project
already has an equivalent helper, verify that it has the same root-scoped
property.

When the environment allows it, start an unrelated MOOS mission outside the
harness run root, run the harness, then assert only processes under the
harness-owned root were signaled. This catches cleanup that is too broad.

Avoid naive cleanup such as `lsof +D "$RUN_ROOT" -t | xargs kill`. It may match
the invoking shell or audit commands whose current directory is inside the run
root. Prefer recorded MOOS app PIDs, a root-scoped repository teardown helper,
or filtering to known MOOS process names before signaling.

## Concurrent Invocation Check

Do not assume only one copy of a harness will run in a working directory. If a
harness writes top-level `results.txt` while another invocation is active, the
two runs can race. Either document that concurrent invocations of the same
harness directory are unsupported, or write aggregate output under the
harness-owned run root and copy it to the top-level result only after the run is
complete.

## Copyable Port Audit

After a grouped run with `--keep_workdirs`, scan the preserved target files:

```bash
run_root=<preserved-run-root>
find "$run_root" -name 'targ_*.moos' -print0 |
  xargs -0 awk '
    /ServerPort[[:space:]]*=/ {
      gsub(/[[:space:]]/, "", $0)
      print FILENAME ":listener:" $0
    }
    /(input|output)[[:space:]]*=.*route/ {
      gsub(/[[:space:]]/, "", $0)
      print FILENAME ":pshare:" $0
    }'
```

Then verify no listener port is duplicated and the largest computed offset
satisfies:

```text
PORT_BASE + (case_count - 1) * PORT_STRIDE + max_offset < 65535
```

For the midpoint block scheme, `max_offset` is normally
`PSHARE_OFFSET + vehicle_count`. With `PORT_STRIDE=30` and
`PSHARE_OFFSET=15`, this supports up to 14 vehicles per case before MOOSDB and
pShare offsets overlap. Increase `PORT_STRIDE` before exceeding that limit.
