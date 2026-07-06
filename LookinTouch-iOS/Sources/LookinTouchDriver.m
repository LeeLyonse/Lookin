#import "LookinTouchDriver.h"

#import <CoreFoundation/CoreFoundation.h>
#import <dlfcn.h>
#import <mach/mach_time.h>
#import <objc/runtime.h>

typedef struct __IOHIDEvent *LKTIOHIDEventRef;
typedef double LKTIOHIDFloat;
typedef uint32_t LKTIOHIDEventField;

typedef struct {
    UInt32 hi;
    UInt32 lo;
} LKTAbsoluteTime;

typedef LKTIOHIDEventRef (*LKTIOHIDEventCreateDigitizerEventFunc)(
    CFAllocatorRef allocator,
    LKTAbsoluteTime timeStamp,
    uint32_t type,
    uint32_t index,
    uint32_t identity,
    uint32_t eventMask,
    uint32_t buttonMask,
    LKTIOHIDFloat x,
    LKTIOHIDFloat y,
    LKTIOHIDFloat z,
    LKTIOHIDFloat tipPressure,
    LKTIOHIDFloat barrelPressure,
    Boolean range,
    Boolean touch,
    uint32_t options
);
typedef LKTIOHIDEventRef (*LKTIOHIDEventCreateDigitizerFingerEventWithQualityFunc)(
    CFAllocatorRef allocator,
    LKTAbsoluteTime timeStamp,
    uint32_t index,
    uint32_t identity,
    uint32_t eventMask,
    LKTIOHIDFloat x,
    LKTIOHIDFloat y,
    LKTIOHIDFloat z,
    LKTIOHIDFloat tipPressure,
    LKTIOHIDFloat twist,
    LKTIOHIDFloat minorRadius,
    LKTIOHIDFloat majorRadius,
    LKTIOHIDFloat quality,
    LKTIOHIDFloat density,
    LKTIOHIDFloat irregularity,
    Boolean range,
    Boolean touch,
    uint32_t options
);
typedef LKTIOHIDEventRef (*LKTIOHIDEventCreateDigitizerFingerEventFunc)(
    CFAllocatorRef allocator,
    LKTAbsoluteTime timeStamp,
    uint32_t index,
    uint32_t identity,
    uint32_t eventMask,
    LKTIOHIDFloat x,
    LKTIOHIDFloat y,
    LKTIOHIDFloat z,
    LKTIOHIDFloat tipPressure,
    LKTIOHIDFloat twist,
    Boolean range,
    Boolean touch,
    uint32_t options
);
typedef void (*LKTIOHIDEventAppendEventFunc)(LKTIOHIDEventRef event, LKTIOHIDEventRef childEvent);
typedef void (*LKTIOHIDEventSetIntegerValueFunc)(LKTIOHIDEventRef event, LKTIOHIDEventField field, int value);

static const uint32_t LKTIOHIDDigitizerTransducerTypeHand = 3;
static const uint32_t LKTIOHIDEventTypeDigitizer = 11;
static const uint32_t LKTIOHIDDigitizerEventRange = 1 << 0;
static const uint32_t LKTIOHIDDigitizerEventTouch = 1 << 1;
static const uint32_t LKTIOHIDDigitizerEventPosition = 1 << 2;
static const uint32_t LKTIOHIDEventFieldDigitizerIsDisplayIntegrated = (LKTIOHIDEventTypeDigitizer << 16) + 25;

static LKTIOHIDEventCreateDigitizerEventFunc LKTCreateDigitizerEvent;
static LKTIOHIDEventCreateDigitizerFingerEventWithQualityFunc LKTCreateFingerEventWithQuality;
static LKTIOHIDEventCreateDigitizerFingerEventFunc LKTCreateFingerEvent;
static LKTIOHIDEventAppendEventFunc LKTAppendEvent;
static LKTIOHIDEventSetIntegerValueFunc LKTSetIntegerValue;
static NSString *LKTLoadError;
static __weak UIResponder *LKTCapturedFirstResponder;

