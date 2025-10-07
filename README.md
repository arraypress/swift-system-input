# Swift System Input

Simple system input retrieval for macOS. Get selected text or clipboard content with a clean, straightforward API.

## Features

- 📋 **Clipboard Access** - Read and write system clipboard
- ✨ **Selected Text** - Get currently selected text from any app (requires accessibility permission)
- 🔍 **Smart Fallback** - Automatically tries selected text, then clipboard
- ✅ **Validation Support** - Optional text validation before returning
- 🎯 **macOS Native** - Built specifically for macOS using native APIs

## Installation

### Swift Package Manager

Add SystemInput to your project via Xcode:

1. File → Add Package Dependencies
2. Enter repository URL: `https://github.com/arraypress/swift-system-input`
3. Select version and add to your target

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/arraypress/swift-system-input", from: "1.0.0")
]
```

## Requirements

- macOS 13.0+
- Swift 5.9+

## Usage

### Quick Start

```swift
import SystemInput

// Get text from best available source (selected text → clipboard)
if let text = SystemInput.getText() {
    print("Got text: \(text)")
}
```

### Get Text with Validation

```swift
// Only accept URLs
if let url = SystemInput.getText(validator: { $0.hasPrefix("http") }) {
    openURL(url)
}

// Only accept email addresses
if let email = SystemInput.getText(validator: { $0.contains("@") }) {
    sendEmail(to: email)
}
```

### Access Sources Directly

```swift
// Get only selected text
if let selected = SystemInput.selectedText {
    print("Selected: \(selected)")
}

// Get only clipboard
if let clipboard = SystemInput.clipboard {
    print("Clipboard: \(clipboard)")
}

// Manual fallback
if let text = SystemInput.selectedText ?? SystemInput.clipboard {
    process(text)
}
```

### Clipboard Operations

```swift
// Copy text to clipboard
SystemInput.copyToClipboard("Hello, World!")

// Read clipboard
if let text = SystemInput.clipboard {
    print(text)
}
```

### Accessibility Permissions

Selected text requires accessibility permission. Handle this in your app:

```swift
// Check if permission is granted
if SystemInput.hasAccessibilityPermission {
    // Use selected text
    if let text = SystemInput.selectedText {
        process(text)
    }
} else {
    // Request permission
    SystemInput.requestAccessibilityPermission()
}

// Or open System Settings directly
SystemInput.openAccessibilitySettings()
```

## API Reference

### Methods

#### `getText() -> String?`
Get text from the best available source. Tries selected text first, then clipboard.

**Returns:** Text string, or `nil` if nothing available.

```swift
if let text = SystemInput.getText() {
    print(text)
}
```

#### `getText(validator:) -> String?`
Get text from the best available source with optional validation.

**Parameters:**
- `validator: ((String) -> Bool)?` - Optional closure to validate text before returning

**Returns:** Valid text string, or `nil` if unavailable or validation fails.

```swift
let url = SystemInput.getText(validator: { $0.hasPrefix("http") })
```

### Properties

#### `selectedText: String?`
Get currently selected text from the frontmost application.

**Returns:** `nil` if no text is selected or accessibility permission not granted.

⚠️ **Not compatible with sandboxed Mac App Store apps.**

```swift
if let text = SystemInput.selectedText {
    print("Selected: \(text)")
}
```

#### `clipboard: String?`
Get current clipboard text content.

```swift
if let text = SystemInput.clipboard {
    print("Clipboard: \(text)")
}
```

#### `hasAccessibilityPermission: Bool`
Check if accessibility permission is granted.

```swift
if SystemInput.hasAccessibilityPermission {
    // Can use selected text
}
```

### Clipboard Operations

#### `copyToClipboard(_ text: String)`
Copy text to the system clipboard.

```swift
SystemInput.copyToClipboard("Hello!")
```

### Permission Helpers

#### `requestAccessibilityPermission()`
Request accessibility permission from the user. Shows system prompt.

⚠️ App may need restart after granting permission.

```swift
SystemInput.requestAccessibilityPermission()
```

#### `openAccessibilitySettings()`
Open System Settings to the Accessibility preferences pane.

```swift
SystemInput.openAccessibilitySettings()
```

## Important Notes

### Mac App Store Compatibility

⚠️ **Selected text functionality is NOT compatible with sandboxed Mac App Store apps.**

The `selectedText` property uses the Accessibility API (`AXIsProcessTrusted`), which is not allowed in sandboxed apps distributed through the Mac App Store.

**For Mac App Store apps:**
- Use `clipboard` only
- Or use `getText()` which will automatically fall back to clipboard when accessibility is unavailable

**For direct distribution:**
- Full functionality available
- Users must grant accessibility permission

### Accessibility Permission

To use `selectedText`, your app needs accessibility permission:

1. The first time you access `selectedText`, call `requestAccessibilityPermission()` to prompt the user
2. User must manually enable your app in System Settings → Privacy & Security → Accessibility
3. App may need to be restarted after granting permission

### Info.plist

Add usage description to your `Info.plist`:

```xml
<key>NSAccessibilityUsageDescription</key>
<string>This app needs accessibility access to read selected text from other applications.</string>
```

## Examples

### URL Opener

```swift
import SystemInput

func openSelectedURL() {
    // Try to get a valid URL from selection or clipboard
    if let urlString = SystemInput.getText(validator: { $0.hasPrefix("http") }),
       let url = URL(string: urlString) {
        NSWorkspace.shared.open(url)
    } else {
        print("No valid URL found")
    }
}
```

### Search Selected Text

```swift
import SystemInput

func searchWeb() {
    guard let query = SystemInput.getText() else {
        print("No text to search")
        return
    }
    
    let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    let searchURL = URL(string: "https://www.google.com/search?q=\(encoded)")!
    NSWorkspace.shared.open(searchURL)
}
```

### Text Processor with Permission Check

```swift
import SystemInput

func processText() {
    // Check for permission first
    if !SystemInput.hasAccessibilityPermission {
        SystemInput.requestAccessibilityPermission()
        return
    }
    
    // Get text with validation
    guard let text = SystemInput.getText(validator: { !$0.isEmpty }) else {
        print("No text available")
        return
    }
    
    // Process the text
    let wordCount = text.split(separator: " ").count
    print("Word count: \(wordCount)")
}
```

## Testing

The library includes tests for clipboard functionality and validation logic. Selected text functionality requires manual testing as it depends on system permissions and UI state.

Run tests:
```bash
swift test
```

## License

MIT License - See LICENSE file for details

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
