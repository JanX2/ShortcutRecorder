//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

import XCTest

import ShortcutRecorder


class SRShortcutRegistrationTests: XCTestCase {
    override func setUp() {
        UserDefaults.standard.removeObject(forKey: "shortcut")
    }

    func testAutoupdatingFromShortcut() {
        class Model: NSObject {
            @objc dynamic var shortcut: Shortcut?
        }

        let model = Model()
        let registration = ShortcutRegistration.register(keyPath: "shortcut", of: model) {_ in }
        XCTAssertNotNil(registration.actionHandler)
        XCTAssertNotNil(registration.observedObject)
        XCTAssertNotNil(registration.observedKeyPath)
        XCTAssertNil(registration.shortcut)
        XCTAssertNil(registration.target)

        let valueExpectation = XCTKVOExpectation(keyPath: "shortcut", object: registration, expectedValue: Shortcut.default, options: [.new])
        model.shortcut = Shortcut.default
        XCTAssertEqual(registration.shortcut, Shortcut.default)

        let nilExpectation = XCTKVOExpectation(keyPath: "shortcut", object: registration, expectedValue: nil, options: [.new])
        model.shortcut = nil
        XCTAssertNil(registration.shortcut)

        wait(for: [valueExpectation, nilExpectation], timeout: 0, enforceOrder: true)
    }

    func testAutoupdatingFromDictionary() {
        class Model: NSObject {
            @objc dynamic var shortcut: [ShortcutKey: Any]?
        }

        let model = Model()
        let registration = ShortcutRegistration.register(keyPath: "shortcut", of: model) {_ in }
        XCTAssertNotNil(registration.actionHandler)
        XCTAssertNotNil(registration.observedObject)
        XCTAssertNotNil(registration.observedKeyPath)
        XCTAssertNil(registration.shortcut)
        XCTAssertNil(registration.target)

        model.shortcut = Shortcut.default.dictionaryRepresentation
        XCTAssertEqual(registration.shortcut, Shortcut.default)

        model.shortcut = nil
        XCTAssertNil(registration.shortcut)
    }

    func testAutoupdatingFromData() {
        class Model: NSObject {
            @objc dynamic var shortcut: Data?
        }

        let model = Model()
        let registration = ShortcutRegistration.register(keyPath: "shortcut", of: model) {_ in }
        XCTAssertNotNil(registration.actionHandler)
        XCTAssertNotNil(registration.observedObject)
        XCTAssertNotNil(registration.observedKeyPath)
        XCTAssertNil(registration.shortcut)
        XCTAssertNil(registration.target)

        model.shortcut = NSKeyedArchiver.archivedData(withRootObject: Shortcut.default)
        XCTAssertEqual(registration.shortcut, Shortcut.default)

        model.shortcut = nil
        XCTAssertNil(registration.shortcut)
    }

    func testAutoupdatingFromUserDefaultsController() {
        let defaults = NSUserDefaultsController.shared
        let keyPath = "values.shortcut"
        let registration = ShortcutRegistration.register(keyPath: keyPath, of: defaults) {_ in }
        XCTAssertNotNil(registration.actionHandler)
        XCTAssertNotNil(registration.observedObject)
        XCTAssertNotNil(registration.observedKeyPath)
        XCTAssertNil(registration.shortcut)
        XCTAssertNil(registration.target)

        defaults.setValue(NSKeyedArchiver.archivedData(withRootObject: Shortcut.default), forKeyPath: keyPath)
        XCTAssertEqual(registration.shortcut, Shortcut.default)

        defaults.setValue(nil, forKeyPath: keyPath)
        XCTAssertNil(registration.shortcut)
    }

