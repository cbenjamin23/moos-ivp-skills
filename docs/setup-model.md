# Setup Model

## Goal

Keep skill content portable while still letting users point agents at their
local MOOS-IvP checkout, missions-auto clone, extension repos, and author
identity.

## Configuration Order

Skills should resolve local MOOS context in this order:

1. `MOOS_IVP_SKILLS_CONFIG`
2. `~/.config/moos-ivp-skills/config.toml`
3. explicit paths in the user's request
4. current workspace and nearby parent/sibling directories
5. common home-directory locations such as `~/moos-ivp`

## Do Not Rewrite Skills During Setup

Installer or setup scripts should not patch `SKILL.md` files with local paths.
That makes updates brittle. Prefer writing a small config file and teaching
skills to consult it.

## Useful Scripts

- `configure-moos-skills.sh` - write local config from flags or prompts.
- `discover-moos-env.sh` - report likely MOOS-IvP, missions-auto, and harness repos.
- `validate-moos-env.sh` - check expected scripts, apps, and log tools exist.
- `validate-skills.sh` - check skill frontmatter and reference links.

