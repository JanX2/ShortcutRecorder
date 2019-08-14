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
assert(shortcut.keyCode == kVK_ANSI_A)
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
 ## System-wide Shortcut Registration
 `ShortcutRegistration` can register a system-wide shortcut (or global hot key as it is called in Carbon)

 - Note:
 ⌥⇧⌘A and ⌃⇧⌘B will be globally overridden until you terminate the Playground
 */
let registration = ShortcutRegistration(shortcut: shortcut) { registration in
    print("Handle global shortcut")
}
/*:
 In practice your shortcuts are stored somewhere, usually inside `NSUserDefaults`. Instead of manually observing
 these key paths and re-creating registrations you can initialize it with a key path. The rest will be handled for you.
 */
let autoupdatingRegistration = ShortcutRegistration(keyPath: "shortcut", of: UserDefaults.standard) { registration in
    print("Handle autoupdating global shortcut")
}
encodedShortcutData = NSKeyedArchiver.archivedData(withRootObject: Shortcut(keyEquivalent: "⌃⇧⌘B")!, requiringSecureCoding: true)
UserDefaults.standard.set(encodedShortcutData, forKey: "shortcut")
/*:
 In addition to `actionHandler`, `ShortcutRegistration` can be configured with a target conforming to `ShortcutRegistrationTarget`.
 It will then receive the corresponding message for every matching system-wide shortcut.
 */
/*:
 ## Shortcut Items and Catalogs
 When implementing custom `NSViewController` and `NSWindowController` subclasses it is often useful to handle
 custom shortcuts there. `ShortcutItemCatalog` allows to associate shortcuts and actions for later execution.

 In the following example a subclass of `NSViewController` handles the next and previous tab shortcuts.

 - Note:
 The `keyDown(with:)` method is overridden instead of the `performKeyEquivalent(with:)` because the latter is not called for controllers.
 */
class MyController: NSViewController {
    var shortcutCatalog = ShortcutItemCatalog()

    override func viewDidLoad() {
        super.viewDidLoad()
        shortcutCatalog.addAction(Selector("selectNextTab:"), forKeyEquivalent: "⇧⌘]")
        shortcutCatalog.addAction(Selector("selectPreviousTab:"), forKeyEquivalent: "⇧⌘[")
    }

    override func keyDown(with event: NSEvent) {
        if (!shortcutCatalog.perform(event, onTarget: self)) {
            super.keyDown(with: event)
        }
    }


    func selectNextTab(_ sender: Any?) {
        print("selectNextTab")
    }

    func selectPreviousTab(_ sender: Any?) {
        print("selectPreviousTab")
    }
}
//: [Next](@next)
