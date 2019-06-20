//#-hidden-code
import AppKit
import PlaygroundSupport
import ShortcutRecorder

PlaygroundPage.current.needsIndefiniteExecution = true
let mainView = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 500))
PlaygroundPage.current.liveView = mainView

let stackView = NSStackView()
stackView.orientation = .vertical
stackView.translatesAutoresizingMaskIntoConstraints = false
mainView.addSubview(stackView)
NSLayoutConstraint.activate([
    stackView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
    stackView.topAnchor.constraint(equalTo: mainView.topAnchor),
    stackView.widthAnchor.constraint(equalTo: mainView.widthAnchor)
])
//#-end-hidden-code
/*:
 - Important:
 Playground uses Live View.

 ## Adding the Control to View Hierarchy
 `RecorderControl` is native to Auto Layout and can handle its own intrinsic size.
 */
let targetActionLabel = NSTextField(labelWithString: "Target-Action:")
let targetActionRecorder = RecorderControl()

let bindingsLabel = NSTextField(labelWithString: "Bindings:")
let bindingsRecorder = RecorderControl()

let delegateLabel = NSTextField(labelWithString: "Delegate:")
let delegateRecorder = RecorderControl()

let views = [
    (targetActionLabel, targetActionRecorder),
    (bindingsLabel, bindingsRecorder),
    (delegateLabel, delegateRecorder)
]
for (label, recorder) in views {
    label.translatesAutoresizingMaskIntoConstraints = false

    let containerView = NSView()
    containerView.addSubview(label)
    containerView.addSubview(recorder)
    NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "|-(>=20)-[label]-[recorder]-(>=20)-|",
                                                               options: [.alignAllFirstBaseline],
                                                               metrics: nil,
                                                               views: ["label": label, "recorder": recorder]))
    NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|[recorder]|",
                                                               options: [],
                                                               metrics: nil,
                                                               views: ["recorder": recorder]))
    NSLayoutConstraint.activate([
        recorder.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
    ])

    stackView.addView(containerView, in: .center)
}
assert(!stackView.hasAmbiguousLayout)
/*:
 - Note: translatesAutoresizingMaskIntoConstraints is *off* by default.

 When clicked, the control beings recording whose product is an instance of `Shortcut`.
 The value can also be set directly via the `objectValue` property or the `NSValueBinding` binding.
 */
targetActionRecorder.objectValue = Shortcut(keyEquivalent: "⇧⌘A")!
// bindingsRecorder.objectValue is set by the corresponding binding below
delegateRecorder.objectValue = Shortcut(keyEquivalent: "⇧⌘B")!
/*:
 ## Configuring Modifier Flags Requirements
 `RecorderControl` allows you to forbid some modifier flags while require other.

 There are 3 properties that govern this behavior:
 - `allowedModifierFlags` controls what flags *can* be set
 - `requiredModifierFlags` controls what flags *must* be set
 - `allowsEmptyModifierFlags` controls whether no modifier flags are allowed

 - Important:
 The control will validate the settings raising an exception for conflicts like marking the flag both disallowed
 and required.
*/
targetActionRecorder.set(allowedModifierFlags: [.command, .shift, .control], // the option flag is not allowed
                         requiredModifierFlags: [.command, .shift], // ⇧ and ⌘ are required
                         allowsEmptyModifierFlags: false) // at least one modifier flag must be set
delegateRecorder.set(allowedModifierFlags: CocoaModifierFlagsMask,
                     requiredModifierFlags: [],
                     allowsEmptyModifierFlags: true)
bindingsRecorder.set(allowedModifierFlags: [.command, .option],
                     requiredModifierFlags: [.option],
                     allowsEmptyModifierFlags: false)
/*:
 The requirements can be bypassed by implementing either the `recorderControl(_:,shouldUnconditionallyAllow:,forKeyCode:)` delegate method or by setting `objectValue` directly.

 ## Configuring Key Code Handling
 Some keys are natural shortcuts with consistent actions assigned to them throughout the system and well-designed apps.
 The `RecorderControl` recognizes Escape to cancel the recording and Delete to end the recording by clearing current value.
 This behavior can be altered with `allowsEscapeToCancelRecording` and `allowsDeleteToClearShortcutAndEndRecording` respectively.

 ## View ↔︎ Controller Communication
 In Cocoa there is a number of ways how a view can communicate value changes to the controller. `RecorderControl`
 supports all of them.

 ### Target-Action
 The `target` and `action` properties inherited from `NSControl` are used to deliver a notification whenever recording ends.
 */
/// Target will print control's value whenever recording ends.
class Target: NSObject {
    @objc func action(sender: RecorderControl) {
        print("action: \(sender.stringValue)")
    }
}
let target = Target()
targetActionRecorder.target = target
targetActionRecorder.action = #selector(target.action(sender:))
/*:
 ### Bindings
 `RecorderControl` implements `NSValueBinding` and supports transformers.

 If the observed object also adopts the `NSEditorRegistration` protocol (typically a subclass of `NSDocument` and `NSController`)
 the control will notify it by using the appropriate methods.
 */
