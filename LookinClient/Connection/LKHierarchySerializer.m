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
            if (group.identifier.length) {
                groupDict[@"id"] = group.identifier;
            }
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

@end
