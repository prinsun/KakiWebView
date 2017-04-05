//
//  KakiJavascriptCorePlugin.h
//  KakiWebView
//
//  Created by MK on 2017/4/5.
//  Copyright © 2017年 makee. All rights reserved.
//

#import <JavaScriptCore/JavaScriptCore.h>
#import <KakiWebView/KakiWebViewPlugin.h>

NS_ASSUME_NONNULL_BEGIN

@interface KakiJavascriptCorePlugin : NSObject <KakiWebViewPlugin>

/**
 *  注入一个 Objective-C 对象到 Javascript 环境中，该对象必须直接实现了一个 **实现JSExport协议的协议**
 *
 *  @param object 要注入的对象
 *  @param name   在 JS 中调用的名称
 */
- (void)setJSObject:(NSObject *)object forName:(NSString *)name;

/**
 *  注入一个 Objective-C 对象到 Javascript 环境中，该对象必须直接实现了一个 **实现JSExport协议的协议**
 *
 *  @param object   要注入的对象
 *  @param protocol 导出到Javascript环境中的协议，必须直接继承至 JSExport
 *  @param name     在 JS 中调用的名称
 */
- (void)setJSObject:(NSObject *)object withExportProtocol:(Protocol *)protocol forName:(NSString *)name;

/**
 *  移除注入到 Javascript 环境中的对象
 *
 *  @param name 要移除的名称
 */
- (void)removeJSObjectForName:(NSString *)name;

/**
 *  移除所有注入到 Javascript 环境中的对象
 */
- (void)removeAllJSObjects;

/**
 *  获取当前的 JSContext
 */
@property (nonatomic, strong, readonly) JSContext *jsContext;

@end


@interface UIWebView (KakiJavascriptCorePlugin)

/**
 *  获取 JavascriptCore 插件实例，如果没有安装则返回 nil
 */
@property (nullable, readonly) KakiJavascriptCorePlugin *javascriptCorePlugin;

@end

NS_ASSUME_NONNULL_END
