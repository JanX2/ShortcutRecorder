//
//  SRValidatorTests.swift
//  ShortcutRecorder.framework
//
//  Copyright 2018 Contributors. All rights reserved.
//  License: BSD
//
//  Contributors to this file:
//      Ilya Kulakov

import XCTest
import ShortcutRecorder


class SRValidatorTests: XCTestCase {
    class RecordingValidator : Validator {
        var calls: [String] = []

        override func validateShortcutAgainstDelegate(_ aShortcut: Shortcut) throws {
            try super.validateShortcutAgainstDelegate(aShortcut)
            self.calls.append("delegate")
        }

        override func validateShortcutAgainstSystemShortcuts(_ aShortcut: Shortcut) throws {
            try super.validateShortcutAgainstSystemShortcuts(aShortcut)
            self.calls.append("system")
        }

        override func validateShortcut(_ aShortcut: Shortcut, againstMenu aMenu: NSMenu) throws {
            try super.validateShortcut(aShortcut, againstMenu: aMenu)
            self.calls.append("menu")
        }
    }

    func testValidationOrder() {
        class FailingValidator : RecordingValidator {
            let failAt: String?

            init(_ failAt: String? = nil) {
                self.failAt = failAt
                super.init(delegate: nil)
            }

            override func validateShortcutAgainstDelegate(_ aShortcut: Shortcut) throws {
                if self.failAt != "delegate" {
                    try super.validateShortcutAgainstDelegate(aShortcut)
                }
                else {
                    throw NSError.init(domain: NSCocoaErrorDomain, code: 0, userInfo: nil)
                }
            }

            override func validateShortcutAgainstSystemShortcuts(_ aShortcut: Shortcut) throws {
                if self.failAt != "system" {
                    try super.validateShortcutAgainstSystemShortcuts(aShortcut)
                }
                else {
                    throw NSError.init(domain: NSCocoaErrorDomain, code: 0, userInfo: nil)
                }
            }

            override func validateShortcut(_ aShortcut: Shortcut, againstMenu aMenu: NSMenu) throws {
                if self.failAt != "menu" {
                    try super .validateShortcut(aShortcut, againstMenu: aMenu)
                }
                else {
                    throw NSError.init(domain: NSCocoaErrorDomain, code: 0, userInfo: nil)
                }
            }
        }

        let v1 = FailingValidator()
        try! v1.validateShortcut(makeShortcut())
        XCTAssertEqual(v1.calls, ["delegate", "system", "menu"])

        let v2 = FailingValidator("delegate")
        try? v2.validateShortcut(makeShortcut())
        XCTAssertEqual(v2.calls, [])

        let v3 = FailingValidator("system")
        try? v3.validateShortcut(makeShortcut())
        XCTAssertEqual(v3.calls, ["delegate"])

        let v4 = FailingValidator("menu")
        try? v4.validateShortcut(makeShortcut())
        XCTAssertEqual(v4.calls, ["delegate", "system"])
    }

    func testDelegateFailure() {
        class Delegate : NSObject, ValidatorDelegate {
            func shortcutValidator(_ aValidator: Validator, isShortcutValid aShortcut: Shortcut, reason outReason: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool {
                outReason.pointee = "reason"
                return false
            }
        }

        let d = Delegate()
        let v = RecordingValidator(delegate: d)
        XCTAssertThrowsError(try v.validateShortcutAgainstDelegate(makeShortcut()))
    }

    func testSystemShortcutsFailure() {
        let v = RecordingValidator()
        XCTAssertThrowsError(try v.validateShortcutAgainstSystemShortcuts(Shortcut(code: 48, modifierFlags: [.command], characters: "⇥", charactersIgnoringModifiers: "⇥")))
    }

    func testMenuFailure() {
        let m = NSMenu()
        m.addItem(NSMenuItem(title: "item", action: nil, keyEquivalent: "a"))
        let v = RecordingValidator()
        XCTAssertThrowsError(try v.validateShortcut(Shortcut(code: 0, modifierFlags: [.command], characters: "a", charactersIgnoringModifiers: "a"), againstMenu: m))
    }

    func testNestedMenuFailure() {
        let m = NSMenu()
        m.addItem(NSMenuItem(title: "item", action: nil, keyEquivalent: ""))
        m.items[0].submenu = NSMenu()
        m.items[0].submenu!.addItem(NSMenuItem(title: "subitem", action: nil, keyEquivalent: "a"))
        let v = RecordingValidator()
        XCTAssertThrowsError(try v.validateShortcut(Shortcut(code: 0, modifierFlags: [.command], characters: "a", charactersIgnoringModifiers: "a"), againstMenu: m))
    }
}
