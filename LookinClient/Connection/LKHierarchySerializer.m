//
//  LKHierarchySerializer.m
//  Lookin
//
//  https://lookin.work
//

#import "LKHierarchySerializer.h"
#import "LookinHierarchyInfo.h"
#import "LookinDisplayItem.h"
#import "LookinDisplayItem+LookinClient.h"
#import "LookinObject.h"
#import "LookinObject+LookinClient.h"
#import "LookinAppInfo.h"
#import "LookinAttributesGroup.h"
#import "LookinAttributesSection.h"
#import "LookinAttribute.h"
#import "LookinAttrType.h"
#import "LookinEventHandler.h"

@implementation LKHierarchySerializer

#pragma mark - Text Tree

+ (NSString *)textTreeFromHierarchyInfo:(LookinHierarchyInfo *)info {
    if (!info.displayItems.count) {
        return @"(empty)";
    }
    NSMutableString *result = [NSMutableString string];
    for (LookinDisplayItem *item in info.displayItems) {
        [self _appendTextTreeForItem:item depth:0 output:result];
    }
    return [result copy];
}

+ (void)_appendTextTreeForItem:(LookinDisplayItem *)item depth:(NSInteger)depth output:(NSMutableString *)output {
    if (!item) return;

    // indent
    for (NSInteger i = 0; i < depth; i++) {
        [output appendString:@"  "];
    }

    // className
    NSString *className = [item title] ?: @"Unknown";
    [output appendString:className];

    // memory address
    LookinObject *obj = item.viewObject ?: item.layerObject;
    if (obj.memoryAddress.length) {
        [output appendFormat:@" %@", obj.memoryAddress];
    }

    // oid
    if (obj.oid) {
        [output appendFormat:@" oid=%lu", obj.oid];
    }

    // subtitle (VC name, ivar name, etc.)
    NSString *subtitle = [item subtitle];
    if (subtitle.length) {
        [output appendFormat:@" (%@)", subtitle];
    }

    // frame
    CGRect frame = item.frame;
    [output appendFormat:@" {%.0f,%.0f,%.0f,%.0f}", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height];

    // flags
    NSMutableArray *flags = [NSMutableArray array];
    if (item.isHidden) [flags addObject:@"hidden"];
    if (item.alpha < 1.0) [flags addObject:[NSString stringWithFormat:@"alpha=%.2f", item.alpha]];
    if (flags.count) {
        [output appendFormat:@" [%@]", [flags componentsJoinedByString:@","]];
    }

    [output appendString:@"\n"];

    // recurse into subitems
    for (LookinDisplayItem *subitem in item.subitems) {
        [self _appendTextTreeForItem:subitem depth:depth + 1 output:output];
    }
}

#pragma mark - JSON Tree

+ (NSArray<NSDictionary *> *)jsonTreeFromHierarchyInfo:(LookinHierarchyInfo *)info {
    if (!info.displayItems.count) {
        return @[];
    }
    NSMutableArray *result = [NSMutableArray array];
    for (LookinDisplayItem *item in info.displayItems) {
        NSDictionary *dict = [self _jsonNodeFromItem:item];
        if (dict) [result addObject:dict];
    }
    return [result copy];
}

