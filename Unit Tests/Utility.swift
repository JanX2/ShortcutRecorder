//
//  Utility.swift
//  UnitTests
//
//  ShortcutRecorder.framework
//
//  Copyright 2018 Contributors. All rights reserved.
//  License: BSD
//
//  Contributors to this file:
//      Ilya Kulakov

import Foundation
import ShortcutRecorder


extension Shortcut {
    class var `default`: Shortcut
    {
        return self.init(code: 0,
                         modifierFlags: .option,
                         characters: "å",
                         charactersIgnoringModifiers: "a")
    }
}
