//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 3.0
//

// Compile the ShortcutRecorder.framework target first!

import AppKit
import PlaygroundSupport

import ShortcutRecorder


let mainView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 50))
PlaygroundPage.current.liveView = mainView

let shortcutRecorder = RecorderControl(frame: .zero)
mainView.addSubview(shortcutRecorder)

NSLayoutConstraint.activate([
    shortcutRecorder.centerXAnchor.constraint(equalTo: mainView.centerXAnchor),
    shortcutRecorder.centerYAnchor.constraint(equalTo: mainView.centerYAnchor)
])
