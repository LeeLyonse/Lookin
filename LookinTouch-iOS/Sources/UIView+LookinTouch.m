#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "LookinTouchDriver.h"

static NSString *LKTLookinTouchDynamicCommand(id self, SEL selector) {
    return [LookinTouchDriver handleKeyboardCommandFromSelector:selector sender:self];
}

@implementation UIView (LookinTouch)

+ (BOOL)resolveInstanceMethod:(SEL)selector {
    if ([LookinTouchDriver canHandleKeyboardCommandSelector:selector]) {
        class_addMethod(self, selector, (IMP)LKTLookinTouchDynamicCommand, "@@:");
        return YES;
    }
    return [super resolveInstanceMethod:selector];
}

- (NSString *)lktouch__tapCenter {
    return [LookinTouchDriver tapCenterOfView:self visibleOnly:NO];
}

- (NSString *)lktouch__tapVisibleCenter {
    return [LookinTouchDriver tapCenterOfView:self visibleOnly:YES];
}

- (NSString *)lktouch__swipeUp {
    return [LookinTouchDriver swipeUpInView:self];
}

- (NSString *)lktouch__swipeDown {
    return [LookinTouchDriver swipeDownInView:self];
}

- (NSString *)lktouch__swipeLeft {
    return [LookinTouchDriver swipeLeftInView:self];
}

- (NSString *)lktouch__swipeRight {
    return [LookinTouchDriver swipeRightInView:self];
}

- (NSString *)lktype__pasteboard {
    return [LookinTouchDriver typePasteboardTextFromSender:self];
}

@end