@interface UIApplication (LookinTouchPrivate)
- (UIEvent *)_touchesEvent;
@end

@interface UIEvent (LookinTouchPrivate)
- (void)_clearTouches;
- (void)_addTouch:(UITouch *)touch forDelayedDelivery:(BOOL)delayed;
- (void)_setHIDEvent:(LKTIOHIDEventRef)event;
@end

@interface UITouch (LookinTouchPrivate)
- (void)setWindow:(UIWindow *)window;
- (void)setView:(UIView *)view;
- (void)setTapCount:(NSUInteger)tapCount;
- (void)setTimestamp:(NSTimeInterval)timestamp;
- (void)setPhase:(UITouchPhase)touchPhase;
- (void)setGestureView:(UIView *)view;
- (void)_setLocationInWindow:(CGPoint)location resetPrevious:(BOOL)resetPrevious;
- (void)_setIsFirstTouchForView:(BOOL)firstTouchForView;
- (void)_setIsTapToClick:(BOOL)tapToClick;
- (void)_setHidEvent:(LKTIOHIDEventRef)event;
@end

@implementation UIResponder (LookinTouchFirstResponder)

- (void)lktouch_captureFirstResponder:(id)sender {
    LKTCapturedFirstResponder = self;
}

@end

static void *LKTLoadSymbol(void *handle, const char *name) {
    void *symbol = dlsym(handle, name);
    if (!symbol && !LKTLoadError) {
        LKTLoadError = [NSString stringWithFormat:@"missing IOKit symbol: %s", name];
    }
    return symbol;
}

static BOOL LKTLoadIOHIDSymbols(void) {
    static dispatch_once_t onceToken;
    static BOOL didLoad = NO;
    dispatch_once(&onceToken, ^{
        void *handle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_LAZY);
        if (!handle) {
            LKTLoadError = [NSString stringWithFormat:@"failed to open IOKit: %s", dlerror()];
            return;
        }

        LKTCreateDigitizerEvent = (LKTIOHIDEventCreateDigitizerEventFunc)LKTLoadSymbol(handle, "IOHIDEventCreateDigitizerEvent");
        LKTCreateFingerEventWithQuality = (LKTIOHIDEventCreateDigitizerFingerEventWithQualityFunc)dlsym(handle, "IOHIDEventCreateDigitizerFingerEventWithQuality");
        LKTCreateFingerEvent = (LKTIOHIDEventCreateDigitizerFingerEventFunc)dlsym(handle, "IOHIDEventCreateDigitizerFingerEvent");
        LKTAppendEvent = (LKTIOHIDEventAppendEventFunc)LKTLoadSymbol(handle, "IOHIDEventAppendEvent");
        LKTSetIntegerValue = (LKTIOHIDEventSetIntegerValueFunc)LKTLoadSymbol(handle, "IOHIDEventSetIntegerValue");

        didLoad = LKTCreateDigitizerEvent && (LKTCreateFingerEventWithQuality || LKTCreateFingerEvent) && LKTAppendEvent && LKTSetIntegerValue;
    });
    return didLoad;
}

static LKTAbsoluteTime LKTCurrentAbsoluteTime(void) {
    uint64_t now = mach_absolute_time();
    return (LKTAbsoluteTime){
        .hi = (UInt32)(now >> 32),
        .lo = (UInt32)now
    };
}

