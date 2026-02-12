//
//  LKHTTPServer.m
//  Lookin
//
//  https://lookin.work
//

#import "LKHTTPServer.h"
#import "LKHierarchySerializer.h"
#import "LKAppsManager.h"
#import "LKStaticHierarchyDataSource.h"
#import "LookinHierarchyInfo.h"
#import "LookinDisplayItem.h"
#import "LookinDisplayItem+LookinClient.h"
#import "LookinObject.h"
#import "LookinAppInfo.h"

@import GCDWebServer;

static const NSUInteger kDefaultPort = 56780;

@interface LKHTTPServer ()

@property(nonatomic, strong) GCDWebServer *webServer;

@end

@implementation LKHTTPServer

+ (instancetype)sharedInstance {
    static LKHTTPServer *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LKHTTPServer alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _webServer = [[GCDWebServer alloc] init];
        [self _registerHandlers];
    }
    return self;
}

- (void)start {
    if (self.webServer.isRunning) return;

    NSError *error = nil;
    NSDictionary *options = @{
        GCDWebServerOption_Port: @(kDefaultPort),
        GCDWebServerOption_BindToLocalhost: @(YES)
    };
    [self.webServer startWithOptions:options error:&error];
    if (error) {
        NSLog(@"LKHTTPServer failed to start: %@", error);
    } else {
        NSLog(@"LKHTTPServer started on port %lu", (unsigned long)kDefaultPort);
    }
}

- (void)stop {
    if (self.webServer.isRunning) {
        [self.webServer stop];
    }
}

- (BOOL)isRunning {
    return self.webServer.isRunning;
}

- (NSUInteger)port {
    return kDefaultPort;
}

#pragma mark - Register Handlers

- (void)_registerHandlers {
    __weak typeof(self) weakSelf = self;

    // GET /api/status
    [self.webServer addHandlerForMethod:@"GET" path:@"/api/status" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        return [weakSelf _handleStatus];
    }];

    // GET /api/apps
    [self.webServer addHandlerForMethod:@"GET" path:@"/api/apps" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        return [weakSelf _handleApps];
    }];

    // GET /api/hierarchy
    [self.webServer addHandlerForMethod:@"GET" path:@"/api/hierarchy" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        NSString *format = request.query[@"format"] ?: @"text";
        return [weakSelf _handleHierarchyWithFormat:format];
    }];

    // GET /api/selected
    [self.webServer addHandlerForMethod:@"GET" path:@"/api/selected" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        return [weakSelf _handleSelected];
    }];

    // GET /api/view (with ?oid=xxx)
    [self.webServer addHandlerForMethod:@"GET" path:@"/api/view" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        NSString *oidStr = request.query[@"oid"];
        return [weakSelf _handleViewWithOid:oidStr];
    }];

    // GET /api/search (with ?keyword=xxx)
    [self.webServer addHandlerForMethod:@"GET" path:@"/api/search" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        NSString *keyword = request.query[@"keyword"];
        return [weakSelf _handleSearchWithKeyword:keyword];
    }];

    // POST /api/reload - refresh hierarchy from iOS device
    [self.webServer addHandlerForMethod:@"POST" path:@"/api/reload" requestClass:[GCDWebServerRequest class] asyncProcessBlock:^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock completionBlock) {
        [weakSelf _handleReloadWithCompletion:completionBlock];
    }];
}

#pragma mark - Handlers

- (GCDWebServerDataResponse *)_handleStatus {
    LKInspectableApp *app = [LKAppsManager sharedInstance].inspectingApp;
    LKStaticHierarchyDataSource *ds = [LKStaticHierarchyDataSource sharedInstance];

    NSDictionary *result = @{
        @"running": @(YES),
        @"hasConnectedApp": @(app != nil),
        @"appName": app.appInfo.appName ?: @"",
        @"hasHierarchy": @(ds.rawHierarchyInfo != nil),
        @"viewCount": @(ds.rawFlatItems.count)
    };
    return [self _jsonResponse:result];
}

- (GCDWebServerDataResponse *)_handleApps {
    LKInspectableApp *currentApp = [LKAppsManager sharedInstance].inspectingApp;
    if (!currentApp) {
        return [self _jsonResponse:@{@"apps": @[], @"message": @"No app connected. Please connect an iOS app in Lookin first."}];
    }

    NSDictionary *appDict = [LKHierarchySerializer jsonFromAppInfo:currentApp.appInfo];
    return [self _jsonResponse:@{@"apps": @[appDict], @"currentApp": appDict}];
}

