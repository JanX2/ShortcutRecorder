//
//  SRRecorderControlStyle.h
//  ShortcutRecorder.framework
//
//  Copyright 2019 Contributors. All rights reserved.
//  License: BSD
//
//  Contributors to this file:
//      Ilya Kulakov

#import <Foundation/Foundation.h>


@class SRRecorderControl;


NS_ASSUME_NONNULL_BEGIN

/*!
 Styling is responsible for providing resources and metrics to draw SRRecorderControl.

 @seealso controlAppearanceDidChange:
 */
NS_SWIFT_NAME(RecorderControlStyling)
@protocol SRRecorderControlStyling <NSCopying>

/*!
 Unique identifier of the style.
 */
@property (readonly) NSString *identifier;

/*!
 @seealso NSView/allowsVibrancy
 */
@property (readonly) BOOL allowsVibrancy;

/*!
 @seealso NSView/opaque
 */
@property (getter=isOpaque, readonly) BOOL opaque;

/*!
 Label attributes for displaying when enabled.
 */
@property (nullable, readonly) NSDictionary<NSAttributedStringKey, id> *normalLabelAttributes;

/*!
 Label attributes for displaying when recoding.
 */
@property (nullable, readonly) NSDictionary<NSAttributedStringKey, id> *recordingLabelAttributes;

/*!
 Label attributes for displaying when enabled.
 */
@property (nullable, readonly) NSDictionary<NSAttributedStringKey, id> *disabledLabelAttributes;

@property (nullable, readonly) NSImage *bezelNormalLeft;
@property (nullable, readonly) NSImage *bezelNormalCenter;
@property (nullable, readonly) NSImage *bezelNormalRight;

@property (nullable, readonly) NSImage *bezelPressedLeft;
@property (nullable, readonly) NSImage *bezelPressedCenter;
@property (nullable, readonly) NSImage *bezelPressedRight;

@property (nullable, readonly) NSImage *bezelRecordingLeft;
@property (nullable, readonly) NSImage *bezelRecordingCenter;
@property (nullable, readonly) NSImage *bezelRecordingRight;

@property (nullable, readonly) NSImage *bezelDisabledLeft;
@property (nullable, readonly) NSImage *bezelDisabledCenter;
@property (nullable, readonly) NSImage *bezelDisabledRight;

@property (nullable, readonly) NSImage *cancelButton;
@property (nullable, readonly) NSImage *cancelButtonPressed;

@property (nullable, readonly) NSImage *clearButton;
@property (nullable, readonly) NSImage *clearButtonPressed;

/*!
 Corner radius of control's shape.

 Used to draw focus ring.
 */
@property (readonly) NSSize shapeCornerRadius;

/*!
 Shape insets relative to alignment frame.

 Used to draw focus ring.
 */
@property (readonly) NSEdgeInsets shapeInsets;

/*!
 @seealso NSView/baselineOffsetFromBottom
 */
@property (readonly) CGFloat baselineOffsetFromBottom;

/*!
 @seealso NSView/alignmentRectInsets
 */
@property (readonly) NSEdgeInsets alignmentRectInsets;

/*!
 @seealso NSView/intrinsicContentSize
 */
@property (readonly) NSSize intrinsicContentSize;

/*!
 Frame that applies alignment insets to view's bounds.
 */
@property (readonly) NSLayoutGuide *alignmentGuide;

/*!
 Frame from background bezel.
 */
@property (readonly) NSLayoutGuide *backgroundDrawingGuide;

/*!
 Frame for label.
 */
@property (readonly) NSLayoutGuide *labelDrawingGuide;

/*!
 Frame for the cancel button.
 */
@property (readonly) NSLayoutGuide *cancelButtonDrawingGuide;

/*!
 Frame for the clear button
 */
@property (readonly) NSLayoutGuide *clearButtonDrawingGuide;

/*!
 Frame for the cancel button with extra space for easier clicking.

 Used to set up tracking areas.
 */
@property (readonly) NSLayoutGuide *cancelButtonLayoutGuide;

/*!
 Frame for the clear button with extra space for easier clicking.

 Used to set up tracking areas.
 */
@property (readonly) NSLayoutGuide *clearButtonLayoutGuide;

/*!
 Constraints that should always be active.
 */
@property (readonly) NSArray<NSLayoutConstraint *> *alwaysConstraints;

/*!
 Constraints for when not recording including the disabled state.
 */
@property (readonly) NSArray<NSLayoutConstraint *> *displayingConstraints;

/*!
 Constraints for recording when there is no value and clear button should not be displayed.
 */
@property (readonly) NSArray<NSLayoutConstraint *> *recordingWithNoValueConstraints;

