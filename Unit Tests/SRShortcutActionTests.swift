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
            let action = ShortcutAction(shortcut: Shortcut.default, target: target, action: Selector(("someAction:")), tag: 0)
            action.perform(onTarget: nil)
            wait(for: [target.expectation], timeout: 0)
        }

        XCTContext.runActivity(named: "custom target") { _ in
            let target = Target()
            target.expectation.assertForOverFulfill = true
            let action = ShortcutAction(shortcut: .default, target: nil, action: Selector(("someAction:")), tag: 0)
            action.perform(onTarget: target)
            wait(for: [target.expectation], timeout: 0)
        }
    }

    func testItemValidation() {
        let target = Target()
        target.expectation.isInverted = true
        let action = ShortcutAction(shortcut: .default, target: target, action: #selector(Target.action(_:)), tag: 1)
        action.perform(onTarget: nil)
        wait(for: [target.expectation], timeout: 0)
    }
}


class SRShortcutMonitorTests: XCTestCase {
    /**
     A subclass of ShortcutMonitor that tracks addition and removal of shortcuts
     as well as verifies invariants in the hooks.
     */
    class TrackingMonitor: ShortcutMonitor {
        enum Change: Equatable {
            case add(Shortcut)
            case remove(Shortcut)
        }

        var changes: [Change] = []

        override func didAddShortcut(_ aShortcut: Shortcut) {
            changes.append(Change.add(aShortcut))

            let allActions = actions.filter { (action) in action.shortcut == aShortcut }
            let keyDownActions = actions(forKeyEvent: .down).filter { (action) in action.shortcut == aShortcut }
            let keyUpActions = actions(forKeyEvent: .up).filter { (action) in action.shortcut == aShortcut }
            let shortcutKeyDownActions = actions(forShortcut: aShortcut, keyEvent: .down)
            let shortcutKeyUpActions = actions(forShortcut: aShortcut, keyEvent: .up)

            XCTAssertTrue(shortcuts.contains(aShortcut))
            XCTAssertFalse(allActions.isEmpty)
            XCTAssertEqual(Set(allActions), Set(keyDownActions).union(keyUpActions))
            XCTAssertEqual(Set(allActions), Set(shortcutKeyDownActions).union(shortcutKeyUpActions))
            XCTAssertEqual(action(for: aShortcut, keyEvent: .down), shortcutKeyDownActions.last as ShortcutAction?)
            XCTAssertEqual(action(for: aShortcut, keyEvent: .up), shortcutKeyUpActions.last as ShortcutAction?)
        }

        override func didRemoveShortcut(_ aShortcut: Shortcut) {
            changes.append(Change.remove(aShortcut))

            let allActions = actions.filter { (action) in action.shortcut == aShortcut }
            let keyDownActions = actions(forKeyEvent: .down).filter { (action) in action.shortcut == aShortcut }
            let keyUpActions = actions(forKeyEvent: .up).filter { (action) in action.shortcut == aShortcut }
            let shortcutKeyDownActions = actions(forShortcut: aShortcut, keyEvent: .down)
            let shortcutKeyUpActions = actions(forShortcut: aShortcut, keyEvent: .up)

            XCTAssertFalse(shortcuts.contains(aShortcut))
            XCTAssertTrue(allActions.isEmpty)
            XCTAssertEqual(Set(allActions), Set(keyDownActions).union(keyUpActions))
            XCTAssertEqual(Set(allActions), Set(shortcutKeyDownActions).union(shortcutKeyUpActions))
            XCTAssertEqual(action(for: aShortcut, keyEvent: .down), shortcutKeyDownActions.last as ShortcutAction?)
            XCTAssertEqual(action(for: aShortcut, keyEvent: .up), shortcutKeyUpActions.last as ShortcutAction?)
        }
    }

    func testShortcutObservationOfSingleActionAdditionAndRemoval() {
        let action = ShortcutAction(shortcut: .default) {_ in true}

        func test(_ keyEvent: KeyEventType) {
            let monitor = TrackingMonitor()
            monitor.addAction(action, forKeyEvent: .down)
            monitor.removeAction(action)
            XCTAssertEqual(monitor.changes, [.add(.default), .remove(.default)])
        }

        XCTContext.runActivity(named: "down key event") { _ in test(.down) }
        XCTContext.runActivity(named: "up key event") { _ in test(.up) }
    }

