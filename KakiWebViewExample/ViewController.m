//
//  ViewController.m
//  KakiWebViewExample
//
//  Created by MK on 2017/4/5.
//  Copyright © 2017年 makee. All rights reserved.
//

#import <KakiWebView/KakiWebView.h>

#import "ViewController.h"

@interface ViewController ()

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // config plugins
    [self.webView setEnableKakiPlugins:YES];
    [self.webView installKakiPlugin:[KakiProgressPlugin.alloc init]];
    [self.webView installKakiPlugin:[KakiPopGesturePlugin.alloc init]];
    [self.webView installKakiPlugin:[KakiTitleObserverPlugin.alloc init]];

    __weak __typeof(self) wself = self;
    [self.webView.titleObserverPlugin setOnTitleChanged:^(NSString *title) {
        wself.titleLabel.text = title;
    }];
    self.webView.progressPlugin.progressColor = [UIColor redColor];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://blog.makeex.com"]]];
}


@end
