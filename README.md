ShortcutRecorder 2
====================
![ShortcutRecorder Preview](http://wireload.net/open_source/ShortcutRecorder%20Preview.png)

The only user interface control to record shortcuts. For Mac OS X 10.6+, 64bit.

- Fresh Look & Feel (brought to you by [Wireload](http://wireload.net))
- With Retina support
- Auto Layout ready
- Correct drawing on Layer-backed and Layer-hosted views
- Accessibility for people with disabilities
- Revised codebase with Automatic Reference Counting support
- Translated into 24 languages

Includes framework to set global shortcuts (PTHotKey).

Take a look at [the demo](https://github.com/Kentzo/ShortcutRecorderDemo).

Get Sources
-----------
The preferred way to add the ShortcutRecorder to your project is to use git submodules:  
`git submodule add git://github.com/Kentzo/ShortcutRecorder.git`
You can download sources from the site as well.

Integrate into your project
---------------------------
First, add ShortcutRecorder.xcodeproj to your workspace via Xcode ([Apple docs](http://developer.apple.com/library/ios/#recipes/xcode_help-structure_navigator/articles/adding_a_project_to_a_workspace.html)). Don't have a workspace? No problem, just add ShortcutRecorder.xcodeproj via the "Add Files to" dialog.

Next step is to ensure your target is linked against the ShortcutRecorder or/and PTHotKey frameworks ([Apple docs](http://developer.apple.com/library/ios/#recipes/xcode_help-project_editor/Articles/AddingaLibrarytoaTarget.html#//apple_ref/doc/uid/TP40010155-CH17)). Desired frameworks will be listed under *Workspace*.

Now it's time to make frameworks part of your app. To do this, you need to add custom Build Phase ([Apple docs](http://developer.apple.com/library/ios/#recipes/xcode_help-project_editor/Articles/CreatingaCopyFilesBuildPhase.html)). Remember to set *Destination* to *Frameworks* and clean up *Subpath*.

Finally, ensure your app will find frameworks upon start. Open Build Settings of your target, look up *Runtime Search Paths*. Add `@executable_path/../Frameworks` to the list of paths.

Add control in Interface Builder
--------------------------------
Since Xcode 4 Apple removed support for custom control, unfortunately. However, you can still use it to add and position/resize ShortcutRecorder control. To do this, you need to add Custom View and set its class to SRRecorderControl.  

SRRecorderControl has fixed height of 25 points so ensure you do not use autoresizing masks/layout rules which allows vertical resizing. I recommend you to pin height in case you're using Auto Layout.

ShortcutRecorder, Key Equivalents and Keyboard Layout
----------------------------------------------------
While ShortcutRecorder keeps your shortcuts as combination of *key code* and modifier masks, key equivalents are expressed using *key character* and modifier mask. The key difference here is that position key on keyboard does not depend on current keyboard layout, position of key character does. 

ShortcutRecorder includes two special transformers: SRKeyEquivalentTransformer and SRKeyEquivalentModifierMaskTransformer. SRKeyEquivalentTransformer uses ASCII keyboard layout to convert key code into character, therefore resulting character does not depend on keyboard layout.  
The drawback is that position of the character on keyboard may change depending on layout and used modifier keys (primarly Option and Shift).

Questions
---------
Still have questions about how to use it? [Create an issue](https://github.com/Kentzo/ShortcutRecorder/issues/new) immediately and feel free to ping me.
