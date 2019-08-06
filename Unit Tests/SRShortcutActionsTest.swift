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

class SRShortcutActionsTest: XCTestCase {
    func testPerformImplementedMethod() {
        let actions = ShortcutActions()
        let shortcut = Shortcut(keyEquivalent: "⌘A")!
        actions.setAction(Selector("myAction:"), for: shortcut)
        let target = Target()
        actions.perform(shortcut, onTarget: target)
        self.wait(for: [target.expectation], timeout: 0)
    }

    func testPerformNotImplementedMethod() {
        let actions = ShortcutActions()
        let shortcut = Shortcut(keyEquivalent: "⌘A")!
        actions.setAction(Selector("anotherAction:"), for: shortcut)
        let target = Target()
        target.expectation.isInverted = true
        actions.perform(shortcut, onTarget: target)
        self.wait(for: [target.expectation], timeout: 0)
    }
}