static LKTIOHIDEventRef LKTCreateFingerHIDEvent(LKTAbsoluteTime timeStamp, UITouch *touch, NSUInteger index) {
    uint32_t isTouching = touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled ? 0 : 1;
    uint32_t eventMask = touch.phase == UITouchPhaseMoved
        ? LKTIOHIDDigitizerEventPosition
        : (LKTIOHIDDigitizerEventRange | LKTIOHIDDigitizerEventTouch);
    CGPoint location = [touch locationInView:touch.window];

    if (LKTCreateFingerEventWithQuality) {
        return LKTCreateFingerEventWithQuality(
            kCFAllocatorDefault,
            timeStamp,
            (uint32_t)index + 1,
            2,
            eventMask,
            location.x,
            location.y,
            0,
            0,
            0,
            5,
            5,
            1,
            1,
            1,
            isTouching,
            isTouching,
            0
        );
    }

    return LKTCreateFingerEvent(
        kCFAllocatorDefault,
        timeStamp,
        (uint32_t)index + 1,
        2,
        eventMask,
        location.x,
        location.y,
        0,
        0,
        0,
        isTouching,
        isTouching,
        0
    );
}

static LKTIOHIDEventRef LKTCreateHIDEventWithTouches(NSArray<UITouch *> *touches) {
    if (!LKTLoadIOHIDSymbols()) {
        return NULL;
    }

    LKTAbsoluteTime timeStamp = LKTCurrentAbsoluteTime();
    LKTIOHIDEventRef handEvent = LKTCreateDigitizerEvent(
        kCFAllocatorDefault,
        timeStamp,
        LKTIOHIDDigitizerTransducerTypeHand,
        0,
        0,
        LKTIOHIDDigitizerEventTouch,
        0,
        0,
        0,
        0,
        0,
        0,
        false,
        true,
        0
    );
    if (!handEvent) {
        return NULL;
    }

    LKTSetIntegerValue(handEvent, LKTIOHIDEventFieldDigitizerIsDisplayIntegrated, 1);

    [touches enumerateObjectsUsingBlock:^(UITouch *touch, NSUInteger index, BOOL *stop) {
        LKTIOHIDEventRef fingerEvent = LKTCreateFingerHIDEvent(timeStamp, touch, index);
        if (!fingerEvent) {
            return;
        }
        LKTSetIntegerValue(fingerEvent, LKTIOHIDEventFieldDigitizerIsDisplayIntegrated, 1);
        LKTAppendEvent(handEvent, fingerEvent);
        CFRelease(fingerEvent);
    }];

    return handEvent;
}

static void LKTSetTouchHIDEvent(UITouch *touch) {
    if (![touch respondsToSelector:@selector(_setHidEvent:)]) {
        return;
    }
    LKTIOHIDEventRef event = LKTCreateHIDEventWithTouches(@[touch]);
    if (!event) {
        return;
    }
    [touch _setHidEvent:event];
    CFRelease(event);
}

static BOOL LKTSetEventHIDEvent(UIEvent *event, NSArray<UITouch *> *touches) {
    if (![event respondsToSelector:@selector(_setHIDEvent:)]) {
        return NO;
    }
    LKTIOHIDEventRef hidEvent = LKTCreateHIDEventWithTouches(touches);
    if (!hidEvent) {
        return NO;
    }
    [event _setHIDEvent:hidEvent];
    CFRelease(hidEvent);
    return YES;
}

static UIView *LKTHitTestView(UIWindow *window, CGPoint point) {
    UIView *hitTestView = [window hitTest:point withEvent:nil];
    return hitTestView ?: window;
}

static void LKTMarkFirstTouchForView(UITouch *touch) {
    if ([touch respondsToSelector:@selector(_setIsFirstTouchForView:)]) {
        [touch _setIsFirstTouchForView:YES];
        return;
    }

    if ([touch respondsToSelector:@selector(_setIsTapToClick:)]) {
        [touch _setIsTapToClick:YES];
    }

    Ivar flagsIvar = class_getInstanceVariable(object_getClass(touch), "_touchFlags");
    if (!flagsIvar) {
        return;
    }
    ptrdiff_t offset = ivar_getOffset(flagsIvar);
    uint8_t *bytes = (__bridge void *)touch;
    bytes[offset] = bytes[offset] | 0x01;
}

