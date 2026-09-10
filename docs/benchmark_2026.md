---
layout: default
article: true
permalink: /benchmark_2026/
title: "Benchmarking MOOS-IvP Skills"
hero_variant: benchmark
description: "Coding agents with and without the MOOS-IvP Skills plugin."
social_title: "Benchmarking MOOS-IvP Skills"
social_image: "/assets/images/benchmark-2026/social.png"
social_image_alt: "440 runs: completion rises from 59.5% to 75.5%, and mean conformance from 56.2% to 85.7%, with skills."
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
  - { id: a-result-that-survives-the-sensitivity-checks, title: "Would different attempts change the results?" }
  - { id: conclusion, title: Conclusion }
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
[chart-data download]({{ '/assets/data/benchmark-2026.json' | relative_url }})
also includes a half-credit alternative.

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

Across all four models, agents with skills completed 166 of 220 attempts
(75.5%), compared with 131 of 220 (59.5%) without the plugin. Mean engineering
conformance rose from 56.2% to 85.7%.

Completion improves for Luna, Terra, and Sol. Average engineering conformance
improves for all four models, including Astra, whose baseline already completes
almost every task.

{% include benchmark-figure.html file="model-completion" title="Completion and conformance by model" alt="Completion baseline/skills out of 55: Luna 20/33, Terra 19/36, Sol 40/47, Astra 52/50. Conformance baseline/skills: Luna 49.6/79.3%, Terra 49.6/81.6%, Sol 60.3/89.8%, Astra 65.1/92.2%." caption="Figure 1. Two separate measures of the delivered work. Skills raise average conformance in every model, while completion gains are largest where the baseline has more room to improve." %}

Terra makes the largest observed completion gain, moving from 19 to 36 complete
runs out of 55. Across all four models, skills produce 35 additional complete
attempts, a 15.9 percentage-point increase in completion. This is an absolute
difference between rates, rather than a relative percentage increase.

Astra's baseline completes 52 of 55 attempts, compared with 50 with skills.
Its overall baseline advantage is concentrated in the harness task. Skills do
not improve Astra's aggregate completion in this sample. They do raise its
average conformance from 65.1% to 92.2%, a difference that completion alone
would miss.

| Model | Completion (baseline → skills) | Completion change | Conformance (baseline → skills) | Conformance change |
|---|---:|---:|---:|---:|
| Luna | 36.4% → 60.0% | +23.6% | 49.6% → 79.3% | +29.7% |
| Terra | 34.5% → 65.5% | +30.9% | 49.6% → 81.6% | +32.0% |
| Sol | 72.7% → 85.5% | +12.7% | 60.3% → 89.8% | +29.5% |
| Astra | 94.5% → 90.9% | −3.6% | 65.1% → 92.2% | +27.1% |

### How individual conformance scores shifted

The average gain reflects a broad shift across individual attempts. Median
conformance rises from 56.3% in the baseline to 92.0% with skills. Only 3 of
220 baseline attempts reach at least 90%, compared with 129 skills attempts.
Scores below 60% fall from 116 to 20.

{% include benchmark-figure.html file="conformance-distribution" title="How individual conformance scores shifted" alt="Number of individual attempts by conformance score range, baseline then skills: 0 to 19 percent, 2 and 0; 20 to 39 percent, 39 and 8; 40 to 59 percent, 75 and 12; 60 to 79 percent, 74 and 24; 80 to 89 percent, 27 and 47; 90 to 100 percent, 3 and 129. Each condition includes 220 attempts." caption="Figure 2. Individual conformance scores shift toward the upper ranges with skills. Scores at or above 90% rise from 3 to 129 attempts, while scores below 60% fall from 116 to 20." %}

Across all 440 runs, skills improve both aggregate completion and average
conformance. The measures still answer different questions. Of the 132
attempts that meet at least 90% of the conformance criteria, 25 are incomplete
because they miss at least one required function.

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

