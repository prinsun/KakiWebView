//
//  KakiProgressPlugin.m
//  KakiWebView
//
//  Created by MK on 2017/4/5.
//  Copyright © 2017年 makee. All rights reserved.
//
//  Note: This file was modify from **NJKWebViewProgress**
//  https://github.com/ninjinkun/NJKWebViewProgress

#import <UIKit/UIApplication.h>

#import "KakiProgressPlugin.h"
#import "UIWebView+Kaki.h"

static NSString *const KakiProgressCompletedRPCURLPath = @"/kakiprogressplugin/completed";

static inline NSString * KakiURLTrimFragment(NSURL *url) {
    if (url.fragment) {
        return [url.absoluteString stringByReplacingOccurrencesOfString:[@"#" stringByAppendingString:url.fragment] withString:@""];
    }
    return url.absoluteString;
}

@interface KakiWebViewProgressView : UIView

@property (nonatomic) float progress;
@property (nonatomic) UIView *progressBarView;
@property (nonatomic) NSTimeInterval barAnimationDuration;
@property (nonatomic) NSTimeInterval fadeAnimationDuration;
@property (nonatomic) NSTimeInterval fadeOutDelay;
@property (nonatomic) UIColor *progressColor;

- (void)setProgress:(float)progress animated:(BOOL)animated;

@end

@interface KakiProgressPlugin () {
    NSUInteger _loadingCount;
    NSUInteger _maxLoadCount;
    NSURL *_currentURL;
    BOOL _interactive;
}

@property (nonatomic, weak, readonly) UIWebView *webView;
@property (nonatomic, strong) KakiWebViewProgressView *progressView;

@end


@implementation KakiProgressPlugin

- (instancetype)init {
    if (self = [super init]) {
        _maxLoadCount = _loadingCount = 0;
        _progress = 0.0;
        _interactive = NO;
        _progressView = [[KakiWebViewProgressView alloc] initWithFrame:CGRectZero];
        _progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        _progressView.progressColor = [UIColor colorWithRed:0x44/255.f green:0xb3/255.f blue:0x36/255.f alpha:1];
    }
    return self;
}

- (void)dealloc {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)setProgressColor:(UIColor *)progressColor {
    self.progressView.progressColor = progressColor;
}

- (UIColor *)progressColor {
    return self.progressView.progressColor;
}

- (void)__startProgress {
    if (_progress < 0.1f) {
        [self setProgress:0.1f];
    }
}

- (void)__incrementProgress {
    float progress = self.progress;
    float maxProgress = _interactive ? 0.9f : 0.5f;
    float remainPercent = (float)_loadingCount / (float)_maxLoadCount;
    float increment = (maxProgress - progress) * remainPercent;
    progress += increment;
    progress = fmin(progress, maxProgress);
    [self setProgress:progress];
}

- (void)__completeProgress {
    [self setProgress:1.0];
    _isFinishLoad = YES;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)setProgress:(float)progress {
    if (progress > _progress || progress == 0) {
        _progress = progress;
        [self.progressView setProgress:progress];
    }
}

- (void)reset {
    _maxLoadCount = _loadingCount = 0;
    _interactive = _isFinishLoad = NO;
    [self setProgress:0.0];
}

- (BOOL)isProgressMonitorRequest:(NSURLRequest *)request {
    return [request.URL.path isEqualToString:KakiProgressCompletedRPCURLPath];
}

- (void)addViewBelowProgressView:(UIView *)view {
    [self.webView insertSubview:view belowSubview:self.progressView];
}

//////////////////////////////////////////////////////////////////////////////////////
#pragma mark - KakiWebViewPlugin
//////////////////////////////////////////////////////////////////////////////////////

- (void)didInstallToWebView:(UIWebView *)webView {
    _webView = webView;
    self.progressView.frame = CGRectMake(0, 0, webView.frame.size.width, 3.0);
    [self reset];
    [webView addSubview:self.progressView];
}

