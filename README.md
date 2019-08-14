[![CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-orange.svg)](http://creativecommons.org/licenses/by/4.0/)
![macOS 10.11](https://img.shields.io/badge/macOS-10.11%2B-black.svg)
![Mac App Store Approved](https://img.shields.io/badge/Mac%20App%20Store-Approved-success.svg)

# ShortcutRecorder

The best control to record shortcuts on macOS

- Designed with Swift in mind
- Easily stylable
- Translated into 23 languages
- Supports macOS Accessibility
- Thoroughly documented
- Mac App Store approved
- End-to-end Interface Builder integration

## What is inside

The framework comes with:
- `SRRecorderControl` to render and capture user input
- `SRRecorderControlStyle` for custom styling
- `SRShortcut` that represents a shortcut model
- `SRShortcutRegistration` to turn the shortcut into an action by registering a global hot key
- `SRShortcutItem` and `SRShortcutItemCatalog` are indispensable for custom key equivalent handling in subclasses of `NSViewController`
- `SRShortcutController` for smooth Cocoa Bindings and seamless Interface Builder integration
- `SRShortcutValidator` to check validity of the shortcut against Cocoa key equivalents and global hot keys
- `NSValueTransformer` and `NSFormatter` subclasses for custom alternations

```swift
import ShortcutRecorder

let shortcut = Shortcut(keyEquivalent: "⇧⌘A")
let recorder = RecorderControl()

let defaults = NSUserDefaultsController.shared
let keyPath = "values.shortcut"
let options = [NSBindingOption.valueTransformerName: NSValueTransformerName.keyedUnarchiveFromDataTransformerName]

recorder.bind(.value, to: defaults, withKeyPath: keyPath, options: options)
let registration = ShortcutRegistration(keyPath: keyPath, of: defaults) {_ in NSSound.beep() }
```

## Integration

Make sure that your binaries depends ShortcutRecorder.framework  `import ShortcutRecorder` /  `#import <ShortcutRecorder/ShortcutRecorder.h>`
The framework supports modulemaps, no linking configuration is required.

### CocoaPods

Just follow your usual routine:

     pod 'ShortcutRecorder', '~> 3.0'

### Carthage

Again, nothing special:

    github "Kentzo/ShortcutRecorder" ~> 3.0

### Git Submodule

Add the submodule:

    git submodule add git://github.com/Kentzo/ShortcutRecorder.git

Then drag'n'drop into your Xcode's workspace and update your targets.

## Next Steps

- The Documentation playground covers all parts of the framework
- The Inspector app gives hands-on experience and is extremely useful for development of custom styles
- Read about [Styling](https://github.com/Kentzo/ShortcutRecorder/wiki/Styling) and special notes regarding [Cocoa's Key Equivalents](https://github.com/Kentzo/ShortcutRecorder/wiki/Cocoa-Key-Equivalents).

## Questions

Still have questions? [Create an issue](https://github.com/Kentzo/ShortcutRecorder/issues/new).

## Paid Support

Paid support is available for custom alternations, help with integration and general advice regarding Cocoa development.
