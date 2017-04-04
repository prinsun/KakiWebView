//
//  KakiWebViewPlugin.h
//  KakiWebView
//
//  Created by MK on 2017/4/4.
//  Copyright © 2017年 makee. All rights reserved.
//

#import <UIKit/UIWebView.h>

NS_ASSUME_NONNULL_BEGIN

@protocol KakiWebViewPlugin <UIWebViewDelegate>
@optional

/**
 *  插件被安装到 WebView 时触发该方法
 *
 *  @param webView 被安装到的 WebView
 */
- (void)didInstallToWebView:(UIWebView *)webView;

/**
 *  插件从 WebView 中卸载时，触发该方法
 */
- (void)didUninstall;

/**
 *  Web 调用了返回
 *
 *  @param webView 调用了返回的 WebView
 */
- (void)webViewDidGoback:(UIWebView *)webView;

/**
 *  WebView 的 Superview 变更检测
 *
 *  @param webView 相关的 WebView
 */
- (void)webViewDidMoveToSuperview:(UIWebView *)webView;

/**
 *  WebView 的 Window 变更检测
 *
 *  @param webView 相关的 WebView
 */
- (void)webViewDidMoveToWindow:(UIWebView *)webView;

/**
 *  WebView 布局子视图触发该方法
 *
 *  @param webView 布局子视图的 WebView
 */
- (void)webViewLayoutSubviews:(UIWebView *)webView;

@end

NS_ASSUME_NONNULL_END