+ (NSDictionary *)_jsonNodeFromItem:(LookinDisplayItem *)item {
    if (!item) return nil;

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    dict[@"className"] = [item title] ?: @"Unknown";

    LookinObject *obj = item.viewObject ?: item.layerObject;
    if (obj.memoryAddress.length) {
        dict[@"address"] = obj.memoryAddress;
    }
    if (obj.oid) {
        dict[@"oid"] = @(obj.oid);
    }

    NSString *subtitle = [item subtitle];
    if (subtitle.length) {
        dict[@"subtitle"] = subtitle;
    }

    CGRect frame = item.frame;
    dict[@"frame"] = @{
        @"x": @(frame.origin.x),
        @"y": @(frame.origin.y),
        @"width": @(frame.size.width),
        @"height": @(frame.size.height)
    };

    dict[@"isHidden"] = @(item.isHidden);
    dict[@"alpha"] = @(item.alpha);

    if (item.hostViewControllerObject) {
        dict[@"viewController"] = item.hostViewControllerObject.lk_simpleDemangledClassName ?: @"";
    }

    if (item.subitems.count) {
        NSMutableArray *children = [NSMutableArray array];
        for (LookinDisplayItem *subitem in item.subitems) {
            NSDictionary *childDict = [self _jsonNodeFromItem:subitem];
            if (childDict) [children addObject:childDict];
        }
        dict[@"children"] = children;
    }

    return [dict copy];
}

#pragma mark - Detail

+ (NSDictionary *)jsonDetailFromDisplayItem:(LookinDisplayItem *)item {
    if (!item) return @{};

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    dict[@"className"] = [item title] ?: @"Unknown";

    LookinObject *obj = item.viewObject ?: item.layerObject;
    if (obj.memoryAddress.length) {
        dict[@"address"] = obj.memoryAddress;
    }
    if (obj.oid) {
        dict[@"oid"] = @(obj.oid);
    }
    if (obj.classChainList.count) {
        dict[@"classChain"] = obj.classChainList;
    }

    NSString *subtitle = [item subtitle];
    if (subtitle.length) {
        dict[@"subtitle"] = subtitle;
    }

    CGRect frame = item.frame;
    dict[@"frame"] = @{
        @"x": @(frame.origin.x),
        @"y": @(frame.origin.y),
        @"width": @(frame.size.width),
        @"height": @(frame.size.height)
    };

    CGRect bounds = item.bounds;
    dict[@"bounds"] = @{
        @"x": @(bounds.origin.x),
        @"y": @(bounds.origin.y),
        @"width": @(bounds.size.width),
        @"height": @(bounds.size.height)
    };

    dict[@"isHidden"] = @(item.isHidden);
    dict[@"alpha"] = @(item.alpha);

    if (item.hostViewControllerObject) {
        dict[@"viewController"] = item.hostViewControllerObject.lk_simpleDemangledClassName ?: @"";
    }

    if (item.backgroundColor) {
        dict[@"backgroundColor"] = [self _colorStringFromColor:item.backgroundColor];
    }

    // attribute groups
    NSArray<LookinAttributesGroup *> *attrGroups = [item queryAllAttrGroupList];
    if (attrGroups.count) {
        NSMutableArray *groupsArray = [NSMutableArray array];
        for (LookinAttributesGroup *group in attrGroups) {
            NSMutableDictionary *groupDict = [NSMutableDictionary dictionary];
            groupDict[@"id"] = group.identifier ?: @"";
            if (group.userCustomTitle.length) {
                groupDict[@"title"] = group.userCustomTitle;
            }

            NSMutableArray *attrsFlat = [NSMutableArray array];
            for (LookinAttributesSection *section in group.attrSections) {
                for (LookinAttribute *attr in section.attributes) {
                    NSDictionary *attrDict = [self _flattenAttribute:attr];
                    if (attrDict) {
                        [attrsFlat addObject:attrDict];
                    }
                }
            }
            groupDict[@"attributes"] = attrsFlat;
            [groupsArray addObject:groupDict];
        }
        dict[@"attributeGroups"] = groupsArray;
    }

    // event handlers
    if (item.eventHandlers.count) {
        NSMutableArray *handlers = [NSMutableArray array];
        for (LookinEventHandler *handler in item.eventHandlers) {
            NSMutableDictionary *handlerDict = [NSMutableDictionary dictionary];
            if (handler.eventName.length) {
                handlerDict[@"eventName"] = handler.eventName;
            }
            handlerDict[@"type"] = (handler.handlerType == LookinEventHandlerTypeTargetAction) ? @"targetAction" : @"gesture";
            [handlers addObject:handlerDict];
        }
        dict[@"eventHandlers"] = handlers;
    }

    // children count
    dict[@"childrenCount"] = @(item.subitems.count);

    return [dict copy];
}

