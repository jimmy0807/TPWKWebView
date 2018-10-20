//
//  TPWKWebViewController.h
//  KKCredit
//
//  Created by jimmy on 2017/10/13.
//  Copyright © 2017年 jimmy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WKWebViewJavascriptBridge.h"
NS_ASSUME_NONNULL_BEGIN
@interface TPWKWebView : UIView

@property(nonatomic, strong)NSString* url;
@property(nonatomic, strong)UIColor* progressColor;
//viewtype为2时有圆角，不显示进度条
@property(nonatomic, assign)BOOL isProgressShow;
@property(nonatomic, copy)void (^titleObserve)(NSString* title);
@property(nonatomic, copy)void (^goBackObserve)(BOOL canGoBack);
@property(nonatomic, copy)BOOL (^urlObserve)(NSString* url);
@property(nonatomic, copy)void (^loadFail)(void);
@property(nonatomic, strong)WKWebView* webView;
@property (nonatomic, strong) UIScrollView *scrollView;
- (void)reSetWebFrameWith:(CGRect)frame;
- (void)goBack;
- (BOOL)canGoback;
- (void)reload;
- (void)reloadUrl:(NSString*)url;
- (void)evaluateJS:(NSString *)js completionHandler:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completionHandler;
- (void)callHandler:(NSString *)handlerName data:(_Nullable id)data;
- (void)callHandler:(NSString *)handlerName data:(id)data responseCallback:(_Nullable WVJBResponseCallback)responseCallback;
- (void)registerHandler:(NSString *)handlerName handler:(WVJBHandler)handler;

@end
NS_ASSUME_NONNULL_END
