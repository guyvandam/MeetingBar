# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MeetingBar is a macOS menu-bar app (macOS 10.15+) written in Swift that shows upcoming calendar events and lets users join meetings with one click. It integrates with 50+ meeting services.

## Building Locally

To build, you must configure your Apple development team. Create `XCConfig/DevTeamOverride.xcconfig` with:
```
DEVELOPMENT_TEAM = <your development team id>
```

For Google Calendar integration, `XCConfig/Project.xcconfig` also requires:
- `GOOGLE_CLIENT_NUMBER`
- `GOOGLE_CLIENT_SECRET`
- `GOOGLE_AUTH_KEYCHAIN_NAME`

Build and test via Xcode or `xcodebuild`:
```bash
# Build
xcodebuild -project MeetingBar.xcodeproj -scheme MeetingBar build

# Run all tests
xcodebuild -project MeetingBar.xcodeproj -scheme MeetingBarTests test

# Run a single test class
xcodebuild -project MeetingBar.xcodeproj -scheme MeetingBarTests test -only-testing:MeetingBarTests/EventFilteringTests
```

## Architecture

### Entry Point & Lifecycle
- `App/AppDelegate.swift` — `@main` app delegate. Initializes `StatusBarItemController` and `EventManager`, wires up notification handling, registers keyboard shortcuts, and manages all app windows (onboarding, preferences, changelog, fullscreen notification).

### Data Layer
- `Core/EventStores/Protocol.swift` — `EventStore` protocol with `signIn`, `fetchAllCalendars`, `fetchEventsForDateRange`.
- `Core/EventStores/EKEventStore.swift` — macOS EventKit implementation (default).
- `Core/EventStores/GCEventStore.swift` — Google Calendar API implementation via OAuth (AppAuth).
- `Core/Models/MBEvent.swift` — Central event model. On init, it auto-detects meeting links from `location`, `url`, and `notes` fields by calling `detectMeetingLink()`. Also normalizes midnight-to-midnight events as all-day.
- `Core/Models/MBCalendar.swift` — Calendar model wrapping calendar source info.
- `Core/Models/MBEvent+Helpers.swift` — Array extension with `filtered()` (applies user Defaults-driven filters) and `nextEvent()` (finds the next joinable event).
- `Core/Managers/EventManager.swift` — `@ObservableObject` that owns the `EventStore` and publishes `calendars` and `events`. Triggers refreshes via Combine from: a periodic timer (180s), `Defaults` key changes, and manual `refreshSubject`. Has a `#if DEBUG` test initializer accepting an injected store.
- `Core/Managers/ActionsOnEventStart.swift` — Polls every 10 seconds for event-start actions: fullscreen notification, auto-join, AppleScript execution, and snooze-until-dismissed notifications.

### UI Layer
- `UI/StatusBar/StatusBarItemController.swift` — Owns the `NSStatusItem`. Calls `updateTitle()` to render next event in the menu bar and `updateMenu()` to rebuild the dropdown. Right-click joins next meeting; left-click opens the menu.
- `UI/StatusBar/MenuBuilder.swift` — Assembles `NSMenuItem` sections: event list, join section, bookmarks, preferences.
- `UI/Views/` — SwiftUI views for Preferences (tabs: General, Appearance, Calendars, Links, Advanced), Onboarding, Changelog, Fullscreen Notification, and the timeline visualization.

### Services & Utilities
- `Services/MeetingServices.swift` — `MeetingServices` enum (50+ values) and `detectMeetingLink()` / `openMeetingURL()` logic. To add a new meeting service, add a case here with its URL pattern regex.
- `Extensions/DefaultsKeys.swift` — All `Defaults.Keys` (using the [Defaults](https://github.com/sindresorhus/Defaults) library). All persistent user settings live here.
- `Extensions/KeyboardShortcutsNames.swift` — Global keyboard shortcut names (using [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)).
- `Utilities/I18N.swift` — Localization singleton. Strings use the `.loco()` String extension (e.g. `"key".loco()`), which routes through `I18N.instance`. Supports runtime language switching.
- `Utilities/Constants.swift` — App-wide enums for display settings, notification timing, browser config, window titles.
- `Utilities/Helpers.swift` — Free functions: `openMeetingURL`, `addInstalledBrowser`, `openLinkFromClipboard`, etc.

### Key Dependencies
- **Defaults** — Type-safe `UserDefaults` wrapper; all settings accessed via `Defaults[.keyName]`.
- **KeyboardShortcuts** — Global hotkey registration.
- **SwiftyStoreKit** — In-app purchases for patronage.
- **AppAuth** — OAuth for Google Calendar.

## Localization

All user-visible strings use `.loco()`. Localization files are in `MeetingBar/<lang>.lproj/Localizable.strings`. When adding new strings, add the key/value to the English strings file first.

## Testing

Tests are in `MeetingBarTests/`. `BaseTestCase` snapshots and restores `UserDefaults` around each test, so tests start with clean defaults. The `EventManager` has a `#if DEBUG` initializer for injecting a mock `EventStore`.

## Data Flow Summary

```
EventStore (EK or GC API)
    └─> EventManager (Combine, @Published events)
            └─> AppDelegate (sink) → StatusBarItemController
                    ├─> updateTitle() [menu bar text]
                    └─> updateMenu() [dropdown items via MenuBuilder]
                            └─> ActionsOnEventStart (timer, auto-join/notification/script)
```
