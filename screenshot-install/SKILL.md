---
name: screenshot-install
description: This skill should be used when the user asks to install shot-cli, set up screenshot tools, or when the screenshot skill reports that shot-cli is not found. Triggers on "install shot-cli", "shot-cli 설치", "screenshot tool setup", or when `which shot-cli` returns empty.
---

# Screenshot Install

Install the `shot-cli` macOS screenshot CLI tool. This skill handles installation, verification, and troubleshooting.

## Install Flow

### Step 1: Check if already installed

```bash
which shot-cli && shot-cli --version
```

If found and version prints, installation is complete. Skip remaining steps.

### Step 2: Check prerequisites

Verify macOS and Swift toolchain:

```bash
sw_vers --productVersion
swift --version 2>&1 | head -1
```

Requirements:
- macOS 13.0+
- Swift 5.9+ (included with Xcode 15+)

If Swift is not available, inform the user to install Xcode or Xcode Command Line Tools:
```bash
xcode-select --install
```

### Step 3: Install

Try Homebrew first. Fall back to source build if Homebrew is unavailable.

**Method A — Homebrew (preferred):**

```bash
brew install d43103/tap/shot-cli
```

If Homebrew is not installed or the tap fails, use Method B.

**Method B — Build from source:**

```bash
git clone https://github.com/d43103/shot-cli.git /tmp/shot-cli-build
cd /tmp/shot-cli-build
swift build -c release 2>&1 | tail -5
mkdir -p ~/.local/bin
cp .build/release/shot-cli ~/.local/bin/shot-cli
rm -rf /tmp/shot-cli-build
```

If `~/.local/bin` is not in PATH, add it:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
export PATH="$HOME/.local/bin:$PATH"
```

### Step 4: Verify installation

```bash
shot-cli --version
```

Expected output: version string (e.g., `0.1.0`).

### Step 5: Grant Screen Recording permission

Test if Screen Recording permission is granted:

```bash
shot-cli --list 2>&1 | head -3
```

If output contains "Screen Recording permission required", guide the user:

1. Open **System Settings > Privacy & Security > Screen Recording**
2. Enable the terminal app being used (Terminal, Warp, iTerm2, etc.)
3. Restart the terminal app

After granting permission, verify again:

```bash
shot-cli --list 2>&1 | head -3
```

A JSON array of windows confirms success.

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `swift: command not found` | Xcode not installed | `xcode-select --install` |
| Build fails with linker error | Xcode CLT version mismatch | `sudo xcode-select -s /Applications/Xcode.app` |
| `shot-cli: command not found` after install | `~/.local/bin` not in PATH | Add to `~/.zshrc` (see Step 3) |
| `--list` returns empty array | Screen Recording not granted | See Step 5 |
| `brew: command not found` | Homebrew not installed | Use Method B (source build) |
