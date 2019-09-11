//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

import XCTest

import ShortcutRecorder


fileprivate class Target: NSObject, ShortcutActionTarget, NSUserInterfaceValidations {
    let expectation = XCTestExpectation()
    func perform(shortcutAction anAction: ShortcutAction) -> Bool {
        expectation.fulfill()
        return true
    }

    @objc func action(_ sender: Any?) {
        expectation.fulfill()
    }

    @objc func anotherAction() {
        expectation.fulfill()
    }

    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        return item.tag == 0
    }
}


class SRShortcutActionTests: XCTestCase {
    override func setUp() {
        UserDefaults.standard.removeObject(forKey: "shortcut")
    }

    func testSettingShortcutKVO() {
        XCTContext.runActivity(named: "Setting the same non-nil value") { _ in
            let action = ShortcutAction(shortcut: Shortcut.default) {_ in true }
            let expectation = keyValueObservingExpectation(for: action, keyPath: "shortcut", expectedValue: nil)
            expectation.isInverted = true
            action.shortcut = Shortcut.default
            wait(for: [expectation], timeout: 0)
        }

        XCTContext.runActivity(named: "Setting the same nil value") { _ in
            let action = ShortcutAction()
            let expectation = keyValueObservingExpectation(for: action, keyPath: "shortcut", expectedValue: nil)
            expectation.isInverted = true
            action.shortcut = nil
            wait(for: [expectation], timeout: 0)
        }

        XCTContext.runActivity(named: "Setting different values") { _ in
            let action = ShortcutAction()
            let expectation = keyValueObservingExpectation(for: action, keyPath: "shortcut", expectedValue: nil)
            expectation.assertForOverFulfill = true
            expectation.expectedFulfillmentCount = 3
            action.shortcut = Shortcut(keyEquivalent: "⌘A")
            action.shortcut = nil
            action.shortcut = Shortcut(keyEquivalent: "⌘B")
            wait(for: [expectation], timeout: 0)
        }
    }

    func testAutoupdatingShortcutKVO() {
        class Model: NSObject {
            @objc dynamic var shortcut: Shortcut?
        }

        XCTContext.runActivity(named: "Setting the same non-nil value") { _ in
            let model = Model()
            model.shortcut = Shortcut.default
            let action = ShortcutAction(keyPath: "shortcut", of: model) {_ in true }
            let expectation = keyValueObservingExpectation(for: action, keyPath: "shortcut", expectedValue: nil)
            expectation.isInverted = true
            model.shortcut = Shortcut.default
            wait(for: [expectation], timeout: 0)
        }

        XCTContext.runActivity(named: "Setting the same nil value") { _ in
            let model = Model()
            let action = ShortcutAction(keyPath: "shortcut", of: model) {_ in true }
            let expectation = keyValueObservingExpectation(for: action, keyPath: "shortcut", expectedValue: nil)
            expectation.isInverted = true
            model.shortcut = nil
            wait(for: [expectation], timeout: 0)
        }

        XCTContext.runActivity(named: "Setting different values") { _ in
            let model = Model()
            let action = ShortcutAction(keyPath: "shortcut", of: model) {_ in true }
            let expectation = keyValueObservingExpectation(for: action, keyPath: "shortcut", expectedValue: nil)
            expectation.assertForOverFulfill = true
            expectation.expectedFulfillmentCount = 3
            model.shortcut = Shortcut(keyEquivalent: "⌘A")
            model.shortcut = nil
            model.shortcut = Shortcut(keyEquivalent: "⌘B")
            wait(for: [expectation], timeout: 0)
        }
    }

    func testResettingAutoupdatingShortcutKVO() {
        class Model: NSObject {
            @objc dynamic var shortcut: Shortcut?
        }

        XCTContext.runActivity(named: "Resetting with the same non-nil value") { _ in
            let model = Model()
            model.shortcut = Shortcut.default
            let action = ShortcutAction(keyPath: "shortcut", of: model) {_ in true }
            let expectation = keyValueObservingExpectation(for: action, keyPath: "shortcut", expectedValue: nil)
            expectation.isInverted = true
            action.shortcut = Shortcut.default
            wait(for: [expectation], timeout: 0)
        }

        XCTContext.runActivity(named: "Resetting with the same nil value") { _ in
            let model = Model()
            let action = ShortcutAction(keyPath: "shortcut", of: model) {_ in true }
            let expectation = keyValueObservingExpectation(for: action, keyPath: "shortcut", expectedValue: nil)
            expectation.isInverted = true
            action.shortcut = nil
            wait(for: [expectation], timeout: 0)
        }
    }