    func testSettingActionHandlerAndTarget() {
        let registration = ShortcutRegistration()
        XCTAssertNil(registration.target)
        XCTAssertNil(registration.actionHandler)

        let action: ShortcutRegistration.Action = {_ in }

        var actionExpectation = XCTKVOExpectation(closureKeyPath: "actionHandler", object: registration)
        var targetExpectation = XCTKVOExpectation(keyPath: "target", object: registration, expectedValue: nil, options: [.new])
        targetExpectation.isInverted = true
        registration.actionHandler = action
        XCTAssertNil(registration.target)
        XCTAssertNotNil(registration.actionHandler)
        wait(for: [actionExpectation, targetExpectation], timeout: 0, enforceOrder: true)

        actionExpectation = XCTKVOExpectation(closureKeyPath: "actionHandler", object: registration)
        targetExpectation = XCTKVOExpectation(keyPath: "target", object: registration, expectedValue: self, options: [.new])
        registration.target = self
        XCTAssertNotNil(registration.target)
        XCTAssertNil(registration.actionHandler)
        wait(for: [actionExpectation, targetExpectation], timeout: 0, enforceOrder: true)

        actionExpectation = XCTKVOExpectation(closureKeyPath: "actionHandler", object: registration)
        actionExpectation.isInverted = true
        targetExpectation = XCTKVOExpectation(keyPath: "target", object: registration, expectedValue: self, options: [.new])
        targetExpectation.isInverted = true
        registration.target = self
        XCTAssertNotNil(registration.target)
        XCTAssertNil(registration.actionHandler)
        wait(for: [actionExpectation, targetExpectation], timeout: 0, enforceOrder: true)

        actionExpectation = XCTKVOExpectation(closureKeyPath: "actionHandler", object: registration)
        actionExpectation.isInverted = true
        targetExpectation = XCTKVOExpectation(keyPath: "target", object: registration, expectedValue: nil, options: [.new])
        registration.target = nil
        XCTAssertNil(registration.target)
        XCTAssertNil(registration.actionHandler)
        wait(for: [actionExpectation, targetExpectation], timeout: 0, enforceOrder: true)

        actionExpectation = XCTKVOExpectation(closureKeyPath: "actionHandler", object: registration)
        actionExpectation.isInverted = true
        targetExpectation = XCTKVOExpectation(keyPath: "target", object: registration, expectedValue: self, options: [.new])
        registration.target = self
        XCTAssertNotNil(registration.target)
        XCTAssertNil(registration.actionHandler)
        wait(for: [actionExpectation, targetExpectation], timeout: 0, enforceOrder: true)

        actionExpectation = XCTKVOExpectation(closureKeyPath: "actionHandler", object: registration)
        targetExpectation = XCTKVOExpectation(keyPath: "target", object: registration, expectedValue: nil, options: [.new])
        registration.actionHandler = action
        XCTAssertNil(registration.target)
        XCTAssertNotNil(registration.actionHandler)
        wait(for: [targetExpectation, actionExpectation], timeout: 0, enforceOrder: true)
    }

    func testFiringWithActionHandler() {
        let registration = ShortcutRegistration()
        let expectation = XCTestExpectation()
        registration.actionHandler = {_ in expectation.fulfill() }
        registration.fire()
        XCTWaiter(delegate: self).wait(for: [expectation], timeout: 1.0)
    }

    func testFiringWithTargetAction() {
        class Target: NSObject {
            let expectation = XCTestExpectation()
            override func performShortcutAction(_ aRegistration: ShortcutRegistration) {
                expectation.fulfill()
            }
        }
        let registration = ShortcutRegistration()
        let target = Target()
        registration.target = target
        registration.fire()
        XCTWaiter(delegate: self).wait(for: [target.expectation], timeout: 1.0)
    }

    func testInvalidation() {
        let registration = ShortcutRegistration()
        XCTAssertFalse(registration.isValid)

        let trueExpectation = XCTKVOExpectation(keyPath: "isValid", object: registration, expectedValue: true, options: [.new])
        registration.shortcut = Shortcut.default
        XCTAssertTrue(registration.isValid)

        let falseExpectation = XCTKVOExpectation(keyPath: "isValid", object: registration, expectedValue: false, options: [.new])
        registration.invalidate()
        XCTAssertFalse(registration.isValid)

        wait(for: [trueExpectation, falseExpectation], timeout: 0)
    }
}