/*!
 Constraints for recording when there is value and clear button should be displayed.
 */
@property (readonly) NSArray<NSLayoutConstraint *> *recordingWithValueConstraints;

/*!
 Called before style is applied to the specified control.

 @discussion Use this method to locate and cache resources, set up observers and install constraints.
 */
- (void)prepareForRecorderControl:(SRRecorderControl *)aControl;

/*!
 Called just before style is removed from the control it was added to.

 @discussion Use this method to free allocated resources, remove observers and remove constraints.
 */
- (void)prepareForRemoval;

/*!
 Update images according to the current appearance settings.

 @discussion Called when:
    - Backing scale factor of aControl's window
    - System's color tint
    - System's accessibility settings
    - Effective appearance of aControl

 @seealso NSView/viewDidChangeBackingProperties
 @seealso NSControlTintDidChangeNotification
 @seealso NSWorkspaceAccessibilityDisplayOptionsDidChangeNotification
 @seealso NSView/viewDidChangeEffectiveAppearance
 */
- (void)recorderControlAppearanceDidChange:(nullable id)aReason;

@end


/*!
 @seealso SRRecorderControlStyleComponents/appearance
 */
typedef NS_ENUM(NSUInteger, SRRecorderControlStyleComponentsAppearance)
{
    SRRecorderControlStyleComponentsAppearanceUnspecified = 0,
    SRRecorderControlStyleComponentsAppearanceAqua,
    SRRecorderControlStyleComponentsAppearanceVibrantLight,
    SRRecorderControlStyleComponentsAppearanceDarkAqua,
    SRRecorderControlStyleComponentsAppearanceVibrantDark,

    SRRecorderControlStyleComponentsAppearanceMax NS_SWIFT_UNAVAILABLE("")
} NS_SWIFT_NAME(SRRecorderControlStyleComponents.Appearance);

/*!
 Make appearance from macOS's NSAppearance.name

 @discussion If system's appearance is not recognized unspecified is returned.

 @seealso NSAppearance/name
 */
SRRecorderControlStyleComponentsAppearance SRRecorderControlStyleComponentsAppearanceFromSystem(NSAppearanceName aSystemAppearanceName)
NS_SWIFT_NAME(SRRecorderControlStyleComponentsAppearance.init(fromSystem:));


/*!
 @seealso SRRecorderControlStyleComponents/tint
 */
typedef NS_ENUM(NSUInteger, SRRecorderControlStyleComponentsTint)
{
    SRRecorderControlStyleComponentsTintUnspecified = 0,
    SRRecorderControlStyleComponentsTintBlue,
    SRRecorderControlStyleComponentsTintGraphite,

    SRRecorderControlStyleComponentsTintMax NS_SWIFT_UNAVAILABLE("")
} NS_SWIFT_NAME(SRRecorderControlStyleComponents.Tint);


/*!
 Make tint for macOS's NSControlTint

 @discussion If system's tint is not recognized unspecified is returned.

 @seealso NSControlTint
 */
SRRecorderControlStyleComponentsTint SRRecorderControlStyleComponentsTintFromSystem(NSControlTint aSystemTint)
NS_SWIFT_NAME(SRRecorderControlStyleComponentsTint.init(fromSystem:));


/*!
 @seealso SRRecorderControlStyleComponents/layoutDirection
 */
typedef NS_ENUM(NSUInteger, SRRecorderControlStyleComponentsLayoutDirection)
{
    SRRecorderControlStyleComponentsLayoutDirectionUnspecified = 0,
    SRRecorderControlStyleComponentsLayoutDirectionLeftToRight = 1,
    SRRecorderControlStyleComponentsLayoutDirectionRightToLeft = 2,

    SRRecorderControlStyleComponentsLayoutDirectionMax NS_SWIFT_UNAVAILABLE("")
} NS_SWIFT_NAME(SRRecorderControlStyleComponents.LayoutDirection);


/*!
 Make layout direction for macOS's NSUserInterfaceLayoutDirection

 @discussion If system's layout direction is not recognized unspecified is returned.

 @seealso NSUserInterfaceLayoutDirection
 */
SRRecorderControlStyleComponentsLayoutDirection SRRecorderControlStyleComponentsLayoutDirectionFromSystem(NSUserInterfaceLayoutDirection aSystemLayoutDirection)
NS_SWIFT_NAME(SRRecorderControlStyleComponentsLayoutDirection.init(fromSystem:));


/*!
 @seealso SRRecorderControlStyleComponents/accessibility
 */
