//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

import AppKit
import PlaygroundSupport

import ShortcutRecorder

PlaygroundPage.current.needsIndefiniteExecution = true
let mainView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 50))
PlaygroundPage.current.liveView = mainView

/*:
 Simply the control center in the container view and let it resize itself.
 RecorderControl is native to the autolayout, no problems here.
 */

let shortcutRecorder = RecorderControl(frame: .zero)
mainView.addSubview(shortcutRecorder)

NSLayoutConstraint.activate([
    shortcutRecorder.centerXAnchor.constraint(equalTo: mainView.centerXAnchor),
    shortcutRecorder.centerYAnchor.constraint(equalTo: mainView.centerYAnchor)
])

/*:
 Now let's do a quick demo of how a recorded shortcut can be turned into an action.
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
 On another side there is a ShortcutRegistration that observes the model
 and binds the value to a simple action.
 */
let sound = NSSound(named: "Purr")!
let action: ShortcutRegistration.Action = { _ in sound.play() }
let registration = ShortcutRegistration.register(keyPath: keyPath, of: defaults, action: action)
registration.dispatchQueue = DispatchQueue.global()

/*:
 Now any shortcut you record can be pressed again to play a short sound.
 Until you invalidate the registration.
 */

//registration.invalidate()

//: [Next](@next)
