//#-hidden-code
import AppKit
import Carbon
import PlaygroundSupport
import ShortcutRecorder
PlaygroundPage.current.needsIndefiniteExecution = true
//#-end-hidden-code
//: [Previous](@previous)
/*:
 ## Shortcut
 Captured key code and modifier flags are represented by an instance of the `Shortcut` model class.

 The easiest way to create one in code is by using an ASCII key equivalent:
 */
let shortcut = Shortcut(keyEquivalent: "⌥⇧⌘A")!
assert(shortcut.keyCode == .ansiA)
assert(shortcut.modifierFlags == [.option, .shift, .command])
/*:
 The `characters` and `charactersIgnoringModifiers` are convenience properties similar to those of `NSEvent`
 and return translation of the key code and modifier flags, if available. They do not participate in equality tests.
 */
print("Shortcut Characters: \(shortcut.characters!)")
print("Shortcut Characters Ignoring Modifiers: \(shortcut.charactersIgnoringModifiers!)")
/*:
 Since some of the underlying API is using Carbon, there are convenience properties to get Carbon-representation
 of the `keyCode` and `modifierFlags`:
 */
print("Carbon Key Code: \(shortcut.carbonKeyCode)")
print("Carbon Modifier Flags: \(shortcut.carbonModifierFlags)")
/*:
 Shortcut can be checked for equality directly against a Cocoa-like key equivalent:
 */
shortcut.isEqual(keyEquivalent: "a", modifierFlags: [.shift])
/*:
 It conforms to `NSSecureCoding`:
 */
var encodedShortcutData = NSKeyedArchiver.archivedData(withRootObject: shortcut, requiringSecureCoding: true)
let decodedShortcut = try! NSKeyedUnarchiver.unarchivedObject(ofClass: Shortcut.self, from: encodedShortcutData)
assert(shortcut == decodedShortcut)
/*:
 ## Shortcut Validation
 The recorded shortcut is often used as either a key equivalent or a global shortcut. In either case you want to avoid
 assigning the same shortcut to multiple actions. `ShortcutValidator` helps to prevent these conflicts by checking
 against Main Menu and System Global Shortcuts for you.
 */
let validator = ShortcutValidator()
do {
    try validator.validate(shortcut: shortcut)
}
catch let error as NSError {
    print(error.localizedDescription)
}
/*:
 ## Shortcut Actions
 The `ShortcutAction` class connects shortcuts to actions.

 Shortcut can be set directly:
 */
let action = ShortcutAction(shortcut: shortcut) { action in
    print("Handle global shortcut")
    return true
}
/*:
 Or it can be observed from another object:
 */
let autoupdatingAction = ShortcutAction(keyPath: "shortcut", of: UserDefaults.standard) { action in
    print("Handle autoupdating global shortcut")
    return true
}
encodedShortcutData = NSKeyedArchiver.archivedData(withRootObject: Shortcut(keyEquivalent: "⌃⇧⌘B")!, requiringSecureCoding: true)
UserDefaults.standard.set(encodedShortcutData, forKey: "shortcut")
/*:
 Action can be a closure, as seen above, or it can be a target/action:
 */
let targetAction = ShortcutAction(shortcut: shortcut, target: nil, action: #selector(NSResponder.selectAll(_:)), tag: 0)
/*:
 If target is not specified it defaults to `NSApp`. See the class documentation for more configuration options.

 ## Shortcut Monitoring
 The `GlobalShortcutMonitor` and `LocalShortcutMonitor` use actions to observe and react to user's keyboard events.

 `GlobalShortcutMonitor` registers a global shortcut that can be activated regardless of an application that
 currently has the keyboard focus.

 - Note:
 ⌥⇧⌘A and ⌃⇧⌘B will be globally overridden until you terminate the Playground
 */
let globalMonitor = GlobalShortcutMonitor.shared
globalMonitor.addAction(action, forKeyEvent: .down)
globalMonitor.addAction(autoupdatingAction, forKeyEvent: .down)
/*:
 `LocalShortcutMonitor` organizes actions into a collection that can later by used for event dispatch e.g.
 in the subclasses of `NSResponder` such as `NSView` and `NSViewController`. It's a convenient alternative
 to `NSMenu`, e.g. when there are too many shortcuts to specify or when the app is headless and lacks
 the main menu altogether.
 */
class MyController: NSViewController {
    var localMonitor = LocalShortcutMonitor()

    override func viewDidLoad() {
        super.viewDidLoad()
        localMonitor.addAction(#selector(MyController.selectNextTab(_:)), forKeyEquivalent: "⇧⌘]", tag: 0)
        localMonitor.addAction(#selector(MyController.selectPreviousTab(_:)), forKeyEquivalent: "⇧⌘[", tag: 0)
    }

    override func keyDown(with event: NSEvent) {
        if (!localMonitor.handle(event, withTarget: self)) {
            super.keyDown(with: event)
        }
    }

    @objc func selectNextTab(_ sender: Any?) {
        print("selectNextTab")
    }

    @objc func selectPreviousTab(_ sender: Any?) {
        print("selectPreviousTab")
    }
}
//: [Next](@next)
