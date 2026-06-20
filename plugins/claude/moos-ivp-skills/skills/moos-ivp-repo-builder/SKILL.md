---
name: moos-ivp-repo-builder
description: "Create a user-owned MOOS-IvP extension repository from moos-ivp-extend: clone/customize the template, confirm the local MOOS-IvP dependency, configure PATH and IVP_BEHAVIOR_DIRS, initialize independent Git, and validate the baseline build before app, behavior, or mission work."
---

# MOOS-IvP Repo Builder

## Overview

Use this skill to bootstrap a new external MOOS-IvP project modeled on the
course `moos-ivp-extend` tree. The goal is a working user-owned repository that
builds, has its `bin`, `scripts`, and behavior `lib` paths available from the
shell, and is ready for custom apps, behaviors, and missions.

This skill owns the repo shell and environment setup. For code inside the new
repo, delegate follow-on work to:

- `moos-app-builder` for custom MOOS apps
- `ivp-behavior-builder` for custom IvP behaviors
- `moos-ivp-mission-builder` for runnable missions

## Defaults

- Template source: `https://github.com/moos-ivp/moos-ivp-extend.git`
- Git handling: fresh repo. Remove the template `.git/`, then run `git init`.
- Environment file: `<repo>/env.sh`
- Persistent shell integration: ask before editing a shell profile
- Environment additions:
  - add `<repo>/bin` and `<repo>/scripts` to `PATH`
  - add `<repo>/lib` to `IVP_BEHAVIOR_DIRS`
- Keep the example app, behavior, and missions unless the user asks for a
  clean shell.

Use a different template repo or skip the repo-local environment file only when
the user explicitly asks.

## Confirmation Gate

Before cloning or editing files, collect and confirm:

1. New repo name and target parent directory or full target path.
2. Repository author name and optional organization string for customized
   project text. This is not the same as Git commit identity.
3. Whether examples should stay or be removed.
4. Whether to add persistent shell integration by sourcing `<repo>/env.sh` from
   the user's preferred shell profile. If yes, confirm the profile path.

If the user already gave these values and said to proceed, treat that as the
confirmation. Otherwise, stop and ask a concise confirmation question before
cloning.

## Guiding Vague Users

When the user starts with a vague request such as "I want a new MOOS-IvP repo",
guide them with one or two small questions at a time instead of dumping the
whole checklist at once.

Good first move:

1. Try to resolve `MOOS_IVP_ROOT` in the background.
2. Say whether it was found.
3. Ask for the repo name.

Then ask for the target location, project display author, examples/defaults,
and shell integration preference as needed. If the user says "wherever is fine",
suggest a concrete default path and confirm it. Prefer a sibling of the
validated `moos-ivp` checkout, for example `~/my-new-repo` when
`MOOS_IVP_ROOT` is `~/moos-ivp`. Do not default to nesting the new repo inside
an unrelated active workspace. Explain that the project display author is for
README/CMake text, not a Git committer email.

When proposing persistent shell integration, show the concise block that would
be added to the selected profile:

```bash
# >>> moos-ivp repo: <repo-name> >>>
[ -f "<absolute-repo-path>/env.sh" ] && . "<absolute-repo-path>/env.sh"
# <<< moos-ivp repo: <repo-name> <<<
```

Before side effects, summarize the resolved values in one sentence and ask for
explicit confirmation.

## MOOS-IvP Root Resolution

Resolve `MOOS_IVP_ROOT` before cloning. Try, in order:

1. Path explicitly provided by the user.
2. `MOOS_IVP_ROOT` from the shell environment.
3. A sibling or parent `moos-ivp` near the target path or current workspace.
4. Common home locations:
   - `~/moos-ivp`
   - `~/src/moos-ivp`
   - `~/repos/moos-ivp`
   - `~/projects/moos-ivp`
5. A bounded shallow home search for a directory named `moos-ivp`, suppressing
   expected permission noise.

Validate a candidate by confirming:

- `ivp/src` exists
- `build-moos.sh` exists
- `build-ivp.sh` exists
- `scripts/GenMOOSApp_AppCasting` exists and is executable
- `scripts/GenBehavior` exists and is executable

If no valid checkout is found, stop and ask explicitly for the path to the
local `moos-ivp` checkout. Do not clone, edit shell profiles, or create a
placeholder path.

If multiple checkouts are found, prefer the one nearest the target repo. State
which path will be used in the confirmation.

## Workflow

