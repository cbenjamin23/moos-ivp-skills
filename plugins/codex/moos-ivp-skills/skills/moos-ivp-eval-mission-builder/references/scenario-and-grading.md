# Scenario And Grading

Start by deciding what the mission is actually proving. Keep the grade at the
same level as the tested behavior.

## Evaluation Levels

Use app-level grading when the tested app can be exercised directly with
controlled inputs. The grade should be about the app-under-test, not incidental
mission events.

Use moving/integration grading when correctness depends on downstream mission
behavior: arrival, encounter outcome, collision state, obstacle interaction, or
helm behavior completion.

Do not grade an app-level test on arrival just because a waypoint exists in the
mission. Arrival is only a valid grade when arrival is part of the claim being
tested.

## Obstacle And Contact Patterns

Use the simplest model that fits the correctness claim.

- Static launch-time obstacle: `given_obstacle` in `pObstacleMgr`. Use this for
  one fixed polygon and minimal machinery.
- Shoreside-published obstacle field: `uFldObstacleSim` plus an obstacle-field
  file. Use this for field-style publication, resets, refreshes, or parity with
  upstream obstacle-avoidance missions.
- Contact/encounter tests: grade stable mission-level outcomes such as
  encounter completion, separation threshold, degraded outcome, or collision
  state rather than relying on fragile visual timing.

If grading depends on `uFldCollObDetect`, remember it evaluates shoreside
`KNOWN_OBSTACLE`, not a vehicle-private `given_obstacle`.

## Structured Payloads

Prefer mission-level grading whenever possible, but keep the value simple at
evaluation time. If an app posts a structured string and the mission should own
the verdict, normalize it into a helper boolean or scalar before `pMissionEval`
checks it.

Harness-side payload matching is acceptable only when the exact string form is
the point of the test. Keep it as a narrow supplement to the mission grade, not
a replacement for `pMissionEval`.

## Current App Semantics

Prefer current apps over deprecated ones. If app config tokens or semantics are
uncertain, inspect the local MOOS-IvP source or use `moos-ivp-docs` before
copying a stale exemplar.
