//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 3.0
//

//: Compile the ShortcutRecorder.framework target first!

import AppKit
import PlaygroundSupport

import ShortcutRecorder

let mainView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 50))
PlaygroundPage.current.liveView = mainView

/*:
 Simply center in the container view and let the control resize itself.
 RecorderControl is native to the autolayout, no problems here.
 */

let shortcutRecorder = RecorderControl(frame: .zero)
mainView.addSubview(shortcutRecorder)

NSLayoutConstraint.activate([
    shortcutRecorder.centerXAnchor.constraint(equalTo: mainView.centerXAnchor),
    shortcutRecorder.centerYAnchor.constraint(equalTo: mainView.centerYAnchor)
])

/*:
 Now let's do a quick demo of how the control can be turned into an action.
 */

let defaults = NSUserDefaultsController.shared
let keyPath = "values.shortcut"
let options = [
    NSBindingOption.valueTransformerName: NSValueTransformerName.keyedUnarchiveFromDataTransformerName
]

/*:
 The value of the control is bound to a model, NSUserDefaultsController in this case.
 */
shortcutRecorder.bind(.value, to: defaults, withKeyPath: keyPath, options: options)

/*:
 From the other side there is a ShortcutRegistration that observes the model
 and binds the value to a simple action, one that beeps.
 */
let action: ShortcutAction = { _ in NSSound.beep() }
let registration = try! ShortcutRegistration.register(autoupdatingShortcutWithKeyPath: keyPath,
                                                      to: defaults,
                                                      action: action)

/*:
 Now any shortcut you record can be pressed again to play a short sound.
 */

//registration.invalidate()