static UITouch *LKTCreateTouchAtWindowPoint(UIWindow *window, CGPoint point) {
    UITouch *touch = [[UITouch alloc] init];
    if (!touch) {
        return nil;
    }

    UIView *hitTestView = LKTHitTestView(window, point);
    [touch setWindow:window];
    [touch setTapCount:1];
    [touch _setLocationInWindow:point resetPrevious:YES];
    [touch setView:hitTestView];
    [touch setPhase:UITouchPhaseBegan];
    LKTMarkFirstTouchForView(touch);
    [touch setTimestamp:NSProcessInfo.processInfo.systemUptime];
    if ([touch respondsToSelector:@selector(setGestureView:)]) {
        [touch setGestureView:hitTestView];
    }
    LKTSetTouchHIDEvent(touch);
    return touch;
}

static void LKTUpdateTouch(UITouch *touch, CGPoint point, UITouchPhase phase) {
    [touch setTimestamp:NSProcessInfo.processInfo.systemUptime];
    [touch _setLocationInWindow:point resetPrevious:NO];
    [touch setPhase:phase];
    LKTSetTouchHIDEvent(touch);
}

static UIEvent *LKTEventWithTouches(NSArray<UITouch *> *touches, NSString **error) {
    UIApplication *application = UIApplication.sharedApplication;
    if (![application respondsToSelector:@selector(_touchesEvent)]) {
        if (error) {
            *error = @"missing UIKit private selector: UIApplication _touchesEvent";
        }
        return nil;
    }

    UIEvent *event = [application _touchesEvent];
    if (!event) {
        if (error) {
            *error = @"failed to create UIKit touch event";
        }
        return nil;
    }

    if (![event respondsToSelector:@selector(_clearTouches)] || ![event respondsToSelector:@selector(_addTouch:forDelayedDelivery:)]) {
        if (error) {
            *error = @"missing UIKit private touch collection selectors";
        }
        return nil;
    }

    [event _clearTouches];
    if (!LKTSetEventHIDEvent(event, touches) && error) {
        *error = LKTLoadError ?: @"failed to create backing IOHID event";
        return nil;
    }

    for (UITouch *touch in touches) {
        [event _addTouch:touch forDelayedDelivery:NO];
    }

    return event;
}

static NSString *LKTSendTapAtWindowPoint(UIWindow *window, CGPoint point) {
    UITouch *touch = nil;
    @try {
        touch = LKTCreateTouchAtWindowPoint(window, point);
        if (!touch) {
            return @"failed to create UITouch";
        }

        NSString *error = nil;
        UIEvent *beganEvent = LKTEventWithTouches(@[touch], &error);
        if (!beganEvent) {
            return error ?: @"failed to create began UIEvent";
        }
        [UIApplication.sharedApplication sendEvent:beganEvent];

        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, false);

        LKTUpdateTouch(touch, point, UITouchPhaseEnded);
        UIEvent *endedEvent = LKTEventWithTouches(@[touch], &error);
        if (!endedEvent) {
            return error ?: @"failed to create ended UIEvent";
        }
        [UIApplication.sharedApplication sendEvent:endedEvent];

        return [NSString stringWithFormat:@"tap sent via UIKit event at %.1f, %.1f", point.x, point.y];
    } @catch (NSException *exception) {
        return [NSString stringWithFormat:@"tap failed: %@ %@", exception.name, exception.reason ?: @""];
    }
}

static CGPoint LKTInterpolatePoint(CGPoint start, CGPoint end, CGFloat progress) {
    return CGPointMake(
        start.x + (end.x - start.x) * progress,
        start.y + (end.y - start.y) * progress
    );
}

