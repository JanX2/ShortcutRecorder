//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 3.0
//

import XCTest

import ShortcutRecorder


class SRKeyCodeTransformerTests: XCTestCase {
    func testUserInterfaceLayoutAltersTabRendering() {
        let c = RecorderControl(frame: .zero)
        c.drawsASCIIEquivalentOfShortcut = true

        c.userInterfaceLayoutDirection = .leftToRight
        c.objectValue = Shortcut(code: UInt16(kVK_Tab), modifierFlags: [], characters: nil, charactersIgnoringModifiers: nil)
        XCTAssertEqual(c.stringValue, "\u{21E5}")
        c.objectValue = Shortcut(code: UInt16(kVK_Tab), modifierFlags: [.shift], characters: nil, charactersIgnoringModifiers: nil)
        XCTAssertEqual(c.stringValue, "⇧\u{21E4}")

        c.userInterfaceLayoutDirection = .rightToLeft
        c.objectValue = Shortcut(code: UInt16(kVK_Tab), modifierFlags: [], characters: nil, charactersIgnoringModifiers: nil)
        XCTAssertEqual(c.stringValue, "\u{21E4}")
        c.objectValue = Shortcut(code: UInt16(kVK_Tab), modifierFlags: [.shift], characters: nil, charactersIgnoringModifiers: nil)
        XCTAssertEqual(c.stringValue, "\u{21E5}⇧")
    }
}
