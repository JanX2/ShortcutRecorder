ShortcutRecorder 2.0
====================

The only user interface control to record shortcuts. For Mac OS X 10.6+, 64bit.

- Fresh Look & Feel
- With Retina support
- Auto Layout ready
- Correct drawing on Layer-backed and Layer-hosted views
- Accessibility for people with disabilities
- Revised codebase with Automatic Reference Counting support
- Translated into 24 languages

Includes framework to set global shortcuts.

Usage
-----
The preferred way to add the ShortcutRecorder to your project is to use git submodules.
Or you can download the sources and add them to copy them to your project.

Then in Xcode add the ShortcutRecorder.xcodeproj file to your project.
Open preferences of your target and add ensure it links against ShortcutRecorder.framework (and optionally PTHotKey)
Don't forget to add Copy Framework phase if needed.

To use ShortcutRecroder in IB, add a Custom View, set it's class SRRecorderControl. The height of the control should be *25* points.
If you're using AutoLayout, you should constraint height of the view to *25* points.
