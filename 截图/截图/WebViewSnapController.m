//
//  WebViewSnapController.m
//  截图
//
//  Created by digitalforest on 2018/8/21.
//  Copyright © 2018年 digitalforest. All rights reserved.
//

#import "WebViewSnapController.h"
#import "SaveImage.h"

@interface WebViewSnapController ()
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation WebViewSnapController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"截屏" style:UIBarButtonItemStylePlain target:self action:@selector(snap)];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.jianshu.com/"]]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)snap{
    [self snapshotForScrollView:self.webView.scrollView];
}

- (void)snapshotForScrollView:(UIScrollView*)scrollView{
    CGPoint currentOffset = scrollView.contentOffset;
    CGRect currentFrame = scrollView.frame;
    
    scrollView.contentOffset = CGPointZero;
    scrollView.frame = CGRectMake(0, 0, scrollView.contentSize.width, scrollView.contentSize.height);
    
    UIGraphicsBeginImageContextWithOptions(scrollView.contentSize,YES,0);
    [scrollView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    scrollView.contentOffset = currentOffset;
    scrollView.frame = currentFrame;
    SaveImage *action = [[SaveImage alloc] init];
    [action saveImage:snapshotImage];
}

@end
