[![CC BY 3.0](https://img.shields.io/badge/license-CC%20BY%203.0-orange.svg)](http://creativecommons.org/licenses/by/3.0/)
![macOS 10.11](https://img.shields.io/badge/macOS-10.11%2B-black.svg)

# ShortcutRecorder

The best control to record shortcuts on macOS

- Interface Builder integration
- Designed with Swift in mind
- Translated into 23 languages
- Support for macOS Accessibility
- Easily stylable

## What is inside

The framework comes with:
- `SRRecorderControl` to render and capture user's input
- `SRShortcut` to represent a shortcut
- `SRShortcutRegistration` to the shortcut into an action
- `SRShortcutController` for smooth Cocoa Bindings and seamless Interface Builder integration
- `SRValidator` to check the shortcut against local and global states
- `NSValueTransformer` and `NSFormatter` subclasses for custom alternations

## Integration

First add the framework into your Xcode project. Then modify your main target against ShortcutRecorder.framework
and `#import <ShortcutRecorder/ShortcutRecorder.h>` / `import ShortcutRecorder`.

### CocoaPods

Just follow your usual routine and add

     pod 'ShortcutRecorder', '~> 3.0'

### Carthage

Again, nothing special:

    github "Kentzo/ShortcutRecorder" ~> 3.0

### Git Submodule

    git submodule add git://github.com/Kentzo/ShortcutRecorder.git

Then drag'n'drop into your Xcode's workspace and update your targets to link against and include the framework

## Next Steps

See the Demo app and playground. Read about [Styling]() and special notes regarding [Cocoa's Key Equivalents]().

Questions
---------
Still have questions? [Create an issue](https://github.com/Kentzo/ShortcutRecorder/issues/new) immediately and feel free to ping me.

Paid Support
------------
If functional you need is missing but you're ready to pay for it, feel free to contact me. If not, create an issue anyway, I'll take a look as soon as I can.
