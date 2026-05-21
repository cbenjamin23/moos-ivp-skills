# CI/CD Skill Migration

## Current Issue

The local `moos-cicd-mission` skill mixes several related but distinct jobs:

- ordinary mission structure
- self-evaluating CI missions
- harnesses and multi-case execution
- `nspatch` sweeps
- representative GIF generation
- timing and benchmark notes

The public version should split these so agents can load only the guidance
needed for the task.

## Proposed Public Skills

### `moos-ivp-mission-builder`

Base skill for mission creation. It should provide canonical examples of:

- `launch.sh`
- `launch_vehicle.sh`
- `launch_shoreside.sh`
- `clean.sh`
- `meta_shoreside.moos`
- `meta_vehicle.moos`
- `meta_vehicle.bhv`

Do not require `missions-auto` to be present. References may explain that
`missions-auto` is an upstream source of patterns, but the public skill should
include enough small examples to work alone against a local `moos-ivp` install.

### `moos-ivp-eval-mission-builder`

Skill for one self-evaluating test mission. It should include references for:

- `pAutoPoke` startup
- `pMissionEval` pass/fail checks
- `results.txt`
- `uMayFinish`
- thin `zlaunch.sh`
- validation checklist

It can reference `moos-ivp-mission-builder` for base wrapper structure.

### `moos-ivp-harness-builder`

Skill for a harness over one or more stem missions. It should include canonical
reference examples for:

- case matrix README format
- serial case loop
- wave-mode `--jobs`
- per-case temp mission copies
- per-case MOOSDB/pShare port blocks
- scoped teardown
- preserved workdirs for debugging

The reference examples can be derived from the MOOS-IvP CI repo, but should be
copied into this repo in minimized, portable form.

### `nspatch` reference material

Keep patching guidance as reference material shared by
`moos-ivp-eval-mission-builder` and `moos-ivp-harness-builder`. Revisit a
standalone skill only if patching becomes common outside harness work.

## Reference Strategy

The public skills should not point at a maintainer's absolute local path.
Instead:

1. Extract small reference exemplars from the CI repo.
2. Strip private paths and repo-specific assumptions.
3. Keep examples compact enough to load on demand.
4. Include source/attribution notes if required by the source repo license.
5. Prefer comments that explain why a pattern exists over wholesale copied
   mission folders.

## Open Decisions

- Whether `nspatch` should become a standalone skill later.
- Whether representative GIF generation belongs in a separate documentation
  media skill or remains outside this repository.
- Whether public examples should mirror `missions-auto` naming or use neutral
  names such as `single_vehicle_baseline`, `ci_eval_minimal`, and
  `harness_wave_minimal`.
