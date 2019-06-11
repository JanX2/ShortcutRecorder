//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

import XCTest
import AppKit

import ShortcutRecorder


class SRKeyEquivalentModifierMaskTransformerTests: XCTestCase {
    func testTransformFromDictionary() {
        let cmd_a = Shortcut(keyEquivalent: "⌘A")!
        let cmd_a_kemm = NSEvent.ModifierFlags(rawValue: KeyEquivalentModifierMaskTransformer.shared.transformedValue(cmd_a.dictionaryRepresentation) as! UInt)
        XCTAssertEqual(cmd_a_kemm, NSEvent.ModifierFlags.command)
    }

    func testTransformFromShortcut() {
        let cmd_a = Shortcut(keyEquivalent: "⌘A")!
        let cmd_a_kemm = NSEvent.ModifierFlags(rawValue: KeyEquivalentModifierMaskTransformer.shared.transformedValue(cmd_a) as! UInt)
        XCTAssertEqual(cmd_a_kemm, NSEvent.ModifierFlags.command)
    }
}
