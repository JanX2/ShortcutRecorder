//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

import XCTest
import ShortcutRecorder


class SRValidatorTests: XCTestCase {
    class RecordingValidator : ShortcutValidator {
        var calls: [String] = []

        override func validateAgainstDelegate(shortcut aShortcut: Shortcut) throws {
            try super.validateAgainstDelegate(shortcut: aShortcut)
            self.calls.append("delegate")
        }

        override func validateAgainstSystemShortcuts(shortcut aShortcut: Shortcut) throws {
            try super.validateAgainstSystemShortcuts(shortcut: aShortcut)
            self.calls.append("system")
        }

        override func validate(shortcut aShortcut: Shortcut, againstMenu aMenu: NSMenu) throws {
            try super.validate(shortcut: aShortcut, againstMenu: aMenu)
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

            override func validateAgainstDelegate(shortcut aShortcut: Shortcut) throws {
                if self.failAt != "delegate" {
                    try super.validateAgainstDelegate(shortcut: aShortcut)
                }
                else {
                    throw NSError.init(domain: NSCocoaErrorDomain, code: 0, userInfo: nil)
                }
            }

            override func validateAgainstSystemShortcuts(shortcut aShortcut: Shortcut) throws {
                if self.failAt != "system" {
                    try super.validateAgainstSystemShortcuts(shortcut: aShortcut)
                }
                else {
                    throw NSError.init(domain: NSCocoaErrorDomain, code: 0, userInfo: nil)
                }
            }

            override func validate(shortcut aShortcut: Shortcut, againstMenu aMenu: NSMenu) throws {
                if self.failAt != "menu" {
                    try super .validate(shortcut: aShortcut, againstMenu: aMenu)
                }
                else {
                    throw NSError.init(domain: NSCocoaErrorDomain, code: 0, userInfo: nil)
                }
            }
        }

        let v1 = FailingValidator()
        try! v1.validate(shortcut: Shortcut.default)
        XCTAssertEqual(v1.calls, ["delegate", "system", "menu"])

        let v2 = FailingValidator("delegate")
        try? v2.validate(shortcut: Shortcut.default)
        XCTAssertEqual(v2.calls, [])

        let v3 = FailingValidator("system")
        try? v3.validate(shortcut: Shortcut.default)
        XCTAssertEqual(v3.calls, ["delegate"])

        let v4 = FailingValidator("menu")
        try? v4.validate(shortcut: Shortcut.default)
        XCTAssertEqual(v4.calls, ["delegate", "system"])
    }

    func testDelegateFailure() {
        class Delegate : NSObject, ShortcutValidatorDelegate {
            func shortcutValidator(_ aValidator: ShortcutValidator, isShortcutValid aShortcut: Shortcut, reason outReason: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool {
                outReason.pointee = "reason"
                return false
            }
        }

        let d = Delegate()
        let v = RecordingValidator(delegate: d)
        XCTAssertThrowsError(try v.validateAgainstDelegate(shortcut: Shortcut.default))
    }

    func testSystemShortcutsFailure() {
        let v = RecordingValidator()
        XCTAssertThrowsError(try v.validateAgainstSystemShortcuts(shortcut: Shortcut(code: 48, modifierFlags: [.command], characters: "⇥", charactersIgnoringModifiers: "⇥")))
    }

    func testMenuFailure() {
        let m = NSMenu()
        m.addItem(NSMenuItem(title: "item", action: nil, keyEquivalent: "a"))
        let v = RecordingValidator()
        XCTAssertThrowsError(try v.validate(shortcut: Shortcut(code: 0, modifierFlags: [.command], characters: "a", charactersIgnoringModifiers: "a"), againstMenu: m))
    }

    func testNestedMenuFailure() {
        let m = NSMenu()
        m.addItem(NSMenuItem(title: "item", action: nil, keyEquivalent: ""))
        m.items[0].submenu = NSMenu()
        m.items[0].submenu!.addItem(NSMenuItem(title: "subitem", action: nil, keyEquivalent: "a"))
        let v = RecordingValidator()
        XCTAssertThrowsError(try v.validate(shortcut: Shortcut(code: 0, modifierFlags: [.command], characters: "a", charactersIgnoringModifiers: "a"), againstMenu: m))
    }
}
