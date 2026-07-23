//
//  SystemInput+Injection.swift
//  SystemInput
//
//  Injects text at the cursor in the frontmost app by swapping the pasteboard,
//  synthesising ⌘V, and restoring the original pasteboard once the paste has
//  landed. This is the most portable injection method — it works in Electron,
//  browsers, and native apps where direct Accessibility text insertion is
//  unreliable.
//
//  Requires Accessibility permission (to post key events).
//

import AppKit
import ApplicationServices

extension SystemInput {

    /// One captured pasteboard item: its types mapped to their raw data.
    typealias PasteboardSnapshot = [NSPasteboard.PasteboardType: Data]

    // MARK: - Text Injection

    /// Inject text at the current cursor position in the frontmost app.
    ///
    /// Writes the text to the pasteboard, synthesises a ⌘V keystroke, then (by
    /// default) restores the previous pasteboard contents once the paste has
    /// landed — so the user's clipboard is left untouched.
    ///
    /// Requires Accessibility permission (to post the paste keystroke). Works in
    /// Electron, browsers, and native apps where direct Accessibility text
    /// insertion is unreliable.
    ///
    /// ## Example
    ///
    /// ```swift
    /// guard SystemInput.inject("Hello, world!") else {
    ///     SystemInput.requestAccessibilityPermission()
    ///     return
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - text: The text to paste at the cursor.
    ///   - restoreClipboard: When `true` (default), the previous pasteboard
    ///     contents are restored after the paste, provided nothing else has
    ///     written to the pasteboard in the meantime.
    /// - Returns: `true` if the paste keystroke was posted, `false` if blocked
    ///   (e.g. Accessibility permission not granted).
    @discardableResult
    public static func inject(_ text: String, restoreClipboard: Bool = true) -> Bool {
        guard AXIsProcessTrusted() else { return false }

        let pasteboard = NSPasteboard.general
        let original = restoreClipboard ? snapshot(of: pasteboard) : nil

        // Write our text and remember the change count so we can detect whether
        // anything else touches the pasteboard before we restore.
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        let ownedChangeCount = pasteboard.changeCount

        // Let the target app settle/focus, then paste.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            postPasteKeystroke()

            guard let original else { return }
            // Restore only if we still own the pasteboard (nothing wrote since).
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                if pasteboard.changeCount == ownedChangeCount {
                    restore(original, to: pasteboard)
                }
            }
        }
        return true
    }

    // MARK: - Keystroke Synthesis

    private static func postPasteKeystroke() {
        // `.privateState` so we don't disturb the user's real modifier state.
        let source = CGEventSource(stateID: .privateState)
        let cmd: CGKeyCode = 0x37   // Left Command
        let v: CGKeyCode = 0x09     // V
        let tap: CGEventTapLocation = .cghidEventTap

        let events = [
            CGEvent(keyboardEventSource: source, virtualKey: cmd, keyDown: true),
            CGEvent(keyboardEventSource: source, virtualKey: v, keyDown: true),
            CGEvent(keyboardEventSource: source, virtualKey: v, keyDown: false),
            CGEvent(keyboardEventSource: source, virtualKey: cmd, keyDown: false),
        ]
        // The V events carry the Command flag so the receiver sees ⌘V.
        events[1]?.flags = .maskCommand
        events[2]?.flags = .maskCommand

        for event in events {
            event?.post(tap: tap)
            usleep(8_000) // 8ms between events — some apps drop events posted too fast
        }
    }

    // MARK: - Pasteboard Snapshot / Restore

    /// Capture every item on `pasteboard` as raw type-to-data maps, so the
    /// contents can be restored verbatim after a temporary write.
    static func snapshot(of pasteboard: NSPasteboard) -> [PasteboardSnapshot] {
        (pasteboard.pasteboardItems ?? []).map { item in
            var dict: PasteboardSnapshot = [:]
            for type in item.types {
                if let data = item.data(forType: type) { dict[type] = data }
            }
            return dict
        }
    }

    /// Restore a previously captured `snapshot(of:)` onto `pasteboard`.
    static func restore(_ items: [PasteboardSnapshot], to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        let objects: [NSPasteboardItem] = items.map { dict in
            let item = NSPasteboardItem()
            for (type, data) in dict { item.setData(data, forType: type) }
            return item
        }
        if !objects.isEmpty { pasteboard.writeObjects(objects) }
    }

}
