# shot-cli Skill Installation Guide

This document is intended for AI agents (Claude Code, etc.) to automatically install the `shot-cli` tool and its screenshot skill.

## Step 1: Install shot-cli binary

Check if already installed:

```bash
which shot-cli && shot-cli --version
```

If not found, install via Homebrew (preferred) or build from source:

**Homebrew:**
```bash
brew install d43103/tap/shot-cli
```

**Source build (fallback):**
```bash
git clone https://github.com/d43103/shot-cli.git /tmp/shot-cli-build
cd /tmp/shot-cli-build
swift build -c release 2>&1 | tail -5
mkdir -p ~/.local/bin
cp .build/release/shot-cli ~/.local/bin/shot-cli
rm -rf /tmp/shot-cli-build
```

Verify:
```bash
shot-cli --version
```

## Step 2: Install screenshot skill

Download the skill file and place it in the Claude Code commands directory:

```bash
mkdir -p ~/.claude/commands
curl -sL https://raw.githubusercontent.com/d43103/shot-cli/main/screenshot/SKILL.md -o ~/.claude/commands/screenshot.md
```

Verify:
```bash
cat ~/.claude/commands/screenshot.md | head -5
```

Expected output should contain `name: screenshot` in the YAML frontmatter.

## Step 3: Verify Screen Recording permission

```bash
shot-cli --list 2>&1 | head -3
```

If output contains "Screen Recording permission required":
1. Open **System Settings > Privacy & Security > Screen Recording**
2. Enable the terminal app (Terminal, Warp, iTerm2, etc.)
3. Restart the terminal app

## Done

The `screenshot` skill is now available. Test with:

```bash
shot-cli --app Finder -o /tmp/test-screenshot.png
```
