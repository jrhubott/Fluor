# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build (requires Xcode; use DEVELOPER_DIR if xcode-select points to CommandLineTools)
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme Fluor -configuration Debug build

# Build without code signing (for development without matching certificates)
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme Fluor -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

There are no tests in this project. The project uses Xcode (not Swift Package Manager) as its build system.

## Architecture

Fluor is a macOS status bar app (Swift 5 / AppKit) that switches the keyboard's fn-key behavior (media keys vs F1-F12) based on the active application.

### Core Flow

```
AppDelegate → StatusMenuController (status bar item, Main.xib)
                ├── BehaviorController     — monitors active app, switches fn-key mode via FKeyManager
                ├── MenuItemsController    — manages menu UI (embeds 3 child ViewControllers)
                └── Window Controllers     — lazy-loaded via StoryboardInstantiable protocol
                    ├── PreferencesWindowController  (Preferences.storyboard)
                    ├── RulesEditorWindowController  (RulesEditor.storyboard)
                    ├── RunningAppWindowController   (RunningApps.storyboard)
                    └── AboutWindowController        (About.storyboard)
```

### Key Components

- **FKeyManager** (`Misc/FKeyManager.swift`) — IOKit interface that reads/writes the fn-key mode via `IOHIDSetCFTypeParameter` and `IORegistryEntryCreateCFProperty`. Requires Accessibility permissions.
- **BehaviorController** (`Controllers/BehaviorController.swift`) — Core logic: listens to NSWorkspace active-app changes, determines target FKeyMode from stored rules, and calls FKeyManager. Also handles Fn-key press detection for hybrid/key switch methods.
- **AppManager** (`Models/AppManager.swift`) — Singleton storing all persistent state via `@Defaults` property wrappers (from DefaultsWrapper SPM package). Holds the rule set, default mode, switch method, UI preferences.
- **StatusMenuController** (`Controllers/StatusMenuController.swift`) — Owns the NSStatusItem, delegates to BehaviorController and MenuItemsController, manages window controller lifecycle.

### Communication Pattern

Components communicate via paired Notification observer/poster protocols defined in `Protocols/NotificationHelpers.swift`:
- `BehaviorDidChange` — fn-key behavior changed for an app
- `SwitchMethodDidChange` — user changed switch method (window/hybrid/key)
- `MenuControlObserver/Poster` — menu open/close coordination

### Three Switch Methods (enum `SwitchMethod`)

1. **Window** — auto-switch based on frontmost app's stored rule
2. **Hybrid** — window mode + Fn-key press toggles current app's behavior
3. **Key** — Fn-key press toggles global default mode only

### Objective-C Interop

Bridged via `Fluor-Bridging-Header.h`:
- **LaunchAtLoginController** — manages login item registration
- **PFMoveApplication** — prompts to move app to /Applications (RELEASE builds only)

### SPM Dependencies

- **DefaultsWrapper** — `@Defaults` property wrapper for typed UserDefaults access
- **Sparkle** (v2.x) — auto-update framework (`SPUStandardUpdaterController` in Preferences.storyboard)
- **CoreGeometry** / **SmoothOperators** — geometry utilities and operator extensions

## Commit Guidelines

- Do not include "Co-Authored-By" lines or any Claude/AI attribution in commit messages.