- (void)didUninstall {
    _webView = nil;
    [self reset];
    [self.progressView removeFromSuperview];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)webViewLayoutSubviews:(UIWebView *)webView {
    CGRect frame = self.progressView.frame;
    frame.origin.y = webView.scrollView.contentInset.top;
    if (self.progressView.frame.origin.y != frame.origin.y) {
        self.progressView.frame = frame;
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([self isProgressMonitorRequest:request]) {
        [self __completeProgress];
        return NO;
    }

    BOOL ret = YES;

    BOOL isFragmentJump = [KakiURLTrimFragment(request.URL) isEqualToString:webView.request.URL.absoluteString];
    BOOL isTopLevelNavigation = [request.mainDocumentURL isEqual:request.URL];
    BOOL isHTTPOrLocalFile = [request.URL.scheme isEqualToString:@"http"] || [request.URL.scheme isEqualToString:@"https"] || [request.URL.scheme isEqualToString:@"file"];

    if (ret && !isFragmentJump && isHTTPOrLocalFile && isTopLevelNavigation) {
        _currentURL = request.URL;
        [self reset];
    }

    _isFinishLoad = NO;
    return ret;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    _loadingCount++;
    _maxLoadCount = fmax(_maxLoadCount, _loadingCount);

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    [self __startProgress];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    _loadingCount--;
    [self __incrementProgress];

    NSString *readyState = [webView stringByEvaluatingJavaScriptFromString:@"document.readyState"];

    BOOL interactive = [readyState isEqualToString:@"interactive"];
    if (interactive) {
        _interactive = YES;
        [self __createWaitCompleteJSForWebView:webView];
    }

    BOOL isNotRedirect = _currentURL && [KakiURLTrimFragment(_currentURL) isEqualToString:KakiURLTrimFragment(webView.request.mainDocumentURL)];
    BOOL complete = [readyState isEqualToString:@"complete"];
    if (complete && isNotRedirect) {
        [self __completeProgress];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    _loadingCount--;
    [self __incrementProgress];

    NSString *readyState = [webView stringByEvaluatingJavaScriptFromString:@"document.readyState"];

    BOOL interactive = [readyState isEqualToString:@"interactive"];
    if (interactive) {
        _interactive = YES;
        [self __createWaitCompleteJSForWebView:webView];
    }

    BOOL isNotRedirect = _currentURL && [KakiURLTrimFragment(_currentURL) isEqualToString:KakiURLTrimFragment(webView.request.mainDocumentURL)];
    BOOL complete = [readyState isEqualToString:@"complete"];
    if ((complete && isNotRedirect) || error) {
        [self __completeProgress];
    }
}

- (void)__createWaitCompleteJSForWebView:(UIWebView *)webView {
    NSString *javascript = [NSString stringWithFormat:
                            @"(function() {"
                            @"    var isSentMockRequest = false;"
                            @"    if (window.kakiProgressFinishObservered) return;"
                            @"    var sendMockRequest = function() {"
                            @"        var ifr = document.createElement('iframe');"
                            @"        ifr.style.display = 'none';"
                            @"        ifr.src = '%@://%@%@';"
                            @"        document.body.appendChild(ifr);"
                            @"        setTimeout(function() {"
                            @"            ifr.parentNode.removeChild(ifr);"
                            @"        }, 0);"
                            @"        isSentMockRequest = true; "
                            @"    };"
                            @" "
                            @"    var timeoutID = setTimeout(sendMockRequest, 3000);"
                            @" "
                            @"    window.addEventListener('load', function() {"
                            @"        clearTimeout(timeoutID);"
                            @"        if (isSentMockRequest) return; "
                            @"        sendMockRequest();"
                            @"    }, false);"
                            @" "
                            @"    window.kakiProgressFinishObservered = true;"
                            @"})();",
                            webView.request.mainDocumentURL.scheme,
                            webView.request.mainDocumentURL.host,
                            KakiProgressCompletedRPCURLPath];
    [webView stringByEvaluatingJavaScriptFromString:javascript];
}

@end


@implementation KakiWebViewProgressView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self configureViews];
    }
    return self;
}

- (void)configureViews {
    self.userInteractionEnabled = NO;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _progressBarView = [[UIView alloc] initWithFrame:self.bounds];
    _progressBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_progressBarView];

    _barAnimationDuration = 0.27f;
    _fadeAnimationDuration = 0.27f;
    _fadeOutDelay = 0.1f;
}

- (void)setProgressColor:(UIColor *)progressColor {
    _progressBarView.backgroundColor = progressColor;
}

- (UIColor *)progressColor {
    return _progressBarView.backgroundColor;
}

- (void)setProgress:(float)progress {
    [self setProgress:progress animated:NO];
}

- (void)setProgress:(float)progress animated:(BOOL)animated {
    BOOL isGrowing = progress > 0.0;
    [UIView animateWithDuration:(isGrowing && animated) ? _barAnimationDuration : 0.0 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect frame = _progressBarView.frame;
        frame.size.width = progress * self.bounds.size.width;
        _progressBarView.frame = frame;
    } completion:nil];

    if (progress >= 1.0) {
        [UIView animateWithDuration:animated ? _fadeAnimationDuration : 0.0 delay:_fadeOutDelay options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _progressBarView.alpha = 0.0;
        } completion:^(BOOL completed){
            CGRect frame = _progressBarView.frame;
            frame.size.width = 0;
            _progressBarView.frame = frame;
        }];
    } else {
        [UIView animateWithDuration:animated ? _fadeAnimationDuration : 0.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _progressBarView.alpha = 1.0;
        } completion:nil];
    }
}

@end


@implementation UIWebView (KakiProgressPlugin)

- (KakiProgressPlugin *)progressPlugin {
    return [self kakiPluginForClass:KakiProgressPlugin.class];
}

@end