static NSString *LKTSendSwipeAtWindowPoints(UIWindow *window, CGPoint startPoint, CGPoint endPoint) {
    if (hypot(endPoint.x - startPoint.x, endPoint.y - startPoint.y) < 2) {
        return @"swipe distance is too short";
    }

    UITouch *touch = nil;
    @try {
        touch = LKTCreateTouchAtWindowPoint(window, startPoint);
        if (!touch) {
            return @"failed to create UITouch";
        }

        NSString *error = nil;
        UIEvent *beganEvent = LKTEventWithTouches(@[touch], &error);
        if (!beganEvent) {
            return error ?: @"failed to create began UIEvent";
        }
        [UIApplication.sharedApplication sendEvent:beganEvent];
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.015, false);

        NSUInteger steps = 10;
        for (NSUInteger step = 1; step <= steps; step++) {
            CGPoint point = LKTInterpolatePoint(startPoint, endPoint, (CGFloat)step / (CGFloat)steps);
            LKTUpdateTouch(touch, point, UITouchPhaseMoved);

            UIEvent *movedEvent = LKTEventWithTouches(@[touch], &error);
            if (!movedEvent) {
                return error ?: @"failed to create moved UIEvent";
            }
            [UIApplication.sharedApplication sendEvent:movedEvent];
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.012, false);
        }

        LKTUpdateTouch(touch, endPoint, UITouchPhaseEnded);
        UIEvent *endedEvent = LKTEventWithTouches(@[touch], &error);
        if (!endedEvent) {
            return error ?: @"failed to create ended UIEvent";
        }
        [UIApplication.sharedApplication sendEvent:endedEvent];

        return [NSString stringWithFormat:@"swipe sent via UIKit event from %.1f, %.1f to %.1f, %.1f",
                                          startPoint.x, startPoint.y, endPoint.x, endPoint.y];
    } @catch (NSException *exception) {
        return [NSString stringWithFormat:@"swipe failed: %@ %@", exception.name, exception.reason ?: @""];
    }
}

typedef NS_ENUM(NSInteger, LKTSwipeDirection) {
    LKTSwipeDirectionUp,
    LKTSwipeDirectionDown,
    LKTSwipeDirectionLeft,
    LKTSwipeDirectionRight
};

static CGFloat LKTGestureInset(CGFloat length) {
    if (length <= 2) {
        return 0;
    }
    return MIN(MAX(length * 0.20, 6), length * 0.45);
}

static BOOL LKTVisibleWindowRectForView(UIView *view, CGRect *rect, NSString **error) {
    UIWindow *window = view.window;
    if (!window) {
        if (error) {
            *error = @"view has no window";
        }
        return NO;
    }
    if (CGRectIsEmpty(view.bounds)) {
        if (error) {
            *error = @"view bounds is empty";
        }
        return NO;
    }

    CGRect windowRect = [view convertRect:view.bounds toView:window];
    windowRect = CGRectIntersection(windowRect, window.bounds);
    if (CGRectIsNull(windowRect) || CGRectIsEmpty(windowRect)) {
        if (error) {
            *error = @"view is outside window bounds";
        }
        return NO;
    }

    *rect = windowRect;
    return YES;
}

static void LKTSwipePointsInRect(CGRect rect, LKTSwipeDirection direction, CGPoint *startPoint, CGPoint *endPoint) {
    CGFloat insetX = LKTGestureInset(rect.size.width);
    CGFloat insetY = LKTGestureInset(rect.size.height);
    CGFloat midX = CGRectGetMidX(rect);
    CGFloat midY = CGRectGetMidY(rect);

    switch (direction) {
        case LKTSwipeDirectionUp:
            *startPoint = CGPointMake(midX, CGRectGetMaxY(rect) - insetY);
            *endPoint = CGPointMake(midX, CGRectGetMinY(rect) + insetY);
            break;
        case LKTSwipeDirectionDown:
            *startPoint = CGPointMake(midX, CGRectGetMinY(rect) + insetY);
            *endPoint = CGPointMake(midX, CGRectGetMaxY(rect) - insetY);
            break;
        case LKTSwipeDirectionLeft:
            *startPoint = CGPointMake(CGRectGetMaxX(rect) - insetX, midY);
            *endPoint = CGPointMake(CGRectGetMinX(rect) + insetX, midY);
            break;
        case LKTSwipeDirectionRight:
            *startPoint = CGPointMake(CGRectGetMinX(rect) + insetX, midY);
            *endPoint = CGPointMake(CGRectGetMaxX(rect) - insetX, midY);
            break;
    }
}