#pragma mark - App Info

+ (NSDictionary *)jsonFromAppInfo:(LookinAppInfo *)appInfo {
    if (!appInfo) return @{};

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (appInfo.appName.length) dict[@"appName"] = appInfo.appName;
    if (appInfo.appBundleIdentifier.length) dict[@"bundleId"] = appInfo.appBundleIdentifier;
    if (appInfo.deviceDescription.length) dict[@"device"] = appInfo.deviceDescription;
    if (appInfo.osDescription.length) dict[@"os"] = appInfo.osDescription;
    dict[@"screenWidth"] = @(appInfo.screenWidth);
    dict[@"screenHeight"] = @(appInfo.screenHeight);
    dict[@"screenScale"] = @(appInfo.screenScale);
    return [dict copy];
}

#pragma mark - Helpers

+ (NSString *)_colorStringFromColor:(NSColor *)color {
    if (!color) return @"";
    NSColor *rgbColor = [color colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    if (!rgbColor) return color.description;
    return [NSString stringWithFormat:@"rgba(%.0f,%.0f,%.0f,%.2f)",
            rgbColor.redComponent * 255,
            rgbColor.greenComponent * 255,
            rgbColor.blueComponent * 255,
            rgbColor.alphaComponent];
}

#pragma mark - Attribute Helpers

+ (NSString *)_attrTypeName:(LookinAttrType)t {
    switch (t) {
        case LookinAttrTypeNone:                return @"None";
        case LookinAttrTypeVoid:                return @"Void";
        case LookinAttrTypeChar:                return @"Char";
        case LookinAttrTypeInt:                 return @"Int";
        case LookinAttrTypeShort:               return @"Short";
        case LookinAttrTypeLong:                return @"Long";
        case LookinAttrTypeLongLong:            return @"LongLong";
        case LookinAttrTypeUnsignedChar:        return @"UnsignedChar";
        case LookinAttrTypeUnsignedInt:         return @"UnsignedInt";
        case LookinAttrTypeUnsignedShort:       return @"UnsignedShort";
        case LookinAttrTypeUnsignedLong:        return @"UnsignedLong";
        case LookinAttrTypeUnsignedLongLong:    return @"UnsignedLongLong";
        case LookinAttrTypeFloat:               return @"Float";
        case LookinAttrTypeDouble:              return @"Double";
        case LookinAttrTypeBOOL:                return @"BOOL";
        case LookinAttrTypeSel:                 return @"SEL";
        case LookinAttrTypeClass:               return @"Class";
        case LookinAttrTypeCGPoint:             return @"CGPoint";
        case LookinAttrTypeCGVector:            return @"CGVector";
        case LookinAttrTypeCGSize:              return @"CGSize";
        case LookinAttrTypeCGRect:              return @"CGRect";
        case LookinAttrTypeCGAffineTransform:   return @"CGAffineTransform";
        case LookinAttrTypeUIEdgeInsets:        return @"UIEdgeInsets";
        case LookinAttrTypeUIOffset:            return @"UIOffset";
        case LookinAttrTypeNSString:            return @"NSString";
        case LookinAttrTypeEnumInt:             return @"EnumInt";
        case LookinAttrTypeEnumLong:            return @"EnumLong";
        case LookinAttrTypeUIColor:             return @"UIColor";
        case LookinAttrTypeCustomObj:           return @"CustomObj";
        case LookinAttrTypeEnumString:          return @"EnumString";
        case LookinAttrTypeShadow:              return @"Shadow";
        case LookinAttrTypeJson:                return @"Json";
    }
    return @"Unknown";
}

/// LookinAttrTypeUIColor value is @[r, g, b, a] where each NSNumber is in 0...1.
/// Returns an 8-digit `#RRGGBBAA` hex string (alpha included), which is compact and AI-friendly.
+ (NSString *)_hexFromRGBAArray:(id)rgba {
    if (![rgba isKindOfClass:NSArray.class]) return @"";
    NSArray *arr = (NSArray *)rgba;
    if (arr.count < 4) return @"";
    for (id v in arr) {
        if (![v isKindOfClass:NSNumber.class]) return @"";
    }
    double r = [arr[0] doubleValue];
    double g = [arr[1] doubleValue];
    double b = [arr[2] doubleValue];
    double a = [arr[3] doubleValue];
    r = MAX(0.0, MIN(1.0, r));
    g = MAX(0.0, MIN(1.0, g));
    b = MAX(0.0, MIN(1.0, b));
    a = MAX(0.0, MIN(1.0, a));
    return [NSString stringWithFormat:@"#%02X%02X%02X%02X",
            (unsigned)(r * 255.0 + 0.5),
            (unsigned)(g * 255.0 + 0.5),
            (unsigned)(b * 255.0 + 0.5),
            (unsigned)(a * 255.0 + 0.5)];
}

/// Flattens an NSValue-boxed geometry struct into a JSON-friendly dictionary.
/// Fallback: returns `[v description]` or an empty string, never nil, so callers can assign
/// the result to `d[@"value"]` without a nil check.
+ (id)_structValueDescription:(id)value attrType:(LookinAttrType)t {
    if (![value isKindOfClass:NSValue.class]) {
        return [value description] ?: @"";
    }
    NSValue *v = (NSValue *)value;

    switch (t) {
        case LookinAttrTypeCGPoint: {
            NSPoint p = v.pointValue;
            return @{ @"x": @(p.x), @"y": @(p.y) };
        }
        case LookinAttrTypeCGSize: {
            NSSize s = v.sizeValue;
            return @{ @"width": @(s.width), @"height": @(s.height) };
        }
        case LookinAttrTypeCGRect: {
            NSRect r = v.rectValue;
            return @{ @"x": @(r.origin.x),
                      @"y": @(r.origin.y),
                      @"width": @(r.size.width),
                      @"height": @(r.size.height) };
        }
        case LookinAttrTypeUIEdgeInsets: {
            NSEdgeInsets i = v.edgeInsetsValue;
            return @{ @"top": @(i.top),
                      @"left": @(i.left),
                      @"bottom": @(i.bottom),
                      @"right": @(i.right) };
        }
        case LookinAttrTypeCGVector: {
            CGFloat parts[2] = {0, 0};
            @try { [v getValue:&parts size:sizeof(parts)]; }
            @catch (__unused NSException *e) { return [v description] ?: @""; }
            return @{ @"dx": @(parts[0]), @"dy": @(parts[1]) };
        }
        case LookinAttrTypeUIOffset: {
            CGFloat parts[2] = {0, 0};
            @try { [v getValue:&parts size:sizeof(parts)]; }
            @catch (__unused NSException *e) { return [v description] ?: @""; }
            return @{ @"horizontal": @(parts[0]), @"vertical": @(parts[1]) };
        }
        case LookinAttrTypeCGAffineTransform: {
            CGFloat parts[6] = {0, 0, 0, 0, 0, 0};
            @try { [v getValue:&parts size:sizeof(parts)]; }
            @catch (__unused NSException *e) { return [v description] ?: @""; }
            return @{ @"a": @(parts[0]),
                      @"b": @(parts[1]),
                      @"c": @(parts[2]),
                      @"d": @(parts[3]),
                      @"tx": @(parts[4]),
                      @"ty": @(parts[5]) };
        }
        default:
            return [v description] ?: @"";
    }
}

/// Serializes a single LookinAttribute into a JSON-friendly dictionary.
/// Returns nil to indicate the attribute should be skipped entirely (None / Void / empty attr).
+ (NSDictionary *)_flattenAttribute:(LookinAttribute *)attr {
    if (!attr) return nil;

    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    d[@"id"] = attr.identifier ?: @"";
    d[@"type"] = [self _attrTypeName:attr.attrType];

    id value = attr.value;
    switch (attr.attrType) {
        case LookinAttrTypeNone:
        case LookinAttrTypeVoid:
            return nil;

        case LookinAttrTypeNSString:
            d[@"value"] = [value isKindOfClass:NSString.class] ? value : @"";
            break;

        case LookinAttrTypeBOOL:
            d[@"value"] = @([value boolValue]);
            break;

        // All integer + float types: value is always NSNumber, pass through directly.
        // ObjC does not support `case A ... B` ranges, so the 10 integer types must be listed individually.
        case LookinAttrTypeChar:
        case LookinAttrTypeInt:
        case LookinAttrTypeShort:
        case LookinAttrTypeLong:
        case LookinAttrTypeLongLong:
        case LookinAttrTypeUnsignedChar:
        case LookinAttrTypeUnsignedInt:
        case LookinAttrTypeUnsignedShort:
        case LookinAttrTypeUnsignedLong:
        case LookinAttrTypeUnsignedLongLong:
        case LookinAttrTypeFloat:
        case LookinAttrTypeDouble:
            d[@"value"] = [value isKindOfClass:NSNumber.class] ? value : @0;
            break;

        case LookinAttrTypeEnumInt:
        case LookinAttrTypeEnumLong:
            d[@"value"] = [value isKindOfClass:NSNumber.class] ? value : @0;
            // extraValue is typically a {rawValue: name} dict or a [name] array; only forward JSON containers.
            if ([attr.extraValue isKindOfClass:NSDictionary.class] ||
                [attr.extraValue isKindOfClass:NSArray.class]) {
                d[@"extraValue"] = attr.extraValue;
            }
            break;

        case LookinAttrTypeEnumString:
            d[@"value"] = [value isKindOfClass:NSString.class] ? value : @"";
            // Per LookinAttribute.h: extraValue is a [NSString *] listing every enum case name.
            if ([attr.extraValue isKindOfClass:NSArray.class]) {
                d[@"allCases"] = attr.extraValue;
            }
            break;

        case LookinAttrTypeUIColor:
            d[@"value"] = [self _hexFromRGBAArray:value];
            break;

        case LookinAttrTypeJson:
            if ([value isKindOfClass:NSDictionary.class] ||
                [value isKindOfClass:NSArray.class]) {
                d[@"value"] = value;
            } else {
                d[@"value"] = @{};
            }
            break;

        case LookinAttrTypeCGPoint:
        case LookinAttrTypeCGVector:
        case LookinAttrTypeCGSize:
        case LookinAttrTypeCGRect:
        case LookinAttrTypeCGAffineTransform:
        case LookinAttrTypeUIEdgeInsets:
        case LookinAttrTypeUIOffset:
            d[@"value"] = [self _structValueDescription:value attrType:attr.attrType];
            break;

        case LookinAttrTypeSel: {
            // The SEL is wrapped in NSValue; its description is unreadable, so use NSStringFromSelector.
            SEL sel = NULL;
            if ([value isKindOfClass:NSValue.class]) {
                @try { [(NSValue *)value getValue:&sel size:sizeof(sel)]; }
                @catch (__unused NSException *e) { sel = NULL; }
            }
            d[@"value"] = sel ? NSStringFromSelector(sel) : ([value description] ?: @"");
            break;
        }

        case LookinAttrTypeClass:
            // A Class's default description is the demangled class name, which is already readable.
            d[@"value"] = [value description] ?: @"";
            break;

        case LookinAttrTypeCustomObj:
        case LookinAttrTypeShadow:
        default:
            // Fallback: keep the field present but degrade content to a string description.
            d[@"value"] = [value description] ?: @"";
            break;
    }
    return [d copy];
}

@end
