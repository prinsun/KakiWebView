//
//  UIWebView+Kaki.h
//  KakiWebView
//
//  Created by MK on 2017/4/4.
//  Copyright © 2017年 makee. All rights reserved.
//

#import <KakiWebView/KakiWebViewPlugin.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIWebView (Kaki)

/**
 *  设置是否启用 Kaki 插件系统
 *
 *  @param enable 是否启用插件系统
 */
- (void)setEnableKakiPlugins:(BOOL)enable;

/**
 *  安装一个插件
 *
 *  @param plugin 要安装的插件
 */
- (void)installKakiPlugin:(id<KakiWebViewPlugin>)plugin;

/**
 *  卸载一个插件
 *
 *  @param pluginClass 要卸载的插件类型
 */
- (void)uninstallKakiPluginForClass:(Class)pluginClass;

/**
 *  卸载所有已安装的插件
 */
- (void)uninstallAllKakiPlugins;

/**
 *  获取已安装的特定插件
 *
 *  @param pluginClass 要获取的插件类型
 *
 *  @return 返回 nil 或者匹配的插件实例
 */
- (__kindof id<KakiWebViewPlugin> _Nullable)kakiPluginForClass:(Class)pluginClass;

@end

NS_ASSUME_NONNULL_END