1. Confirm setup values and validated `MOOS_IVP_ROOT`.
2. Create or verify the target parent directory.
3. Refuse to overwrite a non-empty target directory unless the user explicitly
   asks to reuse it.
4. Clone the template into the target path:

   ```bash
   git clone https://github.com/moos-ivp/moos-ivp-extend.git <target-repo>
   ```

5. Detach the template Git metadata and initialize a fresh repo:

   ```bash
   rm -rf .git
   git init
   git branch -M main
   ```

6. Customize repository text and build wiring.
   - Keep one top-level README by default. Prefer `README.md`, migrate any
     useful unique text from legacy `README` if needed, then remove `README`.
     Keep both only if the user explicitly asks.
   - Remove inherited template CI metadata by default, including
     `.github/workflows/build_extend.yml` and `.gitlab-ci.yml`, and remove any
     README badges or links that refer to the upstream template CI.
   - Update README title and obvious references from `moos-ivp-extend` to the
     new repo name in the retained README.
   - Use the repository author name in the top-level CMake `# NAME:` line and
     any newly written project text. Label this to the user as the project
     display author, not Git commit identity. Do not rewrite upstream example
     source file authors unless the user explicitly asks to claim or replace
     example code.
   - Update top-level CMake comments and `PROJECT(...)` only when a clear
     project identifier is available. Use an uppercase, underscore-safe project
     token.
   - If the repo name appears in nested example docs such as
     `missions/alder/README` or `src/lib_behaviors-test/README`, update only
     path references needed for the examples to remain accurate.
   - Scrub obvious visible template names in comments and docs that a user is
     likely to open, including top-level `CMakeLists.txt`, `src/CMakeLists.txt`,
     and mission/example README files. Do not churn source-file history
     comments merely to remove upstream maintainer names.
   - Make the resolved `MOOS_IVP_ROOT` effective for builds. Treat it as a
     setup-time input, not a shell variable that users must keep forever. The
     upstream
     template only searches nearby relative paths, so a repo outside the same
     parent as `moos-ivp` can fail unless the path is wired explicitly.
     Update top-level `CMakeLists.txt` with the resolved absolute path:
     - append `<moos-ivp-root>/build/MOOS/MOOSCore` to `CMAKE_PREFIX_PATH`
       before `find_package(MOOS 10.0)`
     - add `<moos-ivp-root>` to the
       `find_path(MOOSIVP_SOURCE_TREE_BASE ... PATHS ...)` list
     This makes normal future `./build.sh` runs work without requiring
     `MOOS_IVP_ROOT` in `.bashrc`.
   - Do not add repository automation files or remote GitHub setup unless the
     user explicitly asks.
7. If the user requested a clean shell, remove sample source and mission
   directories carefully and keep the build skeleton valid. Otherwise retain
   examples so the baseline build has known artifacts to verify.
8. Create the repo-local shell environment file.
   - Write `<repo>/env.sh`.
   - Resolve the absolute paths for the new repo's `bin`, `scripts`, and
     `lib` directories before writing the file.
   - Make repeated sourcing idempotent so PATH and `IVP_BEHAVIOR_DIRS` do not
     accumulate duplicate entries.
   - Keep the file source-compatible with common Bash and zsh startup files.
   - Use this shape:

     ```bash
     #!/usr/bin/env bash
     # Source this file to use this MOOS-IvP extension repo.
     case ":$PATH:" in *":<absolute-repo-bin>:"*) ;; *) PATH="$PATH:<absolute-repo-bin>" ;; esac
     case ":$PATH:" in *":<absolute-repo-scripts>:"*) ;; *) PATH="$PATH:<absolute-repo-scripts>" ;; esac
     case ":${IVP_BEHAVIOR_DIRS:-}:" in *":<absolute-repo-lib>:"*) ;; *) IVP_BEHAVIOR_DIRS="${IVP_BEHAVIOR_DIRS:+$IVP_BEHAVIOR_DIRS:}<absolute-repo-lib>" ;; esac
     export PATH
     export IVP_BEHAVIOR_DIRS
     ```