    func testShortcutChangeObservationOfSingleAction() {
        let monitor = TrackingMonitor()
        let action = ShortcutAction()
        let cmd_a = Shortcut(keyEquivalent: "⌘A")!
        let cmd_b = Shortcut(keyEquivalent: "⌘B")!

        monitor.addAction(action, forKeyEvent: .down)
        XCTAssertEqual(monitor.changes, [])

        action.shortcut = cmd_a
        XCTAssertEqual(monitor.changes, [.add(cmd_a)])

        action.shortcut = cmd_b
        XCTAssertEqual(monitor.changes, [.add(cmd_a), .remove(cmd_a), .add(cmd_b)])

        action.shortcut = nil
        XCTAssertEqual(monitor.changes, [.add(cmd_a), .remove(cmd_a), .add(cmd_b), .remove(cmd_b)])
    }

    func testShortcutObservationOfMultipleActionsAdditionAndRemoval() {
        let cmd_a = Shortcut(keyEquivalent: "⌘A")!
        let action1 = ShortcutAction(shortcut: cmd_a) {_ in true}
        let action2 = ShortcutAction(shortcut: cmd_a) {_ in true}

        func test(_ keyEvent1: KeyEventType, _ keyEvent2: KeyEventType) {
            let monitor = TrackingMonitor()
            monitor.addAction(action1, forKeyEvent: keyEvent1)
            monitor.addAction(action2, forKeyEvent: keyEvent2)
            monitor.removeAction(action1)
            XCTAssertEqual(monitor.changes, [.add(cmd_a)])
            monitor.removeAction(action2)
            XCTAssertEqual(monitor.changes, [.add(cmd_a), .remove(cmd_a)])
        }

        XCTContext.runActivity(named: "down key event") { _ in test(.down, .down) }
        XCTContext.runActivity(named: "up key event") { _ in test(.up, .up) }
        XCTContext.runActivity(named: "down & up key events") { _ in test(.down, .up) }
        XCTContext.runActivity(named: "up & down key events") { _ in test(.up, .down) }
    }

    func testShortcutChangeObservationOfMultipleActions() {
        let cmd_a = Shortcut(keyEquivalent: "⌘A")!
        let cmd_b = Shortcut(keyEquivalent: "⌘B")!
        let action1 = ShortcutAction()
        let action2 = ShortcutAction()

        func test(_ keyEvent1: KeyEventType, _ keyEvent2: KeyEventType) {
            let monitor = TrackingMonitor()

            monitor.addAction(action1, forKeyEvent: keyEvent1)
            monitor.addAction(action2, forKeyEvent: keyEvent2)
            XCTAssertEqual(monitor.changes, [])

            action1.shortcut = cmd_a
            XCTAssertEqual(monitor.changes, [.add(cmd_a)])

            action2.shortcut = cmd_a
            XCTAssertEqual(monitor.changes, [.add(cmd_a)])

            action1.shortcut = cmd_b
            XCTAssertEqual(monitor.changes, [.add(cmd_a), .add(cmd_b)])

            action2.shortcut = cmd_b
            XCTAssertEqual(monitor.changes, [.add(cmd_a), .add(cmd_b), .remove(cmd_a)])

            action1.shortcut = cmd_a
            XCTAssertEqual(monitor.changes, [.add(cmd_a), .add(cmd_b), .remove(cmd_a), .add(cmd_a)])

            action2.shortcut = cmd_a
            XCTAssertEqual(monitor.changes, [.add(cmd_a), .add(cmd_b), .remove(cmd_a), .add(cmd_a), .remove(cmd_b)])

            action1.shortcut = nil
            XCTAssertEqual(monitor.changes, [.add(cmd_a), .add(cmd_b), .remove(cmd_a), .add(cmd_a), .remove(cmd_b)])

            action2.shortcut = nil
            XCTAssertEqual(monitor.changes, [.add(cmd_a), .add(cmd_b), .remove(cmd_a), .add(cmd_a), .remove(cmd_b), .remove(cmd_a)])
        }

        XCTContext.runActivity(named: "down key event") { _ in test(.down, .down) }
        XCTContext.runActivity(named: "up key event") { _ in test(.up, .up) }
        XCTContext.runActivity(named: "down & up key events") { _ in test(.down, .up) }
        XCTContext.runActivity(named: "up & down key events") { _ in test(.up, .down) }
    }

