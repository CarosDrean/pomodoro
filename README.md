# Pomodoro

A minimal macOS menu bar Pomodoro timer built with SwiftUI and AppKit.

## Features

- **Menu bar app** — lives in your menu bar, no Dock icon
- **Click to open** — click the icon to show/hide the popover
- **Click circle to toggle** — tap the timer circle or play button to start/pause
- **Auto-countdown** in the menu bar next to the icon
- **Dynamic icon color** — red (focus), green (short break), blue (long break)
- **Auto-start** — automatically advances to the next session
- **Intrusive break mode** — floating alert with cat image + motivational phrase every 0.5s during breaks
- **Break pause** — hide the break alert for 15s, then it reappears with a new cat and phrase
- **Tap to refresh** — tap the cat image during a break to get a new cat + phrase
- **Skip from alert** — skip the current session directly from the floating alert
- **Alert sound picker** — choose from system sounds (Glass, Ping, Pop, etc.)
- **Settings** — customize focus, break, and long break durations
- **Session tracking** — see how many pomodoros you completed today
- **Dark/Light mode** — icon adapts to your menu bar appearance

## Default Pomodoro Cycle

25 min focus → 5 min short break (×4) → 15 min long break → repeat

## Requirements

- macOS 14.0+
- Xcode 16+
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (for building from terminal)

## Build & Run

```bash
# Install xcodegen if you don't have it
brew install xcodegen

# Generate Xcode project
cd pomodoro
xcodegen generate

# Build
xcodebuild -scheme Pomodoro -destination 'platform=macOS' build

# Or open in Xcode
open Pomodoro.xcodeproj
```

## Install

Copy `Pomodoro.app` to `/Applications`:

```bash
cp -R ~/Library/Developer/Xcode/DerivedData/Pomodoro-adctipjngqjmosfnmfkfejxjtmlw/Build/Products/Debug/Pomodoro.app /Applications/
```

## Usage

| Action | How |
|---|---|
| Open popover | Click the menu bar icon |
| Start / Pause timer | Click the timer circle or play button |
| Reset | Click the reset button (rewind icon) |
| Skip session | Click the skip button (forward icon) |
| Settings | Click the gear icon |
| History | Click the "X today" counter |
| Quit | Click the power button |

## Project Structure

```
Pomodoro/
├── PomodoroApp.swift           # App entry point + AppDelegate (NSStatusItem, floating alert window)
├── Info.plist                   # LSUIElement = true (menu bar only)
├── Models/
│   └── PomodoroState.swift     # TimerPhase, SessionRecord
├── ViewModels/
│   └── TimerViewModel.swift    # Timer logic, session cycling, cat image fetching
├── Views/
│   ├── TimerView.swift         # Main timer UI
│   ├── FloatingAlertView.swift # Break/focus floating alert with cat image
│   ├── SettingsView.swift      # Duration settings, alert sound, intrusive mode toggle
│   ├── SessionHistoryView.swift # Today's session history
│   └── PopoverContent.swift    # Navigation wrapper for popover
└── Utilities/
    ├── Defaults.swift          # UserDefaults persistence
    ├── SoundManager.swift      # Alert sound playback
    └── ViewModifiers.swift     # Custom cursor modifier
```