{% include benchmark-figure.html file="model-conformance" title="Conformance in examples with equal completion" alt="Each condition completes all five runs. Mean conformance baseline/skills: Task 01 Astra BatteryWatch 44.0/95.0%. Task 02 Sol contact-waypoint app 79.0/98.0%. Task 05 Astra patrol/shadow mission 56.3/95.6%." caption="Figure 3. Selected examples with equal, perfect completion. The bars show a separate conformance difference that a pass/fail summary would hide." %}

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

{% include benchmark-figure.html file="task-completion" title="Completion and conformance by task" alt="Connected baseline and skills points for eleven tasks. Completion counts out of 20: 19/20, 19/19, 7/13, 10/17, 7/13, 11/16, 9/15, 12/17, 6/1, 13/15, 18/20. Mean conformance baseline/skills: 53.0/89.2%, 74.8/89.5%, 78.0/93.6%, 74.6/95.6%, 46.9/90.7%, 45.8/92.1%, 60.9/93.1%, 51.5/91.7%, 33.8/84.9%, 53.2/73.9%, 45.4/48.5%." caption="Figure 4. Circles show baseline. Diamonds show skills. Completion improves on nine tasks, ties on Task 2, and falls on Task 9. Mean conformance improves on all eleven when the four models are pooled. Counts use 20 attempts per condition. The separate conformance panel reports percentages, not pass counts." %}

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
and collision avoidance around the app. Task 2 and Task 6 were separate
benchmark tasks with separate fresh runs. Task 6 did not continue from a Task 2
implementation, so it does not measure how much extra work it takes to combine
the app with a mission. It does show that near-perfect results on the standalone
application do not settle the mission question.

Task 5 adds another perspective. It asks for patrol, release, timed shadowing,
return, and hold controls across two vehicles. Sol completes two of five
baseline attempts and all five skills attempts. Astra completes all five in
both conditions. Combining the models captures an overall gain, while the
task-by-model view shows how differently each model arrives at it.

### Differences between models and repeated attempts

{% include benchmark-figure.html file="task-model-completion" title="Completion for each task and model" alt="An eleven-row matrix of completion counts out of five, with adjacent baseline and skills columns for Luna, Terra, Sol, and Astra. The harness row is Luna 1/0, Terra 0/0, Sol 0/0, and Astra 5/1." caption="Figure 5. Each cell shows the number complete out of five attempts. Adjacent baseline and skills columns show where the models improve, tie, or regress." %}

Across the 44 task–model combinations, skills produce more complete attempts
in 21, the same number in 20, and fewer in three. Luna moves from 0/5 to 4/5
on both the standalone intercept behavior and the mission that includes it.
Terra moves from 0/5 to 4/5 on the mission with the contact-waypoint app.
These gains are visible within individual task–model comparisons as well as
in the pooled totals.

In the harness task, Luna completes 1/5
baseline attempts and 0/5 with skills. Terra and Sol complete none in either
condition. Astra completes 5/5 baseline attempts and 1/5 with skills. The
other declining combination is Luna's tight-loop enumeration, from 1/5 to
0/5.

{% include benchmark-figure.html file="repeated-completion" title="Distribution of completion across repeated attempts" alt="Numbers of task-model combinations with 0, 1, 2, 3, 4, and 5 completions out of five: baseline 10, 3, 4, 3, 9, 15. Skills 4, 3, 2, 4, 8, 23. Each row sums to 44 combinations." caption="Figure 6. Each segment counts task–model combinations with that many complete attempts. Perfect five-attempt completion occurs in 23 of 44 combinations with skills, versus 15 without. Combinations with no complete attempt fall from ten to four. These are observed repeat counts, not estimated probabilities of future success." %}

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
a plausible explanation and still fall short on timestamped support, complete
log coverage, or enough detail for another reviewer to repeat the analysis.

