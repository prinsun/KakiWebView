//
//  KakiTitleObserverPlugin.m
//  KakiWebView
//
//  Created by MK on 2017/4/5.
//  Copyright © 2017年 makee. All rights reserved.
//

#import "KakiTitleObserverPlugin.h"
#import "UIWebView+Kaki.h"

static NSString *KakiTitleChangedRPCURLPath = @"/kakititleobserverplugin/title_changed";

@interface KakiTitleObserverPlugin ()

@property (nonatomic, weak, readonly) UIWebView *webView;
@property (nonatomic, copy) NSString *title;

@end

@implementation KakiTitleObserverPlugin

- (BOOL)isTitleMonitorRequest:(NSURLRequest *)request {
    return [request.URL.path isEqualToString:KakiTitleChangedRPCURLPath];
}


//////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Extenstion Impl
//////////////////////////////////////////////////////////////////////////////////////

- (void)didInstallToWebView:(UIWebView *)webView {
    _webView = webView;
    [self __updateTitle];
}

- (void)didUninstall {
    _webView = nil;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([self isTitleMonitorRequest:request]) {
        [self __updateTitle];
        return NO;
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self __updateTitle];

    NSString *observerTitleJS = [NSString stringWithFormat:
                                 @"(function() {"
                                 @"     if(window.kakiTitleChangeObserverd) return;"
                                 @"     var target = document.querySelector('head > title');"
                                 @"     var observer = new window.MutationObserver(function(mutations) {"
                                 @"             mutations.forEach(function(mutation) {"
                                 @"                 var ifr = document.createElement('iframe');"
                                 @"                 ifr.style.display = 'none';"
                                 @"                 ifr.src = '%@://%@%@';"
                                 @"                 document.body.appendChild(ifr);"
                                 @"                 setTimeout(function() {"
                                 @"                     ifr.parentNode.removeChild(ifr);"
                                 @"                 }, 0);"
                                 @"             });"
                                 @"     });"
                                 @"     observer.observe(target, {"
                                 @"         subtree: true,"
                                 @"         characterData: true,"
                                 @"         childList: true"
                                 @"     });"
                                 @"     window.kakiTitleChangeObserverd = true;"
                                 @"})();",
                                 webView.request.mainDocumentURL.scheme,
                                 webView.request.mainDocumentURL.host,
                                 KakiTitleChangedRPCURLPath];
    [webView stringByEvaluatingJavaScriptFromString:observerTitleJS];
}

- (void)__updateTitle {
    NSString *documentTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    if (self.title && documentTitle && [documentTitle isEqualToString:self.title])
        return;

    self.title = documentTitle;

    if (self.onTitleChanged) {
        self.onTitleChanged(documentTitle);
    }
}

@end


@implementation UIWebView (KakiTitleObserverPlugin)

- (KakiTitleObserverPlugin *)titleObserverPlugin {
    return [self kakiPluginForClass:KakiTitleObserverPlugin.class];
}

@end
