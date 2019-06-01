//
//  SRRecorderControl.swift
//  Unit Tests
//
//  Created by Ilya Kulakov on 10/11/18.
//

import Cocoa
import XCTest

import ShortcutRecorder


class Delegate: NSObject, RecorderControlDelegate {
    var shouldBegingRecording = true
}


class SRRecorderControlTests: XCTestCase {
    override func setUp() {
        UserDefaults.standard.removeObject(forKey: "shortcut")
    }

    func testCellIsNil() {
        XCTAssertNil(RecorderControl().cell)
    }

    func testEnabled() {
        let c = RecorderControl()
        XCTAssertTrue(c.isEnabled)
        c.isEnabled = false
        XCTAssertFalse(c.isEnabled)
    }

    func testRefusesFirstResponder() {
        let c = RecorderControl()
        XCTAssertFalse(c.refusesFirstResponder)
        c.refusesFirstResponder = true
        XCTAssertTrue(c.refusesFirstResponder)
    }

    func testTag() {
        let c = RecorderControl()
        XCTAssertEqual(c.tag, 0)
        c.tag = 42
        XCTAssertEqual(c.tag, 42)
    }

    func testAcceptsFirstResponder() {
        let c = RecorderControl()
        XCTAssertTrue(c.acceptsFirstResponder)

        c.isEnabled = false
        c.refusesFirstResponder = false
        XCTAssertFalse(c.acceptsFirstResponder)

        c.isEnabled = false
        c.refusesFirstResponder = true
        XCTAssertFalse(c.acceptsFirstResponder)

        c.isEnabled = true
        c.refusesFirstResponder = false
        XCTAssertTrue(c.acceptsFirstResponder)

        c.isEnabled = true
        c.refusesFirstResponder = true
        XCTAssertFalse(c.acceptsFirstResponder)
    }

    func testBindingAndModelChange() {
        let v = RecorderControl()
        v.bind(NSBindingName.value, to: NSUserDefaultsController.shared, withKeyPath: "values.shortcut", options: nil)
        let keyCode: UInt16 = 0
        let modifierFlags: NSEvent.ModifierFlags = [.command, .option]
        let objectValue: [ShortcutKey: Any] = [ShortcutKey.keyCode: keyCode, ShortcutKey.modifierFlags: modifierFlags.rawValue]
        UserDefaults.standard.set(objectValue as NSDictionary, forKey: "shortcut")
        XCTAssertEqual(v.objectValue![.keyCode] as! UInt16, keyCode)
        XCTAssertEqual(v.objectValue![.modifierFlags] as! UInt, modifierFlags.rawValue)
    }

    func testBindingAndViewChange() {
        let v = RecorderControl()
        v.bind(NSBindingName.value, to: NSUserDefaultsController.shared, withKeyPath: "values.shortcut", options: nil)
        let keyCode: UInt16 = 0
        let modifierFlags: NSEvent.ModifierFlags = [.command, .option]
        let objectValue: [ShortcutKey: Any] = [ShortcutKey.keyCode: keyCode, ShortcutKey.modifierFlags: modifierFlags.rawValue]
        v.setValue(objectValue as NSDictionary, forKey: "objectValue")
        XCTAssertEqual(UserDefaults.standard.value(forKeyPath: "shortcut.keyCode") as! UInt16, keyCode)
        XCTAssertEqual(UserDefaults.standard.value(forKeyPath: "shortcut.modifierFlags") as! UInt, modifierFlags.rawValue)
    }

    func testStyleIsCopied() {
        let s = RecorderControlStyle()
        let v1 = RecorderControl(frame: .zero)
        let v2 = RecorderControl(frame: .zero)

        v1.style = s
        v2.style = s

        XCTAssertFalse(v1.style === v2.style)
    }

    func testObjectValueAffectsDictionaryValueObservation() {
        let v = RecorderControl(frame: .zero)
        var calls: [[NSDictionary?]] = []

        let observation = v.observe(\RecorderControl.dictionaryValue, options: [.old, .new]) { (_, change) in
            calls.append([change.oldValue as? NSDictionary, change.newValue as? NSDictionary])
        }

        defer {
            observation.invalidate()
        }

        let s1 = Shortcut(code: UInt16(kVK_ANSI_A),
                          modifierFlags: .command,
                          characters: "A",
                          charactersIgnoringModifiers: "a")
        v.objectValue = s1
        let s2 = Shortcut(code: UInt16(kVK_ANSI_B),
                          modifierFlags: .command,
                          characters: "B",
                          charactersIgnoringModifiers: "b")
        v.objectValue = s2

        let expected = [[nil, s1.dictionaryRepresentation], [s1.dictionaryRepresentation, s2.dictionaryRepresentation]]
        XCTAssertTrue((calls as NSArray).isEqual(to: expected))
    }
}
