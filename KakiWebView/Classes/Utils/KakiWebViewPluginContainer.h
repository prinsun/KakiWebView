//
//  KakiWebViewPluginContainer.h
//  KakiWebView
//
//  Created by MK on 2017/4/4.
//  Copyright © 2017年 makee. All rights reserved.
//

#import <KakiWebView/KakiWebViewPlugin.h>

NS_ASSUME_NONNULL_BEGIN

@interface KakiWebViewPluginContainer : NSObject <KakiWebViewPlugin>

/**
 *  往插件容器中添加一个插件
 *
 *  @param plugin 要添加的插件
 */
- (void)addPlugin:(id<KakiWebViewPlugin>)plugin;

/**
 *  从插件容器中移除一个插件
 *
 *  @param plugin 要移除的插件
 */
- (void)removePlugin:(id<KakiWebViewPlugin>)plugin;

/**
 *  移除当前容器中的所有插件
 */
- (void)removeAllPlugins;

@end

NS_ASSUME_NONNULL_END
