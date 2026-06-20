---
name: moos-ivp-installer
description: "Install or validate upstream MOOS-IvP: locate or clone moos-ivp/moos-ivp, follow the platform setup README, create env.sh, and verify the checkout for MOOS-IvP development."
---

# MOOS-IvP Installer

## Overview

Use this skill to get a working local checkout of upstream MOOS-IvP. Keep the
install simple: clone or locate the checkout, follow the upstream setup README,
then add the small environment setup the other MOOS-IvP skills expect.

After this skill succeeds, the machine should be ready for MOOS-IvP extension
repo, app, behavior, or mission work.

## Defaults

- Source repo: `https://github.com/moos-ivp/moos-ivp.git`
- SSH form when requested: `git@github.com:moos-ivp/moos-ivp.git`
- Default install path: `~/moos-ivp`
- Environment file: `<moos-ivp-root>/env.sh`
- Dependencies and build commands: follow the relevant upstream setup README
- Persistent shell profile edits: ask first

## Confirm Before Changes

Before cloning, installing packages, building, creating `env.sh`, or editing a
shell profile:

1. Do non-destructive discovery first: look for an existing checkout, resolve
   the likely install path, and choose the platform setup README.
2. Ask for any missing user choices: install location and whether to add
   persistent shell integration.
3. Summarize the resolved path, clone URL if cloning, branch or tag if
   requested, selected README, and shell-profile choice in one concise
   sentence.
4. Proceed when the user has already given explicit approval, or after they
   confirm the summary. Still ask before package-manager, `sudo`, or shell
   profile edits unless that specific approval was already given.

## Workflow

1. Check whether the user already has a valid checkout.
   - Try an explicit user path first.
   - Then try `MOOS_IVP_ROOT`.
   - Then try common paths such as `~/moos-ivp`, `~/src/moos-ivp`,
     `~/repos/moos-ivp`, and `~/projects/moos-ivp`.
   - Treat a checkout as valid when it has `ivp/src`, `build-moos.sh`,
     `build-ivp.sh`, `scripts/GenMOOSApp_AppCasting`, and
     `scripts/GenBehavior`.
2. If no checkout exists, confirm the target path before cloning.
3. Clone with the confirmed source URL:

   ```bash
   git clone https://github.com/moos-ivp/moos-ivp.git <target-root>
   ```

   If the user requests a branch or tag, include it in the clone or checkout
   plan before building.

4. Choose the relevant setup README from the checkout:
   - macOS: `README-OS-X.txt`
   - GNU/Linux: `README-GNULINUX.txt`
   - Windows: `README-WINDOWS.txt`
5. Read the selected README and follow its dependency and build instructions.
   Ask before running package-manager or sudo commands.
6. Create the checkout-local shell environment file.
   - Write `<moos-ivp-root>/env.sh`.
   - Resolve the absolute checkout path before writing the file.
   - Write expanded absolute paths inside `env.sh`, not `~` or `$HOME`.
   - Make repeated sourcing idempotent so `PATH` does not accumulate duplicate
     entries.
   - Keep the file source-compatible with common Bash and zsh startup files.
   - Only set `MOOS_IVP_ROOT` and `PATH` for the core checkout. Do not set
     `IVP_BEHAVIOR_DIRS` here; extension repos own their behavior library
     paths.
   - Use this shape:

   ```bash
   #!/usr/bin/env bash
   # Source this file to use this MOOS-IvP checkout.
   export MOOS_IVP_ROOT="<absolute-moos-ivp-root>"
   case ":$PATH:" in *":<absolute-moos-ivp-root>/bin:"*) ;; *) PATH="$PATH:<absolute-moos-ivp-root>/bin" ;; esac
   case ":$PATH:" in *":<absolute-moos-ivp-root>/scripts:"*) ;; *) PATH="$PATH:<absolute-moos-ivp-root>/scripts" ;; esac
   export PATH
   ```

7. If the user opted into persistent shell integration, update the selected
   shell profile.
   - Do not require the user to already know shell profile details. If the user
     named a shell, suggest its usual profile, such as `~/.zshrc` for zsh or
     `~/.bashrc` for Bash, and ask for confirmation. If the user did not name a
     shell, ask which profile to update and offer common choices: `~/.zshrc`,
     `~/.bashrc`, or no profile edit.
   - Create the profile file if it does not exist.
   - Preserve user content.
   - Append the managed source block near the end of the profile so it runs
     after earlier `PATH` setup. Do not insert it before later lines that reset
     or export `PATH`.
   - Use a clearly marked block:

   ```bash
   # >>> moos-ivp core >>>
   [ -f "<absolute-moos-ivp-root>/env.sh" ] && . "<absolute-moos-ivp-root>/env.sh"
   # <<< moos-ivp core <<<
   ```

   - If the user opted out, leave the profile unchanged and tell them they can
     run `. <moos-ivp-root>/env.sh` in a shell session.

   Creating `env.sh` is the normal local shell setup for this skill. Adding the
   profile source block is the separate persistent terminal setup that requires
   explicit user approval.

8. Validate:

   ```bash
   <skill-dir>/scripts/validate_moos_ivp_install.sh <moos-ivp-root>
   ```

   Run this after the README build steps and `env.sh` creation. For earlier
   discovery, use the structural checkout checks in step 1. Treat any
   `fail - ...` line as the concise reason to report or fix.

## Failure Handling

- If dependencies are missing, report the README consulted and the missing
  package or tool.
- If build fails, report the first actionable compiler, linker, CMake, or
  missing-library error.
- If profile editing fails, leave the checkout intact and tell the user to
  source `env.sh` manually.