    func testAutoupdatingFromShortcut() {
        class Model: NSObject {
            @objc dynamic var shortcut: Shortcut?
        }

        let model = Model()
        let action = ShortcutAction(keyPath: "shortcut", of: model) {_ in true }

        let valueExpectation = XCTKVOExpectation(keyPath: "shortcut", object: action, expectedValue: Shortcut.default, options: [.new])
        model.shortcut = Shortcut.default
        XCTAssertEqual(action.shortcut, Shortcut.default)

        let nilExpectation = XCTKVOExpectation(keyPath: "shortcut", object: action, expectedValue: nil, options: [.new])
        model.shortcut = nil
        XCTAssertNil(action.shortcut)

        wait(for: [valueExpectation, nilExpectation], timeout: 0, enforceOrder: true)
    }

    func testAutoupdatingFromDictionary() {
        class Model: NSObject {
            @objc dynamic var shortcut: [ShortcutKey: Any]?
        }

        let model = Model()
        let action = ShortcutAction(keyPath: "shortcut", of: model) {_ in true }

        model.shortcut = Shortcut.default.dictionaryRepresentation
        XCTAssertEqual(action.shortcut, Shortcut.default)

        model.shortcut = nil
        XCTAssertNil(action.shortcut)
    }

    func testAutoupdatingFromData() {
        class Model: NSObject {
            @objc dynamic var shortcut: Data?
        }

        let model = Model()
        let action = ShortcutAction(keyPath: "shortcut", of: model) {_ in true }

        model.shortcut = try! NSKeyedArchiver.archivedData(withRootObject: Shortcut.default, requiringSecureCoding: true)
        XCTAssertEqual(action.shortcut, Shortcut.default)

        model.shortcut = nil
        XCTAssertNil(action.shortcut)
    }

    func testAutoupdatingFromUserDefaultsController() {
        let defaults = NSUserDefaultsController.shared
        let action = ShortcutAction(keyPath: "values.shortcut", of: defaults) {_ in true }

        defaults.setValue(try! NSKeyedArchiver.archivedData(withRootObject: Shortcut.default, requiringSecureCoding: true), forKeyPath: "values.shortcut")
        XCTAssertEqual(action.shortcut, Shortcut.default)

        defaults.setValue(nil, forKeyPath: "values.shortcut")
        XCTAssertNil(action.shortcut)
    }

    func testSettingShortcutInvalidatesObservation() {
        class Model: NSObject {
            @objc dynamic var shortcut: Shortcut?
        }

        let model = Model()
        let action = ShortcutAction(keyPath: "shortcut", of: model) {_ in true }

        model.shortcut = Shortcut.default
        XCTAssertEqual(action.shortcut, Shortcut.default)

        action.shortcut = Shortcut.default
        XCTAssertEqual(action.shortcut, Shortcut.default)
        XCTAssertNil(action.observedObject)
        XCTAssertNil(action.observedKeyPath)
    }

    func testSettingActionHandlerResetsTarget() {
        let target = Target()
        let action = ShortcutAction(shortcut: Shortcut.default, target: target, action: nil, tag: 0)

        let expectation = keyValueObservingExpectation(for: action, keyPath: "target", expectedValue: nil)
        expectation.assertForOverFulfill = true

        XCTAssertTrue(action.target === target)
        XCTAssertNil(action.actionHandler)
        action.actionHandler = {_ in true }
        XCTAssertTrue(action.target === NSApp)
        XCTAssertNotNil(action.actionHandler)

        action.actionHandler = {_ in true }
        wait(for: [expectation], timeout: 0)
    }

    func testSettingTargetResetsActionHandler() {
        let target = Target()
        let action = ShortcutAction(shortcut: Shortcut.default) { _ in true }
        XCTAssertTrue(action.target === NSApp)
        XCTAssertNotNil(action.actionHandler)
        action.target = target
        XCTAssertTrue(action.target === target)
        XCTAssertNil(action.actionHandler)
    }

