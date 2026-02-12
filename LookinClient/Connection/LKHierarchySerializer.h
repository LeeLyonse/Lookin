//
//  LKHierarchySerializer.h
//  Lookin
//
//  https://lookin.work
//

#import <Foundation/Foundation.h>

@class LookinDisplayItem, LookinHierarchyInfo, LookinAppInfo;

@interface LKHierarchySerializer : NSObject

/// Serialize the full UI tree as an indented text tree (token-efficient).
/// Each line: {indent}{className} {address} {text?} {frame} {flags?}
+ (NSString *)textTreeFromHierarchyInfo:(LookinHierarchyInfo *)info;

/// Serialize the full UI tree as a JSON-compatible array of dictionaries.
+ (NSArray<NSDictionary *> *)jsonTreeFromHierarchyInfo:(LookinHierarchyInfo *)info;

/// Serialize a single display item as a detailed JSON dictionary.
+ (NSDictionary *)jsonDetailFromDisplayItem:(LookinDisplayItem *)item;

/// Serialize app info as a JSON dictionary.
+ (NSDictionary *)jsonFromAppInfo:(LookinAppInfo *)appInfo;

@end
