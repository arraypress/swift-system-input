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
    
}
