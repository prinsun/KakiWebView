//
//  KakiProgressPlugin.h
//  KakiWebView
//
//  Created by MK on 2017/4/5.
//  Copyright © 2017年 makee. All rights reserved.
//

#import <KakiWebView/KakiWebViewPlugin.h>

NS_ASSUME_NONNULL_BEGIN

@interface KakiProgressPlugin : NSObject <KakiWebViewPlugin>

/**
 *  获取或设置进度条颜色
 */
@property (nonatomic, strong) UIColor *progressColor;

/**
 *  获取或设定当前进度， 0.0..1.0
 */
@property (nonatomic, assign) float progress;

/**
 *  获取是否已加载完成
 */
@property (nonatomic, assign, readonly) BOOL isFinishLoad;

/**
 *  重置进度条
 */
- (void)reset;

/**
 *  在进度条视图下，添加一个视图
 *
 *  @param view 要添加的视图
 */
- (void)addViewBelowProgressView:(UIView *)view;

@end


@interface UIWebView (KakiProgressPlugin)

/**
 *  获取 Progress 插件实例，如果没有安装则返回 nil
 */
@property (nullable, readonly) KakiProgressPlugin *progressPlugin;

@end

NS_ASSUME_NONNULL_END
