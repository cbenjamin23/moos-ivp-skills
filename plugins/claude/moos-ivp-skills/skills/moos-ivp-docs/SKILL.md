---
name: moos-ivp-docs
description: Consult the live MIT MOOS-IvP PDF index and cite the most relevant upstream documentation for MOOS-IvP apps, behaviors, parameters, and concepts. Use when the user explicitly asks for documentation-backed answers, when upstream MOOS-IvP semantics are uncertain, or when an AI coding agent needs to compare MIT docs against a local moos-ivp checkout under ivp/src.
---

# MOOS-IVP Docs

## Overview

Use this skill to ground MOOS-IvP answers in the live MIT manual PDFs and, when needed, the local `moos-ivp` source tree.

Read `references/doc-selection.md` when you need the filename-family rules, alias map, repo discovery order, or source-inspection rules.

## When To Use

Use this skill when the task is about:
- MOOS-IvP app or utility behavior
- IvP behavior semantics or parameters
- MOOS-IvP terminology, architecture, or conceptual questions
- `.moos` or `.bhv` settings whose upstream meaning should be confirmed in the docs
- comparing upstream documentation against a local `moos-ivp` checkout

## When Not To Use

Do not use this skill as the primary tool for:
- `.alog` mission reconstruction or incident forensics
- launching or tearing down missions
- purely local code-editing tasks when no documentation question is involved

If the task is mainly about `.alog` evidence, use `moos-alog-analysis` first.

## Authority Model

Apply this authority order:

1. If the user explicitly asks for documentation, or if you are unsure about upstream MOOS-IvP behavior, use the MIT PDFs first. Do not answer from memory in this case.
2. If the user asks what the current checkout actually does, inspect local `ivp/src` first and use MIT PDFs only as upstream context.
3. If MIT docs and local source differ, say so explicitly and cite both.
4. Do not widen to broader web sources in v1.

Treat the MIT PDFs as the upstream source of truth for documented semantics when asked or when uncertain. Treat local `ivp/src` as the source of truth for checkout-specific implementation behavior.

## MIT PDF Lookup Workflow

1. Open the live MIT index at `https://oceanai.mit.edu/ivpman/pdfs/` first.
2. Classify the question as one of:
   - app or utility
   - behavior
   - conceptual or architecture
   - tutorial or operator help
3. Build a shortlist of 1 to 3 candidate PDFs from the live filenames only.
   - For an exact app or utility name, prefer the matching `app_*` filename first if it exists, for example `uQueryDB` -> `app_uquerydb.pdf`.
4. Open the best candidate first. If opening the PDF from the index fails, construct the direct PDF URL from the filename shown in the index and open that URL directly. If both attempts fail, treat that document as unavailable and either try another candidate or fall back to local source inspection.
5. Use in-PDF search to verify the app name, behavior name, parameter, or topic appears in the document before relying on it.
6. Open a second or third candidate only if the first document is incomplete, too general, or ambiguous.
7. Answer with the selected PDF URL and line citations. If the PDF tool does
   not provide stable line numbers, use `pdftotext -layout <pdf> - | nl -ba`
   or an equivalent extraction artifact and label those as extracted-text line
   spans rather than canonical PDF anchors.

Representative pattern:

- `uQueryDB` question: inspect the live index, shortlist `app_uquerydb.pdf`, verify `uQueryDB` appears inside the PDF, and only then fall back to local `ivp/src/uQueryDB` if the PDF is unavailable or incomplete.

Critical rule:
- Do not hard-default a conceptual question to a specific `chap_*` PDF before inspecting the live index and verifying the topic inside the PDF.

## Local Repo Fallback Workflow

Use local source inspection when:
- the docs are unavailable
- no clear PDF match exists
- the PDF text is too weak to settle the question
- the user asks what the current checkout actually does
- the local checkout version is newer or more specific than the available MIT PDFs

When local MOOS-IvP source is needed, resolve the checkout in this order:

1. Path explicitly provided by the user.
2. `MOOS_IVP_ROOT` from the shell environment.
3. Active task workspace if it contains `ivp/src`.
4. Parent or sibling directories near the active task workspace.
5. Common home locations such as `~/moos-ivp`, `~/src/moos-ivp`, `~/repos/moos-ivp`, and `~/projects/moos-ivp`.
6. A bounded shallow home search for a directory named `moos-ivp`, excluding noisy folders.

Prefer explicit common-root checks before broad `find` searches. If a bounded
home search is needed on macOS or a permissions-noisy system, suppress expected
permission noise, for example with `2>/dev/null`.

Validate a candidate repo by confirming:
- `ivp/src` exists
- recognizable app or behavior directories exist under `ivp/src`

If local source is required and no valid checkout is found, stop and ask the user for the checkout path. Do not answer source-specific questions from memory or weaker evidence.

If multiple repos are found, prefer the current workspace repo when applicable. Otherwise prefer the repo nearest to the current working directory and state which repo you used.

If the checkout has a versioned app or behavior with no same-version PDF in the MIT index, treat local source as authoritative for that version-specific behavior and cite MIT docs only as the nearest upstream reference.

## Citation Requirements

When you use this skill:
- cite the MIT PDF URL and PDF line spans when the docs path is used
- cite local file paths and line spans when the source path is used
- clearly label whether the answer is based on upstream documentation, local checkout source, or both
- say explicitly when MIT docs did not fully settle the question and the answer was completed from source inspection

## Conflict Handling

If docs and source disagree:
- separate the upstream-doc answer from the checkout-specific answer
- do not collapse them into a single blended claim
- explain which source is authoritative for each part of the answer

## Failure Modes

- MIT index unavailable: fall back to local source inspection if a repo can be found
- MIT index available but no clear PDF match: use local source if present, otherwise say no exact document was identified
- PDF text extraction weak: use nearby lines or a second supporting PDF, but do not overstate certainty
- repo not found: say that local source fallback was unavailable

## Coordination With Other MOOS Skills

- Use `moos-alog-analysis` first for existing `.alog` analysis. Bring this skill in only if documentation context would help interpret the findings.
