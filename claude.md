# Antire Project Setup

## Required Plugin

This project uses the `antire-standards` plugin. Before doing any development work,
verify the plugin is installed by checking if the following skills are available:

- `/python-standards`
- `/module-discovery`
- `/cross-repo-workflow`

If any of these skills are not available, ask the developer to install the plugin:

```
/plugin marketplace add Antire-AS/antire-claude-plugins
/plugin install antire-standards
```

**Do not write or modify Python code until the plugin is confirmed installed.**

## Git SSH Access

Before starting any work, verify the developer has SSH access to GitHub:

```bash
ssh -T git@github.com
```

If this returns "Permission denied" or hangs, guide the developer through SSH setup:

1. Check for existing keys: `ls ~/.ssh/id_ed25519.pub 2>/dev/null || ls ~/.ssh/id_rsa.pub 2>/dev/null`
2. If no key exists, generate one: `ssh-keygen -t ed25519 -C "<their-email>"`
3. Copy the public key: `pbcopy < ~/.ssh/id_ed25519.pub`
4. Tell them to add it at https://github.com/settings/ssh/new
5. Re-run `ssh -T git@github.com` to confirm

**Do not proceed with `/module-discovery` or `/cross-repo-workflow` until SSH access is confirmed.**

## Shared Modules

This project uses `antire-python-modules`. Use `/module-discovery` before creating
any new port, adapter, or domain entity.

## Python Standards

All Python code in this project must follow instructions from the `/python-standards` skill