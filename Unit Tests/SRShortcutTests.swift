//
//  SRShortcutTests.swift
//  ShortcutRecorder.framework
//
//  Copyright 2018 Contributors. All rights reserved.
//  License: BSD
//
//  Contributors to this file:
//      Ilya Kulakov

import XCTest
import ShortcutRecorder


class SRShortcutTests: XCTestCase {
    /*!
        Raw values of the constants must not be changed for the sake of compatibility.
    */
    func testShortcutKeyEnum() {
        XCTAssertEqual(ShortcutKey.keyCode.rawValue, "keyCode")
        XCTAssertEqual(ShortcutKey.modifierFlags.rawValue, "modifierFlags")
        XCTAssertEqual(ShortcutKey.characters.rawValue, "characters")
        XCTAssertEqual(ShortcutKey.charactersIgnoringModifiers.rawValue, "charactersIgnoringModifiers")
    }

    func testInitialization() {
        let s = makeShortcut()
        XCTAssertEqual(s.keyCode, 0)
        XCTAssertEqual(s.modifierFlags, .option)
        XCTAssertEqual(s.characters, "å")
        XCTAssertEqual(s.charactersIgnoringModifiers, "a")
    }

    func testInitializationWithEvent() {
        let e = NSEvent.keyEvent(with: .keyUp,
                                 location: .zero,
                                 modifierFlags: .option,
                                 timestamp: 0.0,
                                 windowNumber: 0,
                                 context: nil,
                                 characters: "å",
                                 charactersIgnoringModifiers: "a",
                                 isARepeat: false,
                                 keyCode: 0)
        let s = ShortcutRecorder.Shortcut(event: e!)
        XCTAssertEqual(s.keyCode, 0)
        XCTAssertEqual(s.modifierFlags, .option)
        XCTAssertEqual(s.characters, "å")
        XCTAssertEqual(s.charactersIgnoringModifiers, "a")
    }

    func testSubscription() {
        let s = makeShortcut()
        XCTAssertEqual(s[.keyCode] as! UInt16, 0)
        XCTAssertEqual(NSEvent.ModifierFlags(rawValue: s[.modifierFlags] as! UInt), .option)
        XCTAssertEqual(s[.characters] as! String, "å")
        XCTAssertEqual(s[.charactersIgnoringModifiers] as! String, "a")
    }

    func testKVC() {
        let s = makeShortcut()
        XCTAssertEqual(s.value(forKey: ShortcutKey.keyCode.rawValue) as! UInt16, 0)
        XCTAssertEqual(NSEvent.ModifierFlags(rawValue: s.value(forKey: ShortcutKey.modifierFlags.rawValue) as! UInt), .option)
        XCTAssertEqual(s.value(forKey: ShortcutKey.characters.rawValue) as! String, "å")
        XCTAssertEqual(s.value(forKey: ShortcutKey.charactersIgnoringModifiers.rawValue) as! String, "a")
    }

    func testDictionaryInitialization() {
        let s1 = Shortcut(dictionary: [ShortcutKey.keyCode: 0])
        XCTAssertEqual(s1.keyCode, 0)
        XCTAssertEqual(s1.modifierFlags, [])
        XCTAssertEqual(s1.characters, nil)
        XCTAssertEqual(s1.charactersIgnoringModifiers, nil)

        let s2 = Shortcut(dictionary: [ShortcutKey.keyCode: 0, ShortcutKey.modifierFlags: NSEvent.ModifierFlags.option.rawValue])
        XCTAssertEqual(s2.keyCode, 0)
        XCTAssertEqual(s2.modifierFlags, NSEvent.ModifierFlags.option)
        XCTAssertEqual(s2.characters, nil)
        XCTAssertEqual(s2.charactersIgnoringModifiers, nil)

        let s3 = Shortcut(dictionary: [ShortcutKey.keyCode: 0, ShortcutKey.modifierFlags: NSEvent.ModifierFlags.option.rawValue,
                                       ShortcutKey.characters: NSNull(), ShortcutKey.charactersIgnoringModifiers: NSNull()])
        XCTAssertEqual(s3.keyCode, 0)
        XCTAssertEqual(s3.modifierFlags, NSEvent.ModifierFlags.option)
        XCTAssertEqual(s3.characters, nil)
        XCTAssertEqual(s3.charactersIgnoringModifiers, nil)

        let s4 = Shortcut(dictionary: [ShortcutKey.keyCode: 0, ShortcutKey.modifierFlags: NSEvent.ModifierFlags.option.rawValue,
                                       ShortcutKey.characters: "å", ShortcutKey.charactersIgnoringModifiers: "a"])
        XCTAssertEqual(s4.keyCode, 0)
        XCTAssertEqual(s4.modifierFlags, NSEvent.ModifierFlags.option)
        XCTAssertEqual(s4.characters, "å")
        XCTAssertEqual(s4.charactersIgnoringModifiers, "a")
    }

