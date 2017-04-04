//
//  KakiWebViewPatcher.h
//  KakiWebView
//
//  Created by MK on 2017/4/4.
//  Copyright © 2017年 makee. All rights reserved.
//

#import "KakiWebViewPluginContainer.h"

NS_ASSUME_NONNULL_BEGIN

@interface KakiWebViewPatcher : NSObject

/**
 *  应用开启插件补丁
 *
 *  @param webView 要应用开启插件补丁的 WebView
 */
+ (void)applyPatchForWebView:(UIWebView *)webView;

/**
 *  移除开启插件补丁
 *
 *  @param webView 要移除开启插件补丁的 WebView
 */
+ (void)removePatchForWebView:(UIWebView *)webView;

@end


@interface UIWebView (KakiPluginContainer)

/**
 *  获取插件容器，注意：只有在应用了 Patch 之后才能获取到，否则为 nil
 *
 *  @return  插件容器 或 nil
 */
- (KakiWebViewPluginContainer *)kakiPluginContainer;

@end

NS_ASSUME_NONNULL_END
