#import <UIKit/UIKit.h>

static NSString *LKXAttributedStringPayload(NSAttributedString *value) {
    if (!value || value.length == 0) {
        return nil;
    }

    return [NSString stringWithFormat:@"string: %@\ndescription: %@",
                                      value.string ?: @"",
                                      value.description ?: @""];
}

static void LKXAddAttributedStringProperty(NSMutableArray<NSDictionary *> *properties,
                                           NSString *title,
                                           NSString *section,
                                           NSAttributedString *value) {
    NSString *payload = LKXAttributedStringPayload(value);
    if (!payload) {
        return;
    }

    [properties addObject:@{
        @"title": title,
        @"valueType": @"string",
        @"section": section,
        @"value": payload,
    }];
}

@implementation UILabel (LookinExtrasAttributedString)

- (NSDictionary *)lookin_customDebugInfos {
    NSMutableArray<NSDictionary *> *properties = [NSMutableArray array];
    LKXAddAttributedStringProperty(properties,
                                   @"attributedText",
                                   @"Attributed String (extras)",
                                   self.attributedText);
    return @{@"properties": properties};
}

@end

@implementation UITextView (LookinExtrasAttributedString)

- (NSDictionary *)lookin_customDebugInfos {
    NSMutableArray<NSDictionary *> *properties = [NSMutableArray array];
    LKXAddAttributedStringProperty(properties,
                                   @"attributedText",
                                   @"Attributed String (extras)",
                                   self.attributedText);
    return @{@"properties": properties};
}

@end

@implementation UITextField (LookinExtrasAttributedString)

- (NSDictionary *)lookin_customDebugInfos {
    NSMutableArray<NSDictionary *> *properties = [NSMutableArray array];
    LKXAddAttributedStringProperty(properties,
                                   @"attributedText",
                                   @"Attributed String (extras)",
                                   self.attributedText);
    LKXAddAttributedStringProperty(properties,
                                   @"attributedPlaceholder",
                                   @"Attributed String (extras)",
                                   self.attributedPlaceholder);
    return @{@"properties": properties};
}

@end

@implementation UIButton (LookinExtrasAttributedString)

- (NSDictionary *)lookin_customDebugInfos {
    NSMutableArray<NSDictionary *> *properties = [NSMutableArray array];
    NSString *section = @"Attributed String (extras)";

    LKXAddAttributedStringProperty(properties,
                                   @"attributedTitle.normal",
                                   section,
                                   [self attributedTitleForState:UIControlStateNormal]);
    LKXAddAttributedStringProperty(properties,
                                   @"attributedTitle.highlighted",
                                   section,
                                   [self attributedTitleForState:UIControlStateHighlighted]);
    LKXAddAttributedStringProperty(properties,
                                   @"attributedTitle.selected",
                                   section,
                                   [self attributedTitleForState:UIControlStateSelected]);
    LKXAddAttributedStringProperty(properties,
                                   @"attributedTitle.disabled",
                                   section,
                                   [self attributedTitleForState:UIControlStateDisabled]);

    return @{@"properties": properties};
}

@end