    func testDictionaryRepresentation() {
        let s1 = Shortcut(dictionary: [ShortcutKey.keyCode: 0])
        XCTAssertEqual(s1.dictionaryRepresentation as NSDictionary, [ShortcutKey.keyCode: 0,
                                                                     ShortcutKey.modifierFlags: 0,
                                                                     ShortcutKey.characters: NSNull(),
                                                                     ShortcutKey.charactersIgnoringModifiers: NSNull()])

        let s2 = Shortcut(dictionary: [ShortcutKey.keyCode: 0, ShortcutKey.modifierFlags: NSEvent.ModifierFlags.option.rawValue])
        XCTAssertEqual(s2.dictionaryRepresentation as NSDictionary, [ShortcutKey.keyCode: 0,
                                                                     ShortcutKey.modifierFlags: NSEvent.ModifierFlags.option.rawValue,
                                                                     ShortcutKey.characters: NSNull(),
                                                                     ShortcutKey.charactersIgnoringModifiers: NSNull()])

        let s3 = Shortcut(dictionary: [ShortcutKey.keyCode: 0, ShortcutKey.modifierFlags: NSEvent.ModifierFlags.option.rawValue,
                                       ShortcutKey.characters: "å", ShortcutKey.charactersIgnoringModifiers: "a"])
        XCTAssertEqual(s3.dictionaryRepresentation as NSDictionary, [ShortcutKey.keyCode: 0,
                                                                     ShortcutKey.modifierFlags: NSEvent.ModifierFlags.option.rawValue,
                                                                     ShortcutKey.characters: "å",
                                                                     ShortcutKey.charactersIgnoringModifiers: "a"])
    }

    func testEquality() {
        let s = makeShortcut()
        XCTAssertEqual(s, s)
        XCTAssertEqual(s, makeShortcut())
        XCTAssertNotEqual(s, Shortcut(code: 0, modifierFlags: .command, characters: nil, charactersIgnoringModifiers: nil));
        XCTAssertTrue(s.isEqual(dictionary: [ShortcutKey.keyCode: 0,
                                             ShortcutKey.modifierFlags: NSEvent.ModifierFlags.option.rawValue,
                                             ShortcutKey.characters: "å",
                                             ShortcutKey.charactersIgnoringModifiers: "a"]))
        XCTAssertFalse(s.isEqual(dictionary: [ShortcutKey.modifierFlags: NSEvent.ModifierFlags.option.rawValue,
                                              ShortcutKey.characters: "å",
                                              ShortcutKey.charactersIgnoringModifiers: "a"]))
        XCTAssertTrue(s.isEqual(keyEquivalent: "a", modifierFlags: NSEvent.ModifierFlags.option));
        XCTAssertTrue(s.isEqual(keyEquivalent: "å", modifierFlags: []));
        XCTAssertFalse(s.isEqual(keyEquivalent: "b", modifierFlags: []));
    }

    func testEncoding() {
        let s = NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: makeShortcut()))!
        XCTAssertEqual(s as! Shortcut, makeShortcut())
    }

    func testCopying() {
        let s = makeShortcut()
        let c = s.copy() as! Shortcut
        XCTAssertEqual(s, c)
    }
}
