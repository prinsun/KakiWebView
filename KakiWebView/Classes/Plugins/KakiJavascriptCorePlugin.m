//
//  KakiJavascriptCorePlugin.m
//  KakiWebView
//
//  Created by MK on 2017/4/5.
//  Copyright © 2017年 makee. All rights reserved.
//

#import <objc/runtime.h>

#import "KakiJavascriptCorePlugin.h"
#import "UIWebView+Kaki.h"

static NSString *const KakiJSContextDidCreateNotification = @"com.makee.kaki.notify.jscontext";

@interface KakiJavascriptCorePlugin ()

@property (nonatomic, weak, readonly) UIWebView *webView;
@property (nonatomic, strong, readonly) NSMutableDictionary *jsObjects;

@end

@implementation KakiJavascriptCorePlugin

- (instancetype)init {
    if (self = [super init]) {
        _jsObjects = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setJSObject:(NSObject *)object forName:(NSString *)name {
    NSAssert(object != nil, @"object cannot be nil!");
    NSAssert(name != nil, @"name cannot be nil!");

    self.jsObjects[name] = object;

    if (self.jsContext != nil) {
        self.jsContext[name] = nil;
        self.jsContext[name] = object;
    }
}

- (void)setJSObject:(NSObject *)object withExportProtocol:(Protocol *)protocol forName:(NSString *)name {
    NSAssert(object != nil, @"object cannot be nil!");
    NSAssert(name != nil, @"name cannot be nil!");

#if DEBUG
    {
        unsigned protocolCount = 0;
        Protocol * __unsafe_unretained * inheritProtocols = protocol_copyProtocolList(protocol, &protocolCount);

        BOOL findJSExport = NO;
        for (unsigned i = 0; i < protocolCount; i++) {
            findJSExport = protocol_isEqual(inheritProtocols[i], @protocol(JSExport));
            if (findJSExport) break;
        }

        if (inheritProtocols != NULL) free(inheritProtocols);

        NSAssert(findJSExport == YES, @"protocol must inherit of JSExport");
    }
#endif

    if (![object conformsToProtocol:protocol]) {
        class_addProtocol(object.class, protocol);
    }

    self.jsObjects[name] = object;

    if (self.jsContext != nil) {
        self.jsContext[name] = nil;
        self.jsContext[name] = object;
    }
}

- (void)removeJSObjectForName:(NSString *)name {
    NSAssert(name != nil, @"name cannot be nil!");

    [self.jsObjects removeObjectForKey:name];

    if (self.jsContext != nil) { self.jsContext[name] = nil; }
}

- (void)removeAllJSObjects {
    if (self.jsContext != nil) {
        [self.jsObjects.allKeys enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
            self.jsContext[name] = nil;
        }];
    }

    [self.jsObjects removeAllObjects];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - KakiWebViewPlugin
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)didInstallToWebView:(UIWebView *)webView {
    _webView = webView;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(__didCreateJSContext:)
                                                 name:KakiJSContextDidCreateNotification
                                               object:nil];

}

- (void)__didCreateJSContext:(NSNotification *)notification {
    NSString *cookie = [NSString stringWithFormat:@"KakiTest_%lud", (unsigned long)self.webView.hash];
    NSString *cookieTestJS = [NSString stringWithFormat:@"var %@ = '%@'", cookie, cookie];
    [self.webView stringByEvaluatingJavaScriptFromString:cookieTestJS];

    JSContext *ctx = notification.object;

    if (![ctx[cookie].toString isEqualToString:cookie]) return;

    _jsContext = ctx;

    [self.jsObjects enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSObject *obj, BOOL *stop) {
        self.jsContext[name] = nil;
        self.jsContext[name]= obj;
    }];

}

- (void)didUninstall {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if (self.jsContext == nil) return;

    [self.jsObjects.allKeys enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
        self.jsContext[name] = nil;
    }];
}

@end


@implementation NSObject (JSContextCreation)

- (void)webView:(id)unuse didCreateJavaScriptContext:(JSContext *)ctx forFrame:(id)frame {
    [[NSNotificationCenter defaultCenter] postNotificationName:KakiJSContextDidCreateNotification
                                                        object:ctx];
}

@end


@implementation UIWebView (KakiJavascriptCorePlugin)

- (KakiJavascriptCorePlugin *)javascriptCorePlugin {
    return [self kakiPluginForClass:KakiJavascriptCorePlugin.class];
}

@end
