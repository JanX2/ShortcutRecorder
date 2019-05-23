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
 */
- (void)prepareForRecorderControl:(SRRecorderControl *)aControl;

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
 @seealso SRRecorderControlStyleLookupOption/appearance
 */
typedef NS_ENUM(NSUInteger, SRRecorderControlStyleLookupOptionAppearance)
{
    SRRecorderControlStyleLookupOptionAppearanceNone = 0,
    SRRecorderControlStyleLookupOptionAppearanceAqua,
    SRRecorderControlStyleLookupOptionAppearanceVibrantLight,
    SRRecorderControlStyleLookupOptionAppearanceDarkAqua,
    SRRecorderControlStyleLookupOptionAppearanceVibrantDark,

    SRRecorderControlStyleLookupOptionAppearanceMax
} NS_SWIFT_NAME(SRRecorderControlStyleLookupOption.Appearance);


/*!
 @seealso SRRecorderControlStyleLookupOption/tint
 */
typedef NS_ENUM(NSUInteger, SRRecorderControlStyleLookupOptionTint)
{
    SRRecorderControlStyleLookupOptionTintNone = 0,
    SRRecorderControlStyleLookupOptionTintBlue,
    SRRecorderControlStyleLookupOptionTintGraphite,

    SRRecorderControlStyleLookupOptionTintMax
} NS_SWIFT_NAME(SRRecorderControlStyleLookupOption.Tint);


/*!
 @seealso SRRecorderControlStyleLookupOption/accessibility
 */
typedef NS_OPTIONS(NSUInteger, SRRecorderControlStyleLookupOptionAccessibility)
{
    SRRecorderControlStyleLookupOptionAccessibilityNone = 0,
    SRRecorderControlStyleLookupOptionAccessibilityHighContrast = 1 << 0,

    SRRecorderControlStyleLookupOptionAccessibilityMask = SRRecorderControlStyleLookupOptionAccessibilityHighContrast
} NS_SWIFT_NAME(SRRecorderControlStyleLookupOption.Accessibility);


/*!
 Intermediate object that represents a given option for ordering.

 @seealso SRRecorderControlStyle/makeLookupPrefixesRelativeToOption:
 */
NS_SWIFT_NAME(RecorderControlStyle.LookupOption)
@interface SRRecorderControlStyleLookupOption: NSObject
@property (readonly) SRRecorderControlStyleLookupOptionAppearance appearance;
@property (readonly) SRRecorderControlStyleLookupOptionTint tint;
@property (readonly) SRRecorderControlStyleLookupOptionAccessibility accessibility;
@property (nonatomic, readonly) NSString *stringRepresentation;

- (instancetype)initWithAppearance:(SRRecorderControlStyleLookupOptionAppearance)anAppearance
                              tint:(SRRecorderControlStyleLookupOptionTint)aTint
                     accessibility:(SRRecorderControlStyleLookupOptionAccessibility)anAccessibility NS_DESIGNATED_INITIALIZER;

/*!
 Compare options against similarity to the effective options.

 @discussion If the receiver is closer to the effective version, returns NSOrderedAscending.
 */
- (NSComparisonResult)compare:(SRRecorderControlStyleLookupOption *)anOption
             relativeToOption:(SRRecorderControlStyleLookupOption *)anEffectiveOption;

@end


@interface SRRecorderControlStyleLookupOption (SRUtility)
@property (class, readonly) NSSet<NSAppearanceName> *supportedSystemAppearences;
@property (class, readonly) NSSet<NSNumber *> *supportedAppearences;
@property (class, readonly) NSSet<NSNumber *> *supportedTints;
@property (class, readonly) NSSet<NSNumber *> *supportedAccessibilities;
@property (class, readonly) NSArray<SRRecorderControlStyleLookupOption *> *allOptions NS_SWIFT_NAME(all);

/*!
 Map system's appearance name to SR's appearance.

 @seealso supportedSystemAppearences
 */
+ (SRRecorderControlStyleLookupOptionAppearance)appearanceForSystemAppearanceName:(NSAppearanceName)aSystemAppearance;

/*!
 Map system's control tint into SR's tint.
 */
+ (SRRecorderControlStyleLookupOptionTint)tintForSystemTint:(NSControlTint)aSystemTint;

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

    Style implements equality based on prefix that determines the set of resources it represents.
    I.e. styles with the same prefix that belong to different views and, optionally, resolve
    into different lookup tables are still equal.

 @seealso makeLookupPrefixes
 */
- (instancetype)initWithIdentifier:(NSString *)anIdentifier NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@property (nullable, weak, readonly) SRRecorderControl *recorderControl;

/*!
 Load image with a given name with respect to the lookup table.
 */
- (NSImage *)loadImageNamed:(NSString *)aName;

/*!
 Load metrics with respect to the lookup table.
 */
- (NSDictionary *)loadMetrics;

/*!
 Make new lookup prefixes, in order, for the current environment.

 @discussion Order depends on the environment such as system configuration (e.g. accessibility)
    and controlView effective appearance.

 @seealso makeLookupPrefixesRelativeToOption:
 */
- (NSArray<NSString *> *)makeLookupPrefixes;

/*!
 Make new lookup prefixes in order by similarity to the given option.

 @param anOption The ideal option. Distance from a given option to the ideal determines order.
 */
- (NSArray<NSString *> *)makeLookupPrefixesRelativeToOption:(SRRecorderControlStyleLookupOption *)anOption NS_SWIFT_NAME(makeLookupPrefixes(relativeTo:));

/*!
 Add style's constraints to the control view.
 */
- (void)addConstraints;

@end

NS_ASSUME_NONNULL_END
