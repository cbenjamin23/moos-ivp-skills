---
layout: default
article: true
permalink: /benchmark_2026/
title: "Benchmarking MOOS-IvP Skills"
hero_variant: benchmark
description: "Coding agents with and without the MOOS-IvP Skills plugin."
social_title: "Benchmarking MOOS-IvP Skills"
social_image: "/assets/images/benchmark-2026/social.png"
social_image_alt: "440 runs: completion rises from 60.5% to 77.3%, and mean conformance from 56.2% to 85.7%, with skills."
companion_url: /moos_dawg_2026/
companion_label: Read the MOOS-DAWG introduction
article_nav:
  - { id: from-workflows-to-evidence, title: Study setup }
  - { id: what-the-benchmark-asked, title: Tasks and conditions }
  - { id: completion-and-conformance-together, title: Results by model }
  - { id: when-completion-hides-the-difference, title: How completed results differ }
  - { id: where-the-difference-appears, title: Results by task }
  - { id: what-the-agents-actually-did, title: Skill use and validation }
  - { id: time-and-cost-of-the-work, title: Time and cost }
  - { id: what-to-improve-next, title: Failures and next steps }
  - { id: a-result-that-survives-the-sensitivity-checks, title: Grading revisions and uncertainty }
  - { id: what-this-means-for-the-plugin, title: Implications for the plugin }
  - { id: evidence-and-reproduction, title: Data and sources }
---