class Editor: NSObject, NSEditorRegistration {
    @objc var objectValue: Shortcut? = Shortcut(keyEquivalent: "⌥⌘C")!

    func objectDidBeginEditing(_ editor: NSEditor) {
        print("editor: did begin editing")
    }

    func objectDidEndEditing(_ editor: NSEditor) {
         print("editor: did end editing with \((editor as! RecorderControl).stringValue)")
    }
}
let editor = Editor()
bindingsRecorder.bind(.value, to: editor, withKeyPath: "objectValue", options: nil)
/*:
 ### Delegate
 The delegate may opt in to receive notifications whenever recording begins and ends.
 */
class Delegate: NSObject, RecorderControlDelegate {
    func recorderControlDidBeginRecording(_ aControl: RecorderControl) {
        print("delegate: did begin editing")
    }

    func recorderControlDidEndRecording(_ aControl: RecorderControl) {
        print("delegate did end editing with \(aControl.stringValue)")
    }
}
let delegate = Delegate()
delegateRecorder.delegate = delegate
/*:
 ## Styling
 Appearance of the control is controller by the `style` property which can be any object conforming to the `RecorderControlStyling` protocol.

 Here is an example of customizing the appearance to replicate XCode-alike Key Bindings preferences.
 */
class TableCellRecorderControl: RecorderControl {
//: `NSTableRowView` will automatically propagate its background style that is later used to alter label's color.
    @objc var backgroundStyle: NSView.BackgroundStyle = .normal {
        didSet {
            self.setNeedsDisplay(self.style.labelDrawingGuide.frame)
        }
    }

//: When row is selected, alter text color to match the behavior of `NSTextField`.
    override var drawingLabelAttributes: [NSAttributedString.Key : Any]? {
        var attributes = super.drawingLabelAttributes!

        if !isRecording {
            attributes[.foregroundColor] = backgroundStyle == .normal ? NSColor.controlTextColor : NSColor.alternateSelectedControlTextColor
        }

        return attributes
    }

//: Indicate recording visually by drawing the standard control background color.
    override func drawBackground(_ aDirtyRect: NSRect) {
        if isRecording {
            NSColor.controlBackgroundColor.setFill()
        }
        else {
            NSColor.clear.setFill()
        }

        aDirtyRect.fill()
    }

//: Do not draw "Click to Record Shortcut".
    override var drawingLabel: String {
        if isRecording {
            return super.drawingLabel
        }
        else {
            return self.stringValue
        }
    }
}

class RecorderControlTableViewStyle: NSObject, RecorderControlStyling {
//: Override required properties.
    let identifier = "sr-tableview"
    let allowsVibrancy = false
    let isOpaque = false
    let baselineDrawingOffsetFromBottom: CGFloat = 3.0
    let alignmentRectInsets = NSEdgeInsetsZero
    let intrinsicContentSize = NSSize(width: 20.0, height: 17.0)
    lazy var alignmentGuide = NSLayoutGuide()
    lazy var labelDrawingGuide = NSLayoutGuide()
    var alwaysConstraints = [NSLayoutConstraint]()
    var displayingConstraints = [NSLayoutConstraint]()
    var recordingWithNoValueConstraints = [NSLayoutConstraint]()
    var recordingWithValueConstraints = [NSLayoutConstraint]()
//: And provide attributes for the label.
    let normalLabelAttributes: [NSAttributedString.Key : Any] = [.font: NSFont.labelFont(ofSize: 13.0)]
    let recordingLabelAttributes: [NSAttributedString.Key : Any] = [
        .font: NSFont.labelFont(ofSize: 13.0),
        .foregroundColor: NSColor.disabledControlTextColor
    ]
    let disabledLabelAttributes: [NSAttributedString.Key : Any] = [.font: NSFont.labelFont(ofSize: 13.0)]
//: Attach guides after the style is added to the control.
    func prepareForRecorderControl(_ aControl: RecorderControl) {
        aControl.addLayoutGuide(alignmentGuide)
        aControl.addLayoutGuide(labelDrawingGuide)

        alwaysConstraints = [
            alignmentGuide.topAnchor.constraint(equalTo: aControl.topAnchor),
            alignmentGuide.leftAnchor.constraint(equalTo: aControl.leftAnchor),
            alignmentGuide.bottomAnchor.constraint(equalTo: aControl.bottomAnchor),
            alignmentGuide.rightAnchor.constraint(equalTo: aControl.rightAnchor),

            labelDrawingGuide.topAnchor.constraint(equalTo: alignmentGuide.topAnchor),
            labelDrawingGuide.leftAnchor.constraint(equalTo: alignmentGuide.leftAnchor),
            labelDrawingGuide.bottomAnchor.constraint(equalTo: alignmentGuide.bottomAnchor),
            labelDrawingGuide.rightAnchor.constraint(equalTo: alignmentGuide.rightAnchor)
        ]

        displayingConstraints = alwaysConstraints
        recordingWithValueConstraints = alwaysConstraints
        recordingWithValueConstraints = alwaysConstraints
    }
//: Detach guides when the style is about to be removed.
    func prepareForRemoval() {
        alignmentGuide.owningView?.removeLayoutGuide(alignmentGuide)
        labelDrawingGuide.owningView?.removeLayoutGuide(labelDrawingGuide)
    }
//: Boilerplate code to support `NSCopying`.
    func copy(with zone: NSZone? = nil) -> Any {
        return type(of: self).init()
    }

