//
//  KakiTitleObserverPlugin.h
//  KakiWebView
//
//  Created by MK on 2017/4/5.
//  Copyright © 2017年 makee. All rights reserved.
//

#import <KakiWebView/KakiWebViewPlugin.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^KakiTitleChangedBlock)(NSString *title);


@interface KakiTitleObserverPlugin : NSObject <KakiWebViewPlugin>

/**
 *  获取或设置 Title 变更时监听 block
 */
@property (nullable, nonatomic, copy) KakiTitleChangedBlock onTitleChanged;

@end


@interface UIWebView (KakiTitleObserverPlugin)

/**
 *  获取 Title Observer 插件实例，如果没有安装则返回 nil
 */
@property (nullable, readonly) KakiTitleObserverPlugin *titleObserverPlugin;

@end

NS_ASSUME_NONNULL_END
