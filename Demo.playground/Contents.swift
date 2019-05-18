//: A Cocoa based Playground to present user interface

import AppKit
import PlaygroundSupport

import ShortcutRecorder


class ColoredView: NSView {
    var backgroundColor: NSColor?
    override func draw(_ dirtyRect: NSRect) {
        backgroundColor?.setFill()
        dirtyRect.fill()
    }
    override class var requiresConstraintBasedLayout: Bool {
        return true
    }
    override var isFlipped: Bool {
        return true
    }
}


class MyButton: NSButton {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

//        NSColor.darkGray.withAlphaComponent(0.5).setFill()
//        NSRect(x: 0.0, y: 0.0, width: self.frame.width, height: self.frame.height).fill()
//
//        NSColor.green.withAlphaComponent(0.5).setFill()
//        NSRect(x: self.alignmentRectInsets.left,
//               y: self.alignmentRectInsets.top,
//               width: self.frame.width - self.alignmentRectInsets.left - self.alignmentRectInsets.right,
//               height: self.frame.height - self.alignmentRectInsets.top - self.alignmentRectInsets.bottom).fill()
//
//        NSColor.red.setFill()
//        NSRect(x: self.alignmentRectInsets.left,
//               y: self.alignmentRectInsets.top + self.firstBaselineOffsetFromTop,
//               width: self.bounds.width - self.alignmentRe    tInsets.left - self.alignmentRectInsets.right,
//               height: 1.0).fill()
    }
}


let mainView = ColoredView(frame: NSRect(x: 0, y: 0, width: 500, height: 100))
mainView.appearance = NSAppearance(named: .darkAqua)
mainView.backgroundColor = NSColor.windowBackgroundColor

PlaygroundPage.current.liveView = mainView

let shortcutRecorder = RecorderControl(frame: NSRect(x: 0, y: 0, width: 100, height: 50))
mainView.addSubview(shortcutRecorder)

NSLayoutConstraint.activate([
    shortcutRecorder.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant: 20.0),
    shortcutRecorder.centerYAnchor.constraint(equalTo: mainView.centerYAnchor, constant: 0.0)
])

shortcutRecorder.hasAmbiguousLayout
shortcutRecorder.bounds
shortcutRecorder.frame
shortcutRecorder.alignmentRectInsets
shortcutRecorder.style.alignmentGuide.frame
shortcutRecorder.style.backgroundDrawingGuide.frame
shortcutRecorder.firstBaselineOffsetFromTop
shortcutRecorder.lastBaselineOffsetFromBottom

let bFirst = MyButton.init(title: "first", target: nil, action: nil)
bFirst.translatesAutoresizingMaskIntoConstraints = false
mainView.addSubview(bFirst)
NSLayoutConstraint.activate([
    bFirst.leadingAnchor.constraint(equalTo: shortcutRecorder.trailingAnchor, constant: -20.0),
//    bFirst.topAnchor.constraint(equalTo: shortcutRecorder.topAnchor),
    bFirst.bottomAnchor.constraint(equalTo: shortcutRecorder.bottomAnchor),
//    bFirst.firstBaselineAnchor.constraint(equalTo: shortcutRecorder.firstBaselineAnchor, constant: 0.0),
    bFirst.widthAnchor.constraint(equalToConstant: 50.0)
])

let bLast = MyButton.init(title: "last", target: nil, action: nil)
bLast.translatesAutoresizingMaskIntoConstraints = false
mainView.addSubview(bLast)
NSLayoutConstraint.activate([
    bLast.leadingAnchor.constraint(equalTo: bFirst.trailingAnchor, constant: 20.0),
    bLast.lastBaselineAnchor.constraint(equalTo: shortcutRecorder.lastBaselineAnchor, constant: 0.0),
    bLast.widthAnchor.constraint(equalToConstant: 50.0)
])
//
bFirst.bounds
bFirst.alignmentRectInsets
bFirst.baselineOffsetFromBottom
bFirst.firstBaselineOffsetFromTop
bFirst.lastBaselineOffsetFromBottom



