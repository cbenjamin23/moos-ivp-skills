# Customizing Skills

The installed plugin provides reusable defaults, but it does not need to own
the style of every project. You can keep the plugin installed while supplying a
local version of one skill for your naming, source layout, build conventions,
shell setup, validation policy, or organizational workflow.

This is useful when you want to customize one workflow, such as
`moos-app-builder`, without forking or editing the complete plugin.

## Recommended Pattern

Create a standalone local skill with the same unqualified name as the plugin
skill. In its frontmatter description, identify it as the preferred local
replacement and preserve an exception for explicit requests for the original
plugin skill.

For example:

```yaml
---
name: moos-app-builder
description: >-
  Preferred local replacement for moos-ivp-skills:moos-app-builder. Use this
  skill for MOOS app creation or modification whenever both versions are
  available. Use the plugin-namespaced version only when the user explicitly
  requests it.
---
```

Put the preference in `description`, not only in the skill body. Codex and
Claude Code use skill metadata to decide which skill is relevant before loading
the full `SKILL.md` instructions.

The local skill can be a modified copy of the bundled skill or a smaller
workflow written from scratch. Keep the `name` unchanged when you want other
MOOS-IvP skills that refer to `moos-app-builder` to find the local workflow.

## Local Skill Locations

### Codex

For a repository-specific customization, use:

```text
<repo>/.agents/skills/moos-app-builder/SKILL.md
```

For a personal skill used across repositories, use the personal skills
directory supported by your Codex installation. Current Codex documentation
uses:

```text
~/.agents/skills/moos-app-builder/SKILL.md
```

Some installations and skill-management tools use the Codex home directory
instead:

```text
~/.codex/skills/moos-app-builder/SKILL.md
```

Use the location already shown by your Codex Skills interface or created by
`$skill-creator`. A repository-local `.agents/skills` copy is the clearest
choice when the customization belongs to one project.

### Claude Code

For a project-specific customization, use:

```text
<repo>/.claude/skills/moos-app-builder/SKILL.md
```

For a personal customization used across projects, use:

```text
~/.claude/skills/moos-app-builder/SKILL.md
```

If the same repository supports both Codex and Claude Code, provide the skill
through each product's standalone skill location. Keep one canonical copy in
your own project if you need to synchronize them.

## What Each Name Selects

Plugin skills are namespaced. A local standalone skill keeps the short,
unqualified name, while the installed plugin copy remains explicitly
addressable.

| Intent | Codex | Claude Code |
| --- | --- | --- |
| Use the preferred local skill | `$moos-app-builder` | `/moos-app-builder` |
| Use the original plugin skill | `$moos-ivp-skills:moos-app-builder` | `/moos-ivp-skills:moos-app-builder` |

An explicit plugin-qualified request should win over the local preference. The
recommended description deliberately preserves this escape hatch.

## Automatic and Cross-Skill Selection

If a user asks to build a MOOS app without naming a skill, the model selects a
skill from the available metadata. The local skill has several favorable
signals:

1. It owns the exact unqualified name.
2. Its description declares it to be the preferred local workflow.
3. The plugin copy has a qualified name.
4. A repository-local skill carries project-specific context.

The same signals apply when another skill says to use `moos-app-builder`. This
lets `moos-ivp-repo-builder` and `moos-ivp-mission-builder` continue to use an
unqualified dependency name while allowing a user to customize the app-building
workflow.

Automatic selection is still model-mediated. Namespacing and the preference
description make the intended choice strong and clear, but they are not a
permanent loader-level override contract. If the distinction matters for one
request, invoke the desired skill explicitly.

## Codex and Claude Code Nuance

Codex exposes plugin skills under qualified runtime names such as
`moos-ivp-skills:moos-app-builder`. Current behavior strongly favors the local
skill for the unqualified name. In scratch testing with both versions enabled:

- an explicit unqualified invocation selected the local skill;
- an adjacent plugin skill referring to `moos-app-builder` selected the local
  skill;
- three fresh natural-language MOOS app requests selected the local skill; and
- an explicit qualified invocation selected the plugin skill.

Claude Code explicitly documents plugin skill namespacing. The local
`/moos-app-builder` and plugin `/moos-ivp-skills:moos-app-builder` therefore
remain separate commands. For standalone skills that share a name across
Claude Code levels, its documented precedence is enterprise, then personal,
then project. That standalone precedence does not remove the separately
namespaced plugin skill.

## Updates and Maintenance

Plugin updates do not overwrite a standalone local skill. This makes local
customization more durable than editing files inside an installed plugin cache.
However, the bundled skill may gain fixes or new capabilities over time.
Periodically compare your local version with the current plugin version and
adopt the upstream changes that are relevant to your workflow.

Avoid modifying cached plugin files directly. Cache paths can contain plugin
versions and are replaced during updates.

Disabling the plugin copy is usually unnecessary because the qualified plugin
name and unqualified local name can coexist. Codex can disable a skill by its
exact `SKILL.md` path, but local testing showed that a versioned cache path can
change during a plugin update, leaving the old disable entry pointing at a path
that is no longer active. Prefer the local-name pattern unless duplicate
visibility causes a concrete problem.

## Scope of Customization

Use a local skill to express choices that genuinely belong to the user or
project, including:

- C++ and mission-file style;
- app or behavior scaffolding conventions;
- repository layout and build wiring;
- environment and `PATH` setup;
- validation commands and test policy; and
- organization-specific metadata or documentation practices.

The bundled skill remains a fallback and a source of upstream improvements.
The local skill should state the user's desired workflow directly rather than
depending only on instructions to ignore another skill.

## Further Reading

- [Codex: Build skills](https://learn.chatgpt.com/docs/build-skills)
- [Codex: Build plugins](https://learn.chatgpt.com/docs/build-plugins)
- [Claude Code: Extend Claude with skills](https://code.claude.com/docs/en/slash-commands)
- [Claude Code: Create plugins](https://code.claude.com/docs/en/plugins)
