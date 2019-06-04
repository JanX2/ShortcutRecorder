//: [Previous](@previous)

import AppKit
import PlaygroundSupport

import ShortcutRecorder

PlaygroundPage.current.needsIndefiniteExecution = true
let mainView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 50))
PlaygroundPage.current.liveView = mainView

let label = NSTextField(labelWithString: "")
label.translatesAutoresizingMaskIntoConstraints = false
mainView.addSubview(label)
NSLayoutConstraint.activate([
    label.centerXAnchor.constraint(equalTo: mainView.centerXAnchor),
    label.centerYAnchor.constraint(equalTo: mainView.centerYAnchor),
    label.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
    label.trailingAnchor.constraint(equalTo: mainView.trailingAnchor),
])

/*:
 Sometimes it's useful to display a shortcut outside of the recorder control.
 E.g. in a tooltip or in a label.

 `ShortcutFormatter`, a subclass of `NSFormatter`, can be used for that
 */
label.formatter = ShortcutFormatter()
let shortcut = Shortcut(code: 0, modifierFlags: [.shift, .command], characters: "A", charactersIgnoringModifiers: "a")
label.objectValue = shortcut

//: [Next](@next)
