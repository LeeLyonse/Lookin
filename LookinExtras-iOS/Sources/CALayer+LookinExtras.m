#import <QuartzCore/QuartzCore.h>

@implementation CALayer (LookinExtras)

#pragma mark - Lookin extension point

- (NSDictionary *)lookin_customDebugInfos {
    return @{
        @"properties": @[
            @{
                @"title":     @"maskedCorners",
                @"valueType": @"string",
                @"section":   @"Layer (extras)",
                @"value":     [self lkx_describeMaskedCorners],
            },
        ],
    };
}

#pragma mark - Helpers

- (NSString *)lkx_describeMaskedCorners {
    CACornerMask mask = self.maskedCorners;
    CACornerMask all  = (kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner |
                         kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner);
    if (mask == all)  return @"all";
    if (mask == 0)    return @"none";

    NSMutableArray<NSString *> *names = [NSMutableArray array];
    if (mask & kCALayerMinXMinYCorner) [names addObject:@"TopLeft"];
    if (mask & kCALayerMaxXMinYCorner) [names addObject:@"TopRight"];
    if (mask & kCALayerMinXMaxYCorner) [names addObject:@"BottomLeft"];
    if (mask & kCALayerMaxXMaxYCorner) [names addObject:@"BottomRight"];
    return [names componentsJoinedByString:@","];
}

@end
