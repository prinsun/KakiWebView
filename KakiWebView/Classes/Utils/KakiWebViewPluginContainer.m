//
//  KakiWebViewPluginContainer.m
//  KakiWebView
//
//  Created by MK on 2017/4/4.
//  Copyright © 2017年 makee. All rights reserved.
//

#import "KakiWebViewPluginContainer.h"

@interface KakiWebViewPluginContainer ()

@property (nonatomic, strong, readonly) NSPointerArray *plugins;

@end

@implementation KakiWebViewPluginContainer

- (instancetype)init {
    if (self = [super init]) {
        _plugins = [NSPointerArray weakObjectsPointerArray];
    }
    return self;
}

- (void)dealloc {
    [self didUninstall];
}

- (void)addPlugin:(id<KakiWebViewPlugin>)plugin {
    NSAssert(plugin != nil, @"plugin can not be nil");

    [self.plugins addPointer:(__bridge void *)(plugin)];
}

- (void)removePlugin:(id<KakiWebViewPlugin>)plugin {
    if (plugin == nil) return;

    @autoreleasepool {
        for (int i = 0; i < self.plugins.count; i++) {
            void *pointer = [self.plugins pointerAtIndex:i];
            if (pointer == NULL) continue;

            if (plugin == (__bridge id<UIWebViewDelegate>)pointer) {
                [self.plugins removePointerAtIndex:i];
                break;
            }
        }
    }
}

- (void)removeAllPlugins {
    [self.plugins setCount:0];
}


//////////////////////////////////////////////////////////////////////////////////////
#pragma mark - KakiWebViewPlugin
//////////////////////////////////////////////////////////////////////////////////////

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {

    BOOL result = YES;

    for (id<UIWebViewDelegate> delegate in self.plugins) {
        if ([delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
            BOOL delegateResult = [delegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
            result = result && delegateResult;
        }
    }

    return result;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    for (id<UIWebViewDelegate> delegate in self.plugins) {
        if ([delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
            [delegate webViewDidStartLoad:webView];
        }
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    for (id<UIWebViewDelegate> delegate in self.plugins) {
        if ([delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
            [delegate webViewDidFinishLoad:webView];
        }
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    for (id<UIWebViewDelegate> delegate in self.plugins) {
        if ([delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
            [delegate webView:webView didFailLoadWithError:error];
        }
    }
}

- (void)webViewDidGoback:(UIWebView *)webView {
    for (id<KakiWebViewPlugin> plugin in self.plugins) {
        if ([plugin respondsToSelector:@selector(webViewDidGoback:)]) {
            [plugin webViewDidGoback:webView];
        }
    }
}

- (void)webViewDidMoveToSuperview:(UIWebView *)webView {
    for (id<KakiWebViewPlugin> plugin in self.plugins) {
        if ([plugin respondsToSelector:@selector(webViewDidMoveToSuperview:)]) {
            [plugin webViewDidMoveToSuperview:webView];
        }
    }
}

- (void)webViewDidMoveToWindow:(UIWebView *)webView {
    for (id<KakiWebViewPlugin> plugin in self.plugins) {
        if ([plugin respondsToSelector:@selector(webViewDidMoveToWindow:)]) {
            [plugin webViewDidMoveToWindow:webView];
        }
    }
}

- (void)didInstallToWebView:(UIWebView *)webView {
    for (id<KakiWebViewPlugin> plugin in self.plugins) {
        if ([plugin respondsToSelector:@selector(didInstallToWebView:)]) {
            [plugin webViewDidStartLoad:webView];
        }
    }
}

- (void)didUninstall {
    for (id<KakiWebViewPlugin> plugin in self.plugins) {
        if ([plugin respondsToSelector:@selector(didUninstall)]) {
            [plugin didUninstall];
        }
    }
}

- (void)webViewLayoutSubviews:(UIWebView *)webView {
    for (id<KakiWebViewPlugin> plugin in self.plugins) {
        if ([plugin respondsToSelector:@selector(webViewLayoutSubviews:)]) {
            [plugin webViewLayoutSubviews:webView];
        }
    }
}

@end
