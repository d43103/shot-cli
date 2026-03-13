---
name: screenshot
description: This skill should be used when the user asks to take a screenshot, capture a window, or when visual inspection of an application is needed for debugging. Triggers on requests like "take a screenshot", "capture Safari", "show me what's on screen", "스크린샷 찍어줘", or when the agent needs to visually verify UI state.
---

# Screenshot

Capture macOS screenshots using the `shot-cli` CLI tool. Supports interactive selection, app-targeted capture, and coordinate-based capture. Output is saved as PNG files that Claude can read directly via the Read tool.

## Prerequisites

The `shot-cli` binary must be available in PATH. Before any capture, verify installation:

```bash
which shot-cli
```

If not found, install via one of the methods below:

**Homebrew (recommended):**
```bash
brew install d43103/tap/shot-cli
```

**Build from source:**
```bash
git clone https://github.com/d43103/shot-cli.git /tmp/shot-cli
cd /tmp/shot-cli
swift build -c release 2>&1 | tail -5
mkdir -p ~/.local/bin
cp .build/release/shot-cli ~/.local/bin/shot-cli
rm -rf /tmp/shot-cli
```

Verify after install:

```bash
shot-cli --version
```

## Workflow

### 1. Determine capture target

Ask the user what to capture, or determine from context. Choose the appropriate mode:

| Scenario | Command |
|----------|---------|
| User specifies an app | `shot-cli --app <AppName>` |
| Need to find windows first | `shot-cli --list` → analyze → `--app` or `--rect` |
| User wants to select area | `shot-cli` (interactive region selection) |
| User wants specific window click | `shot-cli --window` |
| Full screen needed | `shot-cli --full` |
| Exact coordinates known | `shot-cli --rect x,y,w,h` |

### 2. Capture and read

To capture and have Claude view the result, save to a file and read it:

```bash
shot-cli --app Safari -o /path/to/screenshot.png
```

Then use the Read tool on the saved PNG file to view the screenshot.

### 3. AI-driven programmatic capture

For autonomous debugging workflows where the agent decides what to capture:

```bash
# Step 1: Discover available windows
shot-cli --list

# Step 2: Parse the JSON output to find target window
# Output: [{"app":"Safari","title":"GitHub","id":1234,"x":0,"y":25,"w":1440,"h":875}, ...]

# Step 3: Capture the specific app or region
shot-cli --app Safari -o screenshot.png
# or for a precise region:
shot-cli --rect 0,25,1440,875 -o screenshot.png
```

### 4. Multiple app capture

To capture multiple apps at once:

```bash
shot-cli --app Safari --app Terminal --json
```

JSON output schema:
```json
[
  {"index": 0, "app": "Safari", "title": "GitHub", "base64": "iVBORw..."},
  {"index": 1, "app": "Terminal", "title": "zsh", "base64": "iVBORw..."}
]
```

## Output options

Base64 is always printed to stdout. Additional output flags are additive:

| Flag | Effect |
|------|--------|
| `-o path` | Save to file (implies `--file`) |
| `--file` | Save to `~/Desktop/shot-cli-{timestamp}.png` |
| `--clipboard` | Copy to clipboard |
| `--json` | Output as JSON array |

## Error handling

| Exit code | Meaning | Action |
|-----------|---------|--------|
| 0 | Success | — |
| 1 | Screen Recording permission missing | Guide user to System Settings > Privacy & Security > Screen Recording |
| 2 | App not found | Check app name with `--list`, suggest correction |
| 3 | Capture failed | Retry or try different capture mode |
| 130 | User cancelled | No action needed |

## Important notes

- Interactive modes (`shot-cli`, `shot-cli --window`) require user interaction — do not use in fully automated pipelines without informing the user.
- `--list` and `--app` require Screen Recording permission. If `--list` returns empty, guide the user to grant permission.
- App name matching is case-insensitive and uses contains-matching (e.g., `--app code` matches "Visual Studio Code").