    override required init() { super.init() }
}
//: Each row in the table represents a Command and an associated Key Binding. Commands can have a default value
struct KeyBinding: Hashable {
    let name: String
    let defaultShortcut: Shortcut?
    var currentShortcut: Shortcut?
}
//: The table view has 2 columns: Command and Key. The Command column displays name of the command and the Key column displays either current or default shortcut.
extension NSUserInterfaceItemIdentifier {
    static let commandColumn = NSUserInterfaceItemIdentifier("CommandColumn")
    static let commandCell = NSUserInterfaceItemIdentifier("CommandCell")
    static let keyColumn = NSUserInterfaceItemIdentifier("KeyColumn")
    static let keyCell = NSUserInterfaceItemIdentifier("KeyCell")
}

class TableViewOwner: NSObject
{
//: Key Combinations displayed in the table.
    var keyBindings = [
        KeyBinding(name: "Undo", defaultShortcut: Shortcut(keyEquivalent: "⌘Z"), currentShortcut: nil),
        KeyBinding(name: "Redo", defaultShortcut: Shortcut(keyEquivalent: "⇧⌘Z"), currentShortcut: nil),
        KeyBinding(name: "Cut", defaultShortcut: Shortcut(keyEquivalent: "⌘X"), currentShortcut: nil),
        KeyBinding(name: "Copy", defaultShortcut: Shortcut(keyEquivalent: "⌘C"), currentShortcut: nil),
        KeyBinding(name: "Paste", defaultShortcut: Shortcut(keyEquivalent: "⌘V"), currentShortcut: nil),
        KeyBinding(name: "Paste Special", defaultShortcut: Shortcut(keyEquivalent: "⌥⌘V"), currentShortcut: nil),
        KeyBinding(name: "Paste and Preserve Formatting", defaultShortcut: Shortcut(keyEquivalent: "⌥⇧⌘V"), currentShortcut: nil)
    ]
//: Boilerplate code to set up the table view.
    var tableView: NSTableView!
    lazy var view: NSView = {
        tableView = NSTableView()
        tableView.usesAutomaticRowHeights = true
        tableView.dataSource = self
        tableView.delegate = self

        let commandColumn = NSTableColumn(identifier: .commandColumn)
        commandColumn.title = "Command"
        commandColumn.resizingMask = []
        commandColumn.isEditable = false
        commandColumn.width = 200.0

        let keyColumn = NSTableColumn(identifier: .keyColumn)
        keyColumn.title = "Key"

        tableView.addTableColumn(commandColumn)
        tableView.addTableColumn(keyColumn)

        let scrollView = NSScrollView()
        scrollView.borderType = .bezelBorder
        scrollView.documentView = tableView
        NSLayoutConstraint.activate([
            scrollView.widthAnchor.constraint(equalToConstant: 400.0),
            scrollView.heightAnchor.constraint(equalToConstant: 200.0)
        ])

        return scrollView
    }()
}
//: Implement `NSTableViewDelegate` and `NSTableViewDataSource` to populate the table view.
extension TableViewOwner: NSTableViewDelegate, NSTableViewDataSource {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let columnIdentifier = tableColumn!.identifier

        if columnIdentifier == .commandColumn {
            var view = tableView.makeView(withIdentifier: .commandCell, owner: self) as! NSTextField?
            if view == nil {
                view = NSTextField(labelWithString: "")
                view!.identifier = .commandCell
            }

            view!.stringValue = keyBindings[row].name
            return view
        }
        else if columnIdentifier == .keyColumn {
            var view = tableView.makeView(withIdentifier: .keyCell, owner: self) as! TableCellRecorderControl?
            if view == nil {
                view = TableCellRecorderControl()
                view!.style = RecorderControlTableViewStyle()
                view!.delegate = self
                view!.identifier = .keyCell
            }

            view!.objectValue = keyBindings[row].currentShortcut ?? keyBindings[row].defaultShortcut
            return view
        }

        return nil
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return keyBindings.count
    }
}
//: Select table's row visually when editing starts and save value when it ends.
extension TableViewOwner: RecorderControlDelegate {
    func recorderControlDidBeginRecording(_ aControl: RecorderControl) {
        tableView.selectRowIndexes(IndexSet(integer: tableView.row(for: aControl)), byExtendingSelection: false)
    }

    func recorderControlDidEndRecording(_ aControl: RecorderControl) {
        let index = tableView.row(for: aControl)
        keyBindings[index].currentShortcut = aControl.objectValue
        tableView.deselectRow(index)
    }
}
//: Add the table view to the playground.
let tableViewOwner = TableViewOwner()
stackView.addView(tableViewOwner.view, in: .center)
//: [Next](@next)
