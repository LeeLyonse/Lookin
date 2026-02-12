//
//  LKHTTPServer.h
//  Lookin
//
//  https://lookin.work
//

#import <Foundation/Foundation.h>

@interface LKHTTPServer : NSObject

+ (instancetype)sharedInstance;

- (void)start;
- (void)stop;

@property(nonatomic, assign, readonly) BOOL isRunning;
@property(nonatomic, assign, readonly) NSUInteger port;

@end