static NSString *LKTSendSwipeInView(UIView *view, LKTSwipeDirection direction) {
    __block NSString *result = nil;
    void (^work)(void) = ^{
        NSString *error = nil;
        CGRect rect = CGRectZero;
        if (!LKTVisibleWindowRectForView(view, &rect, &error)) {
            result = error ?: @"failed to resolve visible rect";
            return;
        }

        CGPoint startPoint = CGPointZero;
        CGPoint endPoint = CGPointZero;
        LKTSwipePointsInRect(rect, direction, &startPoint, &endPoint);
        result = LKTSendSwipeAtWindowPoints(view.window, startPoint, endPoint);
    };

    if (NSThread.isMainThread) {
        work();
    } else {
        dispatch_sync(dispatch_get_main_queue(), work);
    }
    return result ?: @"unknown LookinTouch error";
}

static UIResponder *LKTFindFirstResponder(void) {
    LKTCapturedFirstResponder = nil;
    [UIApplication.sharedApplication sendAction:@selector(lktouch_captureFirstResponder:)
                                             to:nil
                                           from:nil
                                       forEvent:nil];
    return LKTCapturedFirstResponder;
}

static UIResponder *LKTKeyboardTargetFromSender(id sender) {
    UIResponder *firstResponder = LKTFindFirstResponder();
    if (firstResponder) {
        return firstResponder;
    }

    if (![sender isKindOfClass:UIResponder.class]) {
        return nil;
    }

    UIResponder *responder = sender;
    if ([responder respondsToSelector:@selector(insertText:)] && [responder canBecomeFirstResponder]) {
        [responder becomeFirstResponder];
        return responder;
    }

    return nil;
}

static NSString *LKTInsertText(NSString *text, id sender) {
    if (text.length == 0) {
        return @"text is empty";
    }

    __block NSString *result = nil;
    void (^work)(void) = ^{
        UIResponder *target = LKTKeyboardTargetFromSender(sender);
        if (![target respondsToSelector:@selector(insertText:)]) {
            result = @"no first responder supports insertText:";
            return;
        }

        @try {
            [(id<UIKeyInput>)target insertText:text];
            result = [NSString stringWithFormat:@"typed %lu characters into <%@: %p>",
                                                (unsigned long)text.length,
                                                NSStringFromClass(target.class),
                                                target];
        } @catch (NSException *exception) {
            result = [NSString stringWithFormat:@"type failed: %@ %@", exception.name, exception.reason ?: @""];
        }
    };

    if (NSThread.isMainThread) {
        work();
    } else {
        dispatch_sync(dispatch_get_main_queue(), work);
    }
    return result ?: @"unknown LookinTouch keyboard error";
}

static NSString *LKTDeleteBackward(NSUInteger count, id sender) {
    if (count == 0) {
        count = 1;
    }
    count = MIN(count, 200);

    __block NSString *result = nil;
    void (^work)(void) = ^{
        UIResponder *target = LKTKeyboardTargetFromSender(sender);
        if (![target respondsToSelector:@selector(deleteBackward)]) {
            result = @"no first responder supports deleteBackward";
            return;
        }

        @try {
            NSUInteger deleted = 0;
            for (NSUInteger index = 0; index < count; index++) {
                if ([target respondsToSelector:@selector(hasText)] && ![(id<UIKeyInput>)target hasText]) {
                    break;
                }
                [(id<UIKeyInput>)target deleteBackward];
                deleted += 1;
            }
            result = [NSString stringWithFormat:@"deleted %lu characters from <%@: %p>",
                                                (unsigned long)deleted,
                                                NSStringFromClass(target.class),
                                                target];
        } @catch (NSException *exception) {
            result = [NSString stringWithFormat:@"delete failed: %@ %@", exception.name, exception.reason ?: @""];
        }
    };

    if (NSThread.isMainThread) {
        work();
    } else {
        dispatch_sync(dispatch_get_main_queue(), work);
    }
    return result ?: @"unknown LookinTouch keyboard error";
}

