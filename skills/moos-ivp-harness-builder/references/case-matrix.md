# Case Matrix

Every harness README should include `Cases` or `Current Matrix`.

Use exact case tokens and one concise sentence of intent:

```markdown
## Cases

- `baseline_center_pass` Vehicle reaches the nominal waypoint and should pass.
- `late_deploy_fail` Deployment is delayed beyond the eval window; the case
  passes when the mission observes no waypoint completion.
- `offset_obstacle_pass` Obstacle geometry changes but the vehicle should still avoid and pass.
```

Good case docs explain:

- what changes from the stem baseline
- what behavior or app path is exercised
- what evidence the stem mission should report for the case to pass

Avoid:

- bare lists of tokens
- case names that encode all meaning without prose
- documenting telemetry fields as though they were cases
- hiding expected-negative cases from the matrix

The matrix is source documentation and should be accurate enough for generated
catalogs or automation status pages to consume later.

## Drift Check

Keep three surfaces reconciled:

- README case tokens
- the script's `CASES` or `ALL_CASES` list
- the script's `get_case_config` mapping

After editing cases, compare all three before running the suite. A case listed
in the README but missing from `get_case_config` is documentation drift. A case
in `ALL_CASES` but absent from the README is an undocumented case.

Intentional setup-error or expected-negative cases must be documented just like
nominal cases.

Document case intent and evidence, not a wrapper's expected-vs-actual verdict.
For ordinary harnesses, a case that behaves as intended should produce
`grade=pass`, even when the intended evidence is a negative condition such as
`expected=no_waypoint_completion` or `observed=no_alert_request`.

Keep `_fail` suffixes only when they are already useful as migration-era case
names or when they describe the scenario under test. Do not let the suffix mean
the harness should expect `grade=fail`.
