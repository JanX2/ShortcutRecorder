//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

import XCTest

import ShortcutRecorder


class SRKeyCodeTransformerTests: XCTestCase {
    func testUserInterfaceLayoutAltersTabRendering() {
        let c = RecorderControl(frame: .zero)
        c.drawLabelRespectsUserInterfaceLayoutDirection = true
        c.drawsASCIIEquivalentOfShortcut = true

        c.userInterfaceLayoutDirection = .leftToRight
        c.objectValue = Shortcut(code: UInt16(kVK_Tab), modifierFlags: [], characters: nil, charactersIgnoringModifiers: nil)
        XCTAssertEqual(c.stringValue, "\u{21E5}")

        c.userInterfaceLayoutDirection = .rightToLeft
        c.objectValue = Shortcut(code: UInt16(kVK_Tab), modifierFlags: [], characters: nil, charactersIgnoringModifiers: nil)
        XCTAssertEqual(c.stringValue, "\u{21E4}")
    }

    func testReverseTransform() {
        XCTAssertEqual(ASCIILiteralKeyCodeTransformer.shared.reverseTransformedValue("a") as! Int, kVK_ANSI_A)
        XCTAssertEqual(ASCIILiteralKeyCodeTransformer.shared.reverseTransformedValue("A") as! Int, kVK_ANSI_A)

        XCTAssertNil(ASCIILiteralKeyCodeTransformer.shared.reverseTransformedValue("ф"))

        XCTAssertEqual(ASCIILiteralKeyCodeTransformer.shared.reverseTransformedValue("⇥") as! Int, kVK_Tab)
        XCTAssertEqual(ASCIILiteralKeyCodeTransformer.shared.reverseTransformedValue("⇤") as! Int, kVK_Tab)
        XCTAssertEqual(ASCIILiteralKeyCodeTransformer.shared.reverseTransformedValue("Tab") as! Int, kVK_Tab)
        XCTAssertEqual(ASCIILiteralKeyCodeTransformer.shared.reverseTransformedValue("↩") as! Int, kVK_Return)
        XCTAssertEqual(ASCIILiteralKeyCodeTransformer.shared.reverseTransformedValue("⌅") as! Int, kVK_ANSI_KeypadEnter)
        XCTAssertEqual(ASCIILiteralKeyCodeTransformer.shared.reverseTransformedValue("⌫") as! Int, kVK_Delete)
        XCTAssertEqual(ASCIILiteralKeyCodeTransformer.shared.reverseTransformedValue("⌦") as! Int, kVK_ForwardDelete)
        XCTAssertEqual(ASCIILiteralKeyCodeTransformer.shared.reverseTransformedValue("⌧") as! Int, kVK_ANSI_KeypadClear)
        XCTAssertEqual(ASCIILiteralKeyCodeTransformer.shared.reverseTransformedValue("←") as! Int, kVK_LeftArrow)
        XCTAssertEqual(ASCIILiteralKeyCodeTransformer.shared.reverseTransformedValue("→") as! Int, kVK_RightArrow)
        XCTAssertEqual(ASCIILiteralKeyCodeTransformer.shared.reverseTransformedValue("↑") as! Int, kVK_UpArrow)
        XCTAssertEqual(ASCIILiteralKeyCodeTransformer.shared.reverseTransformedValue("↓") as! Int, kVK_DownArrow)
        XCTAssertEqual(ASCIILiteralKeyCodeTransformer.shared.reverseTransformedValue("⇟") as! Int, kVK_PageDown)
        XCTAssertEqual(ASCIILiteralKeyCodeTransformer.shared.reverseTransformedValue("⇞") as! Int, kVK_PageUp)
        XCTAssertEqual(ASCIILiteralKeyCodeTransformer.shared.reverseTransformedValue("↖") as! Int, kVK_Home)
        XCTAssertEqual(ASCIILiteralKeyCodeTransformer.shared.reverseTransformedValue("↘") as! Int, kVK_End)
        XCTAssertEqual(ASCIILiteralKeyCodeTransformer.shared.reverseTransformedValue("⎋") as! Int, kVK_Escape)
        XCTAssertEqual(ASCIILiteralKeyCodeTransformer.shared.reverseTransformedValue("Esc") as! Int, kVK_Escape)
        XCTAssertEqual(ASCIILiteralKeyCodeTransformer.shared.reverseTransformedValue("Escape") as! Int, kVK_Escape)
        XCTAssertEqual(ASCIILiteralKeyCodeTransformer.shared.reverseTransformedValue(" ") as! Int, kVK_Space)
        XCTAssertEqual(ASCIILiteralKeyCodeTransformer.shared.reverseTransformedValue("space") as! Int, kVK_Space)
    }
}
