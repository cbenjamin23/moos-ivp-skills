# ALog Tool Guide

This reference is intentionally short.

Run `alog*` commands directly in the current shell.

Default stance:
- if you already know the variable names, go straight to `aloggrep`
- if you already know a specific variable set, stay targeted and use one or more `aloggrep` queries for that set
- use `aloghelm` for helm and mode context
- use `scripts/alogvars.sh` for compact variable discovery when the variable names are still unknown
- read raw `.alog` lines only when you need exact payload shape, source clarification, or evidence

Ignore viewer-generated artifacts such as `*_alvtmp/` and `*.klog`.
Use only the original `.alog` files as source evidence.

If the question is geometric or numeric, extract the few relevant variables and analyze them directly with shell or Python.

Speed is important so be targeted and necessary in your use of alog tools, if at all

## When To Use `aloggrep`
Use `aloggrep` as soon as you know which variable or small variable set matters.

Good fits:
- follow one variable over time
- inspect a known set of variables with repeated targeted queries or a shared prefix pattern
- inspect a numeric signal such as position, heading, or speed
- inspect a state variable such as `MODE`
- check the first or final appearance of a variable
- pull selected fields out of structured postings
- create a reduced `.alog` only when that is explicitly needed

According to the official docs and local `--help`, `aloggrep` is commonly used in three ways:
- quick-look output to the terminal
- tabular extraction for plotting or analysis
- reduced `.alog` generation

### Quick-Look
Use this when you want to inspect one variable immediately.

General examples:

```bash
aloggrep <alog_path> MODE --tvv
aloggrep <alog_path> NAV_X --tv
aloggrep <alog_path> <var_name> --first --tvv
aloggrep <alog_path> <var_name> --final --tvv
```

Use `--tv` when you mainly care about time and value.
Use `--tvv` when you want the variable name echoed in the output.
Use `--first` when you want the first matching posting, typically to detect onset or initial state.
Use `--final` when you want the last matching posting, typically to detect terminal state or last known value. It may be slower on large logs because it must scan to the end.

If you already know the exact variable names you need, `aloggrep` is usually more token-efficient than inspecting raw log lines because it suppresses unrelated postings.
If you have a small named variable set, it is usually better to issue several narrow `aloggrep` queries than to broaden into raw-log inspection too early.

### Variable Selection
Use this when the variable family matters more than one exact variable name.

General examples:

```bash
aloggrep <alog_path> NAV_* --tvv
aloggrep <alog_path> <var_name> <source_name> --tvv
```

Docs note that `VAR*` matches any variable starting with that prefix.
Docs also note that the optional `SRC` argument retains postings from that source in addition to named variables. Use it when producer identity matters, but do not assume it is a strict `VAR and SRC` intersection filter.
If your question is about several exact variables that do not share a common prefix, prefer separate targeted `aloggrep` calls over broad raw-log reads.

For source attribution, try:

```bash
aloggrep <alog_path> <var_name> --format=time:var:src
```

If the installed `aloggrep` build emits only source values despite advertising
the full format, fall back to a narrow raw `.alog` check for that variable.

### Structured Values
Use this when the posting value is a comma-separated `param=value` payload.

General example:

```bash
aloggrep <alog_path> NODE_REPORT_LOCAL --v --subpat=X:Y:SPD:HDG
```

Useful options from the docs:
- `--subpat=...` isolates selected fields from structured values
- `--kk` keeps the extracted keys along with the values
- `--format=time:var:src` is useful when source attribution matters

### Reduced `.alog` Output
Use this only when a smaller `.alog` is explicitly needed.

General example:

```bash
aloggrep <alog_path> <var_name> <out_alog> -f
```

Docs note:
- if an output `.alog` is provided, `aloggrep` writes a filtered log instead of terminal output
- the second `.alog` argument is treated as the output file
- `-s`, `-d`, and `-sd` can sort and/or remove duplicates when logger ordering issues matter

Do not make reduced logs the default workflow for agent-led analysis.

## When To Use `aloghelm`
Use `aloghelm` when the question is really about helm-driven context rather than one raw variable.

Good fits:
- reconstruct mission phases
- understand why a vehicle switched behavior
- inspect mode changes before or during an incident
- inspect helm lifecycle events when startup or registration behavior matters

General examples:

```bash
aloghelm <alog_path> --modes
aloghelm <alog_path> --bhvs
aloghelm <alog_path> --life
```

Use `--modes` first for mission-level reconstruction.
Use `--bhvs` when mode changes alone are not enough to explain the event.
Use `--life` when you need helm lifecycle events rather than mission phases.

Docs and local `--help` also note that trailing non-option arguments are interpreted as MOOS variables to report as encountered. Use that only when you want those variables interleaved into the helm report.

## When To Use `alogscan`
Use `scripts/alogvars.sh` when you still do not know which variables exist in the log.

This wrapper runs `alogscan --sort=vars --nocolors`, strips the scan progress noise, and supports optional prefix filtering.

General examples:

```bash
SKILL_DIR="/path/to/moos-alog-analysis"
"$SKILL_DIR/scripts/alogvars.sh" <alog_path>
"$SKILL_DIR/scripts/alogvars.sh" <alog_path> NAV_ WPT_
"$SKILL_DIR/scripts/alogvars.sh" <alog_path> --names-only NAV_ MODE
```

Use raw `alogscan` only when you want the full unfiltered inventory with complete counts, times, and sources for every variable.
Avoid `alogscan --loglist` as the default discovery path because it prints the full inventory table and then appends a second variable-name list.
