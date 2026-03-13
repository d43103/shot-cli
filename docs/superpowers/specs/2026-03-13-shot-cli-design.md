# shot-cli: macOS CLI Screenshot Tool

## Purpose

AI 디버깅 워크플로우를 위한 macOS CLI 스크린샷 도구. 사람이 인터랙티브하게 사용하거나, AI가 프로그래매틱하게 특정 영역/앱을 캡처할 수 있다.

## Architecture

```
shot (Swift CLI)
├── ArgumentParser  ─ 명령어 파싱
├── WindowManager   ─ CGWindowList로 앱 이름 → windowID 매핑
├── Capturer        ─ screencapture 프로세스 실행
└── OutputHandler   ─ base64 / 파일 저장 / 클립보드
```

**Approach:** `screencapture` 명령어 래퍼. 인터랙티브 캡처는 OS 네이티브, 윈도우 탐색만 `CGWindowListCopyWindowInfo` 사용.

**Dependencies:** `apple/swift-argument-parser` (~> 1.3)

**Minimum:** macOS 13+ (Ventura)

## Phases

### Phase 1 (MVP)

단일 캡처에 집중. 인터랙티브 + 프로그래매틱 모드 모두 지원.

### Phase 2 (Future)

- `--session`: 연속 캡처 모드 (Enter로 계속, q로 종료, 시그널 핸들링)
- `-n N`: 캡처 N회 반복
- SessionRunner 모듈 추가

## CLI Interface (Phase 1)

### Interactive (Human)

| Command | Action |
|---------|--------|
| `shot` | Region selection (Shift+Cmd+4 style) |
| `shot --window` | Click to select window |
| `shot --full` | Full screen capture |

### Programmatic (AI)

| Command | Action |
|---------|--------|
| `shot --list` | Window list as JSON |
| `shot --app Safari` | Capture window by app name |
| `shot --app Safari --app Terminal` | Capture multiple apps |
| `shot --rect 0,25,1440,875` | Capture specific coordinates (x,y,w,h) |

### Output Options

**Default: base64 to stdout.** `--file`, `--clipboard`는 base64에 추가되는 동작 (base64는 항상 출력).

| Flag | Action |
|------|--------|
| (none) | base64 to stdout |
| `--file` | base64 stdout + save to `~/Desktop/shot-{timestamp}.png` |
| `-o ./output.png` | base64 stdout + save to specified path (`--file` implied) |
| `--clipboard` | base64 stdout + copy to clipboard |
| `--json` | Multiple results as JSON array (single capture도 배열) |

**`--json` output schema:**

```json
[
  {
    "index": 0,
    "app": "Safari",
    "title": "GitHub",
    "base64": "iVBORw0KGgo..."
  }
]
```

`app`, `title`은 `--app` 모드에서만 포함. 인터랙티브 캡처 시 생략.

**Multiple capture without `--json`:** `--app` 복수 지정 시 `--json` 없으면 base64를 줄바꿈(`\n`)으로 구분하여 출력.

### Flag Constraints

- `--list`는 다른 캡처/출력 플래그와 병용 불가. 단독 사용.
- `--full`, `--window`, `--app`, `--rect`는 상호 배타. 미지정 시 기본 영역 선택.
- `-o`는 `--file`을 암시적으로 활성화.

## Core Modules

### WindowManager

```swift
struct WindowInfo: Codable {
    let app: String       // App name
    let title: String     // Window title
    let id: Int           // CGWindowID (for screencapture -l)
    let x, y, w, h: Int  // Window bounds
}

func listWindows() -> [WindowInfo]
func findWindows(app: String) -> [WindowInfo]
```

- `CGWindowListCopyWindowInfo` wrapping
- App name matching: case-insensitive, contains-based
- Multiple windows per app: frontmost window selected

**Permission handling:**
- `CGWindowListCopyWindowInfo`가 빈 배열을 반환하면 Screen Recording 권한 부재로 판단
- `--list`, `--app` 사용 시 권한 없으면 에러 메시지 + System Preferences 안내 출력
- `-i`, `-iw` (인터랙티브) 모드는 권한 없이도 동작

### Capturer

`screencapture` process wrapper.

| Mode | screencapture flags |
|------|-------------------|
| Region selection | `-i` |
| Window selection | `-iw` |
| Full screen | (none) |
| By app | `-l <windowID>` |
| By coordinates | `-R x,y,w,h` |

Temp file flow: capture to `FileManager.default.temporaryDirectory` → pass to OutputHandler → cleanup.

Note: `screencapture -l <windowID>` — macOS 13+에서 동작 검증 필요. 구현 시 fallback으로 `-R`(bounds 기반) 캡처 고려.

### OutputHandler

- `base64`: Read file, encode, write to stdout (always active)
- `file`: Copy to target path or `~/Desktop/shot-{timestamp}.png`
- `clipboard`: Set image data via `NSPasteboard`

## Error Handling

- **Permission denied (programmatic):** `CGWindowListCopyWindowInfo` 빈 배열 → Screen Recording 권한 안내
- **Permission denied (capture):** `screencapture` 결과 파일 크기 0 → 에러 메시지
- **App not found:** Error + suggest similar app names (contains-based)
- **Multiple windows:** Select frontmost window for the app
- **User cancelled:** `screencapture -i`에서 ESC → exit code 비정상 → 조용히 종료

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Permission error (Screen Recording) |
| 2 | App not found |
| 3 | Capture failed (empty file, process error) |
| 130 | User cancelled (ESC, Ctrl+C) |

## Project Structure

```
shot-cli/
├── Package.swift
├── Sources/
│   └── shot/
│       ├── Shot.swift                 # @main, ArgumentParser entry
│       ├── Commands/
│       │   ├── CaptureCommand.swift   # Default capture (region/window/full/app/rect)
│       │   └── ListCommand.swift      # --list window list
│       ├── Core/
│       │   ├── WindowManager.swift    # CGWindowList wrapping
│       │   ├── Capturer.swift         # screencapture process execution
│       │   └── OutputHandler.swift    # base64 / file / clipboard
│       └── Models/
│           └── WindowInfo.swift       # Window info model
└── Tests/
    └── ShotTests/
        ├── WindowManagerTests.swift
        ├── CapturerTests.swift
        └── OutputHandlerTests.swift
```

## Build & Install

```bash
swift build -c release
cp .build/release/shot /usr/local/bin/
```

## Phase 2: Session & Batch Capture

Phase 1 안정화 후 추가할 기능들.

### CLI (Phase 2)

| Command | Action |
|---------|--------|
| `shot --session` | Continuous capture, q to quit |
| `shot -n 3` | Repeat region selection 3 times |

### SessionRunner Module

```
shot-cli/
└── Sources/
    └── shot/
        ├── Commands/
        │   └── SessionCommand.swift   # --session continuous capture
        └── Core/
            └── SessionRunner.swift    # Session loop + signal handling
```

- Loop: capture → collect result → prompt "Enter to continue, q to quit"
- On quit: output all collected results at once
- Ctrl+C also exits (signal handler)
- Failed captures skip with warning, session continues
- `-n N`과 `--session`은 상호 배타. `-n`은 정해진 횟수, `--session`은 무한.
