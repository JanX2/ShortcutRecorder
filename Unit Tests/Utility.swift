//
//  Copyright 2018 ShortcutRecorder Contributors
//  CC BY 4.0
//

import Foundation
import XCTest

import ShortcutRecorder


extension Shortcut {
    class var `default`: Shortcut
    {
        return self.init(code: 0,
                         modifierFlags: [.option, .command],
                         characters: "å",
                         charactersIgnoringModifiers: "a")
    }
}


extension XCTKVOExpectation {
    convenience init(closureKeyPath: String, object: Any) {
        self.init(keyPath: closureKeyPath, object: object, expectedValue: nil, options: [.new])
        handler = { (_, _) in return true }
    }
}
