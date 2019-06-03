//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 3.0
//

import os
import Cocoa
import ShortcutRecorder


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    override func awakeFromNib() {
        let shortcut = Shortcut(code: 0, modifierFlags: [.shift, .control, .option, .command], characters: "A", charactersIgnoringModifiers: "a")
        let shortcutData = NSKeyedArchiver.archivedData(withRootObject: shortcut)

        UserDefaults.standard.register(defaults: [
            "NSFullScreenMenuItemEverywhere": false,
            "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints": true,
            Setting.showBindingsWindow.rawValue: true,
            Setting.showAssetsWindow.rawValue: true,
            Setting.shortcut.rawValue: shortcutData,
            Setting.style.rawValue: RecorderControlStyle.init().dictionaryRepresentation,
            Setting.isEnabled.rawValue: true,
            Setting.controlTag.rawValue: ControlTag.label.rawValue,
            Setting.recorderControlXAnchorTag.rawValue: AnchorTag.xCenter.rawValue,
            Setting.controlXAnchorTag.rawValue: AnchorTag.xCenter.rawValue,
            Setting.recorderControlYAnchorTag.rawValue: AnchorTag.firstBaseline.rawValue,
            Setting.controlYAnchorTag.rawValue: AnchorTag.firstBaseline.rawValue,
            Setting.assetScaleTag.rawValue: 2,
            Setting.controlAlpha.rawValue: CGFloat(0.5),
            Setting.controlDrawsChessboard.rawValue: false,
            Setting.controlDrawsBaseline.rawValue: false,
            Setting.controlDrawsAlignmentRect.rawValue: false,
            Setting.controlXAnchorConstant.rawValue: CGFloat(0.0),
            Setting.controlYAnchorConstant.rawValue: CGFloat(0.0),
            Setting.controlZoom.rawValue: 8
        ])

        ValueTransformer.setValueTransformer(MutableDictionaryTransformer(), forName: .mutableDictionaryTransformerName)

        super.awakeFromNib()
    }

    func showWindows() {
        let s = NSStoryboard(name: "Main", bundle: nil)
        let layoutInspector = s.instantiateController(withIdentifier: "LayoutInspector") as! NSWindowController
        let bindingsInspector = s.instantiateController(withIdentifier: "BindingsInspector") as! NSWindowController

        let layoutWindow = layoutInspector.window!
        let bindingsWindow = bindingsInspector.window!

        // The Window submenu alraedy lists all available windows.
        layoutWindow.isExcludedFromWindowsMenu = true
        bindingsWindow.isExcludedFromWindowsMenu = true

        bindingsInspector.showWindow(self)
        layoutInspector.showWindow(self)

        // Center both windows on the screen.
        // Must be called _after_ window is shown, otherwise frame origin may not be respected.
        layoutWindow.center()
        var layoutOrigin = layoutWindow.frame.origin
        layoutOrigin.x = (layoutOrigin.x + bindingsWindow.frame.width / 2.0).rounded()
        layoutWindow.setFrameOrigin(layoutOrigin)

        var bindingsOrigin = layoutOrigin
        bindingsOrigin.x -= bindingsWindow.frame.width
        bindingsWindow.setFrameOrigin(bindingsOrigin)

        layoutWindow.setFrameAutosaveName("SRLayoutInspector")
        bindingsWindow.setFrameAutosaveName("SRBindingsInspector")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        showWindows()
    }
}
