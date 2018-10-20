//
//  TPWKWebViewController.m
//  KKCredit
//
//  Created by jimmy on 2017/10/13.
//  Copyright © 2017年 jimmy. All rights reserved.
//

#import "TPWKWebView.h"
#import <WebKit/WebKit.h>

@interface TPWKWebView ()<WKNavigationDelegate, WKUIDelegate>

@property(nonatomic, strong)WKWebViewJavascriptBridge* bridge;
@property(nonatomic, strong)CALayer* progresslayer;
@property(nonatomic, strong, readonly)UIViewController* parentVC;
@end

@implementation TPWKWebView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if ( self )
    {
        self.webView = [[WKWebView alloc] initWithFrame:self.bounds configuration:[self configConfiguration]];
        self.webView.translatesAutoresizingMaskIntoConstraints = NO;
        self.webView.navigationDelegate = self;
        self.webView.UIDelegate = self;
        [self addSubview:self.webView];
        self.scrollView = self.webView.scrollView;
        self.bridge = [WKWebViewJavascriptBridge bridgeForWebView:self.webView];
        [self.bridge setWebViewDelegate:self];
        [self initProgressView];
        [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        [self.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
        self.isProgressShow = YES;
    }
    return self;
}

- (WKWebViewConfiguration *)configConfiguration {
    // 这是创建configuration 的过程
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    WKPreferences *preferences = [WKPreferences new];
    preferences.javaScriptCanOpenWindowsAutomatically = YES;
    configuration.preferences = preferences;
    return configuration;
}


- (void)setUrl:(NSString *)url
{
    _url = url;
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30]];
}

- (void)setProgressColor:(UIColor *)progressColor
{
    _progressColor = progressColor;
    self.progresslayer.backgroundColor = self.progressColor.CGColor;
}

- (void)initProgressView
{
    CALayer* progresslayer = [CALayer layer];
    progresslayer.frame = CGRectMake(0, 0, 0, 3);
    progresslayer.backgroundColor = self.progressColor ? self.progressColor.CGColor : [UIColor colorWithRed:126.0/255 green:206.0/255 blue:34.0/255 alpha:1].CGColor;
    [self.layer addSublayer:progresslayer];
    
    self.progresslayer = progresslayer;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( [keyPath isEqualToString:@"estimatedProgress"] )
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        if ( [change[NSKeyValueChangeNewKey] floatValue] <= [change[NSKeyValueChangeOldKey] floatValue] )
        {
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
        }
        
        if (self.isProgressShow)
        {
            self.progresslayer.frame = CGRectMake(0, 0, self.bounds.size.width * [change[@"new"] floatValue], 3);
            self.progresslayer.hidden = NO;
        }
        else
        {
            self.progresslayer.hidden = YES;
        }
        
        if ( [change[NSKeyValueChangeNewKey] floatValue] <= [change[NSKeyValueChangeOldKey] floatValue] )
        {
            [CATransaction commit];
        }
        
        if ( [change[NSKeyValueChangeNewKey] floatValue] == 1 )
        {
            [self performSelector:@selector(delayToCheckGoBack) withObject:nil afterDelay:0.3];
        }
        
        if ( self.goBackObserve )
        {
            self.goBackObserve(self.webView.canGoBack);
        }
    }
    else if ([keyPath isEqualToString:@"title"])
    {
        if ( self.titleObserve )
        {
            self.titleObserve(self.webView.title);
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)delayToCheckGoBack
{
    if ( self.goBackObserve )
    {
        self.goBackObserve(self.webView.canGoBack);
    }
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.progresslayer.frame = CGRectMake(0, 0, 0, 3);
    [CATransaction commit];
}


- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler
{
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        NSURLCredential *card = [[NSURLCredential alloc]initWithTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential,card);
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    if (!self.parentVC) {
        completionHandler();
        return;
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }])];
    [self.parentVC presentViewController:alertController animated:YES completion:nil];
    
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }])];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }])];
    [self.parentVC presentViewController:alertController animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = defaultText;
    }];
    [alertController addAction:([UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(alertController.textFields[0].text?:@"");
    }])];
    
    [self.parentVC presentViewController:alertController animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if ([[SensorsAnalyticsSDK sharedInstance] showUpWebView:webView WithRequest:navigationAction.request enableVerify:YES]) {
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    if ( self.urlObserve )
    {
        NSString *url = navigationAction.request.URL.absoluteString;
        decisionHandler(self.urlObserve(url) ? WKNavigationActionPolicyAllow : WKNavigationActionPolicyCancel);
        return;
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    if (self.loadFail)
    {
        self.loadFail();
    }
}

- (UIViewController *)parentVC
{
    for (UIView* next = [self superview]; next; next = next.superview)
    {
        UIResponder *nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]])
        {
            return (UIViewController *)nextResponder;
        }
    }
    
    return nil;
}

- (void)reSetWebFrameWith:(CGRect)frame {
    self.frame = frame;
    self.webView.frame = self.bounds;
}

- (void)goBack
{
    [self.webView goBack];
}

- (BOOL)canGoback
{
    return [self.webView canGoBack];
}

- (void)evaluateJS:(NSString *)js completionHandler:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completionHandler
{
    [self.webView evaluateJavaScript:js completionHandler:completionHandler];
}

- (void)reload
{
    self.url = _url;
}
- (void)reloadUrl:(NSString*)url {
    self.url = url;
}
- (void)callHandler:(NSString *)handlerName data:(id)data
{
    [self callHandler:handlerName data:data responseCallback:nil];
}

- (void)callHandler:(NSString *)handlerName data:(id)data responseCallback:(WVJBResponseCallback)responseCallback
{
    [self.bridge callHandler:handlerName data:data responseCallback:responseCallback];
}

- (void)registerHandler:(NSString *)handlerName handler:(WVJBHandler)handler
{
    [self.bridge registerHandler:handlerName handler:handler];
}

- (void)dealloc
{
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
    [self.webView removeObserver:self forKeyPath:@"title"];
    [self.bridge clearAllMessage];
}

@end
