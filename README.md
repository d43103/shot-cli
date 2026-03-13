# shot-cli

macOS screenshot CLI for AI debugging workflows.

A thin wrapper around `screencapture` with base64 output, app-targeted capture, and window coordinate discovery.

## Install

```bash
swift build -c release
cp .build/release/shot-cli ~/.local/bin/shot-cli
```

## Usage

```bash
# Interactive region selection (Cmd+Shift+4 equivalent)
shot-cli

# Click to select a window
shot-cli --window

# Full screen capture
shot-cli --full

# Capture by app name
shot-cli --app Safari

# Capture multiple apps (requires --json)
shot-cli --app Safari --app Terminal --json

# Capture specific region
shot-cli --rect 0,25,1440,875

# List all windows as JSON
shot-cli --list
```

## AI Workflow

Programmatic capture workflow for AI agents:

```bash
# 1. Discover windows
shot-cli --list
# [{"app":"Safari","title":"GitHub","id":1234,"x":0,"y":25,"w":1440,"h":875}, ...]

# 2. Capture target app
shot-cli --app Safari -o screenshot.png

# 3. Or capture exact region
shot-cli --rect 0,25,1440,875 -o screenshot.png
```

## Output

Base64 is always printed to stdout. Additional output flags are additive:

| Flag | Effect |
|------|--------|
| `-o path` | Save to file |
| `--file` | Save to `~/Desktop/shot-cli-{timestamp}.png` |
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
