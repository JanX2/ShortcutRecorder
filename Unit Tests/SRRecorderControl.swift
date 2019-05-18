//
//  SRRecorderControl.swift
//  Unit Tests
//
//  Created by Ilya Kulakov on 10/11/18.
//

import Cocoa
import XCTest

import ShortcutRecorder


class SRRecorderControlCompatibility: XCTestCase {
    override func setUp() {
        UserDefaults.standard.removeObject(forKey: "shortcut")
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
}
