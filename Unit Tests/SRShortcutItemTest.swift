//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

import XCTest
import ShortcutRecorder


fileprivate class Target: NSObject {
    let expectation = XCTestExpectation()
    @objc func myAction(_ sender: Any) {
        expectation.fulfill()
    }
}

class SRShortcutItemTest: XCTestCase {
    func testPerformImplementedMethod() {
        let catalog = ShortcutItemCatalog()
        let shortcut = Shortcut(keyEquivalent: "⌘A")!
        catalog.addAction(Selector("myAction:"), forShortcut: shortcut)
        let target = Target()
        catalog.perform(shortcut, onTarget: target)
        self.wait(for: [target.expectation], timeout: 0)
    }

    func testPerformNotImplementedMethod() {
        let catalog = ShortcutItemCatalog()
        let shortcut = Shortcut(keyEquivalent: "⌘A")!
        catalog.addAction(Selector("anotherAction:"), forShortcut: shortcut)
        let target = Target()
        target.expectation.isInverted = true
        catalog.perform(shortcut, onTarget: target)
        self.wait(for: [target.expectation], timeout: 0)
    }
}
