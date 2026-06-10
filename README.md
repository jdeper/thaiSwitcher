# ThaiSwitcher

A lightweight macOS menu-bar app that converts mistyped Thai ↔ English text in place with a single shortcut.

## The Problem

You start typing, realise you forgot to switch the keyboard layout, and end up with a line of wrong characters. ThaiSwitcher fixes that without retyping.

## How It Works

Press **Shift + Backspace** at any time while typing.

- If you typed in the **wrong language** (e.g. typed `lfu` when you meant `สื่`), ThaiSwitcher deletes what you typed and replaces it with the correct characters — then switches the keyboard layout automatically.
- Works in both directions: **English → Thai** and **Thai → English**.

The conversion is based on the **Thai Kedmanee** keyboard layout, which is the standard Thai layout on macOS.

## Requirements

- macOS 12 or later
- Thai keyboard layout installed in System Settings → Keyboard → Input Sources
- Accessibility permission (required to monitor and simulate keystrokes)

## Install

```bash
./build.sh      # compiles the app → build/ThaiSwitcher.app
./install.sh    # copies to /Applications
open /Applications/ThaiSwitcher.app
```

On first launch, click **Open System Settings** when prompted and enable ThaiSwitcher under **Privacy & Security → Accessibility**. Then relaunch the app.

## Usage

| Action | Result |
|--------|--------|
| **Shift + Backspace** | Converts the current word Thai ↔ English and switches keyboard layout |
| Menu bar **TS** icon | Access settings and quit |
| **Launch at Login** | Toggle in the TS menu to start ThaiSwitcher automatically |

The buffer resets on Space, Enter, Tab, Escape, or any arrow key — so conversion applies to the current word only.

## Build from Source

No Xcode required. The project compiles with the command-line Swift toolchain:

```bash
./build.sh
```

Output: `build/ThaiSwitcher.app`
