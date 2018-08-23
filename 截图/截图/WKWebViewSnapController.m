//
//  WKWebViewSnapController.m
//  截图
//
//  Created by digitalforest on 2018/8/21.
//  Copyright © 2018年 digitalforest. All rights reserved.
//

#import "WKWebViewSnapController.h"
#import <WebKit/WebKit.h>
#import <UIKit/UIKit.h>

#import "SaveImage.h"

@interface WKWebViewSnapController ()
@property (strong, nonatomic) WKWebView *wkWebView;

@end

@implementation WKWebViewSnapController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"截屏" style:UIBarButtonItemStylePlain target:self action:@selector(snap)];
    
    self.wkWebView = [WKWebView new];
    [self.view addSubview:self.wkWebView];
    
    self.wkWebView.translatesAutoresizingMaskIntoConstraints = NO;
    NSString *Hvfl = @"H:|-0-[redView]-0-|";
    NSString *Vvfl = @"V:|-0-[redView]-0-|";
    NSDictionary *views = @{@"redView":self.wkWebView};
    NSLayoutFormatOptions ops = NSLayoutFormatAlignAllLeft | NSLayoutFormatAlignAllTop;
    NSArray *Hconstraints = [NSLayoutConstraint constraintsWithVisualFormat:Hvfl options:ops metrics:nil views:views];
    NSArray *Vconstraints = [NSLayoutConstraint constraintsWithVisualFormat:Vvfl options:ops metrics:nil views:views];
    [self.view addConstraints:Hconstraints];
    [self.view addConstraints:Vconstraints];
    [self.wkWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.jianshu.com/"]]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)snap{
    [self snapTest];
}

- (void)snapTest{
    CGPoint currentOffset = self.wkWebView.scrollView.contentOffset;
    CGSize totalSize = self.wkWebView.scrollView.contentSize;
    UIGraphicsBeginImageContextWithOptions(totalSize, YES, UIScreen.mainScreen.scale);
    NSInteger page = ceil(totalSize.height / self.wkWebView.bounds.size.height);
    
    NSOperationQueue *oq = [[NSOperationQueue alloc] init];
    [oq setMaxConcurrentOperationCount:1];
    NSBlockOperation *last = nil;
    for (int i = 0; i < page; i++) {
        NSBlockOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.wkWebView.scrollView setContentOffset:CGPointMake(0, i*self.wkWebView.bounds.size.height) animated:NO];
            });
            
        }];
        NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.wkWebView drawViewHierarchyInRect:CGRectMake(0, i*self.wkWebView.bounds.size.height, self.wkWebView.bounds.size.width, self.wkWebView.bounds.size.height) afterScreenUpdates:YES];
            });
        }];
        NSBlockOperation *op3 = [NSBlockOperation blockOperationWithBlock:^{
            [NSThread sleepForTimeInterval:1];
        }];
        [op3 addDependency:op2];
        [op2 addDependency:op1];
        if (last) {
            [op1 addDependency:last];
        }
        else{
            last = op3;
        }
        
        [oq addOperation:op1];
        [oq addOperation:op2];
        [oq addOperation:op3];
        
        if (i == page-1) {
            NSBlockOperation *op4 = [NSBlockOperation blockOperationWithBlock:^{
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    if (snapshotImage) {
                        SaveImage *action = [[SaveImage alloc] init];
                        [action saveImage:snapshotImage];
                    }
                });
            }];
            NSBlockOperation *op5 = [NSBlockOperation blockOperationWithBlock:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.wkWebView.scrollView setContentOffset:currentOffset];
                });
            }];
            [op5 addDependency:op4];
            [op4 addDependency:last];
            [oq addOperation:op4];
            [oq addOperation:op5];
        }
    }
}

- (void)snapSplitView:(int)currentIndex{
    
}

- (void)snapshotForWKWebView:(WKWebView *)webView
{
    UIView *snapshotView = [webView snapshotViewAfterScreenUpdates:YES];
    snapshotView.frame = webView.frame;
    [webView.superview addSubview:snapshotView];
    
    CGPoint currentOffset = webView.scrollView.contentOffset;
    CGRect currentFrame = webView.frame;
    UIView *currentSuperView = webView.superview;
    NSUInteger currentIndex = [webView.superview.subviews indexOfObject:webView];
    
    UIView *containerView = [[UIView alloc] initWithFrame:webView.bounds];
    [webView removeFromSuperview];
    [containerView addSubview:webView];
    
    CGSize totalSize = webView.scrollView.contentSize;
    NSInteger page = ceil(totalSize.height / containerView.bounds.size.height);
    
    webView.scrollView.contentOffset = CGPointZero;
    webView.frame = CGRectMake(0, 0, containerView.bounds.size.width, webView.scrollView.contentSize.height);
    
    UIGraphicsBeginImageContextWithOptions(totalSize, YES, UIScreen.mainScreen.scale);
    [self drawContentPage:containerView webView:webView index:0 maxIndex:page completion:^{
        UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        [webView removeFromSuperview];
        [currentSuperView insertSubview:webView atIndex:currentIndex];
        webView.frame = currentFrame;
        webView.scrollView.contentOffset = currentOffset;
        
        [snapshotView removeFromSuperview];
        
        SaveImage *action = [[SaveImage alloc] init];
        [action saveImage:snapshotImage];
    }];
}

- (void)drawContentPage:(UIView *)targetView webView:(WKWebView *)webView index:(NSInteger)index maxIndex:(NSInteger)maxIndex completion:(dispatch_block_t)completion
{
    CGRect splitFrame = CGRectMake(0, index * CGRectGetHeight(targetView.bounds), targetView.bounds.size.width, targetView.frame.size.height);
    CGRect myFrame = webView.frame;
    myFrame.origin.y = -(index * targetView.frame.size.height);
    webView.frame = myFrame;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [targetView drawViewHierarchyInRect:splitFrame afterScreenUpdates:YES];
        
        if (index < maxIndex) {
            [self drawContentPage:targetView webView:webView index:index + 1 maxIndex:maxIndex completion:completion];
        } else {
            completion();
        }
    });
}

@end
