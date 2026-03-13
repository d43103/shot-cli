# shot

macOS screenshot CLI for AI debugging workflows.

A thin wrapper around `screencapture` with base64 output, app-targeted capture, and window coordinate discovery.

## Install

```bash
swift build -c release
cp .build/release/shot ~/.local/bin/shot
```

## Usage

```bash
# Interactive region selection (Cmd+Shift+4 equivalent)
shot

# Click to select a window
shot --window

# Full screen capture
shot --full

# Capture by app name
shot --app Safari

# Capture multiple apps (requires --json)
shot --app Safari --app Terminal --json

# Capture specific region
shot --rect 0,25,1440,875

# List all windows as JSON
shot --list
```

## AI Workflow

Programmatic capture workflow for AI agents:

```bash
# 1. Discover windows
shot --list
# [{"app":"Safari","title":"GitHub","id":1234,"x":0,"y":25,"w":1440,"h":875}, ...]

# 2. Capture target app
shot --app Safari -o screenshot.png

# 3. Or capture exact region
shot --rect 0,25,1440,875 -o screenshot.png
```

## Output

Base64 is always printed to stdout. Additional output flags are additive:

| Flag | Effect |
|------|--------|
| `-o path` | Save to file |
| `--file` | Save to `~/Desktop/shot-{timestamp}.png` |
| `--clipboard` | Copy to clipboard |
| `--json` | Output as JSON array |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Screen Recording permission missing |
| 2 | App not found |
| 3 | Capture failed |
| 130 | User cancelled |

## Requirements

- macOS 13+
- Screen Recording permission (System Settings > Privacy & Security > Screen Recording)

## License

MIT
