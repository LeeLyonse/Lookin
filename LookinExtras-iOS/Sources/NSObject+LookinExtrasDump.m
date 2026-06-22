#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <string.h>

// Forward-declare the Swift bridge instead of importing the generated
// "LookinExtras-Swift.h". In a mixed-language static-library pod that header is
// produced only after Swift compiles, so it is missing at dependency-scan time
// and breaks the build under Xcode's explicit-modules system. The class is
// registered with the Objective-C runtime under this exact name via
// @objc(LookinExtrasDumper), so a forward declaration is all this file needs.
@interface LookinExtrasDumper : NSObject
+ (NSString *)lookinDumpForObject:(NSObject *)object selectorName:(NSString *)selectorName;
@end

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
