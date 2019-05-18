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


func makeShortcut() -> Shortcut {
    return Shortcut(code: 0,
                    modifierFlags: .option,
                    characters: "å",
                    charactersIgnoringModifiers: "a")
}