- (GCDWebServerDataResponse *)_handleHierarchyWithFormat:(NSString *)format {
    LKStaticHierarchyDataSource *ds = [LKStaticHierarchyDataSource sharedInstance];
    LookinHierarchyInfo *info = ds.rawHierarchyInfo;

    if (!info) {
        return [self _errorResponse:@"No hierarchy data. Please connect an iOS app and reload in Lookin." code:404];
    }

    if ([format isEqualToString:@"json"]) {
        NSArray *tree = [LKHierarchySerializer jsonTreeFromHierarchyInfo:info];
        return [self _jsonResponse:@{@"format": @"json", @"tree": tree}];
    } else {
        NSString *textTree = [LKHierarchySerializer textTreeFromHierarchyInfo:info];
        return [self _jsonResponse:@{@"format": @"text", @"tree": textTree}];
    }
}

- (GCDWebServerDataResponse *)_handleSelected {
    LKStaticHierarchyDataSource *ds = [LKStaticHierarchyDataSource sharedInstance];
    LookinDisplayItem *selected = ds.selectedItem;

    if (!selected) {
        return [self _errorResponse:@"No view selected in Lookin." code:404];
    }

    NSDictionary *detail = [LKHierarchySerializer jsonDetailFromDisplayItem:selected];
    return [self _jsonResponse:detail];
}

- (GCDWebServerDataResponse *)_handleViewWithOid:(NSString *)oidStr {
    if (!oidStr.length) {
        return [self _errorResponse:@"Missing 'oid' parameter." code:400];
    }

    unsigned long oid = [oidStr longLongValue];
    LKStaticHierarchyDataSource *ds = [LKStaticHierarchyDataSource sharedInstance];
    LookinDisplayItem *item = [ds displayItemWithOid:oid];

    if (!item) {
        return [self _errorResponse:[NSString stringWithFormat:@"View with oid %@ not found.", oidStr] code:404];
    }

    NSDictionary *detail = [LKHierarchySerializer jsonDetailFromDisplayItem:item];
    return [self _jsonResponse:detail];
}

- (GCDWebServerDataResponse *)_handleSearchWithKeyword:(NSString *)keyword {
    if (!keyword.length) {
        return [self _errorResponse:@"Missing 'keyword' parameter." code:400];
    }

    LKStaticHierarchyDataSource *ds = [LKStaticHierarchyDataSource sharedInstance];
    NSArray<LookinDisplayItem *> *allItems = ds.rawFlatItems;

    NSMutableArray *results = [NSMutableArray array];
    for (LookinDisplayItem *item in allItems) {
        if ([item isMatchedWithSearchString:keyword]) {
            NSDictionary *detail = [LKHierarchySerializer jsonDetailFromDisplayItem:item];
            [results addObject:detail];
        }
    }

    return [self _jsonResponse:@{@"keyword": keyword, @"count": @(results.count), @"results": results}];
}

- (void)_handleReloadWithCompletion:(GCDWebServerCompletionBlock)completionBlock {
    dispatch_async(dispatch_get_main_queue(), ^{
        LKInspectableApp *app = [LKAppsManager sharedInstance].inspectingApp;
        if (!app) {
            completionBlock([self _errorResponse:@"No app connected. Please connect an iOS app in Lookin first." code:404]);
            return;
        }

        [[app fetchHierarchyData] subscribeNext:^(LookinHierarchyInfo *info) {
            [[LKStaticHierarchyDataSource sharedInstance] reloadWithHierarchyInfo:info keepState:YES];
            NSUInteger viewCount = [LKStaticHierarchyDataSource sharedInstance].rawFlatItems.count;
            completionBlock([self _jsonResponse:@{
                @"success": @(YES),
                @"message": @"Hierarchy reloaded successfully.",
                @"viewCount": @(viewCount)
            }]);
        } error:^(NSError * _Nullable error) {
            completionBlock([self _errorResponse:[NSString stringWithFormat:@"Reload failed: %@", error.localizedDescription] code:500]);
        }];
    });
}

#pragma mark - Response Helpers

- (GCDWebServerDataResponse *)_jsonResponse:(id)object {
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:nil];
    return [GCDWebServerDataResponse responseWithData:data contentType:@"application/json"];
}

- (GCDWebServerDataResponse *)_errorResponse:(NSString *)message code:(NSInteger)code {
    NSDictionary *body = @{@"error": message};
    NSData *data = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    GCDWebServerDataResponse *response = [GCDWebServerDataResponse responseWithData:data contentType:@"application/json"];
    response.statusCode = code;
    return response;
}

@end
