//
//  KakiPopGesturePlugin.m
//  KakiWebView
//
//  Created by MK on 2017/4/5.
//  Copyright © 2017年 makee. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "KakiPopGesturePlugin.h"

static NSString *const KakiLocationChangedRPCURLPath = @"/kakipopgestureplugin/location_changed";

typedef NS_ENUM(NSInteger, KakiSnapshotViewType) {
    KakiSnapshotViewTypeShadow = 2,
    KakiSnapshotViewTypeBlackAlpha = 3,
};

@interface KakiPopGesturePlugin () <UIGestureRecognizerDelegate>

// {'href': string, 'snapshot': image }
@property (nonatomic, strong, readonly) NSMutableArray *historySnapshots;
@property (nonatomic, assign) NSUInteger historyCursor;
@property (nonatomic, weak, readonly) UIWebView *webView;
@property (nonatomic, assign, readonly) CGRect webViewOriginalFrame;
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UIView *snapshotView;

@property (nonatomic, weak, readonly) UINavigationController *navigationController;

@end

@implementation KakiPopGesturePlugin

+ (UIImage *)snapshotForView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.frame.size, YES, 0.0);

    if ([view respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    } else {
        [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    }

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@synthesize navigationController = _navigationController;
- (UINavigationController *)navigationController {
    if (_navigationController == nil) {
        id nextResponder = [self.webView nextResponder];
        while (nextResponder && ![nextResponder isKindOfClass:[UIViewController class]]) {
            nextResponder = [nextResponder nextResponder];
        }

        if (nextResponder && [nextResponder isKindOfClass:[UINavigationController class]]) {
            _navigationController = nextResponder;
        } else if (nextResponder && [nextResponder isKindOfClass:[UIViewController class]]) {
            _navigationController = [nextResponder navigationController];
        }
    }
    return _navigationController;
}

- (void)__createOrUpdateSnapshots {
    __strong UIWebView *strongWebView = self.webView;
    if (strongWebView == nil) return;

    NSUInteger historyCount = [strongWebView stringByEvaluatingJavaScriptFromString:@"window.history.length"].integerValue;
    NSString *href = [strongWebView stringByEvaluatingJavaScriptFromString:@"window.location.href"];
    UIImage *snapshot = [self.class snapshotForView:strongWebView];
    if (snapshot == nil) snapshot = [UIImage new];
    id snapshotObj = @{@"href": href, @"snapshot": snapshot};

    if (historyCount > self.historySnapshots.count) {
        [self.historySnapshots addObject:snapshotObj];
        self.historyCursor = self.historySnapshots.count - 1;
    } else if (historyCount == self.historySnapshots.count) {
        if (self.historySnapshots.count > self.historyCursor + 1) {
            NSString *matchHref = self.historySnapshots[self.historyCursor + 1][@"href"];
            if ([matchHref isEqualToString:href]) {
                self.historySnapshots[self.historyCursor + 1] = snapshotObj;
                self.historyCursor += 1;
                return;
            }
        }

        for (NSInteger index = self.historyCursor; index >= 0; index--) {
            NSString *matchHref = self.historySnapshots[index][@"href"];
            if ([matchHref isEqualToString:href]) {
                self.historySnapshots[index] = snapshotObj;
                self.historyCursor = index;
                return;
            }
        }

        self.historySnapshots[historyCount - 1] = snapshotObj;
        self.historyCursor = historyCount - 1;
    } else {
        NSRange removeRange = NSMakeRange(historyCount, self.historySnapshots.count - historyCount);
        [self.historySnapshots removeObjectsInRange:removeRange];
        self.historySnapshots[historyCount - 1] = snapshotObj;
        self.historyCursor = historyCount - 1;
    }
}

- (void)__createSnapshotView {
    if (_snapshotView != nil) {
        [_snapshotView removeFromSuperview];
        _snapshotView = nil;
    }

    __strong UIWebView *strongWebView = self.webView;
    if (strongWebView == nil) return;

    CGRect rect = strongWebView.frame;
    _snapshotView = [[UIView alloc] initWithFrame:rect];
    CGRect bounds = _snapshotView.bounds;

    UIImageView *leftView = [[UIImageView alloc] initWithFrame:CGRectOffset(bounds, -44, 0)];
    leftView.contentMode = UIViewContentModeScaleAspectFit;
    if (self.historySnapshots.count > 0) {
        leftView.image = self.historySnapshots[self.historyCursor - 1][@"snapshot"];
    }
    leftView.tag = KakiSnapshotViewTypeShadow;
    [_snapshotView addSubview:leftView];

    UIView *blackView = [[UIView alloc] initWithFrame:bounds];
    blackView.alpha = 0.8;
    blackView.backgroundColor = [UIColor blackColor];
    blackView.tag = KakiSnapshotViewTypeBlackAlpha;
    [_snapshotView addSubview:blackView];

    _snapshotView.layer.masksToBounds = YES;
    [strongWebView.superview insertSubview:_snapshotView belowSubview:strongWebView];
}

- (void)__updateSnapshotViewWithX:(CGFloat)x {
    __strong UIWebView *strongWebView = self.webView;
    if (strongWebView == nil) return;

    if (x >= 0) {
        CGRect bounds = self.snapshotView.bounds;
        CGRect left = CGRectOffset(bounds, -44, 0);
        UIView *leftView = [self.snapshotView viewWithTag:KakiSnapshotViewTypeShadow];
        leftView.frame = CGRectOffset(left, (x / bounds.size.width) * 44, 0);

        strongWebView.frame = CGRectOffset(self.webViewOriginalFrame, x, 0);

        UIView *blackView = [self.snapshotView viewWithTag:KakiSnapshotViewTypeBlackAlpha];
        blackView.alpha = 0.8 * (1 - x / leftView.frame.size.width);
    }
}

- (void)__handlePanGesture:(UIPanGestureRecognizer *)pan {
    if (!self.webView.canGoBack || self.historySnapshots.count == 0 || self.historyCursor < 1)
        return;

    CGPoint offset = [pan translationInView:self.webView.superview];

    if (pan.state == UIGestureRecognizerStateBegan ) {
        [self __createSnapshotView];
        self.snapshotView.hidden = NO;
    } else if (pan.state == UIGestureRecognizerStateChanged && offset.x > 0) {
        [self __updateSnapshotViewWithX:offset.x];
    } else if (pan.state == UIGestureRecognizerStateEnded) {
        if (offset.x > 44) {
            [self.webView goBack];
            [UIView animateWithDuration:0.2 animations:^{
                [self __updateSnapshotViewWithX:self.webView.frame.size.width];
            } completion:^(BOOL finished) {
                self.webView.frame = self.webViewOriginalFrame;
            }];
        } else {
            [UIView animateWithDuration:0.2 animations:^{
                [self __updateSnapshotViewWithX:0];
            } completion:^(BOOL finished) {
                self.snapshotView.hidden = YES;
            }];
        }
    }
}

- (BOOL)isSnapshotMonitorRequest:(NSURLRequest *)request {
    return [request.URL.path isEqualToString:KakiLocationChangedRPCURLPath];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch locationInView:self.webView].x > 40) {
        return NO;
    }

    return [self gestureRecognizerShouldBegin:gestureRecognizer];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;

    if ([UIApplication sharedApplication].statusBarOrientation != UIInterfaceOrientationPortrait &&
        [UIApplication sharedApplication].statusBarOrientation != UIInterfaceOrientationPortraitUpsideDown) {
        return NO;
    }

    [self __createOrUpdateSnapshots];

    if (self.historySnapshots.count == 0 || self.historyCursor < 1) {
        return NO;
    }

    if ([self.webView canGoBack]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        _webViewOriginalFrame = self.webView.frame;
        return YES;
    }

    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    [otherGestureRecognizer requireGestureRecognizerToFail:gestureRecognizer];
    return YES;
}

