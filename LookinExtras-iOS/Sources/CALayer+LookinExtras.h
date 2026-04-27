#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

/// Adds extra debug attributes to every CALayer for the Lookin macOS client.
/// Implements the official `lookin_customDebugInfos` extension point declared by
/// LookinServer SDK. No public API to call; the SDK invokes this category
/// automatically via Objective-C runtime when collecting view hierarchy details.
@interface CALayer (LookinExtras)

@end

NS_ASSUME_NONNULL_END
