#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <string.h>

// Forward-declare the Swift bridge instead of importing the generated
// "LookinDump-Swift.h". In a mixed-language static-library pod that header is
// produced only after Swift compiles, so it is missing at dependency-scan time
// and breaks the build under Xcode's explicit-modules system. The class is
// registered with the Objective-C runtime under this exact name via
// @objc(LookinDumpDumper), so a forward declaration is all this file needs.
@interface LookinDumpDumper : NSObject
+ (NSString *)lookinDumpForObject:(NSObject *)object selectorName:(NSString *)selectorName;
@end

static const char *const LKDLookinDumpPrefix = "lkdump__";
static const size_t LKDLookinDumpPrefixLength = 8;

static BOOL LKDLookinDumpIsSelectorSupported(SEL selector) {
    const char *name = sel_getName(selector);
    return name != NULL && strncmp(name, LKDLookinDumpPrefix, LKDLookinDumpPrefixLength) == 0;
}

static id LKDLookinDumpInvoke(id object, SEL selector) {
    NSString *selectorName = NSStringFromSelector(selector);
    return [LookinDumpDumper lookinDumpForObject:object selectorName:selectorName];
}

@implementation NSObject (LookinDump)

+ (BOOL)resolveInstanceMethod:(SEL)selector {
    if (!LKDLookinDumpIsSelectorSupported(selector)) {
        return NO;
    }

    return class_addMethod(self, selector, (IMP)LKDLookinDumpInvoke, "@@:");
}

@end