    func testRemovalOfAllActionsForShortcut() {
        let action1 = ShortcutAction(shortcut: Shortcut(keyEquivalent: "⌘A")!) {_ in true}
        let action2 = ShortcutAction(shortcut: Shortcut(keyEquivalent: "⌘B")!) {_ in true}

        func test(_ keyEvent1: KeyEventType, _ keyEvent2: KeyEventType) {
            let monitor = TrackingMonitor()
            monitor.addAction(action1, forKeyEvent: keyEvent1)
            monitor.addAction(action1, forKeyEvent: keyEvent2)
            monitor.addAction(action2, forKeyEvent: keyEvent1)
            monitor.addAction(action2, forKeyEvent: keyEvent2)
            monitor.removeAllActions(forShortcut: action1.shortcut!)
            XCTAssertEqual(monitor.changes, [.add(action1.shortcut!), .add(action2.shortcut!), .remove(action1.shortcut!)])
            XCTAssertEqual(monitor.actions(forShortcut: action1.shortcut!, keyEvent: .down), [])
            XCTAssertEqual(monitor.actions(forShortcut: action1.shortcut!, keyEvent: .up), [])
        }

        XCTContext.runActivity(named: "down key event") { _ in test(.down, .down) }
        XCTContext.runActivity(named: "up key event") { _ in test(.up, .up) }
        XCTContext.runActivity(named: "down & up key events") { _ in test(.down, .up) }
        XCTContext.runActivity(named: "up & down key events") { _ in test(.up, .down) }
    }

    func testRemovalOfAllActionsForKeyEvent() {
        let action1 = ShortcutAction(shortcut: Shortcut(keyEquivalent: "⌘A")!) {_ in true}
        let action2 = ShortcutAction(shortcut: Shortcut(keyEquivalent: "⌘B")!) {_ in true}
        let monitor = TrackingMonitor()
        monitor.addAction(action1, forKeyEvent: .down)
        monitor.addAction(action2, forKeyEvent: .up)
        monitor.removeAllActions(forKeyEvent: .down)
        XCTAssertEqual(monitor.changes, [.add(action1.shortcut!), .add(action2.shortcut!), .remove(action1.shortcut!)])
        XCTAssertEqual(monitor.actions(forKeyEvent: .down), [])
        monitor.removeAllActions(forKeyEvent: .up)
        XCTAssertEqual(monitor.changes, [.add(action1.shortcut!), .add(action2.shortcut!), .remove(action1.shortcut!), .remove(action2.shortcut!)])
        XCTAssertEqual(monitor.actions(forKeyEvent: .up), [])
        XCTAssertEqual(monitor.actions, [])
    }

    func testRemovalOfAllActions() {
        let action1 = ShortcutAction(shortcut: Shortcut(keyEquivalent: "⌘A")!) {_ in true}
        let action2 = ShortcutAction(shortcut: Shortcut(keyEquivalent: "⌘B")!) {_ in true}
        let monitor = TrackingMonitor()
        monitor.addAction(action1, forKeyEvent: .down)
        monitor.addAction(action2, forKeyEvent: .up)
        monitor.removeAllActions()
        XCTAssertEqual(monitor.changes[..<2], [.add(action1.shortcut!), .add(action2.shortcut!)])
        XCTAssertTrue(monitor.changes[2...].allSatisfy([.remove(action1.shortcut!), .remove(action2.shortcut!)].contains))
        XCTAssertEqual(monitor.actions(forKeyEvent: .down), [])
        XCTAssertEqual(monitor.actions(forKeyEvent: .up), [])
        XCTAssertEqual(monitor.actions, [])
    }

