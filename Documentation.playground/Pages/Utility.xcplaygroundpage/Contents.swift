//: [Previous](@previous)
//#-hidden-code
import AppKit
import Carbon
import ShortcutRecorder
//#-end-hidden-code

/*:
 ## Modifier Flags

 Under the hood the framework relies on Carbon to register frameworks since there is no modern replacement in Cocoa.\
 Hence there are methods to convert between Cocoa and Carbom modifier flags:
 */
var cocoaFlags: NSEvent.ModifierFlags = [.command, .shift]
var carbonFlags = UInt32(cmdKey | shiftKey)
assert(cocoaToCarbonFlags(cocoaFlags) == carbonFlags)
assert(carbonToCocoaFlags(carbonFlags) == cocoaFlags)
/*:
 Since modifier flags may have other values than command, option, shift and control, there are masks to remove them:
 */
cocoaFlags = NSEvent.ModifierFlags([.command, .shift, .function]).intersection(CocoaModifierFlagsMask)
assert(cocoaFlags == [.command, .shift])

carbonFlags = UInt32(cmdKey | shiftKey | alphaLock) & CarbonModifierFlagsMask
assert(carbonFlags == UInt32(cmdKey | shiftKey))
/*:
 ## Glyphs

 A number of constants are present for rendering of key codes and modifier flags whose raw values do not\
 map into a representable glyph in the font:`
 - `SRKeyCodeGlyph` / `SRKeyCodeString`
 - `SRModifierFlagGlyph` / `SRModifierFlagString`
*/
assert(KeyCodeString.tabRight.rawValue == "⇥")
assert(String(format: "%C", KeyCodeGlyph.tabRight.rawValue) == "⇥")

assert(ModifierFlagString.command.rawValue == "⌘")
assert(String(format: "%C", ModifierFlagGlyph.command.rawValue) == "⌘")
/*:
 ## Resources

 ShortcutRecorder is a framework and therefore comes with a number of methods to locate and load its own resources
 when distributed as part of the bundle.

 `SRBundle()`, `SRLoc(_)` and `SRImage(_)` will locate bundle, localized string and image respectively.
 */