static NSString *LKTPressReturn(id sender) {
    __block NSString *result = nil;
    void (^work)(void) = ^{
        UIResponder *target = LKTKeyboardTargetFromSender(sender);
        if (!target) {
            result = @"no first responder for return";
            return;
        }

        @try {
            if ([target isKindOfClass:UITextField.class]) {
                UITextField *textField = (UITextField *)target;
                BOOL shouldReturn = YES;
                id<UITextFieldDelegate> delegate = textField.delegate;
                if ([delegate respondsToSelector:@selector(textFieldShouldReturn:)]) {
                    shouldReturn = [delegate textFieldShouldReturn:textField];
                }

                if (!shouldReturn) {
                    result = [NSString stringWithFormat:@"return blocked by UITextField delegate <%@: %p>",
                                                        NSStringFromClass(textField.class),
                                                        textField];
                    return;
                }

                [textField sendActionsForControlEvents:UIControlEventEditingDidEndOnExit];
                result = [NSString stringWithFormat:@"return sent to UITextField <%@: %p>",
                                                    NSStringFromClass(textField.class),
                                                    textField];
                return;
            }

            if ([target respondsToSelector:@selector(insertText:)]) {
                [(id<UIKeyInput>)target insertText:@"\n"];
                result = [NSString stringWithFormat:@"return inserted into <%@: %p>",
                                                    NSStringFromClass(target.class),
                                                    target];
                return;
            }

            result = @"first responder does not support return";
        } @catch (NSException *exception) {
            result = [NSString stringWithFormat:@"return failed: %@ %@", exception.name, exception.reason ?: @""];
        }
    };

    if (NSThread.isMainThread) {
        work();
    } else {
        dispatch_sync(dispatch_get_main_queue(), work);
    }
    return result ?: @"unknown LookinTouch keyboard error";
}

static NSInteger LKTHexValue(unichar character) {
    if (character >= '0' && character <= '9') {
        return character - '0';
    }
    if (character >= 'a' && character <= 'f') {
        return character - 'a' + 10;
    }
    if (character >= 'A' && character <= 'F') {
        return character - 'A' + 10;
    }
    return -1;
}

static NSString *LKTStringFromUTF8Hex(NSString *hex, NSString **error) {
    if (hex.length == 0 || hex.length % 2 != 0) {
        if (error) {
            *error = @"hex text must have an even number of characters";
        }
        return nil;
    }

    NSMutableData *data = [NSMutableData dataWithCapacity:hex.length / 2];
    for (NSUInteger index = 0; index < hex.length; index += 2) {
        NSInteger high = LKTHexValue([hex characterAtIndex:index]);
        NSInteger low = LKTHexValue([hex characterAtIndex:index + 1]);
        if (high < 0 || low < 0) {
            if (error) {
                *error = @"hex text contains a non-hex character";
            }
            return nil;
        }

        uint8_t byte = (uint8_t)((high << 4) | low);
        [data appendBytes:&byte length:1];
    }

    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!text && error) {
        *error = @"hex text is not valid UTF-8";
    }
    return text;
}

static NSString *LKTSelectorSuffix(SEL selector, NSString *prefix) {
    NSString *name = NSStringFromSelector(selector);
    if (![name hasPrefix:prefix]) {
        return nil;
    }
    return [name substringFromIndex:prefix.length];
}

