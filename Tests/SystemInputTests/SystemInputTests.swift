//
//  SystemInputTests.swift
//  SystemInputTests
//

import XCTest
@testable import SystemInput

final class SystemInputTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clear clipboard before each test
        NSPasteboard.general.clearContents()
    }
    
    // MARK: - Clipboard Tests
    
    func testClipboard_whenEmpty_returnsNil() {
        XCTAssertNil(SystemInput.clipboard)
    }
    
    func testClipboard_whenHasText_returnsText() {
        let testText = "Hello, World!"
        SystemInput.copyToClipboard(testText)
        
        XCTAssertEqual(SystemInput.clipboard, testText)
    }
    
    func testClipboard_trimsWhitespace() {
        let testText = "  Hello  \n\t"
        SystemInput.copyToClipboard(testText)
        
        XCTAssertEqual(SystemInput.clipboard, "Hello")
    }
    
    func testCopyToClipboard() {
        let testText = "Test content"
        SystemInput.copyToClipboard(testText)
        
        let result = NSPasteboard.general.string(forType: .string)
        XCTAssertEqual(result, testText)
    }
    
    // MARK: - getText() Tests
    
    func testGetText_withEmptyClipboard_returnsNil() {
        XCTAssertNil(SystemInput.getText())
    }
    
    func testGetText_withClipboard_returnsClipboardText() {
        let testText = "Clipboard text"
        SystemInput.copyToClipboard(testText)
        
        XCTAssertEqual(SystemInput.getText(), testText)
    }
    
    func testGetText_withValidator_whenValid_returnsText() {
        SystemInput.copyToClipboard("https://example.com")
        
        let result = SystemInput.getText(validator: { $0.hasPrefix("https") })
        XCTAssertEqual(result, "https://example.com")
    }
    
    func testGetText_withValidator_whenInvalid_returnsNil() {
        SystemInput.copyToClipboard("not a url")
        
        let result = SystemInput.getText(validator: { $0.hasPrefix("https") })
        XCTAssertNil(result)
    }
    
    // MARK: - Permission Tests (just verify they don't crash)
    
    func testHasAccessibilityPermission_doesNotCrash() {
        _ = SystemInput.hasAccessibilityPermission
        // Can't test actual value as it depends on system state
    }
    
    func testOpenAccessibilitySettings_doesNotCrash() {
        // This will actually open System Settings, so skip in CI
        // SystemInput.openAccessibilitySettings()
    }

    // MARK: - Text Injection Tests

    func testInject_withoutAccessibilityPermission_returnsFalse() throws {
        try XCTSkipIf(SystemInput.hasAccessibilityPermission,
                      "Accessibility permission is granted; the no-permission path can't be exercised.")
        XCTAssertFalse(SystemInput.inject("test"))
    }

    func testSnapshotRestore_preservesStringContent() {
        let pasteboard = NSPasteboard(name: .init("SystemInputTests.snapshotRestore"))
        pasteboard.clearContents()
        pasteboard.setString("Original", forType: .string)

        let saved = SystemInput.snapshot(of: pasteboard)

        // Overwrite, exactly as an injection would.
        pasteboard.clearContents()
        pasteboard.setString("Injected", forType: .string)
        XCTAssertEqual(pasteboard.string(forType: .string), "Injected")

        // Restore returns the original contents verbatim.
        SystemInput.restore(saved, to: pasteboard)
        XCTAssertEqual(pasteboard.string(forType: .string), "Original")

        pasteboard.releaseGlobally()
    }

    func testSnapshot_preservesMultipleTypes() {
        let pasteboard = NSPasteboard(name: .init("SystemInputTests.multiType"))
        let blobType = NSPasteboard.PasteboardType("com.arraypress.systeminput.test.blob")
        pasteboard.clearContents()
        let item = NSPasteboardItem()
        item.setString("plain", forType: .string)
        item.setData(Data([0x01, 0x02, 0x03]), forType: blobType)
        pasteboard.writeObjects([item])

        let saved = SystemInput.snapshot(of: pasteboard)

        pasteboard.clearContents()
        pasteboard.setString("changed", forType: .string)

        SystemInput.restore(saved, to: pasteboard)
        XCTAssertEqual(pasteboard.string(forType: .string), "plain")
        XCTAssertEqual(pasteboard.data(forType: blobType), Data([0x01, 0x02, 0x03]))

        pasteboard.releaseGlobally()
    }

    func testRestore_withEmptySnapshot_clearsPasteboard() {
        let pasteboard = NSPasteboard(name: .init("SystemInputTests.empty"))
        pasteboard.clearContents()
        pasteboard.setString("something", forType: .string)

        SystemInput.restore([], to: pasteboard)
        XCTAssertNil(pasteboard.string(forType: .string))

        pasteboard.releaseGlobally()
    }

}
