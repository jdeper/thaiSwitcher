# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Install

```bash
./build.sh        # compiles Sources/ → build/ThaiSwitcher.app
./install.sh      # copies app to /Applications, removes quarantine flag
```

`build.sh` is a plain `swiftc` invocation — no Xcode project, no Package.swift. Compilation order in the script matters because Swift resolves types by file order when not using modules.

**First run after install:** macOS will prompt for Accessibility permission (System Settings → Privacy & Security → Accessibility). The app must be re-launched after granting it.

**Target:** `arm64-apple-macos12.0`. To support Intel or universal, change `-target` in `build.sh`.

## Architecture

ThaiSwitcher is a macOS menu-bar-only agent (`LSUIElement = true`, no Dock icon). All logic runs on the main run loop.

### Event flow

```
CGEventTap (cgSessionEventTap)
    │
    ├─ Cmd/Ctrl key → clear buffer, pass event through
    ├─ Backspace    → pop last char from buffer, pass through
    ├─ Shift+Backspace → consume event, call triggerConversion()
    ├─ Clear keys (Space/Enter/Tab/arrows) → clear buffer, pass through
    └─ Printable key → append unicode string to buffer, pass through
```

`KeyboardMonitor` builds a per-word buffer of `[String]` entries — one entry per keystroke. The buffer is what the user actually sees on screen (characters produced by the active layout, not raw keycodes).

### Conversion & retype

`triggerConversion()` in `KeyboardMonitor`:
1. Calls `ThaiConverter.isMostlyThai` to determine direction.
2. Calls `ThaiConverter.convert` to map the text.
3. Posts `N` synthetic backspaces (to `.cgAnnotatedSessionEventTap` — downstream of our tap, so they won't be re-intercepted).
4. After 30 ms, pastes the converted string via clipboard + Cmd+V, then calls `InputSourceManager.switchTo(thai:)`.
5. After 250 ms, restores the previous clipboard contents.

### Thai ↔ English mapping

`ThaiConverter` holds a static `engToThai: [Character: Character]` for the **Thai Kedmanee** layout (QWERTY position → Thai character, including shift variants). `thaiToEng` is its computed reverse.

**Critical:** conversion iterates `text.unicodeScalars`, not `text` (Swift `Character`). Thai combining vowels (ื ิ ี ้ ่ etc.) form grapheme clusters with the preceding consonant under `Character` iteration, making them invisible to a per-`Character` map lookup.

### Layout switching

`InputSourceManager.switchTo(thai:)` uses the Carbon TIS API to find the first enabled keyboard input source whose ID contains `"thai"` (or not), filtered to `kTISCategoryKeyboardInputSource` to exclude emoji/dictation sources.

### Launch at login

`LaunchAtLoginManager` uses `SMAppService.mainApp` on macOS 13+ and writes a `~/Library/LaunchAgents/com.thaiswitcher.app.plist` on macOS 12.
