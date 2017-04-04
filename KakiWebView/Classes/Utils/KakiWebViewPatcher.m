//
//  KakiWebViewPatcher.m
//  KakiWebView
//
//  Created by MK on 2017/4/4.
//  Copyright © 2017年 makee. All rights reserved.
//

#import <objc/runtime.h>

#import "KakiWebViewPatcher.h"


static char *const kKakiOriginDelegateKey       = "com.makee.kaki.delegate";
static char *const kKakiPluginContainerKey      = "com.makee.kaki.plugin_conatienr";
static NSString *const kKakiWebViewClassPrefix  = @"KakiDynamic_";

@implementation KakiWebViewPatcher

+ (void)applyPatchForWebView:(UIWebView *)webView {
    if (webView.delegate != nil && [webView.delegate isKindOfClass:[KakiWebViewPluginContainer class]]) {
        return;
    }

    KakiWebViewPluginContainer *pluginContainer = [KakiWebViewPluginContainer new];
    objc_setAssociatedObject(webView, kKakiPluginContainerKey, pluginContainer, OBJC_ASSOCIATION_RETAIN);

    if (webView.delegate != nil) {
        NSString *delegateClsName = NSStringFromClass(object_getClass(webView.delegate));
        if (![delegateClsName hasPrefix:@"NBSLensWebView"] &&
            ![delegateClsName hasPrefix:@"A2Dynamic"]) {
            objc_setAssociatedObject(webView, kKakiOriginDelegateKey, webView.delegate, OBJC_ASSOCIATION_ASSIGN);
            [pluginContainer addPlugin:(id)webView.delegate];
        }
    }

    [webView setDelegate:pluginContainer];
    [self __dynamicInheritWebView:webView];
}