typedef NS_OPTIONS(NSUInteger, SRRecorderControlStyleComponentsAccessibility)
{
    SRRecorderControlStyleComponentsAccessibilityUnspecified NS_SWIFT_UNAVAILABLE("") = 0,
    SRRecorderControlStyleComponentsAccessibilityNone = 1 << 0,
    SRRecorderControlStyleComponentsAccessibilityHighContrast = 1 << 1,

    SRRecorderControlStyleComponentsAccessibilityMask NS_SWIFT_UNAVAILABLE("") = SRRecorderControlStyleComponentsAccessibilityNone | SRRecorderControlStyleComponentsAccessibilityHighContrast
} NS_SWIFT_NAME(SRRecorderControlStyleComponents.Accessibility);


/*!
 Components of the style that determine lookup order.
 */
NS_SWIFT_NAME(RecorderControlStyle.Components)
@interface SRRecorderControlStyleComponents: NSObject <NSCopying>

/*!
 Current components based on the system settings.
 */
@property (class, readonly) SRRecorderControlStyleComponents *currentComponents NS_SWIFT_NAME(current);

@property (readonly) SRRecorderControlStyleComponentsAppearance appearance;
@property (readonly) SRRecorderControlStyleComponentsTint tint;
@property (readonly) SRRecorderControlStyleComponentsAccessibility accessibility;
@property (readonly) SRRecorderControlStyleComponentsLayoutDirection layoutDirection;
@property (nonatomic, readonly) NSString *stringRepresentation;

/*!
 Map system's appearance name to SR's appearance.

 @seealso supportedSystemAppearences
 */

+ (SRRecorderControlStyleComponents *)currentComponentsForView:(nullable NSView *)aView;

- (instancetype)initWithAppearance:(SRRecorderControlStyleComponentsAppearance)anAppearance
                              tint:(SRRecorderControlStyleComponentsTint)aTint
                     accessibility:(SRRecorderControlStyleComponentsAccessibility)anAccessibility
                   layoutDirection:(SRRecorderControlStyleComponentsLayoutDirection)aDirection NS_DESIGNATED_INITIALIZER;

- (BOOL)isEqualToComponents:(SRRecorderControlStyleComponents *)anObject;

/*!
 Compare components against the effective ideal.

 @discussion If the receiver is closer to the ideal, returns NSOrderedAscending.
 */
- (NSComparisonResult)compare:(SRRecorderControlStyleComponents *)anOtherComponents
         relativeToComponents:(SRRecorderControlStyleComponents *)anIdealComponents;

@end


/*!
 Load style from resources.

 @discussion Searches for resources in:
                1. ShortcutRecorder Framework
                2. Main application bundle
 */
NS_SWIFT_NAME(RecorderControlStyle)
@interface SRRecorderControlStyle : NSObject <SRRecorderControlStyling>
{
    NSArray<NSString *> *_lookupPrefixes;
    NSDictionary *_metrics;
}

/*!
 Style that uses a given identifier to locate resources in the framework and application bundles.

 @param anIdentifier Either a concrete (ends with "-") or a template (any other character) prefix.
    If nil, default for the current version of macOS is picked.

 @param aComponents Style components that override current system settings.

 @discussion A template prefix is used to construct lookup prefixes that depend on effective appearance
             while a concrete prefix is used as is.

             Each lookup prefix has a format of "identifier[-{aqua, darkaqua, vibrantlight, vibrantdark}][-{blue, graphite}][-acc]"

 @seealso makeLookupPrefixes
 @seealso effectiveComponents
 */
- (instancetype)initWithIdentifier:(nullable NSString *)anIdentifier
                        components:(nullable SRRecorderControlStyleComponents *)aComponents NS_DESIGNATED_INITIALIZER;

@property (nullable, weak, readonly) SRRecorderControl *recorderControl;

/*!
 Custom components that override system settings.
 */
@property (nullable, copy) SRRecorderControlStyleComponents *components;

/*!
 Currently effective components used to order lookup prefixes.

 @discussion Neither component has the unspecified value.
 */
@property (readonly) SRRecorderControlStyleComponents *effectiveComponents;

/*!
 Load image with a given name with respect to the lookup prefixes.
 */
- (NSImage *)loadImageNamed:(NSString *)aName;

/*!
 Load metrics with respect to the lookup prefixes.
 */
- (NSDictionary *)loadMetrics;

/*!
 Make new lookup prefixes, in order, for the currently effective components.

 @seealso effectiveComponents
 */
- (NSArray<NSString *> *)makeLookupPrefixes;

/*!
 Add style's constraints to the control view.
 */
- (void)addConstraints;

@end

NS_ASSUME_NONNULL_END