    func testAddingActionAgainMakesItMostRecent() {
        let action1 = ShortcutAction(shortcut: .default) {_ in true}
        let action2 = ShortcutAction(shortcut: .default) {_ in true}

        func test(_ keyEvent: KeyEventType) {
            let monitor = TrackingMonitor()
            monitor.addAction(action1, forKeyEvent: keyEvent)
            monitor.addAction(action2, forKeyEvent: keyEvent)
            XCTAssertEqual(monitor.action(for: .default, keyEvent: keyEvent), action2)
            XCTAssertEqual(monitor.actions(forShortcut: .default, keyEvent: keyEvent), [action1, action2])

            monitor.addAction(action1, forKeyEvent: keyEvent)
            XCTAssertEqual(monitor.action(for: .default, keyEvent: keyEvent), action1)
            XCTAssertEqual(monitor.actions(forShortcut: .default, keyEvent: keyEvent), [action2, action1])
        }

        XCTContext.runActivity(named: "down key event") { _ in test(.down) }
        XCTContext.runActivity(named: "up key event") { _ in test(.up) }
    }

    func testActionAddedTwiceIsObservedJustOnce() {
        class ObservedAction: ShortcutAction {
            let addObserverExpectation = XCTestExpectation(description: "add observer", assertForOverFulfill: true)
            let removeObserverExpectation = XCTestExpectation(description: "remove observer", assertForOverFulfill: true)

            override func addObserver(_ observer: NSObject, forKeyPath keyPath: String, options: NSKeyValueObservingOptions = [], context: UnsafeMutableRawPointer?) {
                addObserverExpectation.fulfill()
                super.addObserver(observer, forKeyPath: keyPath, options: options, context: context)
            }

            override func removeObserver(_ observer: NSObject, forKeyPath keyPath: String, context: UnsafeMutableRawPointer?) {
                removeObserverExpectation.fulfill()
                super.removeObserver(observer, forKeyPath: keyPath, context: context)
            }
        }

        func test(_ keyEvent1: KeyEventType, _ keyEvent2: KeyEventType) {
            let action = ObservedAction(shortcut: .default) { _ in true }
            let monitor = TrackingMonitor()
            monitor.addAction(action, forKeyEvent: keyEvent1)
            monitor.addAction(action, forKeyEvent: keyEvent2)
            monitor.removeAction(action, forKeyEvent: keyEvent1)
            monitor.removeAction(action, forKeyEvent: keyEvent2)
            wait(for: [action.addObserverExpectation, action.removeObserverExpectation], timeout: 0)
        }

        XCTContext.runActivity(named: "down key event") { _ in test(.down, .down) }
        XCTContext.runActivity(named: "up key event") { _ in test(.up, .up) }
        XCTContext.runActivity(named: "down & up key events") { _ in test(.down, .up) }
        XCTContext.runActivity(named: "up & down key events") { _ in test(.up, .down) }
    }

    func testActionAddedTwiceForTheSameKeyEventNeedsToBeRemovedOnce() {
        let action = ShortcutAction(shortcut: .default) { _ in true }

        func test(_ keyEvent: KeyEventType) {
            let monitor = TrackingMonitor()
            monitor.addAction(action, forKeyEvent: keyEvent)
            monitor.addAction(action, forKeyEvent: keyEvent)
            monitor.removeAction(action, forKeyEvent: keyEvent)
            XCTAssertEqual(monitor.changes, [.add(action.shortcut!), .remove(action.shortcut!)])
        }

        XCTContext.runActivity(named: "down key event") { _ in test(.down) }
        XCTContext.runActivity(named: "up key event") { _ in test(.up) }
    }

