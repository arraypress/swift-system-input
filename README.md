# Swift System Input

A tiny Swift library for retrieving user input from system sources on macOS. Read the user's currently selected text or clipboard contents with a clean, single-call API, plus the accessibility-permission plumbing needed to make it work.

## Features

- 🎯 **Single-call API** — `SystemInput.getText()` returns the best available text
- 🖱️ **Selected text** — read the current selection from the frontmost app via the Accessibility API
- 📋 **Clipboard access** — read the current clipboard string, or copy text to it
- ⌨️ **Cursor injection** — paste text at the cursor in any app, restoring the clipboard afterwards
- ✅ **Inline validation** — pass a validator closure to accept text only when it matches
- 🔁 **Smart fallback** — prefers selected text, falls back to clipboard automatically
- 🔐 **Permission helpers** — check, request, and deep-link to Accessibility settings
- 🧹 **Auto-trimmed** — returned text is whitespace-trimmed for you
- 🪶 **Zero dependencies** — Foundation, AppKit, and ApplicationServices only

## Requirements

- macOS 13.0+
- Swift 5.9+
- Xcode 15.0+

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/arraypress/swift-system-input.git", from: "1.0.0")
]
```

## Usage

### Get Text from the Best Source

Tries selected text first, then the clipboard, returning `nil` if neither is available:

```swift
import SystemInput

if let text = SystemInput.getText() {
    process(text)
}
```

### Validate Before Accepting

```swift
// Only return the text if it looks like a URL
if let urlString = SystemInput.getText(validator: { $0.hasPrefix("http") }) {
    openURL(urlString)
}
```

### Individual Sources

```swift
// Currently selected text in the frontmost app (requires accessibility permission)
if let selection = SystemInput.selectedText {
    process(selection)
}

// Current clipboard string
if let clipboard = SystemInput.clipboard {
    process(clipboard)
}
```

### Write to the Clipboard

```swift
SystemInput.copyToClipboard("Hello, world!")
```

### Inject Text at the Cursor

Pastes text into whatever app is focused (via a synthesized ⌘V), then restores the previous clipboard contents so the user's clipboard is left untouched. This is the most portable injection method — it works in Electron, browsers, and native apps where direct Accessibility text insertion is unreliable. Requires Accessibility permission.

```swift
guard SystemInput.inject("Hello, world!") else {
    SystemInput.requestAccessibilityPermission()   // not granted yet
    return
}

// Or leave the injected text on the clipboard afterwards:
SystemInput.inject("Hello, world!", restoreClipboard: false)
```

### Accessibility Permission

Reading selected text requires Accessibility permission. (Note: `selectedText` is not available to sandboxed Mac App Store apps.)

```swift
if !SystemInput.hasAccessibilityPermission {
    SystemInput.requestAccessibilityPermission()   // shows the system prompt
    // or take the user straight to the settings pane:
    SystemInput.openAccessibilitySettings()
}
```

## How It Works

`selectedText` queries the system-wide Accessibility element for the focused UI
element, then reads its `AXSelectedText`. If that attribute is unavailable, it
falls back to combining the element's full value with its `AXSelectedTextRange`
to slice out the selection. Clipboard access goes through `NSPasteboard.general`.

`inject(_:)` writes the text to the pasteboard, synthesizes a ⌘V keystroke with a
private-state `CGEventSource`, then restores the previous pasteboard contents once
the paste has landed — but only if nothing else wrote to the pasteboard in the
meantime (tracked via `changeCount`).

## Testing

```bash
swift test
```

Tests cover the text-source fallback logic, validation, clipboard round-trips, and the pasteboard snapshot/restore that backs injection.

## License

MIT License — see LICENSE file for details.

## Author

Created by David Sherlock ([ArrayPress](https://github.com/arraypress)) in 2026.
