---
layout: default
permalink: /benchmark_2026/sources/
title: "Benchmark sources"
description: "Data definitions, source provenance, and figure-generation commands"
companion_url: /benchmark_2026/
companion_label: Read the benchmark
---

[Return to the article]({{ '/benchmark_2026/' | relative_url }}).

## The source snapshot

The article uses the accepted 440-run analysis in `benchmark/evaluation/` from
`cbenjamin23/moos-ivp-skills-benchmark-private`, at commit
`100f4a93b2eec9acc93a3fbcefa6c1be71891083`. The benchmark repository is private.
The article includes an allowlisted export of numeric summaries, the eleven
task prompts, and source identifiers. Participant transcripts and reviewer
workspaces remain private.

The [chart-data JSON]({{ '/assets/data/benchmark-2026.json' | relative_url }})
contains model, task, and task-by-model summaries, along with the five grading
stages, uncertainty and leave-out analyses, observed process counts, exact
task prompts, and source hashes. The `task_prompts` field contains each task's
identifier and original prompt text from `benchmark/config/tasks.json`, matching
the verbatim prompts displayed in the article's table.
Schema version 3 adds the Task 9 audit's coverage and completion-loss counts
and preserves the previous published result as `pre_task09_coverage`.
Model, task, and overall summaries also include `conformance_half_credit`,
the mean score when partially met criteria receive half credit. This makes the
article's alternative-scoring comparison available in the download.
The exporter verifies the complete 440-record matrix, recomputes completion
counts from functional labels, and verifies all 2,172 input hashes recorded by
the source aggregate. Git objects are read at the pinned commit, so a later
folder reorganization or uncommitted work cannot silently change this article.

The post-hoc Task 9 runtime audit now covers all forty submissions under the
unchanged rubric. The additional twenty Luna/Terra reviews removed completion
credit from two baseline and four skills submissions. The headline is now
131/220 baseline and 166/220 skills, a 15.9 percentage-point difference.
The corrections concern harness reliability, including false success when
monitoring or setup fails. They do not establish that skills generally worsen
vehicle behavior. No participant runs were added. Original grades, Task 11,
Sol/Astra grades, conformance, timing, costs, and agent-activity coding remain
unchanged.

## Definitions

| Measure | Definition and boundary |
|---|---|
| Functional completeness | Every required functional criterion is resolved `met`. A partial, failed, or unresolved requirement prevents a run from counting as complete. Completion rate is the fraction of complete runs. |
| Conformance judgments | Each applicable skill-derived architecture, implementation, operation, or analysis criterion retains its own judgment. The same criteria apply in both conditions. These judgments are separate from functional completeness. |
| Headline conformance | Mean across runs of `met / (met + partially_met + not_met)`. Partially met criteria receive no credit. Not-applicable and unresolved criteria are excluded, with their counts retained in the data. All runs in this snapshot have scored conformance criteria. |
| Elapsed time | Median participant wall-clock minutes across complete and incomplete runs. |
| Cost | Median recorded standard API-equivalent USD estimate using the frozen rate table. It is not an invoice or a current price. One Astra skills receipt is unavailable. |
| Model intervals | Descriptive Newcombe/Wilson intervals for the completion difference. |
| Overall bootstrap | 20,000 resamples within each fixed task/model/condition stratum, seed 20260814. Conditions are resampled separately. Matched pairs are not jointly resampled. |
| Routing | Observed access to the required skills, or the full set including prescribed companions. Access does not prove effective use. |
| Live validation | A retained `live_run` validation category, not a correctness judgment. |

The conformance rubric defines `partially_met` as an existing mechanism that
is incomplete or inconsistent. `Not_met` requires contrary evidence or an
absence established through reasonable inspection. `Insufficient_evidence`
records uncertainty. `Not_applicable` is allowed only for an explicitly
conditional criterion. A missing required implementation does not become
optional because it is absent.

Criteria count equally within a run. We then average those run scores with
equal weight, including incomplete attempts. Longer rubrics do not give a run
more influence, and criteria are not weighted by the severity of a failure.
The half-credit variant changes the numerator to `met + 0.5 * partially_met`
and keeps the same denominator. Neither conformance summary is combined with
functional completion or treated as an independent correctness rate.

The original cohort has 330 runs. Astra adds 110. Both use high reasoning and
the same eleven prompts, fixtures, MOOS-IvP revision, and plugin 1.4.12 payload.
The participant CLI changes from 0.147.0 to 0.153.3 for Astra. Each task has a
180-minute ceiling and there is no token ceiling. The combined 220 matched
pairs are balanced 110/110 by starting condition. The benchmark is a fixed,
developer-selected task set. Cross-model comparisons are descriptive.

## Source-to-claim map