    func testActionAddedTwiceForDifferentKeyEventsNeedsToBeRemovedTwice() {
        let action = ShortcutAction(shortcut: .default) { _ in true }

        func test(_ keyEvent1: KeyEventType, _ keyEvent2: KeyEventType) {
            let monitor = TrackingMonitor()
            monitor.addAction(action, forKeyEvent: keyEvent1)
            monitor.addAction(action, forKeyEvent: keyEvent2)
            monitor.removeAction(action, forKeyEvent: keyEvent1)
            XCTAssertEqual(monitor.changes, [.add(action.shortcut!)])
            monitor.removeAction(action, forKeyEvent: keyEvent2)
            XCTAssertEqual(monitor.changes, [.add(action.shortcut!), .remove(action.shortcut!)])
        }

        XCTContext.runActivity(named: "down & up key events") { _ in test(.down, .up) }
        XCTContext.runActivity(named: "up & down key events") { _ in test(.up, .down) }
    }

    func testActionAddedTwiceForTheSameKeyEventInvariants() {
        let action = ShortcutAction(shortcut: .default) { _ in true }

        func test(_ keyEvent: KeyEventType) {
            let monitor = TrackingMonitor()
            let oppositeKeyEvent: KeyEventType = keyEvent == .down ? .up : .down

            monitor.addAction(action, forKeyEvent: keyEvent)
            monitor.addAction(action, forKeyEvent: keyEvent)
            XCTAssertEqual(monitor.actions, [action])
            XCTAssertEqual(monitor.actions(forKeyEvent: keyEvent), [action])
            XCTAssertEqual(monitor.actions(forKeyEvent: oppositeKeyEvent), [])

            monitor.removeAction(action, forKeyEvent: keyEvent)
            XCTAssertEqual(monitor.actions, [])
            XCTAssertEqual(monitor.actions(forKeyEvent: keyEvent), [])
            XCTAssertEqual(monitor.actions(forKeyEvent: oppositeKeyEvent), [])
        }

        XCTContext.runActivity(named: "down key event") { _ in test(.down) }
        XCTContext.runActivity(named: "up key event") { _ in test(.up) }
    }

    func testActionAddedTwiceForDifferentKeyEventsInvariants() {
        let action = ShortcutAction(shortcut: .default) { _ in true }

        func test(_ keyEvent1: KeyEventType, _ keyEvent2: KeyEventType) {
            let monitor = TrackingMonitor()

            monitor.addAction(action, forKeyEvent: keyEvent1)
            monitor.addAction(action, forKeyEvent: keyEvent2)
            XCTAssertEqual(monitor.actions, [action])
            XCTAssertEqual(monitor.actions(forKeyEvent: keyEvent1), [action])
            XCTAssertEqual(monitor.actions(forKeyEvent: keyEvent2), [action])

            monitor.removeAction(action, forKeyEvent: keyEvent1)
            XCTAssertEqual(monitor.actions, [action])
            XCTAssertEqual(monitor.actions(forKeyEvent: keyEvent1), [])
            XCTAssertEqual(monitor.actions(forKeyEvent: keyEvent2), [action])

            monitor.removeAction(action, forKeyEvent: keyEvent2)
            XCTAssertEqual(monitor.actions, [])
            XCTAssertEqual(monitor.actions(forKeyEvent: keyEvent1), [])
            XCTAssertEqual(monitor.actions(forKeyEvent: keyEvent2), [])
        }

        XCTContext.runActivity(named: "down & up key events") { _ in test(.down, .up) }
        XCTContext.runActivity(named: "up & down key events") { _ in test(.up, .down) }
    }
}


class SRGlobalShortcutMonitorTests: XCTestCase {
    /**
    A subclass of ShortcutMonitor that tracks addition and removal of the Carbon event hook.
    */
    class TrackingMonitor: GlobalShortcutMonitor {
        enum Change: Equatable { case add, remove }

        var changes: [Change] = []
        var didAddExpectation: XCTestExpectation!
        var didRemoveExpectation: XCTestExpectation!

        override func didAddEventHandler() {
            super.didAddEventHandler()
            changes.append(.add)
            didAddExpectation?.fulfill()
        }

        override func didRemoveEventHandler() {
            super.didRemoveEventHandler()
            changes.append(.remove)
            didRemoveExpectation?.fulfill()
        }

        func reset() {
            removeAllActions()
            changes = []
        }
    }