## Study setup
{: #from-workflows-to-evidence }

The MOOS-IvP Skills were benchmarked across 440 runs: 4 models × 11 tasks ×
(5 baseline runs + 5 skills runs).

<dl class="benchmark-definitions">
<div><dt>Task</dt><dd>A MOOS-IvP-related task like building an app, behavior, mission, test harness, or analyzing mission logs.</dd></div>
<div><dt>Run</dt><dd>One agent attempt on one task. It runs in a fresh sandboxed workspace, isolated from other attempts, and ends with the agent's final response and output files if applicable.</dd></div>
<div><dt>Model</dt><dd>The language model making the attempt. The study uses GPT-5.6 Luna, GPT-5.6 Terra, GPT-5.6 Sol, and GPT-6 Astra, all at high reasoning effort.</dd></div>
<div><dt>Baseline / skills</dt><dd>The two conditions. Baseline means the plugin is unavailable. Skills means the plugin is available. For each task and model, both conditions are run five times.</dd></div>
</dl>

Repeating each task five times in each condition shows how consistently a
model succeeds on the same request. Reviewers judge the delivered work and its
retained evidence after each run ends.

### How results were judged
{: #two-measures-of-a-useful-result }

Reviewers checked whether the result was functionally complete and how well it
followed MOOS-IvP engineering practices.

A result counts as complete only if it satisfies every functional requirement
in the request. If something required is missing, only partly works, or cannot
be verified, the attempt counts as incomplete. For the log tasks, the requested
result is an explanation or list of events supported by the logs. Completion
rate is the percentage of attempts that satisfy the whole request.

Conformance refers to the type of criteria that, if omitted, would make an
experienced MOOS-IvP developer pause and say "something isn't right here". A
result can therefore be complete while losing conformance points: it does what
the request asks but misses an important MOOS-IvP convention. Reviewers assess
criteria such as whether
an app puts recurring logic in `Iterate()`, a mission launcher exposes
configurable port settings, or a self-evaluating mission uses the existing
`pMissionEval` utility instead of unnecessarily creating a brand new utility.
Both conditions were judged against the same criteria.

For example, a two-vehicle mission may patrol and shadow correctly but still
lose conformance points if its launchers hard-code the MOOSDB or pShare ports.
Another implementation may follow the expected MOOS structure but mishandle
alert acknowledgment, making it incomplete. Completion and conformance capture
these different shortcomings, and we keep their scores separate.

For each run, reviewers use the conformance criteria defined for that task. The
score is the share of applicable criteria fully met. A partly met criterion
means the mechanism exists but is incomplete or inconsistent. Partial and unmet
criteria receive no credit. Eight fully met criteria, one partly met, and one
not met produce an 80% score.

Conformance is averaged across all runs, including incomplete ones. Each run
and each criterion counts equally. The percentage measures adherence to the
tested practices. Later examples show what was missed. The
[source guide]({{ '/benchmark_2026/sources/' | relative_url }}) gives the full
rules and a half-credit alternative.

## Tasks and conditions
{: #what-the-benchmark-asked }

### Prompts and workspaces

Every model receives the same written request for a given task. The request
describes the desired result but does not include the grading criteria.

For Tasks 1–9, each run begins with the same clean repository based on the
standard `moos-ivp-extend` template, with its usual `bin`, `lib`, `missions`,
`scripts`, and `src` layout and the files needed to build it. It contains no
task examples or grading material.
For Tasks 10–11, the inputs are three original mission logs.

Every attempt gets a fresh sandboxed workspace, isolated from other attempts.
Both conditions have the standard MOOS-IvP toolchain and common development
tools such as CMake, Python, Bash, Git, and a C++ compiler. They also have
public internet access, which approximates the environment of a real user
working in the project. Apart from plugin availability, the two conditions
share this environment.

Each attempt has a 180-minute ceiling and no token ceiling. Tasks 6–9 include
components similar to earlier tasks, but each starts from the starter repository.

Skills runs receive the plugin. Baseline runs can still inspect the project
and available MOOS-IvP resources.

### Eleven tasks, five kinds of work

The benchmark covers several of the plugin's central workflows and their
handoffs: applications, IvP behaviors, ordinary missions, evaluation and
harnesses, and log analysis. It does not separately benchmark every installed
skill. Map building, installation, and repository setup are not independent
tasks here. Skills runs had access to the full plugin rather than a single
selected skill.

| Task | Verbatim task prompt |
|---|---|
| Task 01: BatteryWatch app | Build a MOOS application named `pBatteryWatch` that monitors `BATTERY_PERCENT` and publishes an `OK`, `LOW`, or `CRITICAL` battery state. Make its thresholds configurable, prevent state flickering near threshold boundaries, and handle invalid readings safely. While the battery is `LOW` or `CRITICAL`, publish periodic alerts until acknowledged through `BATTERY_ACK`; begin alerting again if the condition worsens. |
| Task 02: Contact-waypoint app | Build a MOOS application named `pContactWaypoint` that uses a configured contact’s reported position to update the vehicle’s active waypoint so it travels toward that contact. Make the contact identity and waypoint output configurable, update the destination as the contact moves, and handle missing or invalid contact data without publishing an invalid waypoint. Provide clear operator-facing status for the selected contact and current waypoint. |
| Task 03: Contact-intercept behavior | Build an IvP contact behavior named `BHV_ContactIntercept` that guides the vehicle toward a predicted intercept point ahead of a configured contact. Make the lead distance and activation state configurable, and handle missing or unusable contact data without producing an objective. |
| Task 04: Heading-sector behavior | Build an IvP helm behavior named `BHV_HeadingExclusion` that applies a soft penalty to a configurable heading sector while an activation MOOS variable is true. Make the excluded sector, penalty strength, and activation state configurable, and keep the behavior inactive when no sector is configured. |
| Task 05: Patrol and shadow mission | Build a standalone two-vehicle MOOS-IvP mission for `alpha` and `bravo`. Alpha should patrol a roughly rectangular route for three cycles by default, pausing at the northeast corner. Bravo should begin at its starting position, wait until released by the operator, then shadow Alpha for 20 MOOS seconds before returning directly home. Add operator buttons to deploy and return Alpha individually, deploy and return Bravo individually, and hold either vehicle in place. |
| Task 06: Mission + application | Build a standalone two-vehicle MOOS-IvP mission for `alpha` and `bravo`, and include a MOOS application named `pContactWaypoint`. Alpha should patrol a 280 meter rectangular route while Bravo runs the application and updates its active waypoint from Alpha’s reported position. The vehicles should use collision avoidance. |
| Task 07: Mission + behavior | Build a standalone two-vehicle MOOS-IvP mission for `alpha` and `bravo`, including an IvP behavior named `BHV_ContactIntercept`. Alpha should patrol a 210 meter triangular route while Bravo uses the behavior to guide toward a predicted intercept point ahead of Alpha. The vehicles should use collision avoidance. |
| Task 08: Self-evaluating mission | Build a self-evaluating MOOS-IvP mission in which a vehicle completes a 210 meter triangular route with a perfect octagon obstacle of side length 4 placed in the second leg. Use obstacle avoidance and pass/fail based on whether the vehicle hits the obstacle. |
| Task 09: Nine-case harness | Build a self-contained MOOS-IvP harness with its own self-evaluating mission in which a vehicle completes a 210 meter triangular route with a perfect octagon obstacle placed in the second leg. Use obstacle avoidance and run all nine combinations of obstacle side length (3, 6, 9) and vehicle speed (2, 4, 6). Report pass/fail for each case based on whether the vehicle hits the obstacle. |
| Task 10: Tight-loop enumeration | Analyze the mission logs and identify every instance of a tight loop for both vehicles. Report each loop with the vehicle name and start and end timestamps. |
| Task 11: Henry/Gilda diagnosis | Analyze the mission log files to determine why Henry appears to make excessive tight maneuvers near waypoints compared with Gilda. |
{: .benchmark-task-table }


## Results by model
{: #completion-and-conformance-together }

Across all four models, agents with skills completed 170 of 220 attempts
(77.3%), compared with 133 of 220 (60.5%) without the plugin. Mean engineering
conformance rose from 56.2% to 85.7%.

Completion improves for Luna, Terra, and Sol. Average engineering conformance
improves for all four models, including Astra, whose baseline already completes
almost every task.

{% include benchmark-figure.html file="model-completion" title="Completion and conformance by model" alt="Completion baseline/skills out of 55: Luna 21/33, Terra 20/40, Sol 40/47, Astra 52/50. Conformance baseline/skills: Luna 49.6/79.3%, Terra 49.6/81.6%, Sol 60.3/89.8%, Astra 65.1/92.2%." caption="Figure 1. Two separate measures of the delivered work. Skills raise average conformance in every model, while completion gains are largest where the baseline has more room to improve." %}

Terra makes the largest observed completion gain, moving from 20 to 40 complete
runs out of 55. Across all four models, the skills advantage is 16.8 percentage
points: 77.3% minus 60.5%. This is an absolute difference between rates, rather
than a relative percentage increase.

Astra's baseline completes 52 of 55 attempts, compared with 50 with skills.
Its overall baseline advantage is concentrated in the harness task. Skills do
not improve Astra's aggregate completion in this sample. They do raise its
average conformance from 65.1% to 92.2%, a difference that completion alone
would miss.

| Model | Completion (baseline → skills) | Completion change | Conformance (baseline → skills) | Conformance change |
|---|---:|---:|---:|---:|
| Luna | 38.2% → 60.0% | +21.8% | 49.6% → 79.3% | +29.7% |
| Terra | 36.4% → 72.7% | +36.4% | 49.6% → 81.6% | +32.0% |
| Sol | 72.7% → 85.5% | +12.7% | 60.3% → 89.8% | +29.5% |
| Astra | 94.5% → 90.9% | −3.6% | 65.1% → 92.2% | +27.1% |

With only 55 attempts per condition for each model, small differences should
be read cautiously. The 95% uncertainty intervals for Sol's and Astra's
completion differences include zero, so these samples do not clearly separate
a skills advantage from a baseline advantage for those models. Average
conformance rises by roughly 27–32 percentage points in every model, making
it the most consistent measured improvement.

## How completed results differ
{: #when-completion-hides-the-difference }

In each example below, baseline and skills complete all five attempts. The
conformance scores show how closely each result follows the specified
engineering practices.

{% include benchmark-figure.html file="model-conformance" title="Conformance in examples with equal completion" alt="Each condition completes all five runs. Mean conformance baseline/skills: Task 01 Astra BatteryWatch 44.0/95.0%. Task 02 Sol contact-waypoint app 79.0/98.0%. Task 05 Astra patrol/shadow mission 56.3/95.6%." caption="Figure 2. Selected examples with equal, perfect completion. The bars show a separate conformance difference that a pass/fail summary would hide." %}

Astra's BatteryWatch application moves from 44.0% to 95.0% conformance.
The skills runs fully meet the startup-configuration, recurring-computation,
mail-registration, and AppCasting-diagnostics criteria in all five attempts.
The baseline runs only partially meet the criterion that assigns recurring
computation to `Iterate()` in all five attempts. Sol's contact-waypoint
application provides another example, rising
from 79.0% to 98.0% conformance while retaining full completion.

### Patrol and shadow mission

Task 5 asks for a two-vehicle patrol and shadow mission with operator controls.
Astra completes all five attempts in both conditions. Its mean conformance,
however, rises from 56.3% to 95.6% with skills.

The selected conformance criteria cover separate community launchers,
configurable MOOSDB and pShare ports, and the components needed to run and
supervise the mission: simulation, helm, communications, monitoring, logging,
and a viewer. They also cover mission documentation:

| Task 5 criterion, Astra | Baseline fully met | Skills fully met |
|---|---:|---:|
| Separate community launchers | 0/5 | 5/5 |
| Network ports configurable at launch | 1/5 | 5/5 |
| Expected runtime and operator components | 1/5 | 5/5 |
| Mission documentation | 0/5 | 5/5 |

The baseline documentation was partially met in all five runs. It existed,
but did not fully meet the documentation criterion. Four baseline runs also
partially met the runtime-and-operator criterion.

The functional result is tied at 5/5, but skills meet these integration and
operation criteria more consistently. Those differences remain visible in
conformance after completion has reached its ceiling.

Conformance gains are not uniform across every task and model, and the
model-level averages combine those gains and losses. The overall conformance
advantage also depends on partial-credit rules: it is 29.6 percentage points
under the headline definition and 20.8 points when partially met criteria
receive half credit. It remains positive under both scoring rules.

## Results by task
{: #where-the-difference-appears }

The two application tasks are already close to 100% completion: together, the
baseline completes 38 of 40 runs and skills completes 39. On these tasks, binary completion offers
little room to show a benefit, even when implementation practices differ.

The behavior tasks show a larger separation. Baseline completes 17 of 40 runs.
Skills completes 30. The mission tasks move from 27 of 60 to 44. Those are
differences of 32.5 and 28.3 percentage points, respectively. A reasonable
interpretation is that the package is especially useful where the agent must
coordinate several MOOS-IvP components and conventions. This study does not
isolate which instructions account for the difference.

{% include benchmark-figure.html file="task-completion" title="Completion and conformance by task" alt="Connected baseline and skills points for eleven tasks. Completion counts out of 20: 19/20, 19/19, 7/13, 10/17, 7/13, 11/16, 9/15, 12/17, 8/5, 13/15, 18/20. Mean conformance baseline/skills: 53.0/89.2%, 74.8/89.5%, 78.0/93.6%, 74.6/95.6%, 46.9/90.7%, 45.8/92.1%, 60.9/93.1%, 51.5/91.7%, 33.8/84.9%, 53.2/73.9%, 45.4/48.5%." caption="Figure 3. Circles show baseline. Diamonds show skills. Completion improves on nine tasks, ties on Task 2, and falls on Task 9. Mean conformance improves on all eleven when the four models are pooled. Counts use 20 attempts per condition. The separate conformance panel reports percentages, not pass counts." %}

The conformance panel shows why a completion-only task ranking would be
incomplete. The contact-waypoint app ties at 19/20 complete while mean
conformance rises from 74.8% to 89.5%. The three ordinary mission tasks improve
by about 32–46 percentage points in conformance. The harness has the largest
conformance increase, from 33.8% to 84.9%, alongside a completion decline.
Higher adherence to the specified practices does not resolve its failures
to report truthful outcomes.

### Application versus integrated mission

Tasks 2 and 6 form a useful contrast. Task 2 asks for the contact-waypoint
application by itself, and both conditions complete 19 of 20 runs. Task 6 asks
for a two-vehicle mission incorporating that application, including vehicle
movement and collision avoidance. Completion falls to 11 of 20 in baseline
and 16 of 20 with skills.

Task 6 adds contact-report routing, active waypoint updates, vehicle motion,
and collision avoidance around the app.
Because these are separate prompts and runs, the comparison is not a controlled
estimate of the cost of integration. It does show that near-perfect results on
the standalone application do not settle the mission question.

Task 5 adds another perspective. It asks for patrol, release, timed shadowing,
return, and hold controls across two vehicles. Sol completes two of five
baseline attempts and all five skills attempts. Astra completes all five in
both conditions. Combining the models captures an overall gain, while the
task-by-model view shows how differently each model arrives at it.

### Differences between models and repeated attempts

{% include benchmark-figure.html file="task-model-completion" title="Completion for each task and model" alt="An eleven-row matrix of completion counts out of five, with adjacent baseline and skills columns for Luna, Terra, Sol, and Astra. The harness row is Luna 2/0, Terra 1/4, Sol 0/0, and Astra 5/1." caption="Figure 4. Each cell shows the number complete out of five attempts. Adjacent baseline and skills columns show where the models improve, tie, or regress." %}

Across the 44 task–model combinations, skills produce more complete attempts
in 22, the same number in 19, and fewer in three. Luna moves from 0/5 to 4/5
on both the standalone intercept behavior and the mission that includes it.
Terra moves from 0/5 to 4/5 on the mission with the contact-waypoint app.
These gains are visible within individual task–model comparisons as well as
in the pooled totals.

The harness is particularly uneven: Terra improves from 1/5 to 4/5, while
Luna falls from 2/5 to 0/5 and Astra from 5/5 to 1/5. Sol completes none in
either condition. A single aggregate bar cannot show those differences. The
other declining combination is Luna's tight-loop enumeration, from 1/5 to
0/5. The later runtime audit examined Sol and Astra's harnesses more deeply,
so that review-depth difference also matters when comparing this row.

{% include benchmark-figure.html file="repeated-completion" title="Distribution of completion across repeated attempts" alt="Numbers of task-model combinations with 0, 1, 2, 3, 4, and 5 completions out of five: baseline 9, 3, 5, 3, 9, 15. Skills 3, 3, 2, 4, 9, 23. Each row sums to 44 combinations." caption="Figure 5. Each segment counts task–model combinations with that many complete attempts. Perfect five-attempt completion occurs in 23 of 44 combinations with skills, versus 15 without. Combinations with no complete attempt fall from nine to three. These are observed repeat counts, not estimated probabilities of future success." %}

The repeated attempts distinguish an occasional success from a result that
holds across all five tries. Sol completes every attempt on eight of eleven
tasks with skills, compared with four without. Terra moves from two such tasks
to four, and Luna from none to two. Astra remains at nine in both conditions.
Five successes are still a small sample, but the shift is useful: the aggregate
gain includes more consistently completed tasks, as well as tasks that become
possible in some attempts.

### Log analysis

The two log tasks require analysis rather than new software. Task 10 asks for
every tight loop in both vehicles' logs, with start and end timestamps, and
completion rises from 13 to 15 of 20. Task 11 asks why Henry makes excessive
tight maneuvers compared with Gilda. Under the accepted grading, 18 baseline
and 20 skills answers are complete, leaving little room to distinguish models.

Conformance still separates the tasks: tight-loop enumeration rises from
53.2% to 73.9%, while diagnosis rises from 45.4% to 48.5%. An answer can give
a plausible explanation and still fall short on timestamped support, log
coverage, or a reproducible method. The grading-history section explains the
revision to Task 11.

## Skill use and validation
{: #what-the-agents-actually-did }

Each task has one or more required skills. For example, integrating a component
into a mission requires both component-building and mission-building guidance.
The evaluation and harness tasks additionally prescribe a companion mission
skill. All 220 skills runs show access to their required skills, and 216 show
access to the full set including prescribed companions. Luna and Terra each
miss that full set in two runs. Sol and Astra access it in every run.

A recorded file access does not prove a complete read or effective use. It does
show that skill discovery was rarely the obstacle in this benchmark.

The study also records live validation: commands that attempt to launch
the software or mission, going beyond reading source files or compiling code.
Here, “live” refers to execution in the benchmark environment, not a field
deployment of a physical vehicle. A recorded launch attempt need not succeed.

{% include benchmark-figure.html file="observed-validation" title="Observed live validation by model" alt="Runs with recorded live validation, baseline then skills, out of 55: Luna 23 and 35. Terra 24 and 38. Sol 30 and 44. Astra 20 and 27." caption="Figure 6. More skills attempts include recorded execution checks in every model. These are observations of agent activity. They do not establish that testing caused the completion differences or that every check was adequate." %}

Skills runs also record more live validation in every model. This is consistent
with workflows that ask the agent to exercise the component or mission it has
built. The counts are observational: they cannot establish how much of the
completion improvement came from testing. They also span analysis tasks that
require no new mission. The harness example below shows why the adequacy of a
check still matters after a run has been recorded.

## Time and cost
{: #time-and-cost-of-the-work }

With skills, median elapsed time is about seven to eleven minutes, an
increase of roughly 0.7–2 minutes depending on the model. These figures include
complete and incomplete attempts.

Cost is estimated from recorded token usage using the study's fixed historical
API rates. It is an
API-equivalent estimate, not a subscription charge or invoice. The rates
are held fixed so later price changes do not alter the comparison.

{% include benchmark-figure.html file="participant-efficiency" title="Participant time and estimated cost" alt="Median minutes baseline/skills: Luna 8.86/9.93, Terra 6.35/7.05, Sol 8.38/9.54, Astra 9.20/11.15. Median estimated USD: 0.149/0.141, 0.597/0.791, 2.352/2.367, 1.864/2.468." caption="Figure 7. Median elapsed time and estimated model-use cost per attempt. Both include available measurements from complete and incomplete runs. Grading and later audit work are excluded." %}

Cost moves differently from elapsed time. Luna's median estimate decreases
slightly, from $0.149 to $0.141. Terra's increases from $0.597 to $0.791. Sol's
is nearly unchanged at $2.352 and $2.367, while Astra's rises from $1.864 to $2.468.
These estimates use the recorded historical rates.

One Astra skills run on Task 9 ended without a token-usage record. Its cost is
unknown and is excluded from the cost median, leaving 54 observations for that
group. The run remains in completion and elapsed-time analyses.

The benchmark measures participant effort, not the later cost of reviewing,
integrating, or maintaining the result. It cannot yet put a dollar value on the
conformance improvement or estimate total project savings.

## Failures and next steps
{: #what-to-improve-next }

Task 9 identifies a specific weakness in the harness workflow. After the
later execution checks corrected its grades, baseline completes 8/20 runs and
skills completes 5/20, despite substantially higher conformance with skills.

The task requires a harness whose pass/fail verdict agrees with whether the
vehicle hits the obstacle. There are two different judgments here: a
mission FAIL reports an unsuccessful simulated route. A complete
benchmark result means the agent built a harness that reports those outcomes
correctly. A harness that truthfully reports a collision can be complete.
Passing every simulated route is not the requirement.

One retained Astra skills run illustrates the gap. The original log records a
vehicle position strictly inside the generated obstacle, independently verified
against the polygon geometry, while the result row reports `grade=pass`,
`hit=false`, and `collisions=0`. The harness therefore reported success despite
evidence of obstacle contact: a false pass. This finding does
not establish the exact internal detector or transport cause. The deeper
Task 9 review covered Sol and Astra. Luna and Terra retain their earlier review
depth, which limits comparisons across the entire task.

For the skills, this points to a potentially fixable shortcoming: strengthen
the workflow for testing the mission's own evaluator. Require evidence
connecting the verdict to the mission event, deliberately include a case known
to fail, and preserve the observation needed to diagnose an inconsistent grade.
These are proposed changes. This benchmark has not yet tested a package
that includes them.

The log-diagnosis task suggests another improvement area. Guidance can help an
agent find an anomaly, but the answer still needs to connect that anomaly to
the observed behavior. The evaluator has the same obligation: it should verify
the participant's causal explanation, rather than supply a better explanation
and credit that reconstruction. The accepted Task 11 review leaves two answers
incomplete at precisely that boundary.

These changes can be tested directly by repeating the affected tasks with a
revised skill package.

## Grading revisions and uncertainty
{: #a-result-that-survives-the-sensitivity-checks }

Sensitivity checks ask whether the overall conclusion changes when grades are
revised or part of the task set is removed. Across the four retained grading
stages of the same 440 attempts, the completion advantage ranges from +15.0
to +17.7 percentage points. The final accepted result is +16.8 points.

The lines in Figure 8 show uncertainty from variation between repeated
attempts. A bootstrap estimates that variation by repeatedly drawing from
the observed attempts, allowing an attempt to be drawn more than once, and
recalculating the completion difference. The middle 95% of those estimates
spans +11.4 to +22.3 points for the final revision. The range stays above
zero, supporting an overall skills advantage within this study.

{% include benchmark-figure.html file="grading-sensitivity" title="Completion difference across grading revisions" alt="Skills-minus-baseline completion differences and bootstrap 95% intervals: original +17.7 points (12.3 to 23.2), earlier correction +17.3 (11.8 to 22.7), runtime corrections +15.0 (9.5 to 20.5), accepted revision +16.8 (11.4 to 22.3)." caption="Figure 8. Points show the completion difference. Lines show its 95% bootstrap interval. Each row uses the same 440 attempts at a different grading stage. Only attempts within the same tasks and models are resampled, so the intervals do not predict performance on unseen tasks." %}

Removing any one task leaves a completion
difference between +15.0 and +20.0 points. Removing any one model leaves a
difference between +10.3 and +23.6 points. Removing any one task family also
leaves the overall direction positive.

The overall advantage therefore persists without any one task or model.
Its scope still matters: the plugin's developer selected the tasks, conformance
follows the skills' practices, and model-based reviewers can make mistakes.
Later audits examined some tasks more deeply than others. These checks show
how stable the result is within the study. A broader task set and independent
replication would test how far it generalizes.

<details class="benchmark-details" markdown="1">
<summary>How the work was graded, and what changed in the accepted revision</summary>

The benchmark combines checks of the submitted files and running software
with model-based reviewers, which are separate agent sessions assigned to
grade the work. For code and mission tasks, reviewers receive copies of the
submitted files under anonymous identifiers. They are not given the producing
model, whether skills were available, the paired result, the agent's
conversation, or its time and token use. Functionality and conformance are
reviewed separately. Disagreements or unresolved evidence receive further
review to reach a judgment.

Reviewer assignments differ across the study. For the first three models,
Tasks 1–5 use Sol reviewers at high and extra-high reasoning effort. From
Task 6, the pairing is Sol and Luna, both at high effort. Astra uses the latter
pairing from Task 2. The log tasks use a shared reference package of log
evidence and review each answer, with further review of flagged cases and a
sample selected in advance.

The bootstrap uses 20,000 resamples and a fixed random seed. For each task,
model, and condition, it draws five attempts from that group's five observed
attempts. Baseline and skills are resampled separately rather than keeping
the original pairs together. The eleven tasks remain fixed throughout. The
[source guide]({{ '/benchmark_2026/sources/' | relative_url }}) gives the exact
method settings and the separate method used for model-level intervals.

### What changed after the initial grades

Later examination found problems with reviewers accessing evidence, applying
grading criteria, and checking software at runtime. The original judgments
were retained alongside the corrections, so their effect on the same 440
attempts can be inspected.

| Grading stage | Baseline complete | Skills complete | Difference |
|---|---:|---:|---:|
| Original | 117/220 | 156/220 | +17.7% |
| Earlier correction | 119/220 | 157/220 | +17.3% |
| Runtime corrections, strict Task 11 | 117/220 | 150/220 | +15.0% |
| Accepted revision, including Task 11 | 133/220 | 170/220 | +16.8% |

The largest change concerns Task 11. Its post-hoc revision, made after
the original answers had been graded, accepts a useful, checkable diagnosis
without requiring an exhaustive investigation or one prescribed causal answer.
The same three functional criteria remain: use the original logs, make a fair
Henry/Gilda comparison, and give a materially correct explanation connected
to the observed behavior. Conformance is unchanged.

All forty submissions meet the first two criteria. Thirty-eight meet the
third. Two baseline answers still lack a sufficiently supported causal
explanation. Passing them would require the reviewer to repair the explanation
instead of verifying what the agent actually wrote.

This is a substantial interpretive revision: Task 11 changes from 0/40
complete under the original strict grading to 38/40 in the accepted
report. With almost every answer complete, the revised result does little to
distinguish models. The table above retains the earlier results.

The runtime review examined forty Astra submissions on Tasks 3, 5, 6, and 9,
plus all ten Sol Task 9 submissions. It found meaningful failures, including
false harness verdicts, while other questioned results survived examination.
No new participant attempts were added. Conformance, resource measurements,
and recorded agent-activity classifications were unchanged by the final
runtime and Task 11 revision. This review history documents corrections. It
does not measure how consistently a fresh set of independent reviewers would
agree on every result.

</details>

## Implications for the plugin
{: #what-this-means-for-the-plugin }

Skills improved conformance to MOOS-IvP practice across all four models,
including tasks that agents already completed reliably. Completion gains were
largest in behaviors and missions. The next package revision can target the
harness's false-pass failures and test whether stronger validation improves
those results. Broader task sets and measurements of integration and maintenance
effort would help establish how far the benefits carry into everyday development.

## Data and sources
{: #evidence-and-reproduction }

All eight figures use the accepted 440-run summaries. SVG, PNG, and numeric
data downloads appear below each figure. The source guide records the exact
benchmark revision, the current folder layout, and the reproduction commands.

- [Chart data, task prompts, and source hashes (JSON)]({{ '/assets/data/benchmark-2026.json' | relative_url }}): model and task results, task-by-model counts, exact task wording, revision stages, uncertainty, timing, cost coverage, and observed process counts.
- [Source notes and reproduction guide]({{ '/benchmark_2026/sources/' | relative_url }}): metric definitions, source-document mapping, and commands for rebuilding the figures.
- [MOOS-DAWG introduction]({{ '/moos_dawg_2026/' | relative_url }}): the plugin architecture, individual workflows, and examples from development projects.

The included data contains the numeric summaries, task prompts, and source identifiers.
The full participant transcripts, reviewer records, and original runtime
evidence remain in the private benchmark repository. Rebuilding a chart from
this snapshot reproduces its presentation. Independently reproducing the
underlying judgments requires access to that evidence and its evaluation
environment.
