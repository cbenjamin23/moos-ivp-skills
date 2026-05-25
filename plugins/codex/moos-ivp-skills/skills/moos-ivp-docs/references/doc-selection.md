# MOOS-IvP Doc Selection

## MIT Index

- Canonical upstream doc index: `https://oceanai.mit.edu/ivpman/pdfs/`
- Open the live index before selecting a PDF. Do not rely on memory for available filenames.
- Keep the shortlist to 1 to 3 PDFs.

## Filename Families

Use the live index to shortlist candidates from these families:

- `app_*`: app and utility manuals
- `bhv_*`: behavior manuals
- `chap_*`: conceptual and chapter-style docs
- `help_mip_*`: task-oriented help docs
- `lab_class_*`: tutorial and instructional material

Selection rules:

- Prefer exact or near-exact filename overlap with the user’s topic.
- For apps and behaviors, prefer a direct `app_*` or `bhv_*` match before broader chapter docs.
- For a utility or app whose binary name is already exact, try the obvious direct candidate first if present in the live index, for example `uQueryDB` -> `app_uquerydb.pdf`.
- For conceptual questions, inspect available `chap_*`, `help_mip_*`, and optionally `lab_class_*` filenames, then verify the topic inside the PDF before citing it.
- If versioned and unversioned variants both exist, treat both as candidates and verify inside the PDF before choosing.
- If the best available document is only a close conceptual match, say so.

## Minimal Alias Map

Use only small, obvious alias corrections:

- `pMarineViewer` -> `app_pmviewer.pdf`
- `pNodeReporter` -> `app_pnreporter.pdf`

Do not build a large hardcoded concept-to-PDF map in v1.

## In-PDF Verification

After opening a candidate PDF:

- search for the exact app name, behavior name, parameter, or concept phrase
- confirm the document actually covers the topic before citing it
- use a second or third candidate only if the first does not settle the question
- if opening the PDF from the index fails, construct the direct PDF URL from the filename shown in the index and open that URL directly
- if both the index path and direct URL fail, treat that PDF as unavailable in this environment and either try another candidate or fall back to local source

For line citations from PDFs, prefer stable tool-provided line references when
available. If the environment only gives the PDF bytes, create an extraction
artifact with `pdftotext -layout <pdf> - | nl -ba` and cite those extracted-text
line spans. Be explicit that they are extracted-text lines, not canonical PDF
anchors.

## Local Repo Discovery

When docs are missing, ambiguous, or checkout-specific behavior matters, locate a local `moos-ivp` repo in this order:

1. current workspace root if it contains `ivp/src`
2. parents of the current workspace
3. sibling directories near the current workspace
4. common home roots:
   - `~/moos-ivp`
   - `~/src/moos-ivp`
   - `~/repos/moos-ivp`
   - `~/projects/moos-ivp`
5. a bounded, shallow home search for a directory named `moos-ivp`

Do the explicit common-root checks before a broad home search. On macOS or any
permissions-noisy filesystem, suppress expected permission errors during the
bounded fallback search, for example:

```bash
find "$HOME" -maxdepth 3 -type d -name moos-ivp 2>/dev/null
```

Validate a candidate repo by confirming:

- `ivp/src` exists
- `ivp/src` contains recognizable app or behavior directories

Command preference:

- Prefer `rg --files` and `rg -n` when `rg` is available.
- Fall back to `find` and `grep -RIn` when `rg` is unavailable.

## Source Inspection Rules

For apps and utilities:

- look for exact directories under `ivp/src`, such as `uPokeDB`, `uQueryDB`, `pHelmIvP`, or `pMarineViewer`
- inspect `main.cpp`, `*_Info.*`, and the main app class files first

For behaviors:

- inspect these libraries:
  - `ivp/src/lib_behaviors`
  - `ivp/src/lib_behaviors-marine`
  - `ivp/src/lib_behaviors-colregs`
  - `ivp/src/lib_dep_behaviors`
- search for the behavior class name, for example `BHV_OpRegion`
- inspect the class definition and the parameter-parsing or validation code when the question is about configuration or semantics

For config or parameter questions:

- search for the exact parameter token in source
- prefer parser, setter, validation, or decision-path code over generic comments

Version-gap rule:

- if the checkout contains a versioned app or behavior such as `uSimMarineV23` and the MIT index only has older or generic PDFs, use local source as authoritative for that version-specific behavior
- cite the MIT PDF only as the nearest upstream reference, not as proof of checkout-specific behavior

## Answer Contract

When you answer:

- label whether the answer comes from upstream documentation, local checkout source, or both
- cite the MIT PDF URL and line spans when the docs path is used
- cite local file paths and line spans when the source path is used
- if docs and source disagree, explain both and say which is authoritative for the specific question