    func testHandlerAdditionAndRemoval() {
        let monitor = TrackingMonitor()
        let action = ShortcutAction(shortcut: Shortcut.default) { _ in true }
        monitor.addAction(action, forKeyEvent: .down)
        XCTAssertEqual(monitor.changes, [.add])
        monitor.removeAction(action)
        XCTAssertEqual(monitor.changes, [.add, .remove])
    }

    func testDeallocationRemovesHandler() {
        let didAddExpectation = XCTestExpectation(description: "did add", assertForOverFulfill: true)
        let didRemoveExpectation = XCTestExpectation(description: "did remove", assertForOverFulfill: true)
        var monitor: TrackingMonitor! = TrackingMonitor()
        let action = ShortcutAction(shortcut: Shortcut.default) { _ in true }

        monitor.didAddExpectation = didAddExpectation
        monitor.didRemoveExpectation = didRemoveExpectation
        monitor.addAction(action, forKeyEvent: .down)
        monitor = nil

        wait(for: [didAddExpectation, didRemoveExpectation], timeout: 0, enforceOrder: true)
    }

    func testPauseAndResumeAreCounted() {
        let monitor = TrackingMonitor()
        let action = ShortcutAction(shortcut: .default) { _ in true }

        monitor.addAction(action, forKeyEvent: .down)
        XCTAssertEqual(monitor.changes, [.add])

        monitor.resume()
        monitor.pause()
        XCTAssertEqual(monitor.changes, [.add])

        monitor.pause()
        XCTAssertEqual(monitor.changes, [.add, .remove])

        monitor.pause()
        monitor.resume()
        XCTAssertEqual(monitor.changes, [.add, .remove])

        monitor.resume()
        XCTAssertEqual(monitor.changes, [.add, .remove, .add])
    }

    func testPauseAndResume() {
        let monitor = TrackingMonitor()
        let action1 = ShortcutAction(shortcut: .default) { _ in true }
        let action2 = ShortcutAction(shortcut: .default) { _ in true }

        monitor.pause()
        monitor.resume()
        XCTAssertEqual(monitor.changes, [])

        monitor.reset()
        monitor.pause()
        monitor.addAction(action1, forKeyEvent: .down)
        XCTAssertEqual(monitor.changes, [])
        monitor.resume()
        XCTAssertEqual(monitor.changes, [.add])

        monitor.reset()
        monitor.pause()
        monitor.addAction(action1, forKeyEvent: .down)
        monitor.removeAction(action1)
        XCTAssertEqual(monitor.changes, [])
        monitor.resume()
        XCTAssertEqual(monitor.changes, [])

        monitor.reset()
        monitor.addAction(action1, forKeyEvent: .down)
        monitor.pause()
        monitor.resume()
        XCTAssertEqual(monitor.changes, [.add, .remove, .add])

        monitor.reset()
        monitor.addAction(action1, forKeyEvent: .down)
        monitor.pause()
        monitor.removeAction(action1)
        monitor.resume()
        XCTAssertEqual(monitor.changes, [.add, .remove])

        monitor.reset()
        monitor.addAction(action1, forKeyEvent: .down)
        monitor.pause()
        monitor.addAction(action2, forKeyEvent: .down)
        monitor.removeAction(action2)
        XCTAssertEqual(monitor.changes, [.add, .remove])
        monitor.resume()
        XCTAssertEqual(monitor.changes, [.add, .remove, .add])
    }

    func testAddingKeylessShortcutDoesNotInstallHandler() {
        let monitor = TrackingMonitor()
        monitor.didAddExpectation = XCTestExpectation(description: "did add", isInverted: true)
        monitor.didRemoveExpectation = XCTestExpectation(description: "did remove", isInverted: true)
        let shortcut = Shortcut(code: .none, modifierFlags: .shift, characters: nil, charactersIgnoringModifiers: nil)
        let action = ShortcutAction(shortcut: shortcut) { _ in true }

        monitor.addAction(action, forKeyEvent: .down)
        monitor.removeAllActions()

        wait(for: [monitor.didAddExpectation, monitor.didRemoveExpectation], timeout: 0, enforceOrder: true)
    }
}
