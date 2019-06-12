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
let cocoaFlags: NSEvent.ModifierFlags = [.command, .shift]
let carbonFlags = cmdKey | shiftKey
assert(SRCocoaToCarbonFlags(cocoaFlags) == carbonFlags)
assert(SRCarbonToCocoaFlags(carbonFlags) == cocoaFlags)
/*:
 Since modifier flags may have other values than command, option, shift and control, there are masks to remove them:
 */
let cocoaFlags: NSEvent.ModifierFlags = [.command, .shift, .function].intersection(SRCocoaModifierFlagsMask)
assert(cocoaFlags == [.command, .shift])

let carbonFlags = (cmdKey | shiftKey | alphaLock) & SRCarbonModifierFlagsMask
assert(carbonFlags == (cmdKey | shiftKey))
/*:
 ## Glyphs

 A number of constants are present for rendering of key codes and modifier flags whose raw values do not\
 map into a representable glyph in the font:`
 - `SRKeyCodeGlyph` / `SRKeyCodeString`
 - `SRModifierFlagGlyph` / `SRModifierFlagString`
*/
assert(SRKeyCodeString.tabRight == "⇥")
assert(String(format: "%C", SRKeyCodeGlyph.tabRight) == "⇥")

assert(SRModifierFlagString.command == "⌘")
assert(String(format: "%C", SRModifierFlagString.command) == "⌘")
/*:
 ## Resources

 ShortcutRecorder is a framework and therefore comes with a number of methods to locate and load its own resources
 when distributed as part of the bundle.

 `SRBundle()`, `SRLoc(_)` and `SRImage(_)` will locate bundle, localized string and image respectively.
 */
