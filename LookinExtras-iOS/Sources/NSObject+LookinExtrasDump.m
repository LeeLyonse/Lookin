#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <string.h>

#import "LookinExtras-Swift.h"

static const char *const LKXLookinDumpPrefix = "lkdump__";
static const size_t LKXLookinDumpPrefixLength = 8;

static BOOL LKXLookinDumpIsSelectorSupported(SEL selector) {
    const char *name = sel_getName(selector);
    return name != NULL && strncmp(name, LKXLookinDumpPrefix, LKXLookinDumpPrefixLength) == 0;
}

static id LKXLookinDumpInvoke(id object, SEL selector) {
    NSString *selectorName = NSStringFromSelector(selector);
    return [LookinExtrasDumper lookinDumpForObject:object selectorName:selectorName];
}

@implementation NSObject (LookinExtrasDump)

+ (BOOL)resolveInstanceMethod:(SEL)selector {
    if (!LKXLookinDumpIsSelectorSupported(selector)) {
        return NO;
    }

    return class_addMethod(self, selector, (IMP)LKXLookinDumpInvoke, "@@:");
}

@end