The repository consolidation places current reports in `benchmark/evaluation/`,
machine data in `benchmark/evaluation/data/`, and earlier evidence in
`benchmark/archive/`. The pinned commit includes the completed Task 9 audit
and retains earlier grading stages alongside the current results.

The public numeric export can redraw the figures. Independent reproduction of
the judgments requires the private evidence and evaluation environment.

| Article content | Source at the pinned revision |
|---|---|
| Headline, model/task counts, conformance, timing, cost | `benchmark/evaluation/RESULTS.md` and `benchmark/evaluation/data/aggregate.json` |
| Intervals, original/revised totals, leave-outs | `benchmark/evaluation/ROBUSTNESS.md` and `benchmark/evaluation/data/robustness.json` |
| Routing and live validation | `benchmark/evaluation/PROCESS.md` and `benchmark/evaluation/data/process.json` |
| Task descriptions, starter, inputs, scheduling | `benchmark/PLAN.md` |
| Verbatim task prompts | `benchmark/config/tasks.json` |
| Astra cohort and CLI difference | `benchmark/archive/ASTRA_EXTENSION.md` |
| Review, blinding, grader changes, metrics | `benchmark/evaluation/PROTOCOL.md` |
| Conformance scope, examples, and judgment labels | `benchmark/archive/evaluation/protocol/CONFORMANCE.md` |
| False-PASS example and geometry check | `benchmark/archive/reviews/2026-09-06-astra-adversarial/TASK09_CONTACT_VERIFICATION.md` |
| All-model Task 9 audit coverage and corrections | `benchmark/archive/evaluation-task09-coverage-v1/README.md`, `ACCEPTANCE_NOTES.md`, `FINAL_DECISIONS.json`, and `SUMMARY.json` |
| Unchanged Task 9 runtime probe contract | `benchmark/archive/evaluation-task09-coverage-v1/PROBE_CONTRACT.md` |
| Accepted Task 11 interpretation | `benchmark/archive/evaluation-task11-v2/TASK.md` |
| Final acceptance and archived decisions | `benchmark/archive/reviews/README.md` |

The source-document SHA-256 digests appear in `source_sha256` in the exported
JSON. The examples also retain the selected application and mission criterion counts.
Every plotted value is read from that JSON rather than manually entered
in the drawing code. Captions and prose state the relevant denominators and
qualifications separately.

The repeated-completion figure counts the 44 entries in `by_task_model` by
their `complete` value (0–5), separately for baseline and skills. A segment
counts task–model combinations, not individual attempts. The article's
21 improved, 20 tied, and three declining combinations compare those counts
within each entry. These are descriptive comparisons of five-attempt samples.
Task-level conformance pools all four models with equal weight per run,
including incomplete attempts.

## Rebuild the figures

From the `moos-ivp-skills` repository root, create an isolated Python environment:

```bash
python3 -m venv /tmp/moos-article-plots
/tmp/moos-article-plots/bin/pip install -r scripts/requirements-benchmark-article.txt
/tmp/moos-article-plots/bin/python scripts/build_benchmark_article.py
```

The script reads the included numeric snapshot and writes SVG and PNG figures
under `docs/assets/images/benchmark-2026/`, together with the social preview.
The pinned plotting environment used for the article is Python 3.14,
Matplotlib 3.11.1, NumPy 2.5.2, and fontTools 4.64.0. The script makes no
participant or grader calls.

With access to the original benchmark Git repository, verify and regenerate
the export from its committed evidence:

```bash
python3 scripts/build_benchmark_article.py \
  --benchmark-repo /path/to/moos-ivp-skills-benchmark-private \
  --data-only
```

This uses the pinned commit by default and does not modify the benchmark
checkout. Omit `--data-only` inside the plotting environment to regenerate the
figures after the verified export. Regeneration does not approve a later
evaluation revision. Adopting one requires reviewing the article's claims and
revision notes together with its data.

## Typography and figure files

Figures use the MOOS-DAWG article's Plus Jakarta Sans typeface, navy and slate
series colors, pale blue/green surfaces, and quiet gridlines. Text is embedded
as outlines in SVG so exported charts preserve the intended font. The generator
instantiates regular and bold weights with distinct PostScript names, preventing
the SVG glyph cache from mixing weights within words. HTML alt text
and the numeric data retain accessible descriptions of the results. The article
provides keyboard-focusable horizontal scrolling for wide figures on small
screens.

The bundled font is the unmodified Google Fonts Plus Jakarta Sans variable
font, distributed under its [SIL Open Font License]({{ '/assets/fonts/OFL-PlusJakartaSans.txt' | relative_url }}).
Temporary static instances are generated only while plotting. The page itself
continues to use the same font-loading and shared layout as the release article.