//let mainView = ColoredView(frame: NSRect(x: 0, y: 0, width: 500, height: 1300))
//mainView.backgroundColor = NSColor.windowFrameColor

//
//let stackView = NSStackView()
//stackView.translatesAutoresizingMaskIntoConstraints = false
//stackView.orientation = .vertical
//stackView.distribution = .fillEqually
//stackView.alignment = .leading
//mainView.addSubview(stackView)
//
//NSLayoutConstraint.activate([
//    stackView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
//    stackView.topAnchor.constraint(equalTo: mainView.topAnchor),
//    stackView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor),
//    stackView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor)
//])
//
//func MakeView(color: NSColor, label: String) -> NSView {
//    let v = NSStackView()
//    v.orientation = .horizontal
//    v.translatesAutoresizingMaskIntoConstraints = false
//
//    let c = ColoredView()
//    c.backgroundColor = color
//    c.translatesAutoresizingMaskIntoConstraints = false
//    v.addSubview(c)
//
//    let cNone = ColoredView()
//    cNone.backgroundColor = color.withSystemEffect(.none)
//    cNone.translatesAutoresizingMaskIntoConstraints = false
//    v.addSubview(cNone)
//
//    let cPressed = ColoredView()
//    cPressed.backgroundColor = color.withSystemEffect(.pressed)
//    cPressed.translatesAutoresizingMaskIntoConstraints = false
//    v.addSubview(cPressed)
//
//    let cDeepPressed = ColoredView()
//    cDeepPressed.backgroundColor = color.withSystemEffect(.deepPressed)
//    cDeepPressed.translatesAutoresizingMaskIntoConstraints = false
//    v.addSubview(cDeepPressed)
//
//    let cDisabled = ColoredView()
//    cDisabled.backgroundColor = color.withSystemEffect(.disabled)
//    cDisabled.translatesAutoresizingMaskIntoConstraints = false
//    v.addSubview(cDisabled)
//
//    let cRollover = ColoredView()
//    cRollover.backgroundColor = color.withSystemEffect(.rollover)
//    cRollover.translatesAutoresizingMaskIntoConstraints = false
//    v.addSubview(cRollover)
//
//    let l = NSTextField(labelWithString: label)
//    l.translatesAutoresizingMaskIntoConstraints = false
//    l.setContentCompressionResistancePriority(.required, for: .vertical)
//    v.addSubview(l)
//
//    NSLayoutConstraint.activate([
//        c.leadingAnchor.constraint(equalTo: v.leadingAnchor),
//        c.topAnchor.constraint(equalTo: v.topAnchor),
//        c.bottomAnchor.constraint(equalTo: v.bottomAnchor),
//        c.widthAnchor.constraint(equalTo: c.heightAnchor, multiplier: 1.0),
//
//        cNone.leadingAnchor.constraint(equalTo: c.trailingAnchor, constant: 8),
//        cNone.topAnchor.constraint(equalTo: c.topAnchor),
//        cNone.widthAnchor.constraint(equalTo: c.widthAnchor, multiplier: 1),
//        cNone.heightAnchor.constraint(equalTo: c.heightAnchor, multiplier: 1),
//
//        cPressed.leadingAnchor.constraint(equalTo: cNone.trailingAnchor, constant: 8),
//        cPressed.topAnchor.constraint(equalTo: c.topAnchor),
//        cPressed.widthAnchor.constraint(equalTo: c.widthAnchor, multiplier: 1),
//        cPressed.heightAnchor.constraint(equalTo: c.heightAnchor, multiplier: 1),
//
//        cDeepPressed.leadingAnchor.constraint(equalTo: cPressed.trailingAnchor, constant: 8),
//        cDeepPressed.topAnchor.constraint(equalTo: c.topAnchor),
//        cDeepPressed.widthAnchor.constraint(equalTo: c.widthAnchor, multiplier: 1),
//        cDeepPressed.heightAnchor.constraint(equalTo: c.heightAnchor, multiplier: 1),
//
//        cDisabled.leadingAnchor.constraint(equalTo: cDeepPressed.trailingAnchor, constant: 8),
//        cDisabled.topAnchor.constraint(equalTo: c.topAnchor),
//        cDisabled.widthAnchor.constraint(equalTo: c.widthAnchor, multiplier: 1),
//        cDisabled.heightAnchor.constraint(equalTo: c.heightAnchor, multiplier: 1),
//
//        cRollover.leadingAnchor.constraint(equalTo: cDisabled.trailingAnchor, constant: 8),
//        cRollover.topAnchor.constraint(equalTo: c.topAnchor),
//        cRollover.widthAnchor.constraint(equalTo: c.widthAnchor, multiplier: 1),
//        cRollover.heightAnchor.constraint(equalTo: c.heightAnchor, multiplier: 1),
//
//        l.leadingAnchor.constraint(equalTo: cRollover.trailingAnchor, constant: 8),
//        l.centerYAnchor.constraint(equalTo: c.centerYAnchor)
//    ])
//
//    return v
//}
//
//let colors = [
//    "labelColor",
//    "secondaryLabelColor",
//    "tertiaryLabelColor",
//    "quaternaryLabelColor",
//    "linkColor",
//    "placeholderTextColor",
//    "windowFrameTextColor",
//    "selectedMenuItemTextColor",
//    "alternateSelectedControlTextColor",
//    "headerTextColor",
//    "separatorColor",
//    "gridColor",
//
//    "windowBackgroundColor",
//    "underPageBackgroundColor",
//    "controlBackgroundColor",
//    "selectedContentBackgroundColor",
//    "unemphasizedSelectedContentBackgroundColor",
//    "findHighlightColor",
//
//    "textColor",
//    "textBackgroundColor",
//    "selectedTextColor",
//    "selectedTextBackgroundColor",
//    "unemphasizedSelectedTextBackgroundColor",
//    "unemphasizedSelectedTextColor",
//
//    "controlColor",
//    "controlTextColor",
//    "selectedControlColor",
//    "selectedControlTextColor",
//    "disabledControlTextColor",
//    "keyboardFocusIndicatorColor",
//
//    "scrubberTexturedBackgroundColor",
//
//    "systemRedColor",
//    "systemGreenColor",
//    "systemBlueColor",
//    "systemOrangeColor",
//    "systemYellowColor",
//    "systemBrownColor",
//    "systemPinkColor",
//    "systemPurpleColor",
//    "systemGrayColor",
//
//    "controlAccentColor",
//    "highlightColor",
//    "shadowColor",
//
//    "controlHighlightColor",
//    "controlLightHighlightColor",
//    "controlShadowColor",
//    "controlDarkShadowColor",
//    "scrollBarColor",
//    "knobColor",
//    "selectedKnobColor",
//    "windowFrameColor",
//    "selectedMenuItemColor",
//    "headerColor",
//    "secondarySelectedControlColor",
//    "alternateSelectedControlColor"
//]
//// colorForControlTint
//// colorWithSystemEffect
//
//for colorName in colors {
//    let color = NSColor.perform(Selector(colorName))?.takeRetainedValue() as! NSColor
//    stackView.addView(MakeView(color: color, label: colorName), in: .top)
//}
//
//stackView.addView(MakeView(color: NSColor(for: .blueControlTint), label: "blueControlTint"), in: .top)
//stackView.addView(MakeView(color: NSColor(for: .graphiteControlTint), label: "graphiteControlTint"), in: .top)
//stackView.addView(MakeView(color: NSColor(for: .clearControlTint), label: "clearControlTint"), in: .top)
//
//func Capture(view: NSView, path: String) throws {
//    let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
//    view.cacheDisplay(in: view.bounds, to: rep)
//    let img = NSImage(size: view.bounds.size)
//    img.addRepresentation(rep)
//    try img.tiffRepresentation!.write(to: URL(fileURLWithPath: path))
//}
//
//let appearances: [NSAppearance.Name] = [
//    .aqua,
//    .darkAqua,
//    .vibrantLight,
//    .vibrantDark,
//]
//
//for a in appearances {
//    mainView.appearance = NSAppearance(named: a)
//    try Capture(view: mainView, path: "/tmp/green.\(a.rawValue).tiff")
//}
//
//let c = NSColor.controlColor.withSystemEffect(.none)