@implementation LookinTouchDriver

+ (NSString *)tapCenterOfView:(UIView *)view visibleOnly:(BOOL)visibleOnly {
    if (![view isKindOfClass:UIView.class]) {
        return @"selected object is not a UIView";
    }

    __block NSString *result = nil;
    void (^work)(void) = ^{
        UIWindow *window = view.window;
        if (!window) {
            result = @"view has no window";
            return;
        }
        if (CGRectIsEmpty(view.bounds)) {
            result = @"view bounds is empty";
            return;
        }

        CGRect rect = [view convertRect:view.bounds toView:window];
        if (visibleOnly) {
            rect = CGRectIntersection(rect, window.bounds);
            if (CGRectIsNull(rect) || CGRectIsEmpty(rect)) {
                result = @"view is outside window bounds";
                return;
            }
        }

        CGPoint point = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
        result = LKTSendTapAtWindowPoint(window, point);
    };

    if (NSThread.isMainThread) {
        work();
    } else {
        dispatch_sync(dispatch_get_main_queue(), work);
    }
    return result ?: @"unknown LookinTouch error";
}

+ (NSString *)swipeUpInView:(UIView *)view {
    if (![view isKindOfClass:UIView.class]) {
        return @"selected object is not a UIView";
    }
    return LKTSendSwipeInView(view, LKTSwipeDirectionUp);
}

+ (NSString *)swipeDownInView:(UIView *)view {
    if (![view isKindOfClass:UIView.class]) {
        return @"selected object is not a UIView";
    }
    return LKTSendSwipeInView(view, LKTSwipeDirectionDown);
}

+ (NSString *)swipeLeftInView:(UIView *)view {
    if (![view isKindOfClass:UIView.class]) {
        return @"selected object is not a UIView";
    }
    return LKTSendSwipeInView(view, LKTSwipeDirectionLeft);
}

+ (NSString *)swipeRightInView:(UIView *)view {
    if (![view isKindOfClass:UIView.class]) {
        return @"selected object is not a UIView";
    }
    return LKTSendSwipeInView(view, LKTSwipeDirectionRight);
}

+ (BOOL)canHandleKeyboardCommandSelector:(SEL)selector {
    NSString *name = NSStringFromSelector(selector);
    return [name hasPrefix:@"lktype__"] ||
        [name hasPrefix:@"lktype_hex__"] ||
        [name hasPrefix:@"lkdelete__"] ||
        [name isEqualToString:@"lkreturn"];
}

+ (NSString *)handleKeyboardCommandFromSelector:(SEL)selector sender:(id)sender {
    NSString *plainText = LKTSelectorSuffix(selector, @"lktype__");
    if (plainText) {
        if ([plainText isEqualToString:@"pasteboard"]) {
            return [self typePasteboardTextFromSender:sender];
        }
        return LKTInsertText(plainText, sender);
    }

    NSString *hexText = LKTSelectorSuffix(selector, @"lktype_hex__");
    if (hexText) {
        NSString *error = nil;
        NSString *text = LKTStringFromUTF8Hex(hexText, &error);
        if (!text) {
            return error ?: @"failed to decode hex text";
        }
        return LKTInsertText(text, sender);
    }

    NSString *deleteCount = LKTSelectorSuffix(selector, @"lkdelete__");
    if (deleteCount) {
        return LKTDeleteBackward((NSUInteger)MAX(1, deleteCount.integerValue), sender);
    }

    if ([NSStringFromSelector(selector) isEqualToString:@"lkreturn"]) {
        return LKTPressReturn(sender);
    }

    return @"unsupported LookinTouch keyboard command";
}

+ (NSString *)typePasteboardTextFromSender:(id)sender {
    NSString *text = UIPasteboard.generalPasteboard.string;
    if (text.length == 0) {
        return @"pasteboard string is empty";
    }
    return LKTInsertText(text, sender);
}

@end
