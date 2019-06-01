import AppKit
import PlaygroundSupport

import ShortcutRecorder


/**
 NSView that draws a background.
 */
class ColorView: NSView {
    var backgroundColor: NSColor = .windowBackgroundColor
    override func draw(_ dirtyRect: NSRect) {
        backgroundColor.setFill()
        dirtyRect.fill()
    }
}

/**
 Capture view into a tiff image.
 */
func ViewToTIFF(view: NSView, path: String, scale: CGFloat) throws {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                               pixelsWide: Int(view.bounds.size.width * scale),
                               pixelsHigh: Int(view.bounds.size.height * scale),
                               bitsPerSample: 8,
                               samplesPerPixel: 4,
                               hasAlpha: true,
                               isPlanar: false,
                               colorSpaceName: .calibratedRGB,
                               bytesPerRow: 0,
                               bitsPerPixel: 0)!
    rep.size = view.bounds.size
    view.cacheDisplay(in: view.bounds, to: rep)
    let img = NSImage.init(size: view.bounds.size)
    img.addRepresentation(rep)
    try img.tiffRepresentation!.write(to: URL(fileURLWithPath: path))
}


let mainView = ColorView(frame: NSRect(x: 0, y: 0, width: 500, height: 100))
//mainView.appearance = NSAppearance(named: .darkAqua)
PlaygroundPage.current.liveView = mainView

let offscreenView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
offscreenView.translatesAutoresizingMaskIntoConstraints = false
let shortcutRecorder = RecorderControl(frame: .zero)
offscreenView.addSubview(shortcutRecorder)
NSLayoutConstraint.activate([
    shortcutRecorder.centerXAnchor.constraint(equalTo: offscreenView.centerXAnchor),
    shortcutRecorder.centerYAnchor.constraint(equalTo: offscreenView.centerYAnchor)
])
