//
//  UIWebView+Kaki.m
//  KakiWebView
//
//  Created by MK on 2017/4/4.
//  Copyright © 2017年 makee. All rights reserved.
//

#import <objc/runtime.h>

#import "UIWebView+Kaki.h"
#import "KakiWebViewPatcher.h"

@implementation UIWebView (Kaki)

- (void)setEnableKakiPlugins:(BOOL)enable {
    if (enable) {
        [KakiWebViewPatcher applyPatchForWebView:self];
    } else {
        [KakiWebViewPatcher removePatchForWebView:self];
    }
}

- (void)installKakiPlugin:(id<KakiWebViewPlugin>)plugin {
    NSAssert(plugin != nil, @"plugin can not be nil");

    NSMutableDictionary *pluginMap = [self __pluginMap];
    pluginMap[NSStringFromClass([plugin class])] = plugin;

    [self.kakiPluginContainer removePlugin:plugin];
    [self.kakiPluginContainer addPlugin:plugin];

    if ([plugin respondsToSelector:@selector(didInstallToWebView:)]) {
        [plugin didInstallToWebView:self];
    }
}

- (void)uninstallKakiPluginForClass:(Class)pluginClass {
    NSAssert(pluginClass != NULL, @"plugin class can not be nil");

    NSMutableDictionary *pluginMap = [self __pluginMap];
    id<KakiWebViewPlugin> plugin = [pluginMap objectForKey:NSStringFromClass(pluginClass)];
    if (plugin != nil) {
        [pluginMap removeObjectForKey:NSStringFromClass(pluginClass)];
        [self.kakiPluginContainer removePlugin:plugin];

        if ([plugin respondsToSelector:@selector(didUninstall)]) {
            [plugin didUninstall];
        }
    }
}

- (void)uninstallAllKakiPlugins {
    for (id<KakiWebViewPlugin> plugin in self.__pluginMap.allValues) {
        [self.kakiPluginContainer removePlugin:plugin];

        if ([plugin respondsToSelector:@selector(didUninstall)]) {
            [plugin didUninstall];
        }
    }

    [self.__pluginMap removeAllObjects];
}

- (__kindof id<KakiWebViewPlugin> _Nullable)kakiPluginForClass:(Class)pluginClass {
    NSMutableDictionary *pluginMap = [self __pluginMap];
    return [pluginMap objectForKey:NSStringFromClass(pluginClass)];
}

- (NSMutableDictionary *)__pluginMap {
    NSAssert(self.kakiPluginContainer != nil, @"must enable kaki plugins first");

    NSMutableDictionary *result = objc_getAssociatedObject(self.kakiPluginContainer, _cmd);
    if (result == nil) {
        result = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self.kakiPluginContainer, _cmd, result, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return result;
}

@end