9. If the user opted into persistent shell integration, update the selected
   shell profile.
   - Ask for the profile path instead of assuming one. If the user named a
     shell, suggest its usual profile, such as `~/.zshrc` for zsh or
     `~/.bashrc` for Bash, and ask for confirmation. If the user did not name a
     shell, ask which profile to update and offer common choices: `~/.zshrc`,
     `~/.bashrc`, or no profile edit.
   - Create the profile file if it does not exist.
   - Preserve user content.
   - Append the managed source block near the end of the profile so it runs
     after earlier PATH setup. Do not insert it before later lines that reset or
     export PATH.
   - Use a clearly marked block:

     ```bash
     # >>> moos-ivp repo: <repo-name> >>>
     [ -f "<absolute-repo-path>/env.sh" ] && . "<absolute-repo-path>/env.sh"
     # <<< moos-ivp repo: <repo-name> <<<
     ```

   - If the user opted out, leave the profile unchanged and tell them they can
     run `. <repo>/env.sh` in a shell session.
10. Validate the baseline.
   - Run `./build.sh` from a normal tool-capable shell, not from a shell whose
     profile has hidden basic build tools. The repo CMake should already have
     the resolved `moos-ivp` path wired in, so build validation should not
     depend on `MOOS_IVP_ROOT` being exported.
   - If examples were retained, confirm:
     - `bin/pXRelayTest` exists and is executable
     - `lib/libBHV_SimpleWaypoint.dylib` on macOS or
       `lib/libBHV_SimpleWaypoint.so` on Linux exists
   - Validate `<repo>/env.sh` separately by sourcing it in a shell and
     confirming the new absolute `bin`, `scripts`, and `lib` paths appear in
     `PATH` / `IVP_BEHAVIOR_DIRS`.
   - If a persistent profile source block was added, validate that applying the
     selected profile reaches the same environment.
   - If sourcing the user's profile hides build tools such as `mkdir`, `make`,
     or `cmake`, report that as a profile/tooling issue, not as a repo build
     failure.
   - Run `which pXRelayTest` or `command -v pXRelayTest` only after applying
     `<repo>/env.sh` or the selected profile.
11. Initialize the first commit when the user asked for Git setup or when they
    asked for a ready fresh repo, but only if Git identity is already
    configured or the user supplied both a commit author name and email.
    Repository author text collected earlier is for project files, not enough
    to invent a Git committer email:

    ```bash
    git add .
    git commit -m "chore: initialize MOOS-IvP extension repo"
    ```

    Skip the commit if Git user identity is missing and report the exact
    blocker instead of inventing identity values. Do not ask for Git email
    during the initial setup unless the user specifically wants the first
    commit completed in the same turn.
12. If no remote was attached, mention the natural next step: create an empty
    GitHub repository under the user's account or organization, add it as
    `origin`, and push `main`. Do not perform this unless the user explicitly
    asks. Remind the user that if their GitHub credentials are connected, the
    AI agent can create the GitHub repo, add the remote, and push for them.

## Environment Editing Rules

- Expand `~` to an absolute path before writing shell profile blocks.
- Quote paths in shell exports.
- Do not edit any shell profile unless the user opts into persistent shell
  integration and confirms the profile path.
- Do not remove an existing matching block for another repo.
- If replacing a block for the same repo path, replace only the managed block
  with the same marker.
- Keep profile edits idempotent: running the skill twice should not append
  duplicate path entries.
- Keep the repo-local `env.sh` as the source of the PATH and
  `IVP_BEHAVIOR_DIRS` details; shell profiles should only source that file.

## Validation Checklist

- Target repo was cloned from the intended template.
- Template `.git/` was removed before `git init`.
- `git remote -v` is empty unless the user asked to attach a remote.
- The resolved local `moos-ivp` checkout was validated.
- The new repo's build can find the resolved `moos-ivp` checkout, even when the
  repo is not a sibling of `moos-ivp`.
- `./build.sh` succeeds, or the exact compiler/configuration blocker is
  reported.
- `PATH` and `IVP_BEHAVIOR_DIRS` setup was written to `<repo>/env.sh`.
- If requested, the selected shell profile sources `<repo>/env.sh`.
- Generated `bin/` and `lib/` artifacts are not treated as source changes.
- Final message names the new repo path, env file path, profile path if
  updated, validation result, and the next appropriate skills.
- If `git remote -v` is empty, final message suggests publishing the repo as an
  optional next step and says the AI agent can do it for the user when GitHub
  credentials are connected.

## Failure Handling

- Missing `MOOS_IVP_ROOT`: stop and ask for the local checkout path.
- Non-empty target path: stop unless the user explicitly asked to reuse it.
- Clone failure: report the template URL and Git error.
- Build failure: report the first actionable CMake or compiler error.
- Shell profile write failure: leave the repo intact and tell the user to
  source `<repo>/env.sh` manually.
- Git commit failure due to identity: leave files initialized and staged state
  as-is; tell the user to configure Git identity.
