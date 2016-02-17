//
//  ViewController.m
//  KSWebView
//
//  Created by KeSen on 16/2/16.
//  Copyright © 2016年 KeSen. All rights reserved.
//

// 参考 http://www.jianshu.com/p/f896d73c670a

#import "ViewController.h"
#import "WebViewJavascriptBridge.h"
#import <JavaScriptCore/JavaScriptCore.h>

// 自定义协议中的方法就是暴露给 web 页面的方法
@protocol JSObjcDelegate <JSExport>

- (void)callCamera;
- (void)share:(NSString *)shareString;

@end


@interface ViewController () <UIWebViewDelegate, JSObjcDelegate>

@property (nonatomic, strong) UIWebView *webView;

// 方式1：使用第三方库 WebViewJavascriptBridge 进行交互
@property (nonatomic, strong) WebViewJavascriptBridge *bridge;

// 方式2：使用 JavaScripCore 进行交互
@property (nonatomic, strong) JSContext *jsContext;

@end

@implementation ViewController

#pragma mark - Life Circle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    webView.delegate = self;
    [self.view addSubview:webView];
    _webView = webView;
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"test2" withExtension:@"html"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [self.webView loadRequest:request];

}

#pragma mark - 使用拦截协议在 JS 中运行 OC 代码

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
//    NSString *url = request.URL.absoluteString;
//    if ([url rangeOfString:@"toyun://"].location != NSNotFound) {
//        // url的协议头是toyun
//        NSLog(@"callCamera");
//        return NO;
//    }
    return YES;
}

#pragma mark - 使用第三方框架 WebViewJavascriptBridge
// TODO 还有问题
- (void)webViewJSBridge {
    //设置能够进行桥接
    [WebViewJavascriptBridge enableLogging];
    
    _bridge = [WebViewJavascriptBridge bridgeForWebView:_webView];
    
    [_bridge registerHandler:@"fn_call" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"call----");
    }];
}

/**
 *  打开照相机
 */
- (void)openCamera
{
    NSLog(@"openCamera----");
}

#pragma mark - 使用 JavaScriptCore （推荐）

#pragma mark UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    // 在 webView 加载完毕的时候获取 JavaScript 运行的上下文环境
    self.jsContext = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    
    // 注入桥梁对象名为 Toyun，承载的对象为 self
    self.jsContext[@"Toyun"] = self;
    
    self.jsContext.exceptionHandler = ^(JSContext *context, JSValue *exceptionValue) {
        context.exception = exceptionValue;
        NSLog(@"异常信息：%@", exceptionValue);
    };
}

#pragma mark JSObjcDelegate

// 注意点：JavaStript 调用本地方法是在子线程中执行的

//  假设此方法是在子线程中执行的，线程名sub-thread
- (void)callCamera {
    
    NSLog(@"%@", [NSThread currentThread]);
    
    // 这句假设要在主线程中执行，线程名main-thread
    NSLog(@"callCamera");
    
    // 下面这两句代码最好还是要在子线程sub-thread中执行啊
    
    // 获取到照片之后在回调 js 的方法 picCallback 把图片传出去
    JSValue *picCallback = self.jsContext[@"picCallback"];
    [picCallback callWithArguments:@[@"photos"]];
}

- (void)share:(NSString *)shareString {
    
    NSLog(@"share:%@", shareString);
    
    // 分享成功回调 js 的方法 shareCallback
    JSValue *shareCallback = self.jsContext[@"shareCallback"];
    [shareCallback callWithArguments:nil];
}


@end
