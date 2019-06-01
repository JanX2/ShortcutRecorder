//
//  Copyright 2018 ShortcutRecorder Contributors
//  CC BY 3.0
//

import Foundation
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
