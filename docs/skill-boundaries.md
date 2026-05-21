# MOOS-IvP Skill Boundaries

## Principle

Each skill should own one primary verb. Cross-references are fine, but a skill
should not require a private local repository to understand its own workflow.

## Proposed Split

### `moos-ivp-mission-builder`

Owns ordinary mission creation and repair:

- mission layout
- launcher conventions
- `.moos` and `.bhv` structure
- vehicle/shoreside split
- mission README expectations
- canonical mission examples copied into this repository as references

### `moos-ivp-eval-mission-builder`

Owns self-evaluating single missions:

- `pAutoPoke`
- `pMissionEval`
- `uMayFinish`
- `results.txt`
- `zlaunch.sh` / `xlaunch.sh` flow
- headless validation

It may reference `moos-ivp-mission-builder` for base mission layout.

### `moos-ivp-harness-builder`

Owns multi-case harnesses and regression suites:

- case matrix documentation
- expected vs actual result aggregation
- per-case mission copies
- per-case ports
- `--jobs`
- `--port_base`
- wave execution
- scoped teardown
- preserved workdirs for debugging

Canonical harness examples should be included under this repo's references,
derived from the existing MOOS-IvP CI repository where licensing permits.

### `nspatch` reference material

Owns patch-driven variants:

- line patches
- full-block patches
- repeated-key hazards
- sidecar `.moosx` / `.bhvx` workflows
- generated target inspection

This should remain reference material inside the harness and eval mission
skills unless it proves useful as an independent skill.

## Canonical References

The public skills should not require the user's machine to contain
`moos-ivp-cicd-testing` or any other private example repo. Instead:

- copy small, representative examples into `references/`
- strip machine-specific paths
- preserve enough context to teach the pattern
- include attribution/license notes when examples are derived from another repo
