//#-hidden-code
import AppKit
import PlaygroundSupport
import ShortcutRecorder

PlaygroundPage.current.needsIndefiniteExecution = true
let mainView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 50))
PlaygroundPage.current.liveView = mainView
//#-end-hidden-code
//: [Previous](@previous)
/*:
 - Important:
 Playground uses Live View.

 ## Formatters
 Sometimes it's useful to display a shortcut outside of the recorder control. E.g. in a tooltip or in a label.

 `ShortcutFormatter`, a subclass of `NSFormatter`, can be used for that:
 */
let label = NSTextField(labelWithString: "")
label.translatesAutoresizingMaskIntoConstraints = false
mainView.addSubview(label)
NSLayoutConstraint.activate([
    label.centerXAnchor.constraint(equalTo: mainView.centerXAnchor),
    label.centerYAnchor.constraint(equalTo: mainView.centerYAnchor),
    label.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
    label.trailingAnchor.constraint(equalTo: mainView.trailingAnchor),
    ])

label.formatter = ShortcutFormatter()
let shortcut = Shortcut(keyEquivalent: "⇧⌘A")!
label.objectValue = shortcut
/*:
 ## Transformers
 A number of transformers, subclasses of `NSValueTransformer`, are available for custom alternations.

 ### KeyCodeTransformer
 `KeyCodeTransformer` is a class-cluster that transforms the given numeric key code into a `String`.

 Translation of a key code varies across combinations of keyboards and input sources. E.g. `KeyCode.ansiA` corresponds
 to "a" in the U.S. English input source but to "ф" in the Russian input source. In addition, some keys, like
 `KeyCode.tab`, have dual representation: as an input character (`\u{9}`) and as a drawable glyph (`⇥`). Some glyphs may be
 sensitive to layout direction, e.g. `KeyCode.tab` glyph for right-to-left languages is `⇤`.

 The class-cluster is split into 2 main groups:
 - `*` uses current input source
 - `ASCII*` uses ASCII-capable input source.

 - Note:
 The ASCII-capable group is recommended as it provides consistent behavior for all users. It's what `RecorderControl`
 uses unless `drawsASCIIEquivalentOfShortcut` is unset.

 Each group is then split into 2 more subgroups:
 - `Symbolic` translates a key code into an input character
 - `Literal` translates a key code into a drawable glyph

 All in all there are 4 subclasses:

 - `SymbolicKeyCodeTransformer`: translates a key code into an input character using current input source
 - `LiteralKeyCodeTransformer`: translates a key code into a drawable glyph using current input source
 - `ASCIISymbolicKeyCodeTransformer`: translates a key code into an input character using ASCII-capable input source
 - `ASCIILiteralKeyCodeTransformer`: translates a key code into a drawable glyph using ASCII-capable input source;
 this is the only class in the cluster that *allows reverse transformation*

 The `transformedValue(_:,withImplicitModifierFlags:,explicitModifierFlags:,layoutDirection:)` designated method
 performs translation.

 Implicit modifier flags are the flags that are incorporated into visual appearance of the key code,
 e.g. ⌥a → å in the U.S. English input source.

 Explicit modifier may alter environment settings, e.g. ⇧ is sometimes used to alter the input direction.

 Layout direction can alter appearance of key codes like `KeyCode.tab`.
*/
print("Symbolic Key Code: \"\(ASCIISymbolicKeyCodeTransformer.shared.transformedValue(KeyCode.tab) as! String)\"")
print("Literal Key Code: \"\(ASCIILiteralKeyCodeTransformer.shared.transformedValue(KeyCode.tab) as! String)\"")
/*:
 ### ModifierFlagsTransformer
 `ModifierFlagsTransformer` is a class-cluster that transforms a combination of modifier flags into a `String`.

 There are 2 subclasses in the cluster.
 - `SymbolicModifierFlagsTransformer` translates a key code into an input sentance, e.g. Shift-Command
 - `LiteralModifierFlagsTransformer` translates a key code into an drawable glyph, e.g. ⇧⌘;
 this is the only class in the cluster that *allows reverse transformation*

 The `transformedValue(_, layoutDirection:)` designated method performs the translation. Layout direction alters the order
 of modifier flags, e.g. ⇧⌘ → ⌘⇧ / Shift-Command → Command-Shift
*/
let flags: NSEvent.ModifierFlags = [.shift, .command]
print("Symbolic Modifier Flags: \"\(SymbolicModifierFlagsTransformer.shared.transformedValue(flags.rawValue) as! String)\"")
print("Literal Modifier Flags: \"\(LiteralModifierFlagsTransformer.shared.transformedValue(flags.rawValue) as! String)\"")
/*:
 ### KeyEquivalentTransformer and KeyEquivalentModifierMaskTransformer
 Both are helper classes that can transform instances of `Shortcut` into Cocoa's
 `keyEquivalent` and `keyEquivalentModifierMask` properties of classes like `NSMenuItem` and `NSButton`.
*/
print("Key Equivalent: \"\(KeyEquivalentTransformer.shared.transformedValue(shortcut) as! String)\"")
print("Key Equivalent Modifier Mask: \"\(KeyEquivalentModifierMaskTransformer.shared.transformedValue(shortcut) as! UInt)\"")
 //: [Next](@next)
