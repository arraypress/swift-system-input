//
//  SystemInput.swift
//  SystemInput
//
//  Simple system input retrieval for macOS
//  Created on 01/07/2025.
//

import Foundation
import AppKit
import ApplicationServices

/// Helper for retrieving user input from system sources on macOS.
///
/// ## Usage
///
/// ```swift
/// // Get text from best available source
/// if let text = SystemInput.getText() {
///     process(text)
/// }
///
/// // Get text with validation
/// if let url = SystemInput.getText(validator: { $0.hasPrefix("http") }) {
///     openURL(url)
/// }
///
/// // Get selected text only
/// if let text = SystemInput.selectedText {
///     process(text)
/// }
///
/// // Get clipboard only
/// if let text = SystemInput.clipboard {
///     process(text)
/// }
/// ```
public struct SystemInput {
    
    // MARK: - Primary API
    
    /// Get text from the best available source.
    ///
    /// Tries sources in this order:
    /// 1. Selected text (if accessibility permission granted)
    /// 2. Clipboard text
    /// 3. Returns nil if nothing available
    ///
    /// ## Example
    ///
    /// ```swift
    /// if let text = SystemInput.getText() {
    ///     process(text)
    /// } else {
    ///     // No text available from any source
    /// }
    /// ```
    public static func getText() -> String? {
        return selectedText ?? clipboard
    }
    
    /// Get text from the best available source.
    ///
    /// Tries sources in this order:
    /// 1. Selected text (if accessibility permission granted)
    /// 2. Clipboard text
    /// 3. Returns nil if nothing available or validation fails
    ///
    /// - Parameter validator: Optional closure to validate the text before returning
    /// - Returns: Valid text string, or nil if unavailable or invalid
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Get any text
    /// if let text = SystemInput.getText() {
    ///     process(text)
    /// }
    ///
    /// // Get text with validation
    /// if let url = SystemInput.getText(validator: { $0.hasPrefix("http") }) {
    ///     openURL(url)
    /// }
    /// ```
    public static func getText(validator: ((String) -> Bool)? = nil) -> String? {
        if let text = selectedText ?? clipboard {
            if let validator = validator {
                return validator(text) ? text : nil
            }
            return text
        }
        return nil
    }
    
    // MARK: - Text Sources
    
    /// Get currently selected text from the frontmost application.
    ///
    /// Returns nil if:
    /// - No text is selected
    /// - Accessibility permission not granted
    ///
    /// **Note:** Not compatible with sandboxed Mac App Store apps.
    public static var selectedText: String? {
        guard AXIsProcessTrusted() else { return nil }
        
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?
        
        guard AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        ) == .success else {
            return nil
        }
        
        let element = focusedElement as! AXUIElement
        
        // Try direct selected text
        var selectedTextValue: CFTypeRef?
        if AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            &selectedTextValue
        ) == .success,
           let text = selectedTextValue as? String,
           !text.isEmpty {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Fallback: value + selected range
        var valueRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXValueAttribute as CFString,
            &valueRef
        ) == .success,
              let fullText = valueRef as? String,
              !fullText.isEmpty else {
            return nil
        }
        
        var rangeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &rangeRef
        ) == .success,
              let rangeValue = rangeRef,
              CFGetTypeID(rangeValue) == AXValueGetTypeID() else {
            return nil
        }
        
        var cfRange = CFRange()
        guard AXValueGetValue(rangeValue as! AXValue, .cfRange, &cfRange),
              cfRange.length > 0 else {
            return nil
        }
        
        let nsRange = NSRange(location: cfRange.location, length: cfRange.length)
        guard nsRange.location != NSNotFound,
              nsRange.location + nsRange.length <= fullText.count else {
            return nil
        }
        
        let startIndex = fullText.index(fullText.startIndex, offsetBy: nsRange.location)
        let endIndex = fullText.index(startIndex, offsetBy: nsRange.length)
        
        return String(fullText[startIndex..<endIndex])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Get current clipboard text content.
    public static var clipboard: String? {
        return NSPasteboard.general.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Clipboard Operations
    
    /// Copy text to clipboard.
    public static func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    // MARK: - Accessibility Permissions
    
    /// Check if accessibility permission is granted.
    public static var hasAccessibilityPermission: Bool {
        return AXIsProcessTrusted()
    }
    
    /// Request accessibility permission from user.
    ///
    /// Shows system prompt. App may need restart after granting.
    public static func requestAccessibilityPermission() {
        let options: [String: Any] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    /// Open System Settings to Accessibility preferences.
    public static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
}