    func testPerformDisabledAction() {
        let target = Target()
        target.expectation.isInverted = true
        let action = ShortcutAction(shortcut: Shortcut.default, target: target, action: #selector(Target.action(_:)), tag: 0)
        action.isEnabled = false
        action.perform(onTarget: nil)
        wait(for: [target.expectation], timeout: 0)
    }

    func testPerformActionHandler() {
        let expectation = self.expectation(description: "action handler")
        let action = ShortcutAction(shortcut: Shortcut.default) { _ in
            expectation.fulfill()
            return true
        }
        action.perform(onTarget: nil)
        wait(for: [expectation], timeout: 0)
    }

    func testPerformAction() {
        XCTContext.runActivity(named: "action's target") { _ in
            let target = Target()
            target.expectation.assertForOverFulfill = true
            let action = ShortcutAction(shortcut: Shortcut.default, target: target, action: #selector(Target.action(_:)), tag: 0)
            action.perform(onTarget: nil)
            wait(for: [target.expectation], timeout: 0)
        }

        XCTContext.runActivity(named: "custom target") { _ in
            let target = Target()
            target.expectation.assertForOverFulfill = true
            let action = ShortcutAction(shortcut: Shortcut.default, target: nil, action: #selector(Target.action(_:)), tag: 0)
            action.perform(onTarget: target)
            wait(for: [target.expectation], timeout: 0)
        }
    }

    func testPerformActionWithoutArguments() {
        XCTContext.runActivity(named: "action's target") { _ in
            let target = Target()
            target.expectation.assertForOverFulfill = true
            let action = ShortcutAction(shortcut: Shortcut.default, target: target, action: #selector(Target.anotherAction), tag: 0)
            action.perform(onTarget: nil)
            wait(for: [target.expectation], timeout: 0)
        }

        XCTContext.runActivity(named: "custom target") { _ in
            let target = Target()
            target.expectation.assertForOverFulfill = true
            let action = ShortcutAction(shortcut: Shortcut.default, target: nil, action: #selector(Target.anotherAction), tag: 0)
            action.perform(onTarget: target)
            wait(for: [target.expectation], timeout: 0)
        }
    }

    func testPerformProtocol() {
        XCTContext.runActivity(named: "action's target") { _ in
            let target = Target()
            target.expectation.assertForOverFulfill = true
            let action = ShortcutAction(shortcut: Shortcut.default, target: target, action: nil, tag: 0)
            action.perform(onTarget: nil)
            wait(for: [target.expectation], timeout: 0)
        }

        XCTContext.runActivity(named: "custom target") { _ in
            let target = Target()
            target.expectation.assertForOverFulfill = true
            let action = ShortcutAction(shortcut: Shortcut.default, target: nil, action: nil, tag: 0)
            action.perform(onTarget: target)
            wait(for: [target.expectation], timeout: 0)
        }
    }

    func testProtocolIsPerformedIfActionIsNotImplemented() {
        XCTContext.runActivity(named: "action's target") { _ in
            let target = Target()
            target.expectation.assertForOverFulfill = true
            let action = ShortcutAction(shortcut: Shortcut.default, target: target, action: Selector("someAction:"), tag: 0)
            action.perform(onTarget: nil)
            wait(for: [target.expectation], timeout: 0)
        }

        XCTContext.runActivity(named: "custom target") { _ in
            let target = Target()
            target.expectation.assertForOverFulfill = true
            let action = ShortcutAction(shortcut: Shortcut.default, target: nil, action: Selector("someAction:"), tag: 0)
            action.perform(onTarget: target)
            wait(for: [target.expectation], timeout: 0)
        }
    }

    func testItemValidation() {
        let target = Target()
        target.expectation.isInverted = true
        let action = ShortcutAction(shortcut: Shortcut.default, target: target, action: #selector(Target.action(_:)), tag: 1)
        action.perform(onTarget: nil)
        wait(for: [target.expectation], timeout: 0)
    }
}


class SRShortcutMonitorTests: XCTestCase {
    func testAddingActionTwice() {
        let action = ShortcutAction(shortcut: Shortcut.default) {_ in true}
        let monitor = ShortcutMonitor()
        monitor.addShortcutAction(action)
        monitor.addShortcutAction(action)
        XCTAssertEqual(monitor.shortcutActions, [action])
        monitor.removeShortcutAction(action)
        XCTAssertTrue(monitor.shortcutActions.isEmpty)
    }

    func testMultipleActionsForShortcut() {
        let action1 = ShortcutAction(shortcut: Shortcut.default) {_ in true}
        let action2 = ShortcutAction(shortcut: Shortcut.default) {_ in true}
        let monitor = ShortcutMonitor()
        monitor.addShortcutAction(action1)
        monitor.addShortcutAction(action2)
        XCTAssertEqual(Set(monitor.shortcutActions), Set([action1, action2]))
        XCTAssertEqual(monitor.action(for: Shortcut.default)!, action2)
        XCTAssertEqual(monitor.allActions(for: Shortcut.default), [action1, action2])
    }

    func testActionShortcutObservation() {
        let shortcut1 = Shortcut(keyEquivalent: "⌘A")!
        let shortcut2 = Shortcut(keyEquivalent: "⌘B")!
        let action1 = ShortcutAction(shortcut: shortcut1) {_ in true}
        let action2 = ShortcutAction(shortcut: shortcut2) {_ in true}
        let monitor = ShortcutMonitor()
        monitor.addShortcutAction(action1)
        monitor.addShortcutAction(action2)
        XCTAssertEqual(monitor.action(for: shortcut1), action1)
        XCTAssertEqual(monitor.action(for: shortcut2), action2)
        XCTAssertEqual(Set(monitor.allShortcuts), Set([shortcut1, shortcut2]))
        action2.shortcut = shortcut1
        XCTAssertEqual(monitor.action(for: shortcut1), action2)
        XCTAssertEqual(Set(monitor.allActions(for: shortcut1)), Set([action1, action2]))
        XCTAssertTrue(monitor.allActions(for: shortcut2).isEmpty)
        XCTAssertEqual(monitor.allShortcuts, [shortcut1])
    }
}
