//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 3.0
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
        let registration = ShortcutRegistration.register(keyPath: "shortcut", of: model, action: {_ in })
        XCTAssertNil(registration.shortcut)

        model.shortcut = Shortcut.default
        XCTAssertEqual(registration.shortcut, Shortcut.default)

        model.shortcut = nil
        XCTAssertNil(registration.shortcut)
    }

    func testAutoupdatingFromDictionary() {
        class Model: NSObject {
            @objc dynamic var shortcut: [ShortcutKey: Any]?
        }

        let model = Model()
        let registration = ShortcutRegistration.register(keyPath: "shortcut", of: model, action: {_ in })
        XCTAssertNil(registration.shortcut)

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
        let registration = ShortcutRegistration.register(keyPath: "shortcut", of: model, action: {_ in })
        XCTAssertNil(registration.shortcut)

        model.shortcut = NSKeyedArchiver.archivedData(withRootObject: Shortcut.default)
        XCTAssertEqual(registration.shortcut, Shortcut.default)

        model.shortcut = nil
        XCTAssertNil(registration.shortcut)
    }

    func testAutoupdatingFromUserDefaultsController() {
        let defaults = NSUserDefaultsController.shared
        let keyPath = "values.shortcut"
        let registration = ShortcutRegistration.register(keyPath: keyPath, of: defaults, action: {_ in })
        XCTAssertNil(registration.shortcut)

        defaults.setValue(NSKeyedArchiver.archivedData(withRootObject: Shortcut.default), forKeyPath: keyPath)
        XCTAssertEqual(registration.shortcut, Shortcut.default)

        defaults.setValue(nil, forKeyPath: keyPath)
        XCTAssertNil(registration.shortcut)
    }

    func testValidity() {
        let registration = ShortcutRegistration()
        XCTAssertFalse(registration.isValid)

        registration.shortcut = Shortcut.default
        XCTAssertTrue(registration.isValid)

        registration.invalidate()
        XCTAssertFalse(registration.isValid)
    }
}
