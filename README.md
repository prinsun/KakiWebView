# KakiWebView

## 描述

KakiWebView，应用于`UIWebView`，提供一些通用的扩展功能，以下是该库的设计目标：

* 对于现有的`UIWebView`无侵入性的使用
* 可扩展性强，可实现自定义扩展
* 简单易用，学习成本低

详见[《Thinking in FE 更好用的 UIWebView》](http://blog.makeex.com/2017/04/06/thinking-in-fe-how-to-enhance-the-uiwebview/)。

## 安装

### Cocoapods

	pod KakiWebView
	
### Carthage

	github prinsun/KakiWebView
	
	
## 使用

```objc
// 启用 Kaki
[self.webView setEnableKakiPlugins:YES];

// 安装 Kaki 插件
[self.webView installKakiPlugin:[KakiProgressPlugin.alloc init]];
[self.webView installKakiPlugin:[KakiPopGesturePlugin.alloc init]];
[self.webView installKakiPlugin:[KakiTitleObserverPlugin.alloc init]];

// 配置插件
__weak __typeof(self) wself = self;
[self.webView.titleObserverPlugin setOnTitleChanged:^(NSString *title) {
    wself.titleLabel.text = title;
}];
self.webView.progressPlugin.progressColor = [UIColor redColor];
```