+ (void)removePatchForWebView:(UIWebView *)webView {
    if (webView.delegate == nil || ![webView.delegate isKindOfClass:[KakiWebViewPluginContainer class]]) {
        return;
    }

    [self __restoreDynamicInherittedWebView:webView];

    [webView setDelegate:objc_getAssociatedObject(webView, kKakiOriginDelegateKey)];

    objc_setAssociatedObject(webView, kKakiOriginDelegateKey, nil, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(webView, kKakiPluginContainerKey, nil, OBJC_ASSOCIATION_RETAIN);
}

+ (void)__dynamicInheritWebView:(UIWebView *)webView {
    NSString *className = NSStringFromClass(webView.class);

    if ([className hasPrefix:kKakiWebViewClassPrefix]) return;

    NSString *dynamicClassName = [NSString stringWithFormat:@"%@%@", kKakiWebViewClassPrefix, className];
    Class dynamicClass = NSClassFromString(dynamicClassName);

    if (dynamicClass == NULL) {
        dynamicClass = objc_allocateClassPair(webView.class, dynamicClassName.UTF8String, 0);
        IMP dynamicIMP;
        dynamicIMP = class_getMethodImplementation(self, @selector(setDelegate:));
        if (dynamicIMP) {
            class_addMethod(dynamicClass, @selector(setDelegate:), dynamicIMP, "v@:@");
        }
        dynamicIMP = class_getMethodImplementation(self, @selector(didMoveToSuperview));
        if (dynamicIMP) {
            class_addMethod(dynamicClass, @selector(didMoveToSuperview), dynamicIMP, "v@:");
        }
        dynamicIMP = class_getMethodImplementation(self, @selector(didMoveToWindow));
        if (dynamicIMP) {
            class_addMethod(dynamicClass, @selector(didMoveToWindow), dynamicIMP, "v@:");
        }
        dynamicIMP = class_getMethodImplementation(self, @selector(layoutSubviews));
        if (dynamicIMP) {
            class_addMethod(dynamicClass, @selector(layoutSubviews), dynamicIMP, "v@:");
        }
        dynamicIMP = class_getMethodImplementation(self, @selector(goBack));
        if (dynamicIMP) {
            class_addMethod(dynamicClass, @selector(goBack), dynamicIMP, "v@:");
        }

        objc_registerClassPair(dynamicClass);
    }

    if (dynamicClass != NULL) {
        object_setClass(webView, dynamicClass);
    }
}

+ (void)__restoreDynamicInherittedWebView:(UIWebView *)webView {
    NSString *className = NSStringFromClass(webView.class);

    if (![className hasPrefix:kKakiWebViewClassPrefix]) return;

    NSString *originClassName = [className substringFromIndex:kKakiWebViewClassPrefix.length];
    Class originClass = NSClassFromString(originClassName);

    NSAssert(originClass != NULL, @"unknow exception, could not found origin class!");

    object_setClass(webView, originClass);
}

//////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Dynamic IMP
//////////////////////////////////////////////////////////////////////////////////////

- (void)setDelegate:(id<UIWebViewDelegate>)delegate {
    KakiWebViewPluginContainer *pluginContainer = objc_getAssociatedObject(self, kKakiOriginDelegateKey);
    id<UIWebViewDelegate> originDelegate = objc_getAssociatedObject(self, kKakiOriginDelegateKey);

    NSAssert(pluginContainer != nil, @"plugin container can not be nil");

    if (delegate == nil && originDelegate != nil) {
        [pluginContainer removePlugin:(id)originDelegate];

        objc_setAssociatedObject(self, kKakiOriginDelegateKey, nil, OBJC_ASSOCIATION_ASSIGN);
    } else if (delegate != nil && originDelegate == nil) {
        [pluginContainer addPlugin:(id)delegate];
    } else if (delegate != nil && originDelegate != nil) {
        [pluginContainer removePlugin:(id)originDelegate];
        [pluginContainer addPlugin:(id)delegate];

        objc_setAssociatedObject(self, kKakiOriginDelegateKey, nil, OBJC_ASSOCIATION_ASSIGN);
        objc_setAssociatedObject(self, kKakiOriginDelegateKey, delegate, OBJC_ASSOCIATION_ASSIGN);
    }
}

- (void)didMoveToSuperview {
    __weak UIWebView *realSelf = (UIWebView *)self;

    Class superClass = [realSelf superclass];
    while (superClass) {
        IMP superIMP = class_getMethodImplementation(superClass, @selector(didMoveToSuperview));
        if (superIMP == NULL) {
            superClass = class_getSuperclass(superClass);
        } else {
            typedef void(*SuperMethodPointer)(id, SEL);
            SuperMethodPointer pMethod = (SuperMethodPointer)superIMP;
            pMethod(self, @selector(didMoveToSuperview));
            break;
        }
    }

    if ([realSelf.delegate respondsToSelector:@selector(webViewDidMoveToSuperview:)]) {
        [(id)realSelf.delegate webViewDidMoveToSuperview:realSelf];
    }
}

- (void)didMoveToWindow {
    __weak UIWebView *realSelf = (UIWebView *)self;

    Class superClass = [realSelf superclass];
    while (superClass) {
        IMP superIMP = class_getMethodImplementation(superClass, @selector(didMoveToWindow));
        if (superIMP == NULL) {
            superClass = class_getSuperclass(superClass);
        } else {
            typedef void(*SuperMethodPointer)(id, SEL);
            SuperMethodPointer pMethod = (SuperMethodPointer)superIMP;
            pMethod(self, @selector(didMoveToWindow));
            break;
        }
    }

    if ([realSelf.delegate respondsToSelector:@selector(webViewDidMoveToWindow:)]) {
        [(id)realSelf.delegate webViewDidMoveToWindow:realSelf];
    }
}

- (void)layoutSubviews {
    __weak UIWebView *realSelf = (UIWebView *)self;

    Class superClass = [realSelf superclass];
    while (superClass) {
        IMP superIMP = class_getMethodImplementation(superClass, @selector(layoutSubviews));
        if (superIMP == NULL) {
            superClass = class_getSuperclass(superClass);
        } else {
            typedef void(*SuperMethodPointer)(id, SEL);
            SuperMethodPointer pMethod = (SuperMethodPointer)superIMP;
            pMethod(self, @selector(layoutSubviews));
            break;
        }
    }

    if ([realSelf.delegate respondsToSelector:@selector(webViewLayoutSubviews:)]) {
        [(id)realSelf.delegate webViewLayoutSubviews:realSelf];
    }
}

- (void)goBack {
    __weak UIWebView *realSelf = (UIWebView *)self;

    Class superClass = [realSelf superclass];
    while (superClass) {
        IMP superIMP = class_getMethodImplementation(superClass, @selector(goBack));
        if (superIMP == NULL) {
            superClass = class_getSuperclass(superClass);
        } else {
            typedef void(*SuperMethodPointer)(id, SEL);
            SuperMethodPointer pMethod = (SuperMethodPointer)superIMP;
            pMethod(self, @selector(goBack));
            break;
        }
    }

    if ([realSelf.delegate respondsToSelector:@selector(webViewDidGoback:)]) {
        [(id)realSelf.delegate webViewDidGoback:realSelf];
    }
}

@end


@implementation UIWebView (KakiPluginContainer)

- (KakiWebViewPluginContainer *)kakiPluginContainer {
    return objc_getAssociatedObject(self, kKakiPluginContainerKey);
}

@end
