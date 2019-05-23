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
 Update images according to the current appearance settings.

 @discussion Called when:
    - Backing scale factor of aControl's window
    - System's color tint
    - System's accessibility settings
    - Effective appearance of aControl

 @see NSView/viewDidChangeBackingProperties
 @see NSControlTintDidChangeNotification
 @see NSWorkspaceAccessibilityDisplayOptionsDidChangeNotification
 @see NSView/viewDidChangeEffectiveAppearance
 */
- (void)controlAppearanceDidChange:(nullable id)aReason;

@end


/*!
 Load style from files.
 */
NS_SWIFT_NAME(RecorderControlStyle)
@interface SRRecorderControlStyle : NSObject <SRRecorderControlStyling>
{
    NSArray<NSString *> *_lookupPrefixes;
    NSDictionary *_metrics;
}

/*!
 @seealso initWithIdentifier:
 */
+ (instancetype)styleWithIdentifier:(NSString *)anIdentifier;

/*!
 Style will use a given identifier to locate resources.

 @param anIdentifier Either a concrete (ends with "-") or a template (any other character) prefix.

 @discussion A template prefix is used to construct a lookup table by adding
    various suffixes while a concrete prefix is used as is.

    The lookup table consists of the strings of the "prefix[-{aqua, darkaqua, vibrantlight, vibrantdark}][-{blue, graphite}][-acc]"
    prefixes ordered according to the environment.

 @seealso makeLookupPrefixes
 */
- (instancetype)initWithIdentifier:(NSString *)anIdentifier NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/*!
 Prefix the style was initialized with.
 */
@property (readonly) NSString *prefix;

/*!
 Load image with a given name with respect to the load order.

 @discussion Image is looked up in the following locations:
    1. ShortcutRecorder Framework
    2. Main application bundle
 */
- (NSImage *)loadImageNamed:(NSString *)aName;

/*!
 Load metrics with respect to the load order.

 @discussion Similarly to -loadImageNamed:, metrics file is looked up in the following locations:
     1. ShortcutRecorder Framework
     2. Main application bundle
 */
- (NSDictionary *)loadMetrics;

/*!
 Make new lookup prefixes, in order, for the current environment.

 @discussion Order depends on the environment such as system configuration (e.g. accessibility)
    and controlView effective appearance.
 */
- (NSArray<NSString *> *)makeLookupPrefixes;

- (void)addConstraints;

@end

NS_ASSUME_NONNULL_END