## Skill use and validation
{: #what-the-agents-actually-did }

Each task has one or more required skills. For example, Task 6 integrates the
`pContactWaypoint` app into a two-vehicle mission, so it requires both
app-building and mission-building guidance.
The evaluation and harness tasks additionally prescribe a companion mission
skill. All 220 skills runs show access to their required skills, and 216 show
access to the full set including prescribed companions. Luna and Terra each
miss that full set in two runs. Sol and Astra access it in every run.

An access record means that the agent opened or otherwise accessed a relevant
skill file during the run. It does not prove that the agent read the guidance
in full or used it effectively. Since all 220 skills runs accessed their
required skills, finding the right skill was rarely the obstacle here.

The study also records live validation: an attempt to launch the built app,
behavior, or mission in the benchmark simulation and check it in execution,
rather than inferring from the source and build that it should satisfy the
request. A recorded launch attempt need not succeed.

{% include benchmark-figure.html file="observed-validation" title="Observed live validation by model" alt="Runs with recorded live validation, baseline then skills, out of 55: Luna 23 and 35. Terra 24 and 38. Sol 30 and 44. Astra 20 and 27." caption="Figure 7. More skills attempts include recorded execution checks in every model. These are observations of agent activity. They do not establish that testing caused the completion differences or that every check was adequate." %}

Skills runs also record more live validation in every model. This is consistent
with workflows that ask the agent to exercise the app, behavior, or mission it
has built. The counts are observational: they cannot establish how much of the
completion improvement came from testing. They also span analysis tasks that
require no new mission, and an app or behavior task can use a temporary mission
or test harness to exercise its deliverable.

## Time and cost
{: #time-and-cost-of-the-work }

With skills, median elapsed time is about seven to eleven minutes, an
increase of roughly 0.7–2 minutes depending on the model. These figures include
complete and incomplete attempts.

Cost is estimated from recorded token usage using API rates as of August 10,
2026 for Luna, Terra, and Sol, and September 4, 2026 for Astra. It is an
API-equivalent estimate, not a subscription charge or invoice. Those rates stay
fixed so later price changes do not alter the comparison.

{% include benchmark-figure.html file="participant-efficiency" title="Participant time and estimated cost" alt="Median minutes baseline/skills: Luna 8.86/9.93, Terra 6.35/7.05, Sol 8.38/9.54, Astra 9.20/11.15. Median estimated USD: 0.149/0.141, 0.597/0.791, 2.352/2.367, 1.864/2.468." caption="Figure 8. Median elapsed time and estimated model-use cost per attempt. Both include available measurements from complete and incomplete runs. Grading work is excluded." %}

Cost moves differently from elapsed time. Luna's median estimate decreases
slightly, from $0.149 to $0.141. Terra's increases from $0.597 to $0.791. Sol's
is nearly unchanged at $2.352 and $2.367, while Astra's rises from $1.864 to $2.468.
One Astra skills run on Task 9 ended without a token-usage record. Its cost is
unknown and is excluded from the cost median, leaving 54 observations for that
group. The run remains in completion and elapsed-time analyses.

The benchmark measures participant effort, not the later cost of reviewing,
integrating, or maintaining the result. It cannot yet put a dollar value on the
conformance improvement or estimate total project savings.

## Failures and next steps
{: #what-to-improve-next }

Task 9 identifies a specific weakness in the harness workflow. Baseline
completes 6/20 runs and skills completes 1/20, despite substantially higher
conformance with skills. Completion does not require every simulated route to
succeed. It requires the harness verdict to match what happened: a collision
reported as FAIL is valid, while a collision reported as PASS is not.

In one Astra skills run, the log places the vehicle inside the obstacle while
the result says `grade=pass`, `hit=false`, and `collisions=0`. Other harnesses
report success after collision monitoring or test-case setup fails. These false
passes show a harness reliability problem, not evidence that skills generally
worsen vehicle behavior.

One possible next step is to strengthen the harness guidance. It could suggest
a known-failure case, compare each verdict with the recorded mission events,
and treat missing monitoring or failed setup as a failure rather than a pass.
Repeating Task 9 would show whether that guidance helps.

## Would different attempts change the results?
{: #a-result-that-survives-the-sensitivity-checks }

The 15.9-point completion advantage and 29.6-point conformance advantage come
from five baseline and five skills attempts for every task and model. Another
set of attempts would produce slightly different values. This analysis
estimates how much each difference could move because of run-to-run variation.

For every task and model, we randomly redraw five baseline attempts and five
skills attempts from those already collected. The same attempt can be drawn
more than once. We then recalculate the completion and mean conformance
advantages and repeat the process 20,000 times. This standard uncertainty check
is called bootstrap resampling. Keeping each group separate preserves the
benchmark's original mix of tasks, models, and conditions.

The middle 95% of the recalculated advantages range from +10.9% to +21.4% for
completion and +28.3% to +30.9% for conformance. Neither range includes zero.
This supports positive skills advantages on both measures for these tasks and
models, but it does not predict the differences for new tasks or future models.

Both advantages stay positive when we exclude each task, model, or task
category in turn. The five categories are applications, behaviors, missions,
evaluation and harnesses, and log analysis. No single part of the benchmark
creates either overall advantage.

{% include benchmark-figure.html file="result-stability" title="How much the measured advantages could vary" alt="Skills-minus-baseline completion and mean conformance advantages. Different sets of five attempts give middle 95% ranges of +10.9 to +21.4 percent for completion and +28.3 to +30.9 percent for conformance. After excluding each item in turn, completion ranges are +14.0 to +20.0 for tasks, +10.9 to +22.4 for models, and +11.2 to +19.4 for task categories. Conformance ranges are +27.4 to +32.2 for tasks, +28.7 to +30.4 for models, and +25.3 to +33.5 for task categories." caption="Figure 9. The first row shows how both measured advantages could vary with different sets of five attempts. The other rows show the smallest and largest values after excluding each task, model, or task category in turn. Every range stays above zero." %}

Submitted files were reviewed under anonymous identifiers. Reviewers did not
see which model produced the work or whether skills were available.
Functionality and conformance were scored separately, and uncertain cases
received further review.

The scope still matters. The plugin's developer selected the tasks,
conformance reflects the skills' practices, and model-based reviewers can make
mistakes. A broader task set and independent replication would test how far
these findings generalize.

## Conclusion
{: #conclusion }

Skills improved conformance to MOOS-IvP practice across all four models,
including tasks that agents already completed reliably. Completion gains were
largest in behaviors and missions. One useful direction for the next package
revision is to address the harness's false-pass failures and test whether
stronger validation improves those results. Broader task sets and measurements
of integration and maintenance effort would help establish how far the benefits
carry into everyday development.

This matters for real robots because software conventions can prevent
operational problems. Configurable ports avoid network conflicts, live
validation catches failures before deployment, and truthful harnesses keep
failed scenarios from being reported as passes. This benchmark uses simulation,
so it does not measure field safety. It does show that domain skills help coding
agents produce more complete MOOS-IvP work that follows the practices experienced
developers rely on. Human review and hardware testing remain essential before
deployment.

The design follows ideas used in software-agent benchmarks such as
[SWE-bench](https://arxiv.org/abs/2310.06770), where an agent works from a
request inside a real repository, and robotics research such as [Code as
Policies](https://openreview.net/forum?id=fmtvpopfLC6) and
[GenSim](https://openreview.net/forum?id=14YqPG4cm0), where generated robot code
is exercised in simulation. This study applies those ideas to complete
MOOS-IvP development workflows and separately measures functional completion
and domain-specific engineering practice.

The private benchmark archive contains a detailed report for each of the eleven
tasks, including model-level results, criterion breakdowns, and failure
analysis. This article presents the main findings across the study.

*Data availability: The chart-data downloads contain the aggregate results and
exact task prompts. Participant transcripts, reviewer workspaces, and runtime
evidence are private.*