//////////////////////////////////////////////////////////////////////////////////////
#pragma mark - KakiWebViewPlugin
//////////////////////////////////////////////////////////////////////////////////////

- (void)didInstallToWebView:(UIWebView *)webView {
    _webView = webView;
    _webViewOriginalFrame = _webView.frame;
    _historySnapshots = [NSMutableArray new];
    _historyCursor = 0;
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(__handlePanGesture:)];
    _panGesture.delegate = self;

    [_webView addGestureRecognizer:_panGesture];
}

- (void)didUninstall {
    [_webView removeGestureRecognizer:_panGesture];
    _webView = nil;
    _historySnapshots = nil;
    _historyCursor = 0;
    _panGesture.delegate = nil;
    _panGesture = nil;

    if (_snapshotView != nil) {
        [_snapshotView removeFromSuperview];
        _snapshotView = nil;
    }
}

- (void)webViewDidMoveToSuperview:(UIWebView *)webView {
    _webViewOriginalFrame = webView.frame;
}

- (void)webViewDidMoveToWindow:(UIWebView *)webView {
    _webViewOriginalFrame = webView.frame;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([self isSnapshotMonitorRequest:request]) {
        self.snapshotView.hidden = YES;
        [self __createOrUpdateSnapshots];
        return NO;
    }

    BOOL isTopLevelNavigation = [request.mainDocumentURL isEqual:request.URL];
    if (!isTopLevelNavigation) {
        self.snapshotView.hidden = YES;
    }

    [self __createOrUpdateSnapshots];

    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSString *javascript = [NSString stringWithFormat:
                            @"(function() {"
                            @"    if (window.kakiSnapshotLocationObservered) return;"
                            @"    var sendMockRequest = function() {"
                            @"        var ifr = document.createElement('iframe');"
                            @"        ifr.style.display = 'none';"
                            @"        ifr.src = '%@://%@%@';"
                            @"        document.body.appendChild(ifr);"
                            @"        setTimeout(function() {"
                            @"            ifr.parentNode.removeChild(ifr);"
                            @"        }, 0);"
                            @"    };"
                            @" "
                            @"    var pushState = window.history.pushState; "
                            @"    window.history.pushState = function(state) { "
                            @"        sendMockRequest();"
                            @"        return pushState.apply(window.history, arguments); "
                            @"    };"
                            @" "
                            @"    window.addEventListener('hashchange', function() {"
                            @"        sendMockRequest();"
                            @"    }, false);"
                            @" "
                            @"    window.addEventListener('popstate', function() {"
                            @"        sendMockRequest();"
                            @"    }, false);"
                            @" "
                            @"    window.kakiSnapshotLocationObservered = true;"
                            @"})();",
                            webView.request.mainDocumentURL.scheme,
                            webView.request.mainDocumentURL.host,
                            KakiLocationChangedRPCURLPath];
    [webView stringByEvaluatingJavaScriptFromString:javascript];

    self.snapshotView.hidden = YES;
    [self __createOrUpdateSnapshots];
}

@end
