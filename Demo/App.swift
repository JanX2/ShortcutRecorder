//
//  AppDelegate.swift
//  Demo
//
//  Created by Ilya Kulakov on 10/11/18.
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
            Setting.controlXAnchorTag.rawValue: AnchorTag.leading.rawValue,
            Setting.recorderControlYAnchorTag.rawValue: AnchorTag.firstBaseline.rawValue,
            Setting.controlYAnchorTag.rawValue: AnchorTag.firstBaseline.rawValue,
            Setting.assetScaleTag.rawValue: 2,
            Setting.controlAlpha.rawValue: CGFloat(0.5),
            Setting.controlDrawsChessboard.rawValue: true,
            Setting.controlDrawsBaseline.rawValue: true,
            Setting.controlDrawsAlignmentRect.rawValue: true,
            Setting.controlXAnchorConstant.rawValue: CGFloat(0.0),
            Setting.controlYAnchorConstant.rawValue: CGFloat(0.0),
            Setting.controlZoom.rawValue: 8
        ])

        ValueTransformer.setValueTransformer(MutableDictionaryTransformer(), forName: .mutableDictionaryTransformerName)

        super.awakeFromNib()
    }
}
