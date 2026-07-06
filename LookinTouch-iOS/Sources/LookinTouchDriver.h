#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LookinTouchDriver : NSObject

+ (NSString *)tapCenterOfView:(UIView *)view visibleOnly:(BOOL)visibleOnly;
+ (NSString *)swipeUpInView:(UIView *)view;
+ (NSString *)swipeDownInView:(UIView *)view;
+ (NSString *)swipeLeftInView:(UIView *)view;
+ (NSString *)swipeRightInView:(UIView *)view;
+ (BOOL)canHandleKeyboardCommandSelector:(SEL)selector;
+ (NSString *)handleKeyboardCommandFromSelector:(SEL)selector sender:(id)sender;
+ (NSString *)typePasteboardTextFromSender:(id)sender;

@end

NS_ASSUME_NONNULL_END